//
//  Spark.swift
//  Healthy Rush
//
//  Created by Luigi Loria on 13/04/21.
//

import Firebase
import FirebaseAuth
import JGProgressHUD
import SwiftyJSON
import FirebaseStorage
import FacebookCore
import FacebookLogin

class Spark {
    static var viewController: GameViewController!
    
    // MARK: -
    // MARK: Start Firebase
    static func start() {
        FirebaseApp.configure()
    }
    
    // MARK: -
    // MARK: Firestore Database
    static var firestoreDatabase: Firestore = {
        let db = Firestore.firestore()
        let settings = db.settings
//      settings.areTimestampsInSnapshotsEnabled = true // it should be default true
        db.settings = settings
        return db
    }()
    
    // MARK: -
    // MARK: Logout
    static func logout(completion: @escaping (_ result: Bool, _ error: Error?) ->()) {
        do {
            try Auth.auth().signOut() // signOut Firebase
            LoginManager().logOut()  // signOut Facebook and clear Token Access
            print("Successfully signed out")
            completion(true, nil)
        } catch let err {
            print("Failed to sign out with error:", err)
            completion(false, err)
        }
    }
    
    // MARK: -
    // MARK: Sign in with Facebook
    static func signInWithFacebook(in viewController: UIViewController, completion: @escaping (_ message: String, _ error: Error?, _ sparkUser: SparkUser?) ->()) {
        let loginManager = LoginManager()
        loginManager.logIn(permissions: [.publicProfile, .email], viewController: viewController) { (result) in
            switch result {
            case .success(granted: _, declined: _, token: _):
                print("Succesfully logged in into Facebook.")
                self.signIntoFirebaseWithFacebook(completion: completion)
            case .failed(let err):
                completion("Failed to get Facebook user with error:", err, nil)
            case .cancelled:
                completion("Canceled getting Facebook user.", nil, nil)
            }
        }
    }
    
    // MARK: -
    // MARK: Fileprivate functions
    fileprivate static func signIntoFirebaseWithFacebook(completion: @escaping (_ message: String, _ error: Error?, _ sparkUser: SparkUser?) ->()) {
        guard let authenticationToken = AccessToken.current?.tokenString else {
            completion("Could not fetch authenticationToken", nil, nil)
            return
        }
        let facebookCredential = FacebookAuthProvider.credential(withAccessToken: authenticationToken)
        signIntoFirebase(withFacebookCredential: facebookCredential, completion: completion)
    }
    
    fileprivate static func signIntoFirebase(withFacebookCredential facebookCredential: AuthCredential, completion: @escaping (_ message: String, _ error: Error?, _ sparkUser: SparkUser?) ->()) {
        Auth.auth().signIn(with: facebookCredential) { (result, err) in
            if let err = err { completion("Failed to sign up with error:", err, nil); return }
            print("Succesfully authenticated with Firebase.")
            self.fetchFacebookUser(completion: completion)
        }
    }
    
    fileprivate static func fetchFacebookUser(completion: @escaping (_ message: String, _ error: Error?, _ sparkUser: SparkUser?) ->()) {
        let graphRequestConnection = GraphRequestConnection()
        let graphRequest = GraphRequest(graphPath: "me", parameters: ["fields": "id, email, name, picture.type(large)"], tokenString: AccessToken.current?.tokenString, version: Settings.defaultGraphAPIVersion, httpMethod: .get)
        graphRequestConnection.add(graphRequest) { (httpResponse, result, error) in
            // Case Failed
            if error != nil {
                completion("Failed to get Facebook user with error:", error, nil)
                return
            }
            // Case Success
            guard let uid = Auth.auth().currentUser?.uid else { completion("Failed to fetch profilePictureUrl.", nil, nil); return }
            
            guard let responseDict = result as? NSDictionary else { completion("Failed to fetch user.", nil, nil); return }
            
            let json = JSON(responseDict)
            guard let name = json["name"].string, let email = json["email"].string, let profileImageFacebookUrl = json["picture"]["data"]["url"].string else { completion("Failed to fetch data from responseDict json.", nil, nil); return }
            
            guard let url = URL(string: profileImageFacebookUrl) else { completion("Failed to create profile picture url.", nil, nil); return }

            URLSession.shared.dataTask(with: url) { (data, result, err) in
                if err != nil { completion("Failed to fetch profile picture with err:", err, nil); return }
                guard let data = data else { completion("Failed to fetch profile picture data with err:", nil, nil); return }
                
                let documentData = [SparkKeys.SparkUser.uid: uid,
                                    SparkKeys.SparkUser.name: name,
                                    SparkKeys.SparkUser.email: email,
                                    SparkKeys.SparkUser.profileImageUrl: profileImageFacebookUrl /* remember to change this to the Firebase Storage url later on*/] as [String : Any]
                
                let sparkUser = SparkUser(documentData: documentData)
                saveUserIntoFirebaseDatabase(profileImageData: data, sparkUser: sparkUser, completion: completion)

                }.resume()
        }
        graphRequestConnection.start()
    }
    
    fileprivate static func saveUserIntoFirebaseDatabase(profileImageData: Data, sparkUser: SparkUser?, completion: @escaping (_ message: String, _ error: Error?, _ sparkUser: SparkUser?) ->()) {
        
        guard let sparkUser = sparkUser else { completion("Failed to fetch sparkUser", nil, nil); return }
        
        fetchSparkUser(sparkUser.uid) { (message, err, fetchedSparkUser) in
            if let err = err {
                completion("Failed to fetch user data", err, nil)
                return
            }
            
            guard let fetchedSparkUser = fetchedSparkUser else {
                saveSparkUser(profileImageData: profileImageData, sparkUser: sparkUser, completion: completion)
                return
            }
            
            deleteAsset(fromUrl: fetchedSparkUser.profileImageUrl, completion: { (result, err) in
                if let err = err {
                    completion("Failed to deleted profile image form Storage", err, nil)
                    return
                }
                
                if result {
                    
                    saveSparkUser(profileImageData: profileImageData, sparkUser: sparkUser, completion: completion)
                    
                } else {
                    completion("Failed to delete profile image from Storage", err, nil)
                }
            })
        }
    }
    
    fileprivate static func saveSparkUser(profileImageData: Data, sparkUser: SparkUser, completion: @escaping (_ message: String, _ error: Error?, _ sparkUser: SparkUser?) ->()) {
        
        guard let profileImage = UIImage(data: profileImageData) else { completion("Failed to generate profile image from data", nil, nil); return }
        guard let profileImageUploadData = profileImage.jpegData(compressionQuality: 0.3) else { completion("Failed to compress jpeg data", nil, nil); return }
        
        let fileName = UUID().uuidString
        Storage_Profile_Images.child(fileName).putData(profileImageUploadData, metadata: nil) { (metadata, err) in
            if let err = err { completion("Failed to save profile image to Storage with error:", err, nil); return }
            guard let metadata = metadata, let path = metadata.path else { completion("Failed to get metadata or path to profile image url.", nil, nil); return }
            Spark.getDownloadUrl(from: path, completion: { (profileImageFirebaseUrl, err) in
                if let err = err { completion("Failed to get download url with error:", err, nil); return }
                guard let profileImageFirebaseUrl = profileImageFirebaseUrl else { completion("Failed to get profileImageUrl.", nil, nil); return }
                print("Successfully uploaded profile image into Firebase storage with URL:", profileImageFirebaseUrl)
                
                let documentPath = sparkUser.uid
                let documentData = [SparkKeys.SparkUser.uid: sparkUser.uid,
                                    SparkKeys.SparkUser.name: sparkUser.name,
                                    SparkKeys.SparkUser.email: sparkUser.email,
                                    SparkKeys.SparkUser.profileImageUrl: profileImageFirebaseUrl] as [String : Any]
                
                Spark.Firestore_Users_Collection.document(documentPath).setData(documentData, completion: { (err) in
                    if let err = err { completion("Failed to save document with error:", err, nil); return }
                    let newSparkUser = SparkUser(documentData: documentData)
                    print("Successfully saved user info into Firestore: \(String(describing: newSparkUser))")
                    completion("Successfully signed in with Facebook.", nil, newSparkUser)
                })
                
            })
        }
    }
    
    // MARK: -
    // MARK: Fetch Profile Image
    static func fetchProfileImage(sparkUser: SparkUser, completion: @escaping (_ message: String, _ error: Error?, _ image: UIImage?) ->()) {
        let profileImageUrl = sparkUser.profileImageUrl
        guard let url = URL(string: profileImageUrl) else { completion("Failed to create url for profile image.", nil, nil); return }
        
        URLSession.shared.dataTask(with: url) { (data, response, err) in
            if err != nil { completion("Failed to fetch profile image with url:", err, nil); return }
            guard let data = data else { completion("Failed to fetch profile image data", nil, nil); return }
            let profileImage = UIImage(data: data)
            completion("Successfully fetched profile image", nil, profileImage)
            }.resume()
    }
    
    // MARK: -
    // MARK: Fetch Current Spark User
    static func fetchCurrentSparkUser(completion: @escaping (_ message: String, _ error: Error?, _ sparkUser: SparkUser?) ->()) {
        if Auth.auth().currentUser != nil {
            guard let uid = Auth.auth().currentUser?.uid else { completion("Failed to fetch user uid.", nil, nil); return }
            fetchSparkUser(uid, completion: completion)
        }
    }
    
    // MARK: -
    // MARK: Fetch Spark User with uid
    static func fetchSparkUser(_ uid: String, completion: @escaping (_ message: String, _ error: Error?, _ sparkUser: SparkUser?) ->()) {
        Firestore_Users_Collection.whereField(SparkKeys.SparkUser.uid, isEqualTo: uid).getDocuments { (snapshot, err) in
            if let err = err { completion("Failed to fetch document with error:", err, nil); return }
            guard let snapshot = snapshot, let sparkUser = snapshot.documents.first.flatMap({SparkUser(documentData: $0.data())}) else { completion("Failed to get spark user from snapshot.", nil, nil); return }
            completion("Successfully fetched spark user", nil, sparkUser)
        }
    }
    
    // MARK: -
    // MARK: Fetch Spark User with uid
    static func fetchAllSparkUsers(completion: @escaping (_ message: String, _ error: Error?, _ sparkUsers: EnumeratedSequence<[QueryDocumentSnapshot]>?) ->()) {
        Firestore_Users_Collection.getDocuments { (snapshot, err) in
            if let err = err { completion("Failed to fetch document with error:", err, nil); return }
            guard let snapshot = snapshot else {
                completion("Failed to get spark user from snapshot.", nil, nil); return }
            completion("Successfully fetched spark user", nil, snapshot.documents.enumerated())
            /*
            var users = snapshot.documents.enumerated()
            for (index, element) in users {
                print("Item \(index): \(element.data())")
                for (key, value) in element.data() {
                    print("Key \(key): value\(value)")
                }
            } */
        }
    }
    
    // MARK: -
    // MARK: Delete Asset
    static func deleteAsset(fromUrl url: String, completion: @escaping (_ result: Bool, _ error: Error?) ->()) {
        Storage.storage().reference(forURL: url).getMetadata { (metadata, err) in
            if let err = err, let errorCode = StorageErrorCode(rawValue: err._code) {
                if errorCode == .objectNotFound {
                    print("Asset not found, no need to delete")
                    completion(true, nil)
                    return
                }
            }
            
            Storage.storage().reference(forURL: url).delete { (err) in
                if let err = err {
                    print("Could not delete asset at url:", url)
                    completion(false, err)
                    return
                }
                print("Successfully deleted asset from url:", url)
                completion(true, nil)
            }
            
        } 
    }
    
    // MARK: -
    // MARK: Get download URL
    static func getDownloadUrl(from path: String, completion: @escaping (String?, Error?) -> Void) {
        Storage.storage().reference().child(path).downloadURL { (url, err) in
            completion(url?.absoluteString, err)
        }
    }
    
}
