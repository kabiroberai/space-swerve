import UIKit
import PlaygroundSupport

/// Instantiates a new instance of a live view.
public func instantiateIntroLiveView() -> IntroLiveViewController {
    let liveViewController = IntroLiveViewController()
    _ = liveViewController.view
    return liveViewController
}
