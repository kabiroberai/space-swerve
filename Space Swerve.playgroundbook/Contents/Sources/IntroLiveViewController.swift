import UIKit
import PlaygroundSupport
import AVFoundation

public class IntroLiveViewController: UIViewController, PlaygroundLiveViewMessageHandler, PlaygroundLiveViewSafeAreaContainer {
    let outputLayer = AVCaptureVideoPreviewLayer()
    
    var tracker: FaceTracker?

    private var square: UIView!

    public func liveViewMessageConnectionOpened() {}

    public func liveViewMessageConnectionClosed() {
        square.isHidden = true
    }

    public func startTracker(withConfiguration config: FaceTracker.Configuration) {
        square.isHidden = false

        tracker = try? FaceTracker(configuration: config)
        tracker?.delegate = self
        outputLayer.session = tracker?.session
        tracker?.startRunning()
        updateOrientation()
    }

    public func startPreview() {
        startTracker(withConfiguration: .init())
        square.isHidden = true
    }

    public func receive(_ message: PlaygroundValue) {
        FaceTracker.Configuration(value: message).map(startTracker)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        square = UIView()
        square.layer.borderColor = UIColor.red.cgColor
        square.layer.borderWidth = 2
        square.layer.zPosition = 10
        view.addSubview(square)

        outputLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(outputLayer)
    }

    // we can't use UIApplication.shared.statusBarOrientation because Playgrounds doesn't allow
    // access to UIApplication.shared
    private func updateOrientation() {
        outputLayer.connection?.videoOrientation = interfaceOrientation.avOrientation
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        outputLayer.frame = view.layer.bounds
        updateOrientation()
    }

    private var prevHeight: CGFloat?
}

extension IntroLiveViewController: FaceTrackerDelegate {

    func faceTracker(_ faceTracker: FaceTracker, didObserveFaceRectangle observation: FaceTracker.RectangleObservation?) {
        let outputFrame = observation.map { outputLayer.layerRectConverted(fromMetadataOutputRect: $0.boundingBox) } ?? .zero
        DispatchQueue.main.async {
            self.square.frame = outputFrame
        }
    }

    func faceTracker(_ faceTracker: FaceTracker, didObserveLips lips: FaceTracker.LipsObservation?) {
        let color: UIColor = (lips?.areOpen == true) ? .green : .red
        DispatchQueue.main.async {
            self.square.layer.borderColor = color.cgColor
        }
    }

}
