//
//  GameSettings.swift
//  Healthy Rush
//
//  Created by mario on 19/04/21.
//


class GameSettings {
 
    var cameraIsSelected : Bool
    var watchIsSelected : Bool
    var musicOn : Bool
    var effectsOn : Bool
    var menuCalls : UInt
    
    init(camera: Bool, watch: Bool){
        self.cameraIsSelected = camera
        self.watchIsSelected = watch
        self.musicOn = true
        self.effectsOn = true
        self.menuCalls = 0
    }
    
    init(camera: Bool,watch: Bool, music : Bool, sfx : Bool) {
        self.cameraIsSelected = camera
        self.watchIsSelected = watch
        self.musicOn = music
        self.effectsOn = sfx
        self.menuCalls = 0
    }
    
    func increaseCalls(){
//        overflow safe increment
//        it is not necessary, since the range of the unsigned integer is large enough to make an overflow impossible in this case, but to be absolutely certain the couter returns to zero if it occurs
        self.menuCalls &+= 1
    }
}
