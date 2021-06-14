//
//  CGFloat+Ext.swift
//  Healthy Rush
//
//  Created by Luigi Loria on 10/02/21.
//

import CoreGraphics

extension CGFloat {
    func radiansToDegrees() -> CGFloat {
        return self * 180.0 / CGFloat.pi
    }
    
    func degreesToRadiants() -> CGFloat {
        return self * CGFloat.pi / 180.0
    }
    
    static func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / Float(0xFFFFFFFF)) // return 0, 1
    }
    
    static func random(min: CGFloat, max: CGFloat) -> CGFloat {
        assert(min < max)
        return CGFloat.random() * (max - min) + min // return min or max
    }
}
