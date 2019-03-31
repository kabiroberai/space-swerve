//
//  UFONode.swift
//  Book_Sources
//
//  Created by Kabir Oberai on 20/03/19.
//

import SpriteKit

class UFONode: SKNode {

    static let baseSize = CGSize(width: 75, height: 75)

    let ufoCenter: SKSpriteNode
    let ufoMiddle: SKSpriteNode
    let ufoRim: SKSpriteNode

    private func rotate(_ part: SKSpriteNode, duration: TimeInterval) {
        part.run(.repeatForever(.rotate(byAngle: 2 * .pi, duration: duration)))
    }

    override init() {
        let rimTexture = SKTexture(imageNamed: "UFO Rim")
        let ufoSize = rimTexture.size().aspectScaled(to: UFONode.baseSize, fill: false)
        ufoRim = SKSpriteNode(texture: rimTexture, color: .white, size: ufoSize)

        let middleTexture = SKTexture(imageNamed: "UFO Middle")
        ufoMiddle = SKSpriteNode(texture: middleTexture, color: .white, size: ufoSize)

        let centerTexture = SKTexture(imageNamed: "UFO Center")
        ufoCenter = SKSpriteNode(texture: centerTexture, color: .white, size: ufoSize)

        super.init()

        zPosition = 2

        physicsBody = SKPhysicsBody(circleOfRadius: ufoSize.width / 2)
        physicsBody?.category = .ufo
        physicsBody?.collisionCategory = .none
        physicsBody?.fieldCategory = .none
        physicsBody?.contactTestCategory = [.asteroid, .enemy]

        addChild(ufoRim)
        rotate(ufoRim, duration: 5)

        addChild(ufoMiddle)
        rotate(ufoMiddle, duration: 8)

        addChild(ufoCenter)
        rotate(ufoCenter, duration: 11)
    }
    required init?(coder aDecoder: NSCoder) {
        unimplemented()
    }

    func releaseCharge() {
        let fieldMultiplier = gameDifficulty.ufoChargeRadiusMultiplier
        let chargeDuration: TimeInterval = 0.5

        let field = SKFieldNode.radialGravityField()
        field.strength = -gameDifficulty.ufoChargeStrength // outwards
        field.region = SKRegion(radius: Float(ufoRim.size.width * fieldMultiplier))
        addChild(field)

        field.run(.sequence([
            .wait(forDuration: chargeDuration),
            .removeFromParent()
        ]))

        let auraTexture = SKTexture(imageNamed: "Aura")
        let auraSize = auraTexture.size().aspectScaled(to: ufoRim.size, fill: true) * 1.5
        let aura = SKSpriteNode(texture: auraTexture, color: .white, size: auraSize)
        aura.zPosition = -0.1
        addChild(aura)

        aura.run(.sequence([
            .group([
                .scale(by: fieldMultiplier, duration: chargeDuration),
                .fadeAlpha(to: 0, duration: chargeDuration)
            ]),
            .removeFromParent()
        ]))
    }

    func explode() {
        let explosion = SKEmitterNode(fileNamed: "Explosion.sks")!
        explosion.zPosition = 5
        addChild(explosion)

        explosion.run(.sequence([
            .playSoundFileNamed("Explosion.mp3", waitForCompletion: false),
            .wait(forDuration: 0.2),
            .run { explosion.particleAlpha = 0 }
        ]))

        let hideAction: SKAction = .hide()
        [ufoCenter, ufoMiddle, ufoRim].forEach { $0.run(hideAction) }

        run(.sequence([
            .wait(forDuration: 1),
            .removeFromParent()
        ]))
    }

}
