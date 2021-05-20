//
//  GameOver.swift
//  Healthy Rush
//
//  Created by Luigi Loria on 14/02/21.
//

import SpriteKit

class GameOver: SKScene {
    //MARK: - Systems
    let groundSelected = UserDefaults.standard.object(forKey: "groundSelectedKey") as? Int // Ground selected in the opening
    
    // User Status and ViewController Reference
    var fbUserLogged : Bool!
    var currentUser: SparkUser!
    var viewController: GameViewController!
    
    override func didMove(to view: SKView) {
        createBGNodes()
        createGroundNodes()
        createNode()
        
        SKTAudio.sharedInstance().stopBGMusic()
        let soundGameOver = SKAction.playSoundFileNamed("gameOver.wav")
        run(soundGameOver)
        
        run(.sequence([
            .wait(forDuration: 5.0),
            .run {
                let scene = MainMenu(size: self.size)
                scene.scaleMode = self.scaleMode
                scene.fbUserLogged = self.fbUserLogged
                scene.currentUser = self.currentUser
                scene.viewController = self.viewController
                self.view!.presentScene(scene, transition: .doorsCloseVertical(withDuration: 0.5))
            }
        ]))
    }
    
    override func update(_ currentTime: TimeInterval) {
        moveNodes()
    }
}

//MARK: - Configurations
extension GameOver {
    func createBGNodes() {
       for i in 0...2 {
            let bgNode = SKSpriteNode(imageNamed: "game_background_\(groundSelected!)")
            bgNode.name = "background"
            bgNode.anchorPoint = .zero
            bgNode.size = self.size
            bgNode.position = CGPoint(x: CGFloat(i) * bgNode.frame.width, y: 0.0)
            bgNode.zPosition = -1.0
            addChild(bgNode)
        }
    }
    
    func createGroundNodes() {
        for i in 0...2 {
            let groundNode = SKSpriteNode(imageNamed: "game_ground_\(groundSelected!)")
            groundNode.name = "ground"
            groundNode.anchorPoint = .zero
            groundNode.zPosition = 1.0
            groundNode.position = CGPoint(x: -CGFloat(i) * groundNode.frame.width,
                                          y: appDI.isX ? 100.0 : 0.0)
            addChild(groundNode)
        }
    }
    
    func moveNodes() {
        enumerateChildNodes(withName: "*") { node, _ in
            if (node.name == "background" || node.name == "ground") {
                let node = node as! SKSpriteNode
                node.position.x -= 8.0
                
                if node.position.x < -self.frame.width {
                    node.position.x += node.frame.width * 3.0
                }
            }
        }
    }
    
    func createNode() {
        let gameOver = SKSpriteNode(imageNamed: "gameOver")
        gameOver.zPosition = 10.0
        gameOver.position = CGPoint(x: size.width/2.0,
                                y: size.height/2.0 + gameOver.frame.height/2.0)
        addChild(gameOver)
        
        let scalepUp = SKAction.scale(to: 1.1, duration: 0.5)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.5)
        let fullScale = SKAction.sequence([scalepUp, scaleDown])
        gameOver.run(.repeatForever(fullScale))
    }
}
