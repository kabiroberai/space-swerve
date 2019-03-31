//
//  GameLiveViewSupport.swift
//  Book_Sources
//
//  Created by Kabir Oberai on 20/03/19.
//

import UIKit
import PlaygroundSupport

/// Instantiates a new instance of a live view.
public func instantiateGameLiveView() -> GameLiveViewController {
    let liveViewController = GameLiveViewController()
    // load the liveView's view so that viewDidLoad is called, which initializes a preview GameScene.
    // this way, our own startTracker call will occur after viewDidLoad's. If this were not the case
    // then the tracker might be buggy
    _ = liveViewController.view
    return liveViewController
}
