//
//  OutputBufferer.swift
//  Book_Sources
//
//  Created by Kabir Oberai on 20/03/19.
//

import Foundation
import AVFoundation
import Vision

private extension FaceTracker.RectangleObservation {
    init(objectObservation: VNDetectedObjectObservation) {
        self.confidence = objectObservation.confidence

        let bounds = objectObservation.boundingBox
        self.boundingBox = CGRect(
            x: bounds.origin.x,
            y: 1 - bounds.origin.y - bounds.height,
            width: bounds.width,
            height: bounds.height
        )

        self.relativeCenter = self.boundingBox.center
    }
}

private extension FaceTracker.LipsObservation {
    init?(faceObservation: VNFaceObservation) {
        self.confidence = faceObservation.confidence

        guard let lips = faceObservation.landmarks?.outerLips,
            lips.pointCount > 1
            else { return nil }

        let points = lips.normalizedPoints
        let path = CGMutablePath()
        path.move(to: points[0])
        path.addLines(between: points)
        path.addLine(to: points[0])
        path.closeSubpath()

        self.gap = path.boundingBox.height
    }
}

class OutputBufferer: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    /// The interval after which the bufferer does an accurate face track (rather than a simple object track).
    ///
    /// A value of zero means that the bufferer will track the user's face continuously.
    private static let accurateTrackInterval: TimeInterval = 0

    /// The interval after which facial landmarks are re-scanned
    ///
    /// A value of zero means that the bufferer will scan the user's facial landmarks continuously.
    private static let landmarkTrackInterval: TimeInterval = 0.05

    /// The amount by which the bounding box resists changes
    private static let lowPassResistance: CGFloat = 0.75

    /// The minimum confidence level required for an observation.
    /// If this is not met then the observation is discarded.
    private static let minimumConfidence: Float = 0.3

    // these are serial queues so that the processing happens in order
    private let faceRectanglesQueue = DispatchQueue(label: "com.kabiroberai.WWDC19.FaceRectanglesQueue", qos: .utility)
    private let faceLandmarksQueue = DispatchQueue(label: "com.kabiroberai.WWDC19.FaceLandmarksQueue", qos: .background)
    let bufferQueue = DispatchQueue(label: "com.kabiroberai.WWDC19.BufferQueue", qos: .default)

    private var lastObservation: FaceTracker.RectangleObservation?
    private var sequenceRequestHandler: VNSequenceRequestHandler!
    private var objectRequest: VNTrackObjectRequest?

    private var centerOffset: CGPoint?
    private var previousCenter: CGPoint?

    private var lastLandmarkRequest: Date = .distantPast
    private var isTrackingLandmarks = false
    private var landmarkLock = NSLock()

    private var lastRectangleTrack: Date = .distantPast
    private var isTrackingRectangle = false
    private var rectangleLock = NSLock()

    var ignoreOutput = false
    private unowned let tracker: FaceTracker

    init(tracker: FaceTracker) {
        self.tracker = tracker
        super.init()

        createSequenceRequestHandler()
    }

    private func createSequenceRequestHandler() {
        sequenceRequestHandler = VNSequenceRequestHandler()
    }

    private func handle(rectangleObservation: FaceTracker.RectangleObservation?) {
        if rectangleObservation == nil {
            // if there was no observation then we have to reset objectRequest
            objectRequest = nil
            // this also means there are no lip observations
            handle(lips: nil)
        }

        if let observation = rectangleObservation, let lastObservation = lastObservation {
            self.lastObservation = FaceTracker.RectangleObservation(
                old: lastObservation,
                new: observation,
                interpolatingBy: tracker.configuration.applyLowPassFilter ? 1 - OutputBufferer.lowPassResistance : 1
            )
        } else {
            lastObservation = rectangleObservation
        }

        tracker.delegate?.faceTracker(tracker, didObserveFaceRectangle: lastObservation)
    }

    private func handle(lips: FaceTracker.LipsObservation?) {
        tracker.delegate?.faceTracker(tracker, didObserveLips: lips)
    }

    private func detectFaceLandmarks(inObservation observation: VNFaceObservation, requestHandler: VNImageRequestHandler) {
        let detectFaceLandmarksRequest = VNDetectFaceLandmarksRequest { [weak self] untypedRequest, error in
            guard let self = self, !self.ignoreOutput else { return }

            self.landmarkLock.lock()
            defer { self.landmarkLock.unlock() }

            defer {
                self.isTrackingLandmarks = false
                self.lastLandmarkRequest = Date()
            }

            guard error == nil,
                let request = untypedRequest as? VNDetectFaceLandmarksRequest,
                let results = request.results as? [VNFaceObservation]
                else { return self.handle(lips: nil) }

            self.handle(
                lips: results.first.flatMap(FaceTracker.LipsObservation.init(faceObservation:))
            )
        }

        detectFaceLandmarksRequest.inputFaceObservations = [observation]
        try? requestHandler.perform([detectFaceLandmarksRequest])
    }

    private func detectFaceRectangles(requestHandler: VNImageRequestHandler) {
        let detectFaceRectanglesRequest = VNDetectFaceRectanglesRequest { [weak self] untypedRequest, error in
            guard let self = self, !self.ignoreOutput else { return }

            self.rectangleLock.lock()
            defer { self.rectangleLock.unlock() }

            defer {
                self.isTrackingRectangle = false
                self.lastRectangleTrack = Date()
            }

            guard error == nil,
                let request = untypedRequest as? VNDetectFaceRectanglesRequest,
                let results = request.results as? [VNFaceObservation]
                else { return }

            let trackingRequestNeedsReset: Bool

            if let prev = self.lastObservation, let result = results.first {
                let curr = FaceTracker.RectangleObservation(objectObservation: result)
                trackingRequestNeedsReset = self.tracker.configuration.retrackPeriodically && curr.isDistant(from: prev)
            } else {
                trackingRequestNeedsReset = true
            }

            if trackingRequestNeedsReset {
                self.objectRequest?.isLastFrame = true
                self.objectRequest = results.first.map(VNTrackObjectRequest.init(detectedObjectObservation:))
                self.createSequenceRequestHandler()
            }

            guard let result = results.first else { return }

            self.landmarkLock.lock()
            let timeSinceFeatures = Date().timeIntervalSince(self.lastLandmarkRequest)
            if !self.isTrackingLandmarks,
                self.tracker.configuration.detectLandmarks &&
                    timeSinceFeatures > OutputBufferer.landmarkTrackInterval {
                self.isTrackingLandmarks = true
                self.faceLandmarksQueue.async { [weak self] in
                    guard let self = self, !self.ignoreOutput else { return }
                    self.detectFaceLandmarks(inObservation: result, requestHandler: requestHandler)
                }
            }
            self.landmarkLock.unlock()
        }

        try? requestHandler.perform([detectFaceRectanglesRequest])
    }

    private func detectFaceObject(pixelBuffer: CVPixelBuffer) {
        guard let request = objectRequest else { return handle(rectangleObservation: nil) }

        try? sequenceRequestHandler.perform([request], on: pixelBuffer)

        guard let observation = request.results?.first as? VNDetectedObjectObservation,
            observation.confidence > OutputBufferer.minimumConfidence
            else {
                request.isLastFrame = true
                return handle(rectangleObservation: nil)
        }

        guard observation.confidence > OutputBufferer.minimumConfidence else { return handle(rectangleObservation: nil) }

        request.inputObservation = observation

        let faceObservation = FaceTracker.RectangleObservation(objectObservation: observation)
        handle(rectangleObservation: faceObservation)
    }

    func captureOutput(
        _ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection
    ) {
        guard !ignoreOutput else { return }

        var requestHandlerOptions: [VNImageOption: AnyObject] = [:]
        if let intrinsicData = CMGetAttachment(
            sampleBuffer, key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, attachmentModeOut: nil
        ) {
            requestHandlerOptions[.cameraIntrinsics] = intrinsicData
        }
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        rectangleLock.lock()
        let timeSinceRectangle = Date().timeIntervalSince(lastRectangleTrack)
        if !isTrackingRectangle,
            objectRequest == nil || timeSinceRectangle > OutputBufferer.accurateTrackInterval {
            isTrackingRectangle = true
            faceRectanglesQueue.async { [weak self] in
                guard let self = self, !self.ignoreOutput else { return }
                let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: requestHandlerOptions)
                self.detectFaceRectangles(requestHandler: requestHandler)
            }
        }
        rectangleLock.unlock()

        detectFaceObject(pixelBuffer: pixelBuffer)
    }
}
