//
//  PlayerSetting.swift
//  Healthy Rush
//
//  Created by Luigi Loria on 14/06/21.
//

import Foundation

enum PlayerName: String {
    case theBoy, cuteGirl, ellie, dino
}

struct PlayerAnimation {
    let dead: Int
    let idle: Int
    let run: Int
    let jump: Int
    
    init(dead: Int, idle: Int, run: Int, jump: Int) {
        self.dead = dead
        self.idle = idle
        self.run = run
        self.jump = jump
    }
}

let playerPrice = ["Ellie": 250, "Dino": 500] // the other player are free

class PlayerSetting {
    static let sharedInstance = PlayerSetting()
    private init() {}
    
    let playerLives = ["theBoy": 3, "cuteGirl": 3, "ellie": 4, "dino": 5]
    let playerRunTimeFrame = ["theBoy": 0.075, "cuteGirl": 0.075, "ellie": 0.10, "dino": 0.12]
    let playerAnimationsIndex = ["theBoy": PlayerAnimation(dead: 15, idle: 15, run: 15, jump: 15),
                                 "cuteGirl": PlayerAnimation(dead: 30, idle: 16, run: 20, jump: 30),
                                 "ellie": PlayerAnimation(dead: 10, idle: 10, run: 8, jump: 10),
                                 "dino": PlayerAnimation(dead: 8, idle: 10, run: 8, jump: 12)]
    
    static let keyPlayerSelected = "PlayerSelected"
    
    // Player Selected Animations Index
    func getPlayerSelectedDeadIndex() -> Int {
        return playerAnimationsIndex[getPlayerSelected()]!.dead
    }
    
    func getPlayerSelectedIdleIndex() -> Int {
        return playerAnimationsIndex[getPlayerSelected()]!.idle
    }
    
    func getPlayerSelectedRunIndex() -> Int {
        return playerAnimationsIndex[getPlayerSelected()]!.run
    }
    
    func getPlayerSelectedJumpIndex() -> Int {
        return playerAnimationsIndex[getPlayerSelected()]!.jump
    }
    
    // Player Animations Index
    func getPlayerDeadIndex(_ playerName: PlayerName) -> Int {
        return playerAnimationsIndex[playerName.rawValue]!.dead
    }
    
    func getPlayerIdleIndex(_ playerName: PlayerName) -> Int {
        return playerAnimationsIndex[playerName.rawValue]!.idle
    }
    
    func getPlayerRunIndex(_ playerName: PlayerName) -> Int {
        return playerAnimationsIndex[playerName.rawValue]!.run
    }
    
    func getPlayerJumpIndex(_ playerName: PlayerName) -> Int {
        return playerAnimationsIndex[playerName.rawValue]!.jump
    }
    
    // Player Selected Getter and Setter
    func setPlayerSelected(_ playerName: PlayerName) {
        UserDefaults.standard.set(playerName.rawValue, forKey: PlayerSetting.keyPlayerSelected)
    }
    
    func getPlayerSelected() -> String {
        if (!isPlayerSelectedPresent()) {
            setPlayerSelected(PlayerName.theBoy) // if not already set, it's the boy
        }
        return UserDefaults.standard.string(forKey: PlayerSetting.keyPlayerSelected)!
    }
    
    func isPlayerSelectedPresent() -> Bool {
        return UserDefaults.standard.object(forKey: PlayerSetting.keyPlayerSelected) != nil
    }
}

