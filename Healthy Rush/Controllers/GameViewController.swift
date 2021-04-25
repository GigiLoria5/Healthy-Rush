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
<<<<<<< Updated upstream
=======
    
    // Firebase utilis
    var handler: AuthStateDidChangeListenerHandle?
    var userLoggedIn = true
>>>>>>> Stashed changes

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
        // Drop handler listener
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
<<<<<<< Updated upstream
        scene.viewController = self // save controller reference
        
        let skView = view as! SKView
=======
        scene.fbUserLogged = self.userLoggedIn   // save user login status
        scene.viewController = self              // save controller reference
        Spark.viewController = self              // save controller reference
        
        let skView = self.view as! SKView
>>>>>>> Stashed changes
        skView.showsFPS = false
        skView.showsNodeCount = false
        skView.showsPhysics = false
        skView.ignoresSiblingOrder = true
        skView.presentScene(scene)
    }
    
<<<<<<< Updated upstream
    override var prefersStatusBarHidden: Bool {
        return true
    }
=======
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
    
    func showMessagePrompt(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        present(alert, animated: false, completion: nil)
      }
>>>>>>> Stashed changes
    
}
