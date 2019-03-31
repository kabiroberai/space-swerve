//
//  LaserNode.swift
//  Book_Sources
//
//  Created by Kabir Oberai on 22/03/19.
//

import SpriteKit

class LaserNode: SKSpriteNode {

    private static var baseSize = CGSize(width: 20, height: 30)

    init() {
        let texture = SKTexture(imageNamed: "Laser")
        let size = texture.size().aspectScaled(to: LaserNode.baseSize, fill: false)
        super.init(texture: texture, color: .white, size: size)

        physicsBody = SKPhysicsBody(rectangleOf: size)
        physicsBody?.category = .laser
        physicsBody?.collisionCategory = .none
        physicsBody?.fieldCategory = .none
        physicsBody?.contactTestCategory = .ufo
    }
    required init?(coder aDecoder: NSCoder) {
        unimplemented()
    }

}
