//
//  AsteroidNode.swift
//  Book_Sources
//
//  Created by Kabir Oberai on 22/03/19.
//

import SpriteKit

class AsteroidNode: SKNode {
    private enum Variant: String, CaseIterable {
        case brown = "a"
        case gray = "b"

        var particleColor: UIColor {
            switch self {
            case .brown: return UIColor(red: 0.51, green: 0.38, blue: 0.29, alpha: 1)
            case .gray: return UIColor(red: 0.55, green: 0.59, blue: 0.61, alpha: 1)
            }
        }
    }

    private enum StartEdge: CaseIterable {
        case top, bottom, left, right
    }

    static let types = 3

    static let baseSize = CGSize(width: 30, height: 30)
    static let maxSizeMultiplier: CGFloat = 1.5

    static let baseParticleAcceleration: CGFloat = 5
    static let maxSpeedMultiplier: TimeInterval = 1.5

    let sprite: SKSpriteNode
    let particleEmitter: SKEmitterNode

    var velocity: Double?
    var unitAngleVector: CGPoint?

    override init() {
        let type = Int.random(in: 1...AsteroidNode.types)
        let variant = Variant.allCases.randomElement()!
        let texture = SKTexture(imageNamed: "asteroid-\(type)\(variant.rawValue)")

        let sizeMultiplier = CGFloat.random(in: 1...AsteroidNode.maxSizeMultiplier)
        let textureSize = texture.size().aspectScaled(to: AsteroidNode.baseSize, fill: false) * sizeMultiplier
        sprite = SKSpriteNode(texture: texture, color: .white, size: textureSize)

        particleEmitter = SKEmitterNode(fileNamed: "AsteroidParticle.sks")!
        particleEmitter.particleColorSequence = nil
        particleEmitter.particleColor = variant.particleColor
        super.init()

        physicsBody = SKPhysicsBody(rectangleOf: textureSize)
        physicsBody?.category = .asteroid
        physicsBody?.collisionCategory = .none
        physicsBody?.contactTestCategory = .none

        sprite.position = .zero
        sprite.zPosition = 1
        addChild(sprite)

        particleEmitter.position = .zero
        addChild(particleEmitter)

        zRotation = CGFloat.random(in: 0...(2 * .pi))
        particleEmitter.zRotation = -zRotation
    }
    required init?(coder aDecoder: NSCoder) {
        unimplemented()
    }

    func setDestination(_ dest: CGPoint) {
        let edge = StartEdge.allCases.randomElement()!

        let size = sprite.size
        let top: CGFloat = scene!.size.height + size.height / 2
        let bottom: CGFloat = -size.height / 2
        let left: CGFloat = -size.width / 2
        let right: CGFloat = scene!.size.width + size.width / 2

        let horizontalRange = left...right
        let verticalRange = bottom...top

        let start: CGPoint
        switch edge {
        case .top:
            start = CGPoint(x: CGFloat.random(in: horizontalRange), y: top)
        case .bottom:
            start = CGPoint(x: CGFloat.random(in: horizontalRange), y: bottom)
        case .left:
            start = CGPoint(x: left, y: CGFloat.random(in: verticalRange))
        case .right:
            start = CGPoint(x: right, y: CGFloat.random(in: verticalRange))
        }

        position = start

        let destAngle = atan2(dest.y - start.y, dest.x - start.x)
        let targetAngle = destAngle + CGFloat.random(in: (-.pi / 7)...(.pi / 7))

        let speedMultiplier = TimeInterval.random(in: 1...AsteroidNode.maxSpeedMultiplier)

        unitAngleVector = CGPoint(x: cos(targetAngle), y: sin(targetAngle))
        velocity = gameDifficulty.asteroidVelocity * speedMultiplier

        let scaled = unitAngleVector! * CGFloat(velocity!)
        physicsBody!.applyImpulse(CGVector(dx: scaled.x, dy: scaled.y))
    }

    func update(dt: TimeInterval) {
        let velocity = physicsBody!.velocity
        let magnitude = sqrt(pow(velocity.dx, 2) + pow(velocity.dy, 2))
        let targetAngle = atan2(velocity.dy, velocity.dx)

        particleEmitter.xAcceleration = cos(targetAngle + .pi) * magnitude / 50
        particleEmitter.yAcceleration = sin(targetAngle + .pi) * magnitude / 50
        particleEmitter.emissionAngle = targetAngle + .pi
    }

}
