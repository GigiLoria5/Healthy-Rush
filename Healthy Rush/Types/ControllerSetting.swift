//
//  ControllerSetting.swift
//  Healthy Rush
//
//  Created by Luigi Loria on 14/06/21.
//

import Foundation

class ControllerSetting {
    static let sharedInstance = ControllerSetting()
    private init() {}
    
    static let keyWatchMode = "watchMode"
    static let keyCameraMode = "cameraMode"
    
    // Check if a controller is set
    func isControllerSet() -> Bool {
        return getWatchMode() || getCameraMode()
    }
    
    // Watch Mode
    func setWatchMode(_ isSet: Bool) {
        UserDefaults.standard.set(isSet, forKey: ControllerSetting.keyWatchMode)
    }
    
    func getWatchMode() -> Bool {
        if (!isWatchModePresent()) {
            setWatchMode(false) // if not already set, it's false
        }
        return UserDefaults.standard.bool(forKey: ControllerSetting.keyWatchMode)
    }
    
    func isWatchModePresent() -> Bool {
        return UserDefaults.standard.object(forKey: ControllerSetting.keyWatchMode) != nil
    }
    
    // Camera Mode
    func setCameraMode(_ isSet: Bool) {
        UserDefaults.standard.set(isSet, forKey: ControllerSetting.keyCameraMode)
    }
    
    func getCameraMode() -> Bool {
        if (!isCameraModePresent()) {
            setCameraMode(false) // if not already set, it's false
        }
        return UserDefaults.standard.bool(forKey: ControllerSetting.keyCameraMode)
    }
    
    func isCameraModePresent() -> Bool {
        return UserDefaults.standard.object(forKey: ControllerSetting.keyCameraMode) != nil
    }
}
