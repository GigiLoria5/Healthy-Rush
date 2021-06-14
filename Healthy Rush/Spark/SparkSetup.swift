//
//  SparkSetup.swift
//  Healthy Rush
//
//  Created by Luigi Loria on 13/04/21.
//

import Firebase

extension Spark {
    static let Firestore_Users_Collection = firestoreDatabase.collection(SparkKeys.CollectionPath.users)
    static let Firestore_Stats_Collection = firestoreDatabase.collection(SparkKeys.CollectionPath.stats)
    static let Storage_Profile_Images = Storage.storage().reference().child(SparkKeys.StorageFolder.profileImages)
}
