//
//  ChargeNode.swift
//  Book_Sources
//
//  Created by Kabir Oberai on 22/03/19.
//

import SpriteKit

class ChargeNode: SKSpriteNode {

    private static var baseSize = CGSize(width: 20, height: 20)

    init() {
        let texture = SKTexture(imageNamed: "Charge")
        let size = texture.size().aspectScaled(to: ChargeNode.baseSize, fill: false)
        super.init(texture: texture, color: .white, size: size)

        physicsBody = SKPhysicsBody(rectangleOf: size)
        physicsBody?.category = .charge
        physicsBody?.collisionCategory = .none
        physicsBody?.fieldCategory = .none
        physicsBody?.contactTestCategory = .ufo

        let fadeAmount: CGFloat = 0.5
        run(.repeatForever(.sequence([
            .fadeAlpha(by: -fadeAmount, duration: 1),
            // .reversed() doesn't seem to work for this
            .fadeAlpha(by: fadeAmount, duration: 1)
        ])))
    }
    required init?(coder aDecoder: NSCoder) {
        unimplemented()
    }

}
