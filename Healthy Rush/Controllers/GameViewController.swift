//
//  GameViewController.swift
//  Healthy Rush
//
//  Created by Luigi Loria on 10/02/21.
//

import UIKit
import SpriteKit
import GameplayKit

var settings = GameSettings(camera: false, watch: false)

class GameViewController: UIViewController{
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let scene = MainMenu(size: CGSize(width: 2048, height: 1536))
        scene.scaleMode = .aspectFill
        scene.viewController = self // save controller reference for the main menu
        let skView = view as! SKView
        skView.showsFPS = false
        skView.showsNodeCount = false
        skView.showsPhysics = false
        skView.ignoresSiblingOrder = true
        skView.presentScene(scene)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}
