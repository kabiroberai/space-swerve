//#-hidden-code
import Foundation
import PlaygroundSupport
PlaygroundPage.current.needsIndefiniteExecution = true

func startTracking(withConfiguration configuration: FaceTracker.Configuration) {
    let liveView = PlaygroundPage.current.liveView as! PlaygroundRemoteLiveViewProxy
    liveView.send(configuration)
    if configuration.retrackPeriodically &&
        configuration.applyLowPassFilter &&
        configuration.detectLandmarks {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            PlaygroundPage.current.assessmentStatus = .pass(
                message: "Amazing! Now that you've explored the face tracker, move on to the [next page](@next) to check out the game itself."
            )
        }
    }
}
//#-end-hidden-code
//#-code-completion(everything, hide)
//#-code-completion(literal, show, boolean)
/*:
 _Space Swerve_ is a videogame in which you have to dodge asteroids and lasers. There's one twist though: you control the game by moving your head!

 In order to support a large range of devices, the game tracks your face using AVFoundation and Vision instead of ARKit. To achieve a smooth and accurate track, we need to apply a few filters first. In order to see this for yourself, set the following parameters to `true` one by one in the code below.

 - **`retrackPeriodically`**: In order to maximise speed, `FaceTracker` performs full face recognition once and then uses regular object detection. Setting this to `true` performs full face recognition on a periodic basis.

 - **`applyLowPassFilter`**: Setting this to `true` will apply a **low-pass filter** which smoothens out the movement of the bounding box.

 - **`detectLandmarks`**: Setting this to `true` will perform periodic feature detection on your face. This is used in the game to detect whether your mouth is open.

 - Note: When you run the playground, it should draw a red box around your face. If this does not happen, restart your code after ensuring that your environment is well lit and glare-free.
 */
let configuration = FaceTracker.Configuration(
    retrackPeriodically: /*#-editable-code*/false/*#-end-editable-code*/,
    applyLowPassFilter: /*#-editable-code*/false/*#-end-editable-code*/,
    detectLandmarks: /*#-editable-code*/false/*#-end-editable-code*/
)
startTracking(withConfiguration: configuration)
/*:
 You may move on to the next page once you have set all of the above values to `true`.
 */
