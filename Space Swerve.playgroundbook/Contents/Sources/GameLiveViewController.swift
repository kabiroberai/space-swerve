//
//  GameLiveViewController.swift
//  Book_Sources
//
//  Created by Kabir Oberai on 20/03/19.
//

import UIKit
import SpriteKit
import PlaygroundSupport

public class GameLiveViewController: UIViewController, PlaygroundLiveViewMessageHandler, PlaygroundLiveViewSafeAreaContainer {
    let imageView = UIImageView()
    let gameView = SKView(frame: CGRect(origin: .zero, size: GameScene.gameSize))

    private func presentScene(withConfiguration config: FaceTracker.Configuration?, difficulty: Difficulty) {
        let scene = GameScene(trackerConfiguration: config, gameViewController: self, difficulty: difficulty)
        gameView.presentScene(scene)
        updateOrientation()
        scene.tracker?.startRunning()
    }

    public func startPreview() {
        presentScene(withConfiguration: nil, difficulty: .default)
    }

    public func startGame(ofDifficulty difficulty: Difficulty) {
        presentScene(withConfiguration: .init(), difficulty: difficulty)
    }

    public func restart() {
        let gameScene = gameView.scene as? GameScene
        let configuration = gameScene?.tracker?.configuration
        presentScene(withConfiguration: configuration, difficulty: gameScene?.difficulty ?? .default)
    }

    public func liveViewMessageConnectionOpened() {}

    public func liveViewMessageConnectionClosed() {
        startPreview()
    }

    public func receive(_ message: PlaygroundValue) {
        guard case let .integer(rawDifficulty) = message,
            let difficulty = Difficulty(rawValue: rawDifficulty)
            else { return }
        startGame(ofDifficulty: difficulty)
    }

    private func registerFont(named fontName: String) {
        // https://gist.github.com/JaviLorbada/4c3c07da7d9294fd3d71
        let fontURL = Bundle.main.url(forResource: fontName, withExtension: "ttf")!
        CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        view.clipsToBounds = true

        registerFont(named: "kenvector_future")
        registerFont(named: "kenvector_future_thin")

        // the background image can extend beyond the game view's bounds so make it separately
        imageView.image = UIImage(named: "Background")
        imageView.contentMode = .scaleAspectFill
        view.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            imageView.leftAnchor.constraint(equalTo: view.leftAnchor),
            imageView.rightAnchor.constraint(equalTo: view.rightAnchor)
        ])

        gameView.ignoresSiblingOrder = true
        gameView.backgroundColor = .clear
        gameView.allowsTransparency = true
        gameView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gameView)

        // aspect-fit the scene to the live view safe area guide

        let size = GameScene.gameSize

        let requiredConstraints = [
            gameView.widthAnchor.constraint(equalTo: gameView.heightAnchor, multiplier: size.width / size.height),
            gameView.centerXAnchor.constraint(equalTo: liveViewSafeAreaGuide.centerXAnchor),
            gameView.centerYAnchor.constraint(equalTo: liveViewSafeAreaGuide.centerYAnchor),
        ]
        requiredConstraints.forEach { $0.priority = .required }
        NSLayoutConstraint.activate(requiredConstraints)

        let highConstraints = [
            gameView.widthAnchor.constraint(equalTo: liveViewSafeAreaGuide.widthAnchor),
            gameView.heightAnchor.constraint(equalTo: liveViewSafeAreaGuide.heightAnchor),
            gameView.widthAnchor.constraint(lessThanOrEqualTo: liveViewSafeAreaGuide.widthAnchor),
            gameView.heightAnchor.constraint(lessThanOrEqualTo: liveViewSafeAreaGuide.heightAnchor)
        ]
        highConstraints.forEach { $0.priority = .defaultHigh }
        NSLayoutConstraint.activate(highConstraints)

        startPreview()
    }

    // see IntroLiveViewController for rationale behind using -[UIViewController interfaceOrientation]
    private func updateOrientation() {
        guard let scene = gameView.scene as? GameScene,
            let tracker = scene.tracker
            else { return }
        tracker.updateOrientation(to: interfaceOrientation)
    }

}
