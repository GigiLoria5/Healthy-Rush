//
//  SparkModels.swift
//  Healthy Rush
//
//  Created by Luigi Loria on 13/04/21.
//

import Foundation

protocol DocumentSerializable { // To save inside database
    init?(documentData: [String: Any])
}

// SparkUser with all the "personal" informations
struct SparkUser {
    let uid: String
    let name: String
    let email: String
    let profileImageUrl: String
    
    var dictionary: [String: Any] {
        return [
            SparkKeys.SparkUser.uid: uid,
            SparkKeys.SparkUser.name: name,
            SparkKeys.SparkUser.email: email,
            SparkKeys.SparkUser.profileImageUrl: profileImageUrl
        ]
    }
}

extension SparkUser: DocumentSerializable {
    init?(documentData: [String : Any]) {
        guard
            let uid = documentData[SparkKeys.SparkUser.uid] as? String,
            let name = documentData[SparkKeys.SparkUser.name] as? String,
            let email = documentData[SparkKeys.SparkUser.email] as? String,
            let profileImageUrl = documentData[SparkKeys.SparkUser.profileImageUrl] as? String
            else { return nil }
        self.init(uid: uid,
                  name: name,
                  email: email,
                  profileImageUrl: profileImageUrl)
    }
}

// SparkUser with all the stats
struct SparkUserStats {
    let uid: String
    var record: Int
    var diamonds: Int
    var ellieUnlocked: Bool
    var dinoUnlocked: Bool
    
    var dictionary: [String: Any] {
        return [
            SparkKeys.SparkUserStats.uid: uid,
            SparkKeys.SparkUserStats.record: record,
            SparkKeys.SparkUserStats.diamonds: diamonds,
            SparkKeys.SparkUserStats.ellieUnlocked: ellieUnlocked,
            SparkKeys.SparkUserStats.dinoUnlocked: dinoUnlocked
        ]
    }
}

extension SparkUserStats: DocumentSerializable {
    init?(documentData: [String : Any]) {
        guard
            let uid = documentData[SparkKeys.SparkUserStats.uid] as? String,
            let record = documentData[SparkKeys.SparkUserStats.record] as? Int,
            let diamonds = documentData[SparkKeys.SparkUserStats.diamonds] as? Int,
            let ellieUnlocked = documentData[SparkKeys.SparkUserStats.ellieUnlocked] as? Bool,
            let dinoUnlocked = documentData[SparkKeys.SparkUserStats.dinoUnlocked] as? Bool
            else { return nil }
        self.init(uid: uid,
                  record: record,
                  diamonds: diamonds,
                  ellieUnlocked: ellieUnlocked,
                  dinoUnlocked: dinoUnlocked)
    }
}
