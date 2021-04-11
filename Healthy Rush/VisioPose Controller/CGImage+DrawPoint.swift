//
//  CGImage+DrawPoint.swift
//  VisionPose
//
//  Created by Mario on 03/04/2021.
//

import Foundation
import CoreGraphics
import UIKit

/**
 An image is created according to points passed as parameter
 */
extension CGImage {
    func drawPoints(points:[CGPoint]) -> UIImage? {
        
        //create a new 2D drawing environment
        let cntx = CGContext(data: nil, width: Int(width), height: Int(height), bitsPerComponent: bitsPerComponent , bytesPerRow: 0, space: colorSpace ?? CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        
        //create a rectangle according to device screen size
        cntx?.draw(self, in: CGRect(x: 0, y: 0, width: width, height: height))
        for point in points {
            //colors can be changed toggling the RGB values
            cntx?.setFillColor(red: 1, green: 0, blue: 0, alpha: 1)
            //creates a point in the context drawing a zero to 2*pi arc of circumference
            cntx?.addArc(center: point, radius: 9, startAngle: 0, endAngle: CGFloat(2*Double.pi), clockwise: false)
            //used to fill the point 
            cntx?.drawPath(using: .fill)
        }
        let _cgim = cntx?.makeImage()
        if let cgi = _cgim {
            let img = UIImage(cgImage: cgi)
            return img
        }
        return nil
    }
}
