//
//  SpriteNodeExtension.swift
//  Healthy Rush
//
//  Created by Luigi Loria on 11/06/21.
//

import SpriteKit

extension SKSpriteNode {
    
    func drawBorder(color: UIColor, width: CGFloat) {
        let shapeNode = SKShapeNode(rectOf: size)
        shapeNode.fillColor = .clear
        shapeNode.strokeColor = color
        shapeNode.lineWidth = width
        addChild(shapeNode)
    }
    
}
