//
//  GameViewController.swift
//  Healthy Rush
//
//  Created by Luigi Loria on 10/02/21.
//

import UIKit
import SpriteKit
import GameplayKit
import FirebaseAuth

class GameViewController: UIViewController {
    
    // Firebase utilis
    var handler: AuthStateDidChangeListenerHandle?
    var userLoggedIn = true

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        handler = Auth.auth().addStateDidChangeListener({ (auth, user) in
            self.checkLoggedInUserStatus()
        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Drop handler listener on view disappear
        guard let handler = handler else { return }
        Auth.auth().removeStateDidChangeListener(handler)
    }
    
    // Check if user is already logged in
    fileprivate func checkLoggedInUserStatus() {
        DispatchQueue.main.async { // Create an object that manages the execution of this task serially
            if Auth.auth().currentUser == nil {
                self.userLoggedIn = false               // the user is not logged
            } else {
                self.userLoggedIn = true                // the user is logged
            }
            self.presentMainMenuScene()
            return
        }
    }
    
    func presentMainMenuScene() {
        let scene = MainMenu(size: CGSize(width: 2048, height: 1536))
        scene.scaleMode = .aspectFill
        scene.fbUserLogged = self.userLoggedIn   // save user login status
        scene.viewController = self              // save controller reference
        Spark.viewController = self              // save controller reference
        
        let skView = self.view as! SKView
        skView.showsFPS = false
        skView.showsNodeCount = false
        skView.showsPhysics = false
        skView.ignoresSiblingOrder = true
        skView.presentScene(scene)
    }
    
    func showTextInputPrompt(withMessage message: String,
                               completionBlock: @escaping ((Bool, String?) -> Void)) {
        let prompt = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
          completionBlock(false, nil)
        }
        weak var weakPrompt = prompt
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
          guard let text = weakPrompt?.textFields?.first?.text else { return }
          completionBlock(true, text)
        }
        prompt.addTextField(configurationHandler: nil)
        prompt.addAction(cancelAction)
        prompt.addAction(okAction)
        present(prompt, animated: true, completion: nil)
      }
    
    // "Spark Service"
    func showAlert(style: UIAlertController.Style, title: String?, message: String?, actions: [UIAlertAction] = [UIAlertAction(title: "Ok", style: .cancel, handler: nil)], completion: (() -> Swift.Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: style)
        for action in actions {
            alert.addAction(action)
        }
        present(alert, animated: true, completion: completion)
    }
    
}
