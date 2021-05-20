//
//  AppDelegate.swift
//  Healthy Rush
//
//  Created by Luigi Loria on 10/02/21.
//

import UIKit
import WatchConnectivity
import Firebase
import FBSDKCoreKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate, WCSessionDelegate {

    var isX: Bool = false // to adact screen size
    var session: WCSession! // to connect the watch app
    var window: UIWindow?
    var jump: Bool = false // var which will be sent
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        // Called when the session prepares to stop communicating with the current Apple Watch
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        // Called after all data from the previous session has been delivered and communication with the Apple Watch has ended
    }
    
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        // Called when the activation of a session finishes
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        jump = (message["movement"] != nil)
    }


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
<<<<<<< Updated upstream
=======
        
        // Firebase setup
        Spark.start()
        
        // Facebook setup
        ApplicationDelegate.shared.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )
        
>>>>>>> Stashed changes
        // Detecting screen types (iphoneX, iphone11, ...)
        switch UIScreen.main.nativeBounds.height {
        case 2688, 1792, 2436:
            isX = true
        default:
            isX = false
        }
        // To activate the Watch Connettivity
        if WCSession.isSupported() {
            session = WCSession.default
            session.delegate = self
            session.activate()
        }
        // Firebase configuration
        FirebaseApp.configure()
        // Facebook configuration
        ApplicationDelegate.shared.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )
        
        return true
    }
    
    // Facebook configuration
    func application(
            _ app: UIApplication,
            open url: URL,
            options: [UIApplication.OpenURLOptionsKey : Any] = [:]
        ) -> Bool {

            ApplicationDelegate.shared.application(
                app,
                open: url,
                sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
                annotation: options[UIApplication.OpenURLOptionsKey.annotation]
            )

<<<<<<< Updated upstream
        }

=======
        }  
>>>>>>> Stashed changes

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }


}

