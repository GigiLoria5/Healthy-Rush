//
//  SparkModels.swift
//  Healthy Rush
//
//  Created by Luigi Loria on 13/04/21.
//

import Foundation

protocol DocumentSerializable {
    init?(documentData: [String: Any])
}

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
