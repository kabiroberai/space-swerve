import UIKit
import PlaygroundSupport

// Instantiate a new instance of the live view from the book's auxiliary sources and pass it to PlaygroundSupport.
let liveView = instantiateGameLiveView()
PlaygroundPage.current.liveView = liveView
