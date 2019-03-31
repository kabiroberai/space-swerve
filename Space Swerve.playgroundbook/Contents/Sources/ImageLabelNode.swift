//
//  ImageLabelNode.swift
//  Book_Sources
//
//  Created by Kabir Oberai on 23/03/19.
//

import SpriteKit

class ImageLabelNode: SKNode {

    static let baseImageSize = CGSize(width: 20, height: 20)

    let image: SKSpriteNode
    let label: SKLabelNode

    init(imageNamed imageName: String, text: String) {
        let texture = SKTexture(imageNamed: imageName)
        let size = texture.size().aspectScaled(to: ImageLabelNode.baseImageSize, fill: false)
        image = SKSpriteNode(texture: texture, color: .white, size: size)

        label = SKLabelNode(text: text)
        label.fontColor = .white
        label.fontName = "KenVector Future Thin"
        label.fontSize = 15

        super.init()

        zPosition = 4

        addChild(image)

        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .left
        label.position = CGPoint(
            x: image.position.x + image.size.width / 2 + 5,
            y: image.position.y
        )
        addChild(label)

        run(.repeatForever(.sequence([
            .fadeAlpha(by: -0.3, duration: 1),
            .fadeAlpha(by: 0.3, duration: 1),
        ])))
    }
    required init?(coder aDecoder: NSCoder) {
        unimplemented()
    }

}
