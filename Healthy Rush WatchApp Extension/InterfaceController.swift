//
//  InterfaceController.swift
//  Healthy Rush WatchApp Extension
//
//  Created by Francesco Manna.
//

import WatchKit
import Foundation
import CoreMotion
import WatchConnectivity
import HealthKit

class InterfaceController: WKInterfaceController, WCSessionDelegate, WKExtendedRuntimeSessionDelegate {
    
    // MARK: - Extendend Session Functions
    
    func extendedRuntimeSession(_ extendedRuntimeSession: WKExtendedRuntimeSession, didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason, error: Error?) {
        print("Session stopped at", Date())
    }
    
    func extendedRuntimeSessionDidStart(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        print("Session started at", Date())
    }
    
    func extendedRuntimeSessionWillExpire(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        // TODO: write logic for this method
    }
    
    // MARK: - Connectivity Functions
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        // TODO: write logic for this method
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let start = message["startDate"] {
            startDate = start as! Date
        }
        if let end = message["endDate"] {
            endDate = end as! Date
            sendHealthData()
        }
    }
    
    // MARK: - Variables Declaration And Initialization
    
    // HealthKit Variables
    
    // TODO: Check which variables can be nil or which should be initialized here
    var healthStore: HKHealthStore!
    let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
    let activeEnergyBurnedType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
    let respiratoryRateType = HKQuantityType.quantityType(forIdentifier: .respiratoryRate)!
    
    var startDate = Date()
    var endDate = Date()
    
    var extendedSession: WKExtendedRuntimeSession!
    
    // WatchConnectivity Variables
    
    var session: WCSession!
    var motionManager : CMMotionManager!
    
    // Storyboard Variables
    
    @IBOutlet weak var startOutlet: WKInterfaceButton!
    @IBOutlet weak var stopOutlet: WKInterfaceButton!
    @IBOutlet weak var trackingLabel: WKInterfaceLabel!
    @IBOutlet weak var jumpLabel: WKInterfaceLabel!
    
    @IBAction func startButton() {
        
        extendedSession.start()
        
        motionManager.startDeviceMotionUpdates(to: OperationQueue.current!) { dataOrNil, errorOrNil in
            if let data = dataOrNil {
                if self.detectJump(data.userAcceleration) {
                    self.sendJump()
                    self.jumpLabel.setHidden(false)
                    self.jumpLabel.setText("Jump detected!")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.jumpLabel.setHidden(true)
                    }
                }
            }
        }
        
        trackingLabel.setText("I am tracking jumps. Enjoy your gaming session!")
        startOutlet.setEnabled(false)
        stopOutlet.setEnabled(true)
        
        
    }
    
    @IBAction func stopButton() {
        
        motionManager.stopDeviceMotionUpdates()
        extendedSession.invalidate()
        
        stopOutlet.setEnabled(false)
        startOutlet.setEnabled(true)
        
        trackingLabel.setText("Not tracking jumps at the moment.")
    }
    
    override func awake(withContext context: Any?) {
        // Configure interface objects here.
        // TODO: write logic for this method
    }
    
    override func willActivate() {
        // TODO: write logic for this method
        
    }
    
    override func didDeactivate() {
        // TODO: write logic for this method
    }
    
    // MARK: - Detection Variables
    
    func detectJump(_ acceleration: CMAcceleration) -> Bool {
        return acceleration.z > 1
    }
    
    func detectCrouch() -> Bool {
        // FIXME: Make congruent with the other function
        if let data = motionManager.deviceMotion?.userAcceleration {
            return data.z < -0.5
        }
        return false
    }
    
    // MARK: - Sending Functions
    
    func sendJump() {
        session.sendMessage(["jump" : true], replyHandler: nil, errorHandler: nil)
    }
    
    func sendCrouch() {
        session.sendMessage(["crouch" : true], replyHandler: nil, errorHandler: nil)
    }
    
    func sendHealthData() {
        
        let samplePeriod = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [])
        
        let sampleQueryHeartRate = HKStatisticsQuery(quantityType: heartRateType, quantitySamplePredicate: samplePeriod, options: .discreteAverage) { query, statisticsOrNil, errorOrNil in
            
            guard let statistics = statisticsOrNil else {
                print("No heart rate data.")
                return
            }
            
            let average = statistics.averageQuantity()
            let averageHeartRate = average?.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))
            self.session.sendMessage(["averageHeartRate" : averageHeartRate!], replyHandler: nil, errorHandler: nil)
            
        }
        
        let sampleQueryActiveEnergyBurned = HKStatisticsQuery(quantityType: activeEnergyBurnedType, quantitySamplePredicate: samplePeriod, options: .cumulativeSum) { query, statisticsOrNil, errorOrNil in
            
            guard let statistics = statisticsOrNil else {
                print("No active energy burned data.")
                return
            }
            
            let sum = statistics.sumQuantity()
            let sumActiveEnergyBurned = sum?.doubleValue(for: HKUnit.kilocalorie())
            self.session.sendMessage(["sumActiveEnergyBurned" : sumActiveEnergyBurned!], replyHandler: nil, errorHandler: nil)
            
        }
        
        let sampleQueryRespiratoryRate = HKStatisticsQuery(quantityType: respiratoryRateType, quantitySamplePredicate: samplePeriod, options: .discreteAverage) { query, statisticsOrNil, errorOrNil in
            
            guard let statistics = statisticsOrNil else {
                print("No active respiratory rate data.")
                return
            }
            
            let average = statistics.averageQuantity()
            let averageRespiratoryRate = average?.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.second()))
            self.session.sendMessage(["averageRespiratoryRate" : averageRespiratoryRate!], replyHandler: nil, errorHandler: nil)
            
        }
        
        healthStore.execute(sampleQueryHeartRate)
        healthStore.execute(sampleQueryActiveEnergyBurned)
        healthStore.execute(sampleQueryRespiratoryRate)
        
    }
    
    // MARK: - Initializer
    
    override init() {
        
        // TODO: Change code order 
        
        super.init()
        
        guard HKHealthStore.isHealthDataAvailable() else {
            fatalError("This app requires a device that supports HealthKit")
        }
        healthStore = HKHealthStore()
        
        let allTypes = Set([activeEnergyBurnedType, heartRateType, respiratoryRateType])
        healthStore.requestAuthorization(toShare: allTypes, read: allTypes) { success, error in
            if success {
                print("Authorization request succeded.")
            } else {
                print("Authorization request failed.")
            }
        }
        
        extendedSession = WKExtendedRuntimeSession()
        extendedSession.delegate = self
        
        motionManager = CMMotionManager()
        if motionManager.isDeviceMotionAvailable {
            motionManager.showsDeviceMovementDisplay = true
            motionManager.deviceMotionUpdateInterval = 1.0/60.0
        }
        
        if WCSession.isSupported() {
            session = WCSession.default
            session.delegate = self
            session.activate()
        }
        
    }
    
    
    
    
    
}

