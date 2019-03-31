//
//  EnemyNode.swift
//  Book_Sources
//
//  Created by Kabir Oberai on 22/03/19.
//

import SpriteKit

class EnemyNode: SKNode {
    private static let baseSize = CGSize(width: 70, height: 70)
    private static let blastSpeed: CGFloat = 200
    private static let laserStartOffset: CGFloat = 10

    let sprite: SKSpriteNode

    override init() {
        let texture = SKTexture(imageNamed: "Enemy")
        let size = texture.size().aspectScaled(to: EnemyNode.baseSize, fill: false)
        sprite = SKSpriteNode(texture: texture, color: .white, size: size)

        super.init()

        zPosition = 3

        physicsBody = SKPhysicsBody(rectangleOf: size)
        physicsBody?.category = .enemy
        physicsBody?.collisionCategory = .none
        physicsBody?.fieldCategory = .none
        physicsBody?.contactTestCategory = .ufo

        sprite.position = .zero
        addChild(sprite)
    }
    required init?(coder aDecoder: NSCoder) {
        unimplemented()
    }

    private func fireSingleLaser(completion: (() -> Void)?) {
        let laser = LaserNode()
        laser.position.y = -sprite.size.height / 2 - EnemyNode.laserStartOffset - laser.size.height / 2
        addChild(laser)

        var sceneEndPoint = convert(laser.position, to: scene!)
        sceneEndPoint.y = -laser.size.height / 2
        let relEndPoint = convert(sceneEndPoint, from: scene!)

        let distance = laser.position.y - relEndPoint.y
        let duration = distance / EnemyNode.blastSpeed

        laser.run(.sequence([
            .playSoundFileNamed("Laser.mp3", waitForCompletion: false),
            .move(to: relEndPoint, duration: TimeInterval(duration)),
            .removeFromParent(),
            .run { completion?() }
        ]))
    }

    func fire(_ completion: @escaping () -> Void) {
        let numLasers = gameDifficulty.laserCount + Int.random(in: 0...3)
        let range = 0..<numLasers

        for i in range {
            run(.sequence([
                .wait(forDuration: TimeInterval(i) * gameDifficulty.laserBlastPeriod),
                .run {
                    self.fireSingleLaser(completion: i == range.last ? completion : nil)
                }
            ]))
        }
    }

}
