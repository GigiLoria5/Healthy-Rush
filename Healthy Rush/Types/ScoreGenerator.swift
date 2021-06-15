//
//  ScoreGenerator.swift
//  Healthy Rush
//
//  Created by Luigi Loria on 13/02/21.
//

import Foundation

class ScoreGenerator {
    static let sharedInstance = ScoreGenerator()
    private init() {}
    
    static let keyNewRecordSet = "keyNewRecordSet"
    static let keyHighscore = "keyHighscore"
    static let keyScore = "keyScore" // a.k.a. last match score
    static let keyDiamonds = "keyDiamonds"
    static let keyDiamondsLastMatch = "keyDiamondsLastMatch"
    
    // Reset all the local scores to 0
    func resetAll() {
        ScoreGenerator.sharedInstance.setScore(0)
        ScoreGenerator.sharedInstance.setHighscore(0)
        ScoreGenerator.sharedInstance.setNewRecordSet(false)
        ScoreGenerator.sharedInstance.setDiamonds(0)
        ScoreGenerator.sharedInstance.setDiamondsLastMatch(0)
    }
    
    // Last Score
    func setScore(_ score: Int) {
        UserDefaults.standard.set(score, forKey: ScoreGenerator.keyScore)
    }
    
    func getScore() -> Int {
        return UserDefaults.standard.integer(forKey: ScoreGenerator.keyScore)
    }
    
    func isScorePresent() -> Bool {
        return UserDefaults.standard.object(forKey: ScoreGenerator.keyScore) != nil
    }
    
    // Highscore
    func setHighscore(_ highscore: Int) {
        UserDefaults.standard.set(highscore, forKey: ScoreGenerator.keyHighscore)
    }
    
    func getHighscore() -> Int {
        return UserDefaults.standard.integer(forKey: ScoreGenerator.keyHighscore)
    }
    
    func isHighscorePresent() -> Bool {
        return UserDefaults.standard.object(forKey: ScoreGenerator.keyHighscore) != nil
    }
    
    // Highscore
    func setNewRecordSet(_ isNewRecord: Bool) {
        UserDefaults.standard.set(isNewRecord, forKey: ScoreGenerator.keyNewRecordSet)
    }
    
    func getNewRecordSet() -> Bool {
        return UserDefaults.standard.bool(forKey: ScoreGenerator.keyNewRecordSet)
    }
    
    func isNewRecordSetPresent() -> Bool {
        return UserDefaults.standard.object(forKey: ScoreGenerator.keyNewRecordSet) != nil
    }
    
    // Diamonds Collected
    func setDiamonds(_ diamonds: Int) {
        UserDefaults.standard.set(diamonds, forKey: ScoreGenerator.keyDiamonds)
    }
    
    func getDiamonds() -> Int {
        return UserDefaults.standard.integer(forKey: ScoreGenerator.keyDiamonds)
    }
    
    func isDiamondsPresent() -> Bool {
        return UserDefaults.standard.object(forKey: ScoreGenerator.keyDiamonds) != nil
    }
    
    // Diamonds Collected in the Last Match
    func setDiamondsLastMatch(_ diamonds: Int) {
        UserDefaults.standard.set(diamonds, forKey: ScoreGenerator.keyDiamondsLastMatch)
    }
    
    func getDiamondsLastMatch() -> Int {
        return UserDefaults.standard.integer(forKey: ScoreGenerator.keyDiamondsLastMatch)
    }
    
    func isDiamondsPresentLastMatch() -> Bool {
        return UserDefaults.standard.object(forKey: ScoreGenerator.keyDiamondsLastMatch) != nil
    }
}

