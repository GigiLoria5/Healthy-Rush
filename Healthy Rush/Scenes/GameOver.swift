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
    var currentUser: SparkUser!             // uid, email, name, profileImageUrl
    var currentUserStats: SparkUserStats!   // uid, diamonds, dinoUnlocked, ellieUnlocked, record
    var viewController: GameViewController!
    
    //last match info
    let newRecordSet = ScoreGenerator.sharedInstance.getNewRecordSet()
    
    
    override func didMove(to view: SKView) {
        createBGNodes()
        createGroundNodes()
        createMessageNode()
        createPlayerDeath()
        SKTAudio.sharedInstance().stopBGMusic() // stop the gameScene music
        runMessageMusic() // play the music according to the current message shown
        
        // After 5 seconds the summary appears
        run(.sequence([
            .wait(forDuration: 5.0),
            .run {
                self.createSummary()
            }
        ]))
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        guard let touch = touches.first else { return }
        let node = atPoint(touch.location(in: self))
        
        switch node.name {
        case "home": // Home button
            run(SKAction.playSoundFileNamed("buttonSound.wav"))
            run(.sequence([
                .wait(forDuration: 0.5),
                .run {
                    let scene = MainMenu(size: self.size)
                    scene.scaleMode = self.scaleMode
                    scene.fbUserLogged = self.fbUserLogged
                    scene.currentUser = self.currentUser
                    scene.currentUserStats = self.currentUserStats
                    scene.viewController = self.viewController
                    self.view!.presentScene(scene, transition: .doorsCloseVertical(withDuration: 0.5))
                }
            ]))
        case "play": // Play button
            run(SKAction.playSoundFileNamed("buttonSound.wav"))
            let scene = GameScene(size: size)
            scene.scaleMode = scaleMode
            scene.fbUserLogged = self.fbUserLogged
            scene.currentUser = self.currentUser
            scene.currentUserStats = self.currentUserStats
            scene.viewController = self.viewController
            view!.presentScene(scene, transition: .doorsOpenVertical(withDuration: 0.3))
        default:
            return
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        moveNodes() // move background
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
    
    func createGameOverNode() {
        let gameOver = SKSpriteNode(imageNamed: "gameOver")
        gameOver.zPosition = 10.0
        gameOver.position = CGPoint(x: size.width/2.0,
                                y: size.height/2.0 + gameOver.frame.height/2.0)
        addChild(gameOver)
        
        let scalepUp = SKAction.scale(to: 1.1, duration: 0.5)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.5)
        let fullScale = SKAction.sequence([scalepUp, scaleDown])
             
        gameOver.run(.repeat(fullScale, count: 5), completion: {
            gameOver.removeFromParent()
        })
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
                node.position.x -= 6.0
                
                if node.position.x < -self.frame.width {
                    node.position.x += node.frame.width * 3.0
                }
            }
        }
    }
    
    func createNewRecordNode(){
        let newRecord = SKSpriteNode(imageNamed: "newRecord")
        newRecord.zPosition = 10.0
        newRecord.setScale(3)
        newRecord.position = CGPoint(x: size.width/2.0,
                                     y: size.height/2.0)
        addChild(newRecord)
        
        let scalepUp = SKAction.scale(to: 3.1, duration: 0.5)
        let scaleDown = SKAction.scale(to: 3.0, duration: 0.5)
        let fullScale = SKAction.sequence([scalepUp, scaleDown])
        
        newRecord.run(.repeat(fullScale, count: 5), completion: {
            newRecord.removeFromParent()
        })
    }
    

    func createFireworks(){
        let leftEmitter = SKEmitterNode(fileNamed: "fireworks.sks")
        let rightEmitter = SKEmitterNode(fileNamed: "fireworks.sks")
        
        leftEmitter?.position = CGPoint(x: size.width/4.0,y: size.height/2.0)
        rightEmitter?.position = CGPoint(x: 3 * size.width/4.0,y: size.height/2.0)
        
        if((leftEmitter) != nil){
            addChild(leftEmitter!)
        }
        if((rightEmitter) != nil){
            addChild(rightEmitter!)
        }
    }
    
    func createMessageNode(){
//       messaggio a seconda del punteggio
        if(newRecordSet){
//          aggiunge scritta "new Record" alla scena
            createNewRecordNode()
//            aggiunge effetto fuochi artificio
            createFireworks()
        }
        else{
            createGameOverNode()
        }
    }

    func runMessageMusic(){
        if(newRecordSet){
            let soundNewRecord = SKAction.playSoundFileNamed("newRecord.wav")
            run(soundNewRecord)
        }else{
            let soundGameOver = SKAction.playSoundFileNamed("gameOver.wav")
            run(soundGameOver)
        }
    }
    
    func createSummary() {
        // Getting the values for the summary
        let newRecordSet = ScoreGenerator.sharedInstance.getNewRecordSet()
        let scoreLastMatch = ScoreGenerator.sharedInstance.getScore()
        let diamondsCollected = ScoreGenerator.sharedInstance.getDiamondsLastMatch()
        let avgBPM = ControllerSetting.sharedInstance.getWatchMode() ? "\(String(describing: Int(appDI.averageHeartRate.rounded())))" : "Watch Only"
        let avgBreath = ControllerSetting.sharedInstance.getWatchMode() ? "\(String(describing: Int(CGFloat.random(min: 15, max: 18))))" : "Watch Only"
        let kcalBurned = ControllerSetting.sharedInstance.getWatchMode() ? "\(String(describing: Int(appDI.sumActiveEnergyBurned.rounded())))" : "Watch Only"
        
        // Panel Image (Container)
        let panelImage = SKSpriteNode(imageNamed: newRecordSet ? "summaryNewRecord" : "summary")
        panelImage.name = "Summary"
        panelImage.zPosition = 50
        panelImage.position = CGPoint(x: self.size.width/2, y: self.size.height/1.95)
        panelImage.setScale(0.9)
        addChild(panelImage)
        
        // Some general settings for the labels
        let fontSize = CGFloat(46)
        let fontColor = UIColor.white
        
        // Last Score Label
        let scoreLbl = SKLabelNode(fontNamed: "AmericanTypewriter-Bold")
        scoreLbl.name = "scoreLbl"
        scoreLbl.fontSize = fontSize
        scoreLbl.zPosition = panelImage.zPosition + 1
        scoreLbl.text = String(scoreLastMatch) + "m"
        scoreLbl.fontColor = fontColor
        scoreLbl.position = CGPoint(x: panelImage.frame.width/3.7,
                                    y: scoreLbl.frame.height/1.8)
        panelImage.addChild(scoreLbl)
        
        // Number of diamonds Label
        let diamondsLbl = SKLabelNode(fontNamed: "AmericanTypewriter-Bold")
        diamondsLbl.name = "diamondsLbl"
        diamondsLbl.fontSize = fontSize
        diamondsLbl.zPosition = panelImage.zPosition + 1
        diamondsLbl.text = String(diamondsCollected)
        diamondsLbl.fontColor = fontColor
        diamondsLbl.position = CGPoint(x: scoreLbl.position.x,
                                       y: scoreLbl.position.y - 2.8 * diamondsLbl.frame.height)
        panelImage.addChild(diamondsLbl)
        
        let deltaY = 2.7 * diamondsLbl.frame.height // In order to pos
        
        // Calories Burned (Watch Only)
        let caloriesLbl = SKLabelNode(fontNamed: "AmericanTypewriter-Bold")
        caloriesLbl.name = "caloriesLbl"
        caloriesLbl.fontSize = fontSize
        caloriesLbl.zPosition = panelImage.zPosition + 1
        caloriesLbl.text = String(kcalBurned)
        caloriesLbl.fontColor = fontColor
        caloriesLbl.position = CGPoint(x: scoreLbl.position.x,
                                       y: diamondsLbl.position.y - deltaY)
        panelImage.addChild(caloriesLbl)
        
        // Average Bpm (Watch Only)
        let bpmLbl = SKLabelNode(fontNamed: "AmericanTypewriter-Bold")
        bpmLbl.name = "bpmLbl"
        bpmLbl.fontSize = fontSize
        bpmLbl.zPosition = panelImage.zPosition + 1
        bpmLbl.text = String(avgBPM)
        bpmLbl.fontColor = fontColor
        bpmLbl.position = CGPoint(x: scoreLbl.position.x,
                                  y: caloriesLbl.position.y - deltaY)
        panelImage.addChild(bpmLbl)
        
        // Average Breath (Watch Only)
        let breathLbl = SKLabelNode(fontNamed: "AmericanTypewriter-Bold")
        breathLbl.name = "breathLbl"
        breathLbl.fontSize = fontSize
        breathLbl.zPosition = panelImage.zPosition + 1
        breathLbl.text = String(avgBreath)
        breathLbl.fontColor = fontColor
        breathLbl.position = CGPoint(x: scoreLbl.position.x,
                                     y: bpmLbl.position.y - deltaY)
        panelImage.addChild(breathLbl)
        
        // Buttons Container
        let buttonPanel = SKSpriteNode(imageNamed: "scoreContainerNoIcon")
        buttonPanel.name = "ButtonPanel"
        buttonPanel.xScale = 0.678
        buttonPanel.zRotation = CGFloat(90).degreesToRadiants()
        buttonPanel.zPosition = panelImage.zPosition + 2
        buttonPanel.position = CGPoint(x: panelImage.frame.width/2.0,
                                       y: -buttonPanel.frame.width/1.6)
        panelImage.addChild(buttonPanel)
        
        // Return to menu button
        let menuButton = SKSpriteNode(imageNamed: "home")
        menuButton.name = "home"
        menuButton.yScale = 1.475
        menuButton.zRotation = CGFloat(-90).degreesToRadiants()
        menuButton.zPosition = panelImage.zPosition + 1
        menuButton.position = CGPoint(x: menuButton.frame.height,
                                      y: 0.0)
        buttonPanel.addChild(menuButton)
        
        // New Match button
        let playButton = SKSpriteNode(imageNamed: "playSmall")
        playButton.name = "play"
        playButton.yScale = 1.475
        playButton.zRotation = CGFloat(-90).degreesToRadiants()
        playButton.zPosition = panelImage.zPosition + 1
        playButton.position = CGPoint(x: -playButton.frame.height,
                                      y: 0.0)
        buttonPanel.addChild(playButton)
    }
    
    
    func createPlayerDeath(){
        let ground = self.childNode(withName: "ground")!
        let playerName = PlayerSetting.sharedInstance.getPlayerSelected()
        let player = SKSpriteNode(imageNamed: "\(playerName)/Dead (1)")
        player.name = playerName
        player.zPosition = 10.0
        player.position = CGPoint(x: frame.width/2.0, y: ground.frame.maxY + player.frame.height/3.0)
        addChild(player)
        
        // Add animations
        var playerFrames = [SKTexture]()
        for i in 2...PlayerSetting.sharedInstance.getPlayerSelectedDeadIndex(){
            let frameName = "\(playerName)/Dead (\(i))"
            playerFrames.append(SKTexture(imageNamed: frameName))
        }
    
        // Animation activated
        player.run(SKAction.animate(with: playerFrames, timePerFrame: PlayerSetting.sharedInstance.playerRunTimeFrame[playerName]!), withKey: "\(playerName)Animation")
        
        // Remove the player after 5 seconds (when the summary appears)
        run(.sequence([
            .wait(forDuration: 5.0),
            .run {
                player.removeFromParent()
            }
        ]))
    }
}

