//
//  GesturesCapture.swift
//  Healthy Rush
//
//  Created by Luigi Loria on 11/06/21.
//

import SpriteKit
import GameplayKit

class GesturesCapture {
    // For the swipe gestures
    private var touchStart: CGPoint?
    private var startTime : TimeInterval?
    private let minSpeed:CGFloat = 1400
    private let maxSpeed:CGFloat = 6000
    private let minDistance:CGFloat = 25
    private let minDuration:TimeInterval = 0.1
    private let minAngle: CGFloat = 0.26 //sin^-1(0.26) = 15 degrees ca.
    enum swipeDirection{
        case left,right,up,down,none
    }
    private var currentSwipe : swipeDirection!
    
    // Get Current Swipe
    func getCurrentSwipe() -> swipeDirection {
        guard let curSwipe = self.currentSwipe else {
            return swipeDirection.none
        }
        currentSwipe = nil
        return curSwipe
    }
    
    // saves the initial touch point and the instant when it was pressed
    func startCapturing(_ touches: Set<UITouch>, scene: SKScene) {
        touchStart = touches.first?.location(in: scene)
        startTime = touches.first?.timestamp
    }
    
    //check if exists a starting touch when and where it was recognized
    func findGesture(_ touches: Set<UITouch>, scene: SKScene) {
         guard var touchStart = self.touchStart else {
             return
         }
         guard var startTime = self.startTime else {
             return
         }
         guard let currLocation = touches.first?.location(in: scene) else {
             return
         }
         guard let currTime = touches.first?.timestamp else {
             return
         }
         var dx = currLocation.x - touchStart.x
         var dy = currLocation.y - touchStart.y
         // Distance of the gesture
         let distance = sqrt(dx*dx+dy*dy)
         if distance >= minDistance {
             // Duration of the gesture
             let deltaT = currTime - startTime
             if deltaT > minDuration {
                 // Speed of the gesture
                 let speed = distance / CGFloat(deltaT)
                 if speed >= minSpeed && speed <= maxSpeed {
                     // Normalize by distance to obtain unit vector
                     dx /= distance
                     dy /= distance
                    // Swipe detected
                    //currentSwipe will contain the direction of the swipe
                    if(abs(dy) < minAngle){
                        if(dx > 0){
                            currentSwipe = .right
                        }
                        else{
                            currentSwipe = .left
                        }
                    } else if(abs(dx) < minAngle){
                        if(dy > 0){
                            currentSwipe = .up
                        } else {
                            currentSwipe = .down
                        }
                    } else {
                        currentSwipe = GesturesCapture.swipeDirection.none
                    }
                 }
             }
         }
        // Reset variables
        touchStart = .zero
        startTime = 0
    }
    
}
