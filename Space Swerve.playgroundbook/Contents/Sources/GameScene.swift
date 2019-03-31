//
//  GameScene.swift
//  Book_Sources
//
//  Created by Kabir Oberai on 20/03/19.
//

import SpriteKit

class GameScene: SKScene {

    static let gameSize = CGSize(width: 600, height: 350)

    private static let startPosition = CGPoint(x: 0.5, y: 0.75)
    private static let scaleFactor: CGFloat = 3.5
    private static let lowPassResistance: CGFloat = 0.6

    enum AsteroidSpawnerState {
        case isPrepared
        case ready(nextSpawnTime: TimeInterval)
    }

    enum EnemyState {
        case isFiring
        case finished
        case ready(nextSpawnTime: TimeInterval)
    }

    enum ChargeState {
        case isAvailable
        case isAbsorbed
        case finished
        case ready(nextSpawnTime: TimeInterval)
    }

    weak var gameViewController: GameLiveViewController?

    var isGameOver = false
    let timeLabel = SKLabelNode()
    var startTime: Date?
    var currentScore: Int {
        guard let startTime = startTime else { return 0 }
        return Int(floor(Date().timeIntervalSince(startTime) * 10))
    }

    let difficulty: Difficulty

    let tracker: FaceTracker?
    var trackerOffset: CGPoint?

    var isPreview: Bool { return tracker == nil }
    var wereLipsOpen = false
    var lowPassPosition: CGPoint?

    var backgroundMusicNode: SKAudioNode!

    let ufo = UFONode()

    let enemy = EnemyNode()
    var enemyStart: CGPoint!
    var enemyState: EnemyState = .finished

    var asteroids: [AsteroidNode] = []
    private var lastAsteroidTime: TimeInterval = 0
    var nextAsteroidSpawnTime: TimeInterval?

    private static let chargeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    let charge = ChargeNode()
    var chargeState: ChargeState = .finished

    let releaseIndicator = ImageLabelNode(imageNamed: "Charge Badge", text: "Open Mouth to Release Charge")

    /// Creates a new `GameScene`.
    ///
    /// - Parameter trackerConfiguration: The configuration options for the face tracker. Pass `nil` to make this a
    /// preview `GameScene`.
    init(trackerConfiguration: FaceTracker.Configuration?, gameViewController: GameLiveViewController, difficulty: Difficulty) {
        self.difficulty = difficulty
        self.tracker = try! trackerConfiguration.map(FaceTracker.init)
        self.gameViewController = gameViewController
        super.init(size: GameScene.gameSize)
        tracker?.delegate = self
    }
    required init?(coder aDecoder: NSCoder) {
        unimplemented()
    }

    override func sceneDidLoad() {
        super.sceneDidLoad()

        // the scaleMode shouldn't be needed anyway since it's managed by AL
        scaleMode = .aspectFit
        backgroundColor = .clear

        physicsWorld.contactDelegate = self
        // we're not really using any dynamic physics bodies, but hey, space has near-zero gravity anyway
        physicsWorld.gravity = .zero

        physicsBody = SKPhysicsBody(rectangleOf: size, center: frame.center)
        physicsBody?.isDynamic = false
        physicsBody?.category = .scene
        physicsBody?.contactTestCategory = .asteroid

        let backgroundMusicURL = Bundle.main.url(forResource: "Background", withExtension: "m4a")!
        backgroundMusicNode = SKAudioNode(url: backgroundMusicURL)
        backgroundMusicNode.run(.changeVolume(to: 0.5, duration: 0))

        if isPreview {
            ufo.position = frame.center

            var textY: CGFloat = 20
            // descending order so that the hardest is the bottom-most
            let completed = Difficulty.completedDifficulties.sorted { $0.rawValue > $1.rawValue }
            for difficulty in completed {
                let textNode = SKLabelNode(text: difficulty.displayText)
                textNode.fontColor = .white
                textNode.fontName = "KenVector Future Thin"
                textNode.fontSize = 15
                textNode.verticalAlignmentMode = .bottom
                textNode.horizontalAlignmentMode = .left
                textNode.position = CGPoint(x: 20, y: textY)
                addChild(textNode)
                textY += textNode.calculateAccumulatedFrame().size.height + 10
            }

            if !completed.isEmpty {
                let completedNode = SKLabelNode(text: "Completed:")
                completedNode.fontColor = .white
                completedNode.fontName = "KenVector Future"
                completedNode.fontSize = 18
                completedNode.verticalAlignmentMode = .bottom
                completedNode.horizontalAlignmentMode = .left
                completedNode.position = CGPoint(x: 20, y: textY)
                addChild(completedNode)
            }
        } else {
            ufo.position = CGPoint(
                x: GameScene.startPosition.x * frame.width,
                y: GameScene.startPosition.y * frame.height
            )
            addChild(ufo)

            addChild(backgroundMusicNode)

            timeLabel.horizontalAlignmentMode = .left
            timeLabel.verticalAlignmentMode = .baseline
            timeLabel.fontColor = .white
            timeLabel.fontSize = 20
            timeLabel.fontName = "KenVector Future Thin"
            timeLabel.position = CGPoint(x: 20, y: 20)
            timeLabel.zPosition = 10
            addChild(timeLabel)
        }

        let enemySize = enemy.sprite.size
        let topMargin: CGFloat = 10
        enemyStart = CGPoint(x: -enemySize.width / 2, y: size.height - enemySize.height / 2 - topMargin)
        enemy.position = enemyStart
        addChild(enemy)

        charge.isHidden = true
        addChild(charge)

        let releaseFrame = releaseIndicator.calculateAccumulatedFrame()
        releaseIndicator.position = CGPoint(
            x: size.width - releaseFrame.width,
            y: releaseFrame.height / 2 + 17
        )
        releaseIndicator.isHidden = true
        addChild(releaseIndicator)
    }

    private func spawnAsteroid() {
        let node = AsteroidNode()
        asteroids.append(node)
        addChild(node)
        node.setDestination(ufo.position)
    }

    private func removeAsteroid(_ asteroid: AsteroidNode) {
        asteroid.run(.sequence([
            .wait(forDuration: 4),
            .removeFromParent(),
            .run { self.asteroids.removeAll { $0 === asteroid } }
        ]))
    }

    private func spawnEnemy() {
        let enemySize = enemy.sprite.size
        let horizontalMargins: CGFloat = 10

        let moveSpeed: TimeInterval = 300
        let exitSpeed: TimeInterval = 500

        let waitTime: TimeInterval = 5
        let waitMaxMultiplier: TimeInterval = 1.5

        let left = enemySize.width / 2 + horizontalMargins
        let right = size.width - enemySize.width / 2 - horizontalMargins
        let moveDistance = right - left
        let moveDuration = TimeInterval(moveDistance) / moveSpeed

        let key = "moveAction"
        enemy.run(.repeatForever(.sequence([
            .moveTo(x: right, duration: moveDuration),
            .moveTo(x: left, duration: moveDuration),
        ])), withKey: key)

        enemy.run(.sequence([
            .wait(forDuration: waitTime * TimeInterval.random(in: 1...waitMaxMultiplier)),
            .run {
                self.enemy.removeAction(forKey: key)
                self.enemy.fire {
                    self.enemy.run(.sequence([
                        .moveTo(
                            x: self.enemyStart.x,
                            duration: TimeInterval(self.enemy.position.x - self.enemyStart.x) / exitSpeed
                        ),
                        .run {
                            self.enemyState = .finished
                        }
                    ]))
                }
            }
        ]))
    }

    private func spawnCharge() {
        let rect = frame.insetBy(dx: charge.size.width, dy: charge.size.height).inset(by: GameScene.chargeInsets)

        // pick a location that isn't too close to the UFO
        let minDistanceFromUFO = (ufo.ufoRim.size.width / 2) * 1.5
        var chargePosition: CGPoint
        repeat {
            chargePosition = CGPoint(
                x: .random(in: rect.minX...rect.maxX),
                y: .random(in: rect.minY...rect.maxY)
            )
        } while chargePosition.distance(from: ufo.position) < minDistanceFromUFO
        charge.position = chargePosition
        charge.isHidden = false
    }

    private func absorbCharge() {
        guard !isGameOver else { return }
        releaseIndicator.isHidden = false
        run(.playSoundFileNamed("Absorb.mp3", waitForCompletion: false))
    }

    private func releaseCharge() {
        releaseIndicator.isHidden = true
        ufo.releaseCharge()
        run(.playSoundFileNamed("Release.mp3", waitForCompletion: false))
    }

    private func ufoDidContact(_ node: SKNode) {
        guard !isGameOver else { return }

        let canAbsorbCharge: Bool
        switch chargeState {
        case .isAvailable: canAbsorbCharge = true
        default: canAbsorbCharge = false
        }

        if let charge = node as? ChargeNode, canAbsorbCharge {
            charge.isHidden = true
            chargeState = .isAbsorbed
            absorbCharge()
        } else if !(node is ChargeNode) {
            gameOver()
            node.removeFromParent()
        }
    }

    private func gameOver() {
        isGameOver = true

        self.releaseIndicator.isHidden = true

        let fadeOut: SKAction = .fadeOut(withDuration: 0.1)
        enemy.run(.sequence([
            fadeOut,
            .run { self.enemy.isPaused = true }
        ]))
        asteroids.forEach { $0.run(fadeOut) }
        charge.removeAllActions()
        charge.run(fadeOut)
        backgroundMusicNode.run(.changeVolume(to: 0, duration: 0.1))

        ufo.explode()

        let gameOverLabel = SKLabelNode(text: "Game Over")
        gameOverLabel.fontColor = .white
        gameOverLabel.fontSize = 40
        gameOverLabel.fontName = "KenVector Future"
        gameOverLabel.verticalAlignmentMode = .center
        gameOverLabel.horizontalAlignmentMode = .center
        gameOverLabel.position = frame.center
        gameOverLabel.zPosition = 10
        addChild(gameOverLabel)

        gameOverLabel.run(.repeatForever(.sequence([
            .wait(forDuration: 0.5),
            .hide(),
            .wait(forDuration: 0.5),
            .unhide()
        ])))

        let restartLabel = SKLabelNode(text: "Tap anywhere to restart")
        restartLabel.fontColor = .white
        restartLabel.fontSize = 19.5
        restartLabel.fontName = "KenVector Future Thin"
        restartLabel.verticalAlignmentMode = .center
        restartLabel.horizontalAlignmentMode = .center
        restartLabel.position = CGPoint(
            x: gameOverLabel.position.x,
            y: gameOverLabel.position.y
                - gameOverLabel.calculateAccumulatedFrame().size.height / 2
                - 10
                - restartLabel.calculateAccumulatedFrame().size.height / 2
        )
        restartLabel.zPosition = 10
        addChild(restartLabel)

        gameViewController?.send(.boolean(true))
    }

    private func calculateNextAsteroidSpawnTime(isInitial: Bool, currentTime: TimeInterval) -> TimeInterval {
        if isInitial {
            return currentTime + (isPreview ? 0 : 2)
        } else {
            return currentTime + difficulty.asteroidSpawnPeriod
        }
    }

    private func setNextAsteroidSpawnTime(isInitial: Bool, currentTime: TimeInterval) {
        nextAsteroidSpawnTime = calculateNextAsteroidSpawnTime(isInitial: isInitial, currentTime: currentTime)
    }

    private var markedCompleted = false // so that we don't keep accessing the KV-store
    private var lastUpdateTime: TimeInterval = 0
    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)

        guard !isGameOver else { return }

        if startTime == nil {
            startTime = Date()
        }

        if !isPreview && !markedCompleted && currentScore >= difficulty.baselineScore {
            difficulty.setCompleted()
            markedCompleted = true
        }
        timeLabel.text = "Score: \(currentScore)"

        let dt = currentTime - lastUpdateTime
        lastUpdateTime = currentTime

        asteroids.forEach { $0.update(dt: dt) }
        if let nextAsteroidSpawnTime = nextAsteroidSpawnTime, currentTime >= nextAsteroidSpawnTime {
            spawnAsteroid()
            setNextAsteroidSpawnTime(isInitial: false, currentTime: currentTime)
        } else if nextAsteroidSpawnTime == nil {
            setNextAsteroidSpawnTime(isInitial: true, currentTime: currentTime)
        }

        switch enemyState {
        case .finished:
            let nextSpawnTime = currentTime + difficulty.enemySpawnPeriod * TimeInterval.random(in: 1...1.5)
            enemyState = .ready(nextSpawnTime: nextSpawnTime)
        case .ready(let nextSpawnTime) where !isPreview && currentTime >= nextSpawnTime:
            enemyState = .isFiring
            spawnEnemy()
        default:
            break
        }

        switch chargeState {
        case .finished:
            let nextSpawnTime = currentTime + difficulty.chargeSpawnPeriod * TimeInterval.random(in: 1...1.5)
            chargeState = .ready(nextSpawnTime: nextSpawnTime)
        case .ready(let nextSpawnTime) where !isPreview && currentTime >= nextSpawnTime:
            chargeState = .isAvailable
            spawnCharge()
        default:
            break
        }
    }

    func changeMouthState(isOpen: Bool) {
        guard !isGameOver else { return }

        let isChargeAbsorbed: Bool
        switch chargeState {
        case .isAbsorbed: isChargeAbsorbed = true
        default: isChargeAbsorbed = false
        }

        if isOpen && isChargeAbsorbed {
            chargeState = .finished
            releaseCharge()
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        if isGameOver {
            gameViewController?.restart()
        }
    }

}

extension GameScene: FaceTrackerDelegate {

    func faceTracker(_ faceTracker: FaceTracker, didObserveFaceRectangle observation: FaceTracker.RectangleObservation?) {
        guard let observation = observation, !isGameOver else { return }

        let scaledCenter = observation.relativeCenter * GameScene.scaleFactor

        if trackerOffset == nil {
            // calibrate the offset such that the UFO is at `GameScene.startPosition` in the beginning
            trackerOffset = GameScene.startPosition - scaledCenter
        }

        let center = scaledCenter + trackerOffset!

        let ufoSize = ufo.ufoRim.size
        let position = CGPoint(
            x: (size.width * center.x).clamped(to: (ufoSize.width / 2)...(size.width - ufoSize.width / 2)),
            y: (size.height * center.y).clamped(to: (ufoSize.height / 2)...(size.height - ufoSize.height / 2))
        )

        let lowPassPosition: CGPoint
        if let oldPosition = self.lowPassPosition {
            lowPassPosition = oldPosition + (position - oldPosition) * (1 - GameScene.lowPassResistance)
        } else {
            lowPassPosition = position
        }
        self.lowPassPosition = lowPassPosition
        DispatchQueue.main.async {
            self.ufo.position = lowPassPosition
        }
    }

    func faceTracker(_ faceTracker: FaceTracker, didObserveLips lips: FaceTracker.LipsObservation?) {
        let areLipsOpen = lips?.areOpen ?? false
        if wereLipsOpen != areLipsOpen {
            DispatchQueue.main.async {
                self.changeMouthState(isOpen: areLipsOpen)
            }
        }
        wereLipsOpen = areLipsOpen
    }

}

extension GameScene: SKPhysicsContactDelegate {

    func didBegin(_ contact: SKPhysicsContact) {
        if contact.bodyA.node is UFONode, let node = contact.bodyB.node {
            ufoDidContact(node)
        } else if contact.bodyB.node is UFONode, let node = contact.bodyA.node {
            ufoDidContact(node)
        }
    }

    func didEnd(_ contact: SKPhysicsContact) {
        if contact.bodyA.node is GameScene, let asteroid = contact.bodyB.node as? AsteroidNode {
            removeAsteroid(asteroid)
        } else if contact.bodyB.node is GameScene, let asteroid = contact.bodyA.node as? AsteroidNode {
            removeAsteroid(asteroid)
        }
    }

}
