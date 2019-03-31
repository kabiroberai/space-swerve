//
//  FaceTracker.swift
//  Book_Sources
//
//  Created by Kabir Oberai on 19/03/19.
//

import UIKit
import AVFoundation

protocol FaceTrackerDelegate: class {
    func faceTracker(_ faceTracker: FaceTracker, didObserveFaceRectangle observation: FaceTracker.RectangleObservation?)

    func faceTracker(_ faceTracker: FaceTracker, didObserveLips lips: FaceTracker.LipsObservation?)
}

public class FaceTracker {
    struct RectangleObservation {
        private enum Delta {
            case small
            case medium
            case large

            static func between(_ a: RectangleObservation, _ b: RectangleObservation) -> Delta {
                let area1 = a.boundingBox.width * a.boundingBox.height
                let area2 = b.boundingBox.width * b.boundingBox.height
                let largerArea = max(area1, area2)
                let smallerArea = min(area1, area2)
                let ratio = largerArea / smallerArea

                let sqDist = a.boundingBox.center.squaredDistance(from: b.boundingBox.center)

                if sqDist > pow(0.5, 2) || ratio > 4 {
                    return .large
                } else if sqDist > pow(0.25, 2) || ratio > 2.5 {
                    return .medium
                } else {
                    return .small
                }
            }
        }

        let confidence: Float
        /// bounds with origin at top left
        let boundingBox: CGRect
        let relativeCenter: CGPoint

        init(old oldObs: RectangleObservation, new newObs: RectangleObservation, interpolatingBy factor: CGFloat) {
            self.confidence = newObs.confidence

            let old = oldObs.boundingBox
            let new = newObs.boundingBox

            self.boundingBox = CGRect(
                x: old.origin.x + factor * (new.origin.x - old.origin.x),
                y: old.origin.y + factor * (new.origin.y - old.origin.y),
                width: old.width + factor * (new.width - old.width),
                height: old.height + factor * (new.height - old.height)
            )

            let oldCenter = old.center
            let newCenter = new.center
            let relativeCenter: CGPoint
            switch Delta.between(oldObs, newObs) {
            case .large: // reset position to new center
                relativeCenter = newCenter
            case .medium: // don't change position at all
                relativeCenter = oldObs.relativeCenter
            case .small: // adjust position relative to old one
                relativeCenter = oldObs.relativeCenter + (newCenter - oldCenter)
            }
            self.relativeCenter = relativeCenter
        }

        func isDistant(from other: RectangleObservation) -> Bool {
            return Delta.between(self, other) != .small
        }
    }

    struct LipsObservation {
        private static let openGap: CGFloat = 0.25

        let confidence: Float
        let gap: CGFloat

        var areOpen: Bool {
            return gap > LipsObservation.openGap
        }
    }

    enum Error: Swift.Error {
        case invalidInput
        case invalidOutput
    }

    weak var delegate: FaceTrackerDelegate?

    let configuration: Configuration
    let session = AVCaptureSession()
    var connection: AVCaptureConnection?
    private var _resolution: CGSize!
    // we could do private(set) var resolution: CGSize! but that would reveal its IUO-ness
    var resolution: CGSize { return _resolution }

    private var outputBufferer: OutputBufferer!

    init(configuration: Configuration) throws {
        self.configuration = configuration
        
        outputBufferer = OutputBufferer(tracker: self)
        try configureSession()
    }

    deinit {
        // there may be leftover frames that are sent to the bufferer after the FaceTracker deallocates.
        // this ensures that when those frames come in, the bufferer doesn't try to access the tracker
        // which would cause a crash since it's `unowned`
        outputBufferer.ignoreOutput = true
        session.stopRunning()
    }

    // loosely based off https://developer.apple.com/documentation/vision/tracking_the_user_s_face_in_real_time
    private func configureSession() throws {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
            else { throw Error.invalidInput }
        let input = try AVCaptureDeviceInput(device: device)
        guard session.canAddInput(input) else { throw Error.invalidInput }
        session.addInput(input)

        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(outputBufferer, queue: outputBufferer.bufferQueue)

        guard session.canAddOutput(output) else { throw Error.invalidOutput }
        session.addOutput(output)

        guard let connection = output.connection(with: .video) else { throw Error.invalidOutput }
        self.connection = connection
        connection.isEnabled = true
        if connection.isCameraIntrinsicMatrixDeliverySupported {
            connection.isCameraIntrinsicMatrixDeliveryEnabled = true
        }
    }

    func updateOrientation(to orientation: UIInterfaceOrientation) {
        let videoOrientation: AVCaptureVideoOrientation
        switch orientation {
        case .portraitUpsideDown: videoOrientation = .portrait
        case .landscapeRight: videoOrientation = .landscapeLeft
        case .landscapeLeft: videoOrientation = .landscapeRight
        default: videoOrientation = .portraitUpsideDown
        }
        connection?.videoOrientation = videoOrientation
    }

    func startRunning() {
        session.startRunning()
    }

}
