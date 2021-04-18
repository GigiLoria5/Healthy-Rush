//
//  BodyPoseProcessor.swift
//  VisionPose
//
//  Created by mario on 05/04/21.
//

import CoreGraphics
import Vision

@available(iOS 14.0, *)
let jointsOfInterest: [VNHumanBodyPoseObservation.JointName] = [
    .rightElbow,
    .leftElbow,
   .rightShoulder,
   .leftShoulder,
    .neck,
    .rightKnee,
    .leftKnee,
    .root
]

class BodyPoseProcessor{
    
/**
     possible body states:
     - steady: when the person is still
     - jumping: enters when feet leaves the floor
     - crouched: when the torso lowers beyond a certain level
     - possible Steady: transition state, there is an uncertainty in the body pose
     
     - // armRaised : indicates that an arm has reached such a height that it is considered high,
                 the threshold is the level of the shoulders
     - // armLowering: indicates that the arm is lowering, that is, it has passed the threshold
                of the shoulders and is directed towards the ground
     - // legRaised : indicates that a leg has been lifted beyond the threshold of the pelvis(bacino)
     - // legLowering: indicates that the leg is lowering towards the ground
     - unknown: it was not possible to obtain a valid position of the body, comparable to a state of maximum uncertainty
     
 */
    enum BodyState {
        case possibleSteady
        case steady
        case jumping
        case crouched
        
        case leftArmRaised
        case leftArmLowering
        case rightArmRaised
        case rightArmLowering
        
        case bothArmsRaised
        case bothArmsLowered
        
        case leftLegRaised
        case leftLegLowering
        case rightLegRaised
        case rightLegLowering
        
        case unknown
    }
    
    /**
     the class provides the logic that allows you to establish whether a certain action leads
     to an increase or decrease in the state variables, allowing you to keep track of the measurement
     in two distinct instants of time.
     for performance reasons  two 16-bit unsigned integers are used,
     which respectively represent the previous and current state.
     when the current state changes, the previous state changes accordingly:
     if the current state undergoes a change, the previous state takes on the value of the current one before the change.
     */
    
    class BiStateCounter{
        var s1 : UInt16 = 0
        var s2 : UInt16 = 0
        
        func increase(amount: UInt16){
            s2 = s1
            s1 &+= amount //handles overflow
            if(s2 > s1){
                debugPrint("overflow")
                s2 = UInt16.min
                s1 = UInt16.min + 1
            }
        }
        func decrease(amount: UInt16){
            s2 = s1
            s1 &-= amount //handles underflow
            if(s2 < s1){
                debugPrint("underflow")
                s2 = UInt16.max
                s1 = UInt16.max - 1
            }
        }
        func isIncreasing() -> Bool{
            return (s1 > s2)
        }
        func isDecreasing() -> Bool{
            return (s1 < s2)
        }
        func reset(){
            s1 = 0
            s2 = 0
        }
        func value1() -> UInt16{
            return s1
        }
        func value2() -> UInt16{
            return s2
        }
    }
    
    
    var didChangeStateClosure: ((BodyState) -> Void)?
    
    private var currentState = BodyState.unknown{
        didSet{
            didChangeStateClosure?(currentState)
        }
    }
    
    private let maxEvaluations: UInt8
    
    private var heightEvalCounter : UInt8
    private var shouldersWidthEvaluated : Bool
    private var kneesPositionEvaluated : Bool
    private var armsPositionEvaluated: Bool
    private var waistPositionEvaluated : Bool
    
    
    private var leftLegIsUpCounter : BiStateCounter
    private var rightLegIsUpCounter : BiStateCounter
    
    private var leftArmIsUpCounter : BiStateCounter
    private var rightArmIsUpCounter : BiStateCounter
    
    
   
    /** the height value of shoulder at rest position
        each person has a different height
        should be evaluated during a series of measures
     */
    private var relativeBodyHeight : CGFloat
    
    /**
                    joints  positions of interests
     */
    private var leftShoulderPos,rightShoulderPos : CGFloat
    
    private var waistPoint : CGPoint
    private var leftKneePoint,rightKneePoint : CGPoint
    private var leftElbowPoint,rightElbowPoint : CGPoint
    
    
    private var shouldersWidth: CGFloat
    
    private var leftLegIsUp: Bool
    private var rightLegIsUp: Bool
    
    private var leftElbowIsUp: Bool
    private var rightElbowIsUp: Bool
    
    /**
        The thresholds  are useful to identify the transition zones between one state and another
     */
    private let heightThreshold : CGFloat
    private let widthThreshold : CGFloat
    private let crouchedThresh : CGFloat
    private let jumpingThresh  : CGFloat
    private let kneeToWaistThresh : CGFloat
    private let elbowToNeckThresh: CGFloat
    private let legMovementThresh : CGFloat
    private let armsMovementThresh: CGFloat
    
    
    private let scaleFactor : CGFloat
    
    /**
     saves previous height values, describes how the height changes during measurements
     */
    private var heightTrend  = Array<CGFloat>([])
    
    init(scaleFactor : CGFloat) {
        
        self.scaleFactor = scaleFactor
        
        self.leftShoulderPos = 0
        self.rightShoulderPos = 0
        self.waistPoint = .zero
        self.leftKneePoint = .zero
        self.rightKneePoint = .zero
        self.leftElbowPoint = .zero
        self.rightElbowPoint = .zero
        
        self.rightLegIsUp = false
        self.leftLegIsUp = false
        
        self.rightElbowIsUp = false
        self.leftElbowIsUp = false
        
        self.shouldersWidth = 0
        self.relativeBodyHeight = 0
        
        self.heightThreshold = 10.0 * self.scaleFactor
        self.widthThreshold  = 80.0 * self.scaleFactor
        self.jumpingThresh   = 50.0 * self.scaleFactor
        self.kneeToWaistThresh = 150.0 * self.scaleFactor
        self.elbowToNeckThresh = 50.0 * self.scaleFactor
        self.armsMovementThresh = 80.0
        
//      the scale factor doesn't work when scale factor is 0.2,
//      because the screen rate is diffenent
//      it should be set manually
        if(scaleFactor == 1/5){
            self.crouchedThresh  = 18
            self.legMovementThresh = 8
        }
        else{
            self.crouchedThresh = 150 * self.scaleFactor
            self.legMovementThresh = 80 * self.scaleFactor
        }
       
        self.maxEvaluations = 5
        self.heightEvalCounter = 0
        
        self.shouldersWidthEvaluated  = false
        self.kneesPositionEvaluated = false
        self.waistPositionEvaluated = false
        self.armsPositionEvaluated = false
        
        self.leftLegIsUpCounter = BiStateCounter()
        self.rightLegIsUpCounter = BiStateCounter()

        self.leftArmIsUpCounter = BiStateCounter()
        self.rightArmIsUpCounter = BiStateCounter()
        
        
    }
    
    /**
        Cleans all the values associated with measurements and restores the initial values
     */
    func reset(){
        currentState = .unknown
        relativeBodyHeight = 0
        shouldersWidth = 0
        heightEvalCounter = 0
        leftKneePoint = .zero
        rightKneePoint = .zero
        shouldersWidthEvaluated = false
        kneesPositionEvaluated = false
        waistPositionEvaluated = false
        
        
        leftArmIsUpCounter.reset()
        rightArmIsUpCounter.reset()
        leftLegIsUpCounter.reset()
        rightLegIsUpCounter.reset()
    }
    /**
        Evaluates the relative height of the body through a series of measures.
        When the height counter has just set and its value is 0,
        the initial relative height is set according to the ordinate of the height point passed as parameter;
        if the counter has already been updated, the relative height is obtained through an arithmetic mean
        with the previous value of the height and the new height point given.
     */
    func computeBodyHeight(point : CGPoint){
        let delta = absoluteDifference(a1: relativeBodyHeight, a2: point.y)
        if(heightEvalCounter == 0){
            relativeBodyHeight = point.y
            heightEvalCounter += 1
        }else if (heightEvalCounter <= maxEvaluations){
            if(delta < heightThreshold){ // if the height has not changed abruptly from the previous measurement
                relativeBodyHeight = (relativeBodyHeight + point.y) / 2
                if(heightEvalCounter < maxEvaluations){
                    heightEvalCounter += 1
                }
            }
        }
    }
    @available(iOS 14.0, *)
    func computeShouldersWidth(key: VNHumanBodyPoseObservation.JointName, point: CGPoint){
        if(key == VNHumanBodyPoseObservation.JointName.leftShoulder){
            leftShoulderPos = point.x
        }
        else if(key == VNHumanBodyPoseObservation.JointName.rightShoulder){
            rightShoulderPos = point.x
        }
        if(rightShoulderPos != 0 && leftShoulderPos != 0){
            let delta = absoluteDifference(a1: rightShoulderPos, a2: leftShoulderPos)
            if (!shouldersWidthEvaluated){
                shouldersWidthEvaluated = true
            }
            else {
//                the body has approached or moved away from camera, should recalculate references
                if(absoluteDifference(a1: shouldersWidth, a2: delta) > widthThreshold){
                    reset()
                }
            }
//            update the width with the current value
            shouldersWidth = delta
        }
    }
    
    @available(iOS 14.0, *)
    func computeWaistPosition(key: VNHumanBodyPoseObservation.JointName, point: CGPoint){
        if(!waistPositionEvaluated){
            waistPoint = point
            waistPositionEvaluated = true
        }
    }
    
    @available(iOS 14.0, *)
    func computeArmsPosition(key: VNHumanBodyPoseObservation.JointName, point: CGPoint){
        
        if(!armsPositionEvaluated){
            if(key == VNHumanBodyPoseObservation.JointName.leftElbow){
                leftElbowPoint = point
            }
            else if(key == VNHumanBodyPoseObservation.JointName.rightElbow){
                rightElbowPoint = point
            }
            if(leftElbowPoint != .zero && rightElbowPoint != .zero){
                armsPositionEvaluated = true
            }
        }else{
            let delta = point.y - relativeBodyHeight
            
            if(key == VNHumanBodyPoseObservation.JointName.leftElbow){
                if(delta >= 0){
                    leftElbowIsUp = true
                    leftArmIsUpCounter.increase(amount: 1)
                }
                else{
                    let vLeft = leftArmIsUpCounter.value1()
                    if(vLeft > 1){
                        //grows linearly, decreases geometrically
                        leftArmIsUpCounter.decrease(amount: UInt16(vLeft/2))
                    }
                    else{
                        leftElbowIsUp = false
                    }
                }
            }
            else if(key == VNHumanBodyPoseObservation.JointName.rightElbow){
                
                if(delta >= 0){
                        rightElbowIsUp = true
                        rightArmIsUpCounter.increase(amount: 1)
                }
                else{
                    let vRight = rightArmIsUpCounter.value1()
                    if(vRight > 1){
                        rightArmIsUpCounter.decrease(amount: UInt16(vRight/2))
                    }
                    else{
                        rightElbowIsUp = false
                    }
                }
            }
        }
    }
    
    
    @available(iOS 14.0, *)
    func computeLegsPosition(key: VNHumanBodyPoseObservation.JointName, point: CGPoint){
        
        if(!kneesPositionEvaluated){
            if(key == VNHumanBodyPoseObservation.JointName.leftKnee){
                leftKneePoint = point
            }
            else if(key == VNHumanBodyPoseObservation.JointName.rightKnee){
                rightKneePoint = point
            }
            if(leftKneePoint != .zero && rightKneePoint != .zero){
                kneesPositionEvaluated = true
            }
        }else{
            let delta = point.y - waistPoint.y
            
            if(key == VNHumanBodyPoseObservation.JointName.leftKnee){
                if(delta >= 0){
                     leftLegIsUp = true
                    leftLegIsUpCounter.increase(amount: 1)
                }
                else{
                    let vLeft = leftLegIsUpCounter.value1()
                    if(vLeft > 1){
                        leftLegIsUpCounter.decrease(amount: UInt16(vLeft/2))
                    }
                    else{
                        leftLegIsUp = false
                    }
                }
            }
            else if(key == VNHumanBodyPoseObservation.JointName.rightKnee){
                //linear increase, geometric decrease
                if(delta >= 0){
                        rightLegIsUp = true
                        rightLegIsUpCounter.increase(amount: 1)
                }
                else{
                    let vRight = rightLegIsUpCounter.value1()
                    if(vRight > 1){
                        rightLegIsUpCounter.decrease(amount: UInt16(vRight/2))
                    }
                    else{
                        rightLegIsUp = false
                    }
                }
            }
        }
    }
    
    

    @available(iOS 14.0, *)
    func processJoints(_ joints : [VNHumanBodyPoseObservation.JointName: CGPoint]) -> CGFloat{
//        if joints contains all the points of interest, else is discarded
        if(heightEvalCounter <= maxEvaluations){
            for (key,p) in joints{
                if(key == VNHumanBodyPoseObservation.JointName.neck){
                    computeBodyHeight(point: p)
                    return p.y
                    
                }
                else if (key == VNHumanBodyPoseObservation.JointName.leftShoulder ||
                            key == VNHumanBodyPoseObservation.JointName.rightShoulder){
                    computeShouldersWidth(key:key,point: p)
                }
                else if(key == VNHumanBodyPoseObservation.JointName.root && !waistPositionEvaluated){
                    computeWaistPosition(key: key, point: p)
                }
                else if((key == VNHumanBodyPoseObservation.JointName.leftElbow ||
                            key == VNHumanBodyPoseObservation.JointName.rightElbow)
                            && heightEvalCounter == maxEvaluations){
                    computeArmsPosition(key: key, point: p)
                }
                else if((key == VNHumanBodyPoseObservation.JointName.leftKnee ||
                            key == VNHumanBodyPoseObservation.JointName.rightKnee)
                            && waistPositionEvaluated
                            && heightEvalCounter == maxEvaluations){
                    computeLegsPosition(key: key, point: p)
                }
                
            }
        }
        
        return 0
    }
    
    
    @available(iOS 14.0, *)
    func processPose(_ joints: [VNHumanBodyPoseObservation.JointName: CGPoint]){
        let currentHeight = processJoints(joints)
        
        if(heightEvalCounter == maxEvaluations){ //calibration ended, could perform pose analysis
            if(heightTrend.count < 2){
                heightTrend.append(currentHeight)
            }
            else{
                //update the trend with new values
                heightTrend[1] = heightTrend[0]
                heightTrend[0] = currentHeight
            }
            if(heightTrend.count == 2) {
                //strictly increasing points, must be jumping
                if(heightTrend.allSatisfy{$0 > self.relativeBodyHeight + jumpingThresh} && heightTrend[0] < heightTrend[1]){
                    currentState = .jumping
                }
                else if(heightTrend.allSatisfy({$0 <= self.relativeBodyHeight - crouchedThresh})){
                    currentState = .crouched
                }
                else if(rightLegIsUp){
                    if(rightLegIsUpCounter.isIncreasing()){
                        currentState = .leftLegRaised
                    }else{
                        currentState = .leftLegLowering
                    }
                }
                else if(leftLegIsUp){
                    if(leftLegIsUpCounter.isIncreasing()){
                        currentState = .rightLegRaised
                    }else{
                        currentState = .rightLegLowering
                    }
                }
                else if (rightElbowIsUp && leftElbowIsUp){
                    if(rightArmIsUpCounter.isIncreasing() &&
                        leftArmIsUpCounter.isIncreasing()){
                        currentState = .bothArmsRaised
                    }
                    else if(rightArmIsUpCounter.isDecreasing() && leftArmIsUpCounter.isDecreasing()){
                        currentState = .bothArmsLowered
                    }
                }
                else if(rightElbowIsUp){
                    if(rightArmIsUpCounter.isIncreasing()){
                        currentState = .leftArmRaised
                    }else{
                        currentState = .leftArmLowering
                    }
                    
                }
                else if(leftElbowIsUp){
                    if(leftArmIsUpCounter.isIncreasing()){
                        currentState = .rightArmRaised
                    }else{
                        currentState = .rightArmLowering
                    }
                }
                else{
                    currentState = .steady
                }
            }
        }
        else if(heightEvalCounter > 1 && heightEvalCounter < maxEvaluations){
            currentState = .possibleSteady
        }
        
    }
//    utility function, return the difference of values without sign
    func absoluteDifference(a1 : CGFloat, a2: CGFloat) -> CGFloat{
        return abs(a1 - a2)
    }
    
    /**
     returns a representation of the current state as a string
     */
    func printBodyState() -> String{
        switch currentState {
        case .possibleSteady:
            return "Possible Steady"
        case .steady:
            return "Steady"
        case .crouched:
            return "Crouched"
        case .jumping:
            return "Jumping"
        case .leftArmRaised:
            return "Left Arm up"
        case .leftArmLowering:
            return "left Arm lowering"
        case .rightArmRaised:
            return "Right Arm up"
        case .rightArmLowering:
            return "right Arm lowering"
        case .bothArmsRaised:
            return "Both Arms raised"
        case .bothArmsLowered:
            return "Both Arms lowering"
        case .leftLegRaised:
            return "Left leg up"
        case .leftLegLowering:
            return "left leg lowering"
        case .rightLegRaised:
            return "Right leg up"
        case .rightLegLowering:
            return "right leg lowering"
        default:
            return "UNKNOWN"
        }
    }
    
    func returnBodyState() -> BodyState{
        return currentState
    }
}
