//
//  SparkKeys.swift
//  Healthy Rush
//
//  Created by Luigi Loria on 13/04/21.
//

import Foundation

struct SparkKeys {
    
    struct SparkUser {
        static let uid = "uid"
        static let name = "name"
        static let email = "email"
        static let profileImageUrl = "profileImageUrl"
    }
    
    struct SparkUserStats {
        static let uid = "uid"
        static let record = "record"
        static let diamonds = "diamonds"
        static let ellieUnlocked = "ellieUnlocked"
        static let dinoUnlocked = "dinoUnlocked"
    }
    
    struct CollectionPath {
        static let users = "users"
        static let stats = "stats"
    }
    
    struct StorageFolder {
        static let profileImages = "profileImages"
    }
}
