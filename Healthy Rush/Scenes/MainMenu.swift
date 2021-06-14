//
//  MainMenu.swift
//  Healthy Rush
//
//  Created by Luigi Loria on 13/02/21.
//

import SpriteKit
import JGProgressHUD
import FirebaseAuth

class MainMenu: SKScene {
    
    //MARK: - Properties
    var containerNode: SKSpriteNode!
    
    // Controller reference
    var viewController: GameViewController!
    
    // Settings
    let buttonScale: CGFloat = 1.2
    let buttonScaleBigger: CGFloat = 1.44
    var timePerFrameTheBoyAnimations: TimeInterval = 0.095 // Animations speed
    var timePerFrameCuteGirlAnimations: TimeInterval = 0.065 // Animations speed
    var timePerFrameDino : TimeInterval = 0.095
    var timePerFrameIndiana : TimeInterval = 0.075
    var playerSelectedKey = "PlayerSelected"
    var firstOpen = true // in order to avoid bug in updatePlayerSelection()
    let selectionLbl = SKLabelNode(fontNamed: "AmericanTypewriter-Bold") // selection label
    
    // For the info panel
    var currInfoPageNum : Int = 1
    var pageInfoNum : Int = 3
    var istanceInfoActive : Bool = false
    
    
//    For the shop panel
    var currShopPageNum : Int = 1
    var prevShopPageNum : Int = 1
    var shopCharacters : Int = 4
    var istanceShopActive : Bool = false
    
    
    // For the top run panel
    var currTopRunPageNum : Int = 1
    var maxTopRunPageNum : Int!
    
    // Gesture Captures
    var gestureCaptureIstance = GesturesCapture()
    
    // Firebase utilis
    var currentUser: SparkUser!
    
    // Facebook utilis
    var fbUserLogged : Bool!
    let facebookLoginLbl = SKLabelNode(fontNamed: "AmericanTypewriter-Bold") // login fb label
    let beforeLoginTxt = "To save your progress, login with Facebook" // initial text
    let duringLoginTxt = "Signing in with Facebook..." // during signing text
    let afterLoginTxt  = "You are login as " // after signed text
    let signingOutTxt = "You're about to be signed out..." // during signing out text
    let hud: JGProgressHUD = { // Pop up loading type
        let hud = JGProgressHUD(style: .light)
        hud.interactionType = .blockTouchesOnHUDView
        return hud
    } ()
    
    //MARK: - Systems
    override func didMove(to view: SKView) {
        // Get current user
        if(fbUserLogged) {
            Spark.fetchCurrentSparkUser(completion: { message, err, sparkUser in
                self.currentUser = sparkUser
            })
        }
        setupBG()
        setupNodes()
        setupPlayer()
        SKTAudio.sharedInstance().playBGMusic("backgroundMusic.mp3") // play bg music
        if UserDefaults.standard.object(forKey: "PlayerSelected") == nil { // first time setting
            UserDefaults.standard.setValue("TheBoy", forKey: playerSelectedKey)
        }
        setupSelectionLabel()
        updatePlayerSelection()
    }
    
    //MARK: - Touches
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        // saves the initial touch point and the instant when it was pressed
        gestureCaptureIstance.startCapturing(touches, scene: self)
        
        guard let touch = touches.first else { return }
        let node = atPoint(touch.location(in: self))
        
        switch node.name {
        case "play":
            run(SKAction.playSoundFileNamed("buttonSound.wav"))
            let scene = GameScene(size: size)
            scene.scaleMode = scaleMode
            scene.fbUserLogged = self.fbUserLogged
            scene.currentUser = self.currentUser
            scene.viewController = self.viewController
            view!.presentScene(scene, transition: .doorsOpenVertical(withDuration: 0.3))
        case "highscore":
            run(SKAction.playSoundFileNamed("buttonSound.wav"))
            setupHighscorePanel()
        case "setting":
            run(SKAction.playSoundFileNamed("buttonSound.wav"))
            setupSettingPanel()
        case "music":
            run(SKAction.playSoundFileNamed("buttonSound.wav"))
            let node = node as! SKSpriteNode
            SKTAudio.musicEnabled = !SKTAudio.musicEnabled
            node.texture = SKTexture(imageNamed: SKTAudio.musicEnabled ? "musicOn" : "musicOff")
            SKTAudio.sharedInstance().playBGMusic("backgroundMusic.mp3")
        case "effect":
            let node = node as! SKSpriteNode
            effectEnabled = !effectEnabled
            node.texture = SKTexture(imageNamed: effectEnabled ? "effectOn" : "effectOff")
            run(SKAction.playSoundFileNamed("buttonSound.wav"))
        case "facebookBtn":
            run(SKAction.playSoundFileNamed("buttonSound.wav"))
            fbUserLogged ? handleSignOutWithFacebookButtonTapped() : handleSignInWithFacebookButtonTapped()
            let node = node as! SKSpriteNode
            node.texture = SKTexture(imageNamed: fbUserLogged ? "facebookOn" : "facebookOff")
            facebookLoginLbl.text = fbUserLogged ? afterLoginTxt + (Auth.auth().currentUser?.displayName ?? "DISPLAY NAME NOT FOUND") : beforeLoginTxt
        case "controllerSelect":
            run(SKAction.playSoundFileNamed("buttonSound.wav"))
            if(containerNode != nil) {
                containerNode.removeFromParent() // Remove any other panel already active
            }
            setupControllerChoicePanel()
        case "cameraImage":
            if #available(iOS 14.0, *) {
                let cameraMode = UserDefaults.standard.bool(forKey: "cameraMode")
                UserDefaults.standard.set(!cameraMode, forKey: "cameraMode")
                UserDefaults.standard.set(false, forKey: "watchMode")
                updateControllerChoicePanel()
            }
        case "watchImage":
            let watchMode = UserDefaults.standard.bool(forKey: "watchMode")
            UserDefaults.standard.set(!watchMode, forKey: "watchMode")
            UserDefaults.standard.set(false, forKey: "cameraMode")
            updateControllerChoicePanel()
        
        case "shop":
            if(istanceInfoActive == false){
                run(SKAction.playSoundFileNamed("buttonSound.wav"))
                if(containerNode != nil) {
                    containerNode.removeFromParent() // Remove any other panel already active
                }
                setupShopPanel()
                istanceShopActive = true
            }
            
        case "ShopArrowRight":
            if(currShopPageNum <= shopCharacters) {
                run(SKAction.playSoundFileNamed("buttonSound.wav"))
                prevShopPageNum = currShopPageNum
                currShopPageNum += 1
                updateShop()
            }
        case "ShopArrowLeft":
            if(currInfoPageNum >= 1) {
                run(SKAction.playSoundFileNamed("buttonSound.wav"))
                prevShopPageNum = currShopPageNum
                currShopPageNum -= 1
                updateShop()
            }
            
        case "info":
            if(istanceInfoActive == false){
                run(SKAction.playSoundFileNamed("buttonSound.wav"))
                if(containerNode != nil) {
                    containerNode.removeFromParent() // Remove any other panel already active
                }
                setupInfoPanel()
                istanceInfoActive = true
            }
        case "infoArrowRight":
            if(currInfoPageNum <= pageInfoNum) {
                run(SKAction.playSoundFileNamed("buttonSound.wav"))
                currInfoPageNum += 1
                updateInfo()
            }
        case "infoArrowLeft":
            if(currInfoPageNum >= 1) {
                run(SKAction.playSoundFileNamed("buttonSound.wav"))
                currInfoPageNum -= 1
                updateInfo()
            }
        case "container":
            currInfoPageNum = 1 //reset the page counter
            istanceInfoActive = false
            run(SKAction.playSoundFileNamed("buttonSound.wav"))
            containerNode.removeAllChildren()
            containerNode.removeFromParent()
        case "theBoy":
            run(SKAction.playSoundFileNamed("playerSelect.mp3"))
            let playerSelected = UserDefaults.standard.object(forKey: playerSelectedKey) as? String
            if playerSelected! != "TheBoy" { // if already selected is useless
                UserDefaults.standard.setValue("TheBoy", forKey: playerSelectedKey)
                updatePlayerSelection()
            }
        case "cuteGirl":
            run(SKAction.playSoundFileNamed("playerSelect.mp3"))
            let playerSelected = UserDefaults.standard.object(forKey: playerSelectedKey) as? String
            if playerSelected! != "CuteGirl" { // if already selected is useless
                UserDefaults.standard.setValue("CuteGirl", forKey: playerSelectedKey)
                updatePlayerSelection()
            }
        default:
            break
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Find the gesture
        gestureCaptureIstance.findGesture(touches, scene: self)
        
        containerNode?.enumerateChildNodes(withName: "HighscorePanel") { node, _ in
            node.enumerateChildNodes(withName: "TopRun") { node, _ in
                let gesture = self.gestureCaptureIstance.getCurrentSwipe()
                if(gesture == .up) {
                    print("Swipe up")
                } else if (gesture == .down) {
                    print("Swipe down")
                }
            }
        }
        
        super.touchesEnded(touches, with: event)
    }
}

//MARK: - Configurations
extension MainMenu {
    func setupBG() {
        let bgNode = SKSpriteNode(imageNamed: "menu_background")
        bgNode.zPosition = -1.0
        bgNode.anchorPoint = .zero
        bgNode.size = self.size
        bgNode.position = .zero
        addChild(bgNode)
    }
    
    func setupNodes() {
        let play = SKSpriteNode(imageNamed: "play")
        play.name = "play"
        play.setScale(buttonScaleBigger)
        play.zPosition = 10.0
        play.position = CGPoint(x: size.width/2.0, y: size.height/2.0)
        addChild(play)
        
        let highscore = SKSpriteNode(imageNamed: "highscore")
        highscore.name = "highscore"
        highscore.setScale(buttonScale)
        highscore.zPosition = 10.0
        highscore.position = CGPoint(x: size.width/2.0, y: size.height/2.0 + highscore.frame.height + 60.0)
        addChild(highscore)
        
        let setting = SKSpriteNode(imageNamed: "setting")
        setting.name = "setting"
        setting.setScale(buttonScale)
        setting.zPosition = 10.0
        setting.position = CGPoint(x: size.width/2.0, y: size.height/2.0 - setting.size.height - 50.0)
        addChild(setting)
        
        let info = SKSpriteNode(imageNamed: "info")
        info.setScale(0.625)
        info.zPosition = 50.0
        info.name = "info"
        info.position = CGPoint(x: info.frame.width/2 + 50, y: size.height/2 + play.frame.height + 120)
        addChild(info)
        
        let shop = SKSpriteNode(imageNamed: "shop")
        shop.setScale(0.625)
        shop.zPosition = 10.0
        shop.name = "shop"
        shop.position = CGPoint(x: info.position.x, y: info.position.y - 3*shop.size.height/2)
        addChild(shop)
        
        let controllerSelect = SKSpriteNode(imageNamed: "controllerOn")
        controllerSelect.setScale(0.8)
        controllerSelect.zPosition = 50.0
        controllerSelect.name = "controllerSelect"
        controllerSelect.position = CGPoint(x: size.width - controllerSelect.frame.width, y: info.position.y)
        addChild(controllerSelect)
    }
    
    func setupPlayer() {
        // Setup the boy
        let theBoy = SKSpriteNode(imageNamed: "TheBoy/Run (1)")
        theBoy.name = "theBoy"
        theBoy.zPosition = 10.0
        theBoy.position = CGPoint(x: size.width/2.0 + size.width/4.0, y: size.height/2.0)
        addChild(theBoy)
        // Add animations
        var theBoyFrames = [SKTexture]()
        for i in 1...15 {
            let frameName = "TheBoy/Run (\(i))"
            theBoyFrames.append(SKTexture(imageNamed: frameName))
        }
        // Animation activated
        theBoy.run(SKAction.repeatForever(SKAction.animate(with: theBoyFrames, timePerFrame: timePerFrameTheBoyAnimations)), withKey: "theBoyAnimation")
        
        // Setup the girl
        let cuteGirl = SKSpriteNode(imageNamed: "CuteGirl/Run (1)")
        cuteGirl.name = "cuteGirl"
        cuteGirl.zPosition = 10.0
        cuteGirl.xScale = CGFloat(-1)
        cuteGirl.position = CGPoint(x: size.width/4.0, y: size.height/2.0)
        addChild(cuteGirl)
        // Add animations
        var cuteGirlFrames = [SKTexture]()
        for i in 1...20 {
            let frameName = "CuteGirl/Run (\(i))"
            cuteGirlFrames.append(SKTexture(imageNamed: frameName))
        }
        // Animation activated
        cuteGirl.run(SKAction.repeatForever(SKAction.animate(with: cuteGirlFrames, timePerFrame: timePerFrameCuteGirlAnimations)), withKey: "cuteGirlAnimation")
    }
    
    func updatePlayerSelection() {
        let playerSelected = UserDefaults.standard.object(forKey: playerSelectedKey) as? String
        let zoomIn = SKAction.scale(by: 1.3, duration: 1) // animation select
   
        switch playerSelected! {
        case "TheBoy":
            let spriteNotSelected = self.childNode(withName: "cuteGirl") as! SKSpriteNode
            let spriteSelected = self.childNode(withName: "theBoy") as! SKSpriteNode
            // Resume and stop animation
            spriteNotSelected.action(forKey: "cuteGirlAnimation")?.speed = 0
            spriteSelected.action(forKey: "theBoyAnimation")?.speed = 1
            // Create selection animation
            spriteSelected.run(zoomIn)
            if !firstOpen {
                spriteNotSelected.run(zoomIn.reversed())
            }
            // Add selection label
            selectionLbl.position = CGPoint(x: spriteSelected.position.x,
                                            y: size.height/2.0 - selectionLbl.frame.height - 300.0)
            
        case "CuteGirl":
            let spriteNotSelected = self.childNode(withName: "theBoy") as! SKSpriteNode
            let spriteSelected = self.childNode(withName: "cuteGirl") as! SKSpriteNode
            // Resume and stop animation
            spriteNotSelected.action(forKey: "theBoyAnimation")?.speed = 0
            spriteSelected.action(forKey: "cuteGirlAnimation")?.speed = 1
            // Create selection animation
            spriteSelected.run(zoomIn)
            if !firstOpen {
                spriteNotSelected.run(zoomIn.reversed())
            }
            // Add selection label
            selectionLbl.position = CGPoint(x: spriteSelected.position.x,
                                            y: size.height/2.0 - selectionLbl.frame.height - 300.0)
            
        default:
            return
        }
        
        firstOpen = false // not useful anymore
    }
    
    func setupSelectionLabel() {
        selectionLbl.text = "Player Selected"
        selectionLbl.horizontalAlignmentMode = .center
        selectionLbl.fontSize = 60.0
        selectionLbl.zPosition = 25.0
        selectionLbl.fontColor = .yellow
        addChild(selectionLbl)
    }
    
    //MARK: - Input Controller Panel
    func setupInputController() {
        if UserDefaults.standard.object(forKey: "cameraMode") == nil { // first time setting
            UserDefaults.standard.setValue(false, forKey: "cameraMode")
        }
        if UserDefaults.standard.object(forKey: "watchMode") == nil { // first time setting
            UserDefaults.standard.setValue(false, forKey: "watchMode")
        }
    }
    
    func setupControllerChoicePanel(){
        // Create a Container
        setupContainer()
        
        // Create a panel inside the container
        let panel = SKSpriteNode(imageNamed: "bigPanel")
        panel.name = "controllerRoot"
        panel.setScale(1.3)
        panel.zPosition = 20.0
        panel.position = .zero
        containerNode.addChild(panel)
        
        let cameraImage = SKSpriteNode(imageNamed: "camera")
        cameraImage.name = "cameraImage"
        cameraImage.setScale(0.8)
        cameraImage.zPosition = 21.0
        cameraImage.position = CGPoint(x: panel.size.width/5, y: panel.position.y)
        panel.addChild(cameraImage)
        
        let watchImage = SKSpriteNode(imageNamed: "watch")
        watchImage.name = "watchImage"
        watchImage.setScale(0.7)
        watchImage.zPosition = 21.0
        watchImage.position = CGPoint(x: -(panel.size.width/5), y: panel.position.y)
        panel.addChild(watchImage)
        
        
        let controllerLblcamera = SKLabelNode(fontNamed: "AmericanTypewriter-Bold")
        controllerLblcamera.name = "textControllerCamera"
        controllerLblcamera.fontColor = .black
        controllerLblcamera.fontSize = 35.0
        controllerLblcamera.zPosition = 25.0
        controllerLblcamera.preferredMaxLayoutWidth = cameraImage.frame.width
        controllerLblcamera.numberOfLines = 0
        controllerLblcamera.verticalAlignmentMode = .center
        controllerLblcamera.horizontalAlignmentMode = .center
        controllerLblcamera.lineBreakMode = .byWordWrapping
        controllerLblcamera.position = CGPoint(x: cameraImage.position.x, y: cameraImage.size.height/1.5 + cameraImage.position.y)
        
        let controllerLblWatch = SKLabelNode(fontNamed: "AmericanTypewriter-Bold")
        controllerLblWatch.name = "textControllerWatch"
        controllerLblWatch.fontColor = .black
        controllerLblWatch.fontSize = 35.0
        controllerLblWatch.zPosition = 25.0
        controllerLblWatch.preferredMaxLayoutWidth = watchImage.frame.width
        controllerLblWatch.numberOfLines = 0
        controllerLblWatch.verticalAlignmentMode = .center
        controllerLblWatch.horizontalAlignmentMode = .center
        controllerLblWatch.lineBreakMode = .byWordWrapping
        controllerLblWatch.position = CGPoint(x: watchImage.position.x, y: watchImage.size.height/1.5 + watchImage.position.y)

        //add text according to ios version
        if #available(iOS 14.0, *) {
            // Add text
            controllerLblcamera.text = "Camera Tracking"
        } else {
            controllerLblcamera.text = "Vision NON disponibile"
        }
        controllerLblWatch.text = "Apple Watch"
        
        panel.addChild(controllerLblcamera)
        panel.addChild(controllerLblWatch)
        
        updateControllerChoicePanel()
        
    }

    func updateControllerChoicePanel(){
        let panel = containerNode.childNode(withName: "controllerRoot")as! SKSpriteNode
        let bgCamera = panel.childNode(withName: "cameraImage") as? SKSpriteNode
        let bgWatch = panel.childNode(withName: "watchImage") as? SKSpriteNode
        let labelCamera = panel.childNode(withName: "textControllerCamera") as? SKLabelNode
        let labelWatch = panel.childNode(withName: "textControllerWatch") as? SKLabelNode
        
        let blendFactor = CGFloat(0.4)
        
        let cameraMode = UserDefaults.standard.bool(forKey: "cameraMode")
        let watchMode = UserDefaults.standard.bool(forKey: "watchMode")
        
        
        if(cameraMode){
            bgWatch?.colorBlendFactor = blendFactor
            bgCamera?.colorBlendFactor = 0
            labelCamera?.text = "Camera selected"
            labelWatch?.text = "Apple Watch"
        }
        else if (watchMode){
            bgCamera?.colorBlendFactor = blendFactor
            bgWatch?.colorBlendFactor = 0
            labelWatch?.text = "Watch selected"
            labelCamera?.text = "Camera Tracking"
        }
        else if(!cameraMode && !watchMode){
            bgWatch?.colorBlendFactor = 0
            labelWatch?.text = "Apple Watch"
            if #available(iOS 14.0, *) {
                labelCamera?.text = "Camera Tracking"
                bgCamera?.colorBlendFactor = 0
            }
            
        }
    }
    
    //MARK: - Highscore Panel
    func setupHighscorePanel() {
        // Create a Container
        setupContainer()
        
        // Create a panel inside the container
        let panel = SKSpriteNode(imageNamed: fbUserLogged ? "bigPanel" : "panel")
        panel.name = "HighscorePanel"
        panel.setScale(fbUserLogged ? 1.2 : 1.5)
        panel.zPosition = 20.0
        panel.position = .zero
        containerNode.addChild(panel)
    
        if(fbUserLogged) { // Show Top Run
            // Heading
            let headingLbl = SKLabelNode(fontNamed: "AmericanTypewriter-Bold")
            headingLbl.name = "TopRun"
            headingLbl.text = "Top Run"
            headingLbl.fontSize = 60.0
            headingLbl.zPosition = 25.0
            headingLbl.fontColor = .black
            headingLbl.position = CGPoint(x: 0, y: panel.frame.height/3 - 35)
            panel.addChild(headingLbl)
            
            // Get All Users
            Spark.fetchAllSparkUsers { (message, err, sparkUsers) in
                if let err = err {
                    print("Error: \(message) \(err.localizedDescription)")
                    return
                }
                guard let sparkUsers = sparkUsers else {
                    print("Failed to fetch user")
                    return
                }
                for (index, element) in sparkUsers {
                    print(element.data())
                    self.insertIntoTopRun(index: index+1, panel: panel, sparkUser: element.data() as NSDictionary)
                }
            }
        } else { // Show only your scores
            // Show Highscore
            let x = -panel.frame.width/2.0 + 300.0
            let highscoreLbl = SKLabelNode(fontNamed: "AmericanTypewriter-Bold")
            highscoreLbl.text = "Highscore: \(ScoreGenerator.sharedInstance.getHighscore())"
            highscoreLbl.horizontalAlignmentMode = .left
            highscoreLbl.fontSize = 80.0
            highscoreLbl.zPosition = 25.0
            highscoreLbl.fontColor = .black
            highscoreLbl.position = CGPoint(x: x, y: highscoreLbl.frame.height/2.0 - 20.0)
            panel.addChild(highscoreLbl)
            
            // Show Last Score
            let scoreLbl = SKLabelNode(fontNamed: "AmericanTypewriter-Bold")
            scoreLbl.text = "Last Score: \(ScoreGenerator.sharedInstance.getScore())"
            scoreLbl.horizontalAlignmentMode = .left
            scoreLbl.fontSize = 80.0
            scoreLbl.zPosition = 25.0
            scoreLbl.fontColor = .black
            scoreLbl.position = CGPoint(x: x, y: -scoreLbl.frame.height - 20.0)
            panel.addChild(scoreLbl)
        }
    }
    
    func insertIntoTopRun(index i: Int, panel: SKSpriteNode, sparkUser: NSDictionary) {
        // Check if is currentUser
        let isCurrentUser:Bool = (sparkUser.value(forKey: "uid") as? String) == currentUser.uid
        let userColor = UIColor(red: 0.25, green: 0.17, blue: 0.08, alpha: 1.00)
        let notUserColor = UIColor(red: 0.84, green: 0.68, blue: 0.31, alpha: 1.00)
        let rowColor = (isCurrentUser ? userColor : notUserColor)
        let rowFontColor = (isCurrentUser ? UIColor.white : UIColor.black)
        // Add new row
        let row = SKSpriteNode(color: rowColor, size: CGSize(width: panel.frame.width-450, height: 110.0))
        row.name = "row\(String(describing: index))"
        row.zPosition = 22.0
        row.position = CGPoint(x: 0.0,
                               y: panel.frame.height/4.6 - (row.frame.height * CGFloat(i-1)) - (10.0 * CGFloat(i)))
        panel.addChild(row)
        row.drawBorder(color: .black, width: 2)
        if(i > 4) {
            row.isHidden = true
        }
        // Add Position
        let rank = SKLabelNode(fontNamed: "AmericanTypewriter-Bold")
        rank.text = String(i)
        rank.fontSize = 40.0
        rank.zPosition = 25.0
        rank.fontColor = rowFontColor
        row.addChild(rank)
        rank.position = CGPoint(x: -row.frame.width/2.0 + 40,
                                y: -15.0)
        // Add Image
        // Find user by uid
        Spark.fetchSparkUser(((sparkUser.value(forKey: "uid") as? String)!)) { (message, err, user) in
            if let err = err {
                print("Error: \(message) \(err.localizedDescription)")
                return
            }
            guard let user = user else {
                print("Failed to fetch user")
                return
            }
            // Fetch profile image 
            Spark.fetchProfileImage(sparkUser: user) { (message, err, image) in
                if let err = err {
                    print("Error: \(message) \(err.localizedDescription)")
                    return
                }
                guard let image = image else {
                    print("Failed to fetch image")
                    return
                }
                let texture = SKTexture(image: image)
                let userImage = SKSpriteNode(texture: texture)
                userImage.zPosition = 25.0
                userImage.scale(to: CGSize(width: 100.0, height: 100.0))
                userImage.position = CGPoint(x: -row.frame.width/2.0 + 120,
                                        y: 0.0)
                row.addChild(userImage)
            }
        }
        // Add Name (only)
        let userName = SKLabelNode(fontNamed: "AmericanTypewriter-Bold")
        userName.text = (sparkUser.value(forKey: "name") as? String)?.components(separatedBy: " ").first
        if isCurrentUser {
            userName.text?.append(" (Me)")
        }
        userName.fontSize = 40.0
        userName.zPosition = 25.0
        userName.fontColor = rowFontColor
        userName.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        userName.position = CGPoint(x: -row.frame.width/2.0 + 120 + 60,
                                    y: rank.position.y)
        row.addChild(userName)
    }
    
    //MARK: - Setting Panel
    func setupContainer() {
        containerNode = SKSpriteNode()
        containerNode.name = "container"
        containerNode.zPosition = 15.0
        containerNode.color = .clear // UIColor (white: 0.5, alpha 0.5)
        containerNode.size = size
        containerNode.position = CGPoint(x: size.width/2.0, y: size.height/2.0)
        addChild(containerNode)
    }
    
    func setupSettingPanel() {
        // Create a Container
        setupContainer()
        
        // Create a panel inside the container
        let panel = SKSpriteNode(imageNamed: "panel")
        panel.name = "SettingPanel"
        panel.setScale(1.5)
        panel.zPosition = 20.0
        panel.position = .zero
        containerNode.addChild(panel)
        
        // Music
        let music = SKSpriteNode(imageNamed: SKTAudio.musicEnabled ? "musicOn" : "musicOff")
        music.name = "music"
        music.setScale(0.875)
        music.zPosition = 25.0
        music.position = CGPoint(x: -music.frame.width - 50.0, y: 5.0)
        panel.addChild(music)
        
        // Sound
        let effect = SKSpriteNode(imageNamed: effectEnabled ? "effectOn" : "effectOff")
        effect.name = "effect"
        effect.setScale(0.875)
        effect.zPosition = 25.0
        effect.position = CGPoint(x: music.frame.width + 50.0, y: 5.0)
        panel.addChild(effect)
        
        // Facebook
        let facebookBtn = SKSpriteNode(imageNamed: fbUserLogged ? "facebookOn" : "facebookOff")
        facebookBtn.name = "facebookBtn"
        facebookBtn.setScale(0.875)
        facebookBtn.zPosition = 25.0
        facebookBtn.position = CGPoint(x: 0.0, y: 5.0)
        panel.addChild(facebookBtn)
        
        // Log In with Facebook Label
        facebookLoginLbl.text = fbUserLogged ? afterLoginTxt + (Auth.auth().currentUser?.displayName ?? "DISPLAY NAME NOT FOUND") : beforeLoginTxt
        facebookLoginLbl.horizontalAlignmentMode = .center
        facebookLoginLbl.fontSize = 30.0
        facebookLoginLbl.fontColor = .black
        facebookLoginLbl.zPosition = 25.0
        facebookLoginLbl.position = CGPoint(x: 0.0, y: -(facebookBtn.size.height/2.0 + 25.0))
        panel.addChild(facebookLoginLbl)
    }
    
    //MARK: - Facebook
    func handleSignInWithFacebookButtonTapped() {
        // Present the signing-in process message
        hud.textLabel.text = "Login"
        hud.detailTextLabel.text = duringLoginTxt
        hud.show(in: view!)
        // Sign-in with facebook
        Spark.signInWithFacebook(in: viewController) { (message, err, sparkUser) in
            if let err = err {
                SparkService.dismissHud(self.hud, text: "Error", detailText: "\(message) \(err.localizedDescription)", delay: 3)
                return
            }
            guard let sparkUser = sparkUser else {
                SparkService.dismissHud(self.hud, text: "Cancelled", detailText: "The operation was cancelled by the user", delay: 3)
                return
            }
            // We have the Spark user
            self.currentUser = sparkUser
            print("Successfully signed in with Facebook with Spark User: \(self.currentUser!)")
            SparkService.dismissHud(self.hud, text: "Success", detailText: "Successfully signed in with Facebook", delay: 3)
            // Update login status
            self.fbUserLogged = true
        }
    }
    
    func handleSignOutWithFacebookButtonTapped() {
        // Present the signing-out process message
        hud.textLabel.text = "Logout"
        hud.detailTextLabel.text = signingOutTxt
        hud.show(in: view!)
        Spark.logout { (result, err) in
            if let err = err {
                SparkService.dismissHud(self.hud, text: "Sign Out Error", detailText: "Failed to sign out with error: \(err.localizedDescription)", delay: 3)
                return
            }
            if result { // User Signed Out
                self.fbUserLogged = false
                SparkService.dismissHud(self.hud, text: "Success", detailText: "Successfully signed out", delay: 3)
            } else {
                SparkService.dismissHud(self.hud, text: "Sign Out Error",
                                        detailText: "Failed to sign out", delay: 1)
            }
        }
    }
    
//    MARK: Shop Panel
//    generate the container of the shop
    func setupShopPanel(){

        // Create a Container
        setupContainer()

        // Create a panel inside the container
        let panel = SKSpriteNode(imageNamed: "bigPanel")
        panel.name = "ShopPanel"
        panel.setScale(1)
        panel.zPosition = 20.0
        panel.position = .zero
        containerNode.addChild(panel)


        // add a right arrow to the panel
        let rightArrow = SKSpriteNode(imageNamed: "rightArrow")
        rightArrow.name = "ShopArrowRight"
        rightArrow.setScale(0.5)
        rightArrow.zPosition = 20.0
        rightArrow.position = CGPoint(x: panel.position.x + panel.size.width/2 - 60, y: panel.position.y/2)

        panel.addChild(rightArrow)

        // add left arrow
        let leftArrow = SKSpriteNode(imageNamed: "leftArrow")
        leftArrow.name = "ShopArrowLeft"
        leftArrow.setScale(0) // invisible arrow (no dimension)
        leftArrow.zPosition = 20.0
        leftArrow.position = CGPoint(x: -(panel.position.x + panel.size.width/2 - 60), y: panel.position.y/2)
        panel.addChild(leftArrow)
        
        //execute the first update call
        updateShop()
    }
//  loads the current page of the shop
//  ad unloads the previous page to
//  obtain a smooth transition and save memory
    func updateShop(){
        loadShopPage(pageNum: currShopPageNum)
        if(currShopPageNum != prevShopPageNum){
            unloadShopPage(pageNum: prevShopPageNum)
        }
        
        updateShopArrows()
        
    }
//    updates the shop page, loading sprites,
//    number of character's lives and the selection/buy button
    func loadShopPage(pageNum: Int){
        
        guard let panel = containerNode.childNode(withName: "ShopPanel") as? SKSpriteNode
        else{
            print("nope load")
            return
        }
        
        switch pageNum {
//        pagina dedicata a boy
        case 1:
            let theBoy = SKSpriteNode(imageNamed: "TheBoy/Idle (1)")
            theBoy.name = "theBoy"
            theBoy.zPosition = 10.0
            theBoy.position = CGPoint(x: -3*theBoy.frame.width/4, y:panel.position.y/2)
            panel.addChild(theBoy)
            // Add animations
            var theBoyFrames = [SKTexture]()
            for i in 2...15 {
                let frameName = "TheBoy/Idle (\(i))"
                theBoyFrames.append(SKTexture(imageNamed: frameName))
            }
            // Animation activated
            theBoy.run(SKAction.repeatForever(SKAction.animate(with: theBoyFrames, timePerFrame: timePerFrameTheBoyAnimations)), withKey: "theBoyAnimation")
            
            loadNameCharacter(Labelname: "boyname", CharacterName: "Mike")
            loadHeartsCharacter(amount: 3)
            
//        pagina dedicata a girl
        case 2:
            // Setup the girl
            let cuteGirl = SKSpriteNode(imageNamed: "CuteGirl/Idle (1)")
            cuteGirl.name = "cuteGirl"
            cuteGirl.zPosition = 10.0
            cuteGirl.position = CGPoint(x: -3*cuteGirl.frame.width/4, y:panel.position.y/2)
            panel.addChild(cuteGirl)
            // Add animations
            var cuteGirlFrames = [SKTexture]()
            for i in 2...16 {
                let frameName = "CuteGirl/Idle (\(i))"
                cuteGirlFrames.append(SKTexture(imageNamed: frameName))
            }
            // Animation activated
            cuteGirl.run(SKAction.repeatForever(SKAction.animate(with: cuteGirlFrames, timePerFrame: timePerFrameCuteGirlAnimations)), withKey: "cuteGirlAnimation")
            
            loadNameCharacter(Labelname: "girlname", CharacterName: "Peach")
            loadHeartsCharacter(amount: 3)
            
//        pagina dedicata a dino
        case 4:
            let dino = SKSpriteNode(imageNamed: "Dino/Idle (1)")
            dino.name = "Dino"
            dino.zPosition = 10.0
            dino.position = CGPoint(x: -dino.frame.width/2, y:panel.position.y/2)
            panel.addChild(dino)
            // Add animations
            var dinoFrames = [SKTexture]()
            for i in 2...10 {
                let frameName = "Dino/Idle (\(i))"
                dinoFrames.append(SKTexture(imageNamed: frameName))
            }
            // Animation activated
            dino.run(SKAction.repeatForever(SKAction.animate(with: dinoFrames, timePerFrame: timePerFrameDino)), withKey: "DinoAnimation")
            
            loadNameCharacter(Labelname: "dinoname", CharacterName: "Dino")
            loadHeartsCharacter(amount: 5)
            
//        pagina dedicata a indiana
        case 3:
            let indiana = SKSpriteNode(imageNamed: "indianaFemmina/Idle (1)")
            indiana.name = "Indiana"
            indiana.zPosition = 10.0
            indiana.position = CGPoint(x: -3*indiana.frame.width/4, y:panel.position.y/2)
            panel.addChild(indiana)
            // Add animations
            var indianaFrames = [SKTexture]()
            for i in 2...10 {
                let frameName = "indianaFemmina/Idle (\(i))"
                indianaFrames.append(SKTexture(imageNamed: frameName))
            }
            // Animation activated
            indiana.run(SKAction.repeatForever(SKAction.animate(with: indianaFrames, timePerFrame: timePerFrameIndiana)), withKey: "IndianaAnimation")
            
            loadNameCharacter(Labelname: "indianame", CharacterName: "Ellie")
            loadHeartsCharacter(amount: 4)
            
        default:
            return
        }
    }
    
//  deallocates all the elements in the page
//  with pageNum number
    func unloadShopPage(pageNum: Int){
        
        guard let panel = containerNode.childNode(withName: "ShopPanel") as? SKSpriteNode
        else{
            
            print("nope unload")
            return
        }
        switch pageNum {
        case 1:
            let boy = panel.childNode(withName: "theBoy") as? SKSpriteNode
            boy?.removeFromParent()
            unloadNameCharacter(Labelname: "boyname")
            unloadHeartsCharacter(amount: 3)
        case 2:
            let girl = panel.childNode(withName: "cuteGirl") as? SKSpriteNode
            girl?.removeFromParent()
            unloadNameCharacter(Labelname: "girlname")
            unloadHeartsCharacter(amount: 3)
        case 4:
            let dino = panel.childNode(withName: "Dino") as? SKSpriteNode
            dino?.removeFromParent()
            unloadNameCharacter(Labelname: "dinoname")
            unloadHeartsCharacter(amount: 5)
        case 3:
            let indiana = panel.childNode(withName: "Indiana") as? SKSpriteNode
            indiana?.removeFromParent()
            unloadNameCharacter(Labelname: "indianame")
            unloadHeartsCharacter(amount: 4)
        default:
            return
        }
    }
//    a name to che corresponding character is generated and added
//    to the shop panel
    func loadNameCharacter(Labelname: String,CharacterName: String){
        guard let panel = containerNode.childNode(withName: "ShopPanel") as? SKSpriteNode
        else{
            print("nope load nome")
            return
        }
        let name = SKLabelNode(fontNamed: "AmericanTypewriter-Bold")
        name.name = Labelname
        name.text = CharacterName
        name.fontSize = 80
        name.zPosition = 20
        name.fontColor = .black
        name.position = CGPoint(x: panel.frame.width/5,y: panel.frame.height/4)
        panel.addChild(name)
    }
//  removes the name from the scene
    func unloadNameCharacter(Labelname: String){
        guard let panel = containerNode.childNode(withName: "ShopPanel") as? SKSpriteNode
        else{
            print("nope load nome")
            return
        }
        let label = panel.childNode(withName: Labelname)
        label?.removeFromParent()
    }
    
//  add the number of lives to associated characters in the shop
    func loadHeartsCharacter(amount: Int){
        var livesSprites = [SKSpriteNode]()
        //add livesNumber hearts to the player
        for i in 0..<amount{
            livesSprites.append(SKSpriteNode(imageNamed: "life-on"))
            setupLifePos(livesSprites[i], i: CGFloat(i+1), j: CGFloat(i*8))
        }
    }
//  to position the lives in the panel
    func setupLifePos(_ node: SKSpriteNode, i: CGFloat, j: CGFloat) {
        guard let panel = containerNode.childNode(withName: "ShopPanel") as? SKSpriteNode
        else{
            print("nope setup hearts")
            return
        }
        
        node.setScale(0.5)
        node.zPosition = 50.0
        
        var x = node.frame.width * i + j
        var y = panel.frame.height/4 - node.size.height
        if(i > 3){
            x = node.frame.width * (i-3) + 2*j
            y = panel.frame.height/4  - 2*node.size.height
        }
        
        node.position = CGPoint(x: x, y: y)
        node.name = "life \(Int(i-1))"
        panel.addChild(node)
    }
//  to remove the hearts from the corresponding shop page
    func unloadHeartsCharacter(amount: Int){
        
        guard let panel = containerNode.childNode(withName: "ShopPanel") as? SKSpriteNode
        else{
            print("nope unload hearts")
            return
        }
        
        for i in 0..<amount{
            let node = panel.childNode(withName: "life \(i)")
            node?.removeFromParent()
        }
    }
    
    
//  to show the shop arrows according to the page
//  in the first page only the right arrow is shown, can go only forward
//  in intermediate pages both right and left arrow are shown
//  in the last page only the left arrow is shown, can go only backwards
    func updateShopArrows(){
        guard let panel = containerNode.childNode(withName: "ShopPanel") as? SKSpriteNode
        else{
            print("nope update arrows")
            return
        }
        
        guard let leftArrow = panel.childNode(withName: "ShopArrowLeft") else {
            print("nope freccia sinistra")
            return
        }
        guard let rightArrow = panel.childNode(withName: "ShopArrowRight") else {
            print("nope freccia destra")
            return
        }
        
        if(currShopPageNum == 1){
            leftArrow.setScale(0)
            rightArrow.setScale(0.5)
        }
        else if(currShopPageNum == shopCharacters){
            leftArrow.setScale(0.5)
            rightArrow.setScale(0)
        }else{
            leftArrow.setScale(0.5)
            rightArrow.setScale(0.5)
        }
    }
    
    
    
    //MARK: - Info Panel
    func setupInfoPanel() {
        // Create a Container
        setupContainer()
        
        // Create a panel inside the container
        let panel = SKSpriteNode(imageNamed: "bigPanel")
        panel.name = "bigInfoPanel"
        panel.setScale(1)
        panel.zPosition = 20.0
        panel.position = .zero
        containerNode.addChild(panel)
        
        // add a right arrow to the panel
        let rightArrow = SKSpriteNode(imageNamed: "rightArrow")
        rightArrow.name = "infoArrowRight"
        rightArrow.setScale(0.5)
        rightArrow.zPosition = 20.0
        rightArrow.position = CGPoint(x: panel.position.x + panel.size.width/2 - 60, y: panel.position.y/2)
        
        panel.addChild(rightArrow)
        
        // add left arrow
        let leftArrow = SKSpriteNode(imageNamed: "leftArrow")
        leftArrow.name = "infoArrowLeft"
        leftArrow.setScale(0) // invisible arrow (no dimension)
        leftArrow.zPosition = 20.0
        leftArrow.position = CGPoint(x: -(panel.position.x + panel.size.width/2 - 60), y: panel.position.y/2)
        panel.addChild(leftArrow)
        
        // add info images to panel
        let info1 = SKSpriteNode(imageNamed: "infoImg1")
        info1.name = "info1"
        info1.zPosition = 30.0
        info1.position = CGPoint(x:panel.position.x - panel.size.width/4 + 20,y:panel.position.y + panel.size.height/4 - 40)
        info1.setScale(0) //invisible
        let info2 = SKSpriteNode(imageNamed: "infoImg2")
        info2.name = "info2"
        info2.position = CGPoint(x:panel.position.x + panel.size.width/4 - 20,y:panel.position.y + panel.size.height/4 - 40)
        info2.zPosition = 30.0
        info2.setScale(0) //invisible
        panel.addChild(info1)
        panel.addChild(info2)
        
        // Add text
        let infoLbl = SKLabelNode(fontNamed: "AmericanTypewriter-Bold")
        infoLbl.name = "textInfo"
        infoLbl.text = "On your path, you have to use your skills to collect diamonds and jump over different kinds of obstacles."
        infoLbl.fontColor = .black
        infoLbl.fontSize = 65.0
        infoLbl.zPosition = 25.0
        infoLbl.preferredMaxLayoutWidth = panel.frame.width - 200
        infoLbl.numberOfLines = 0
        infoLbl.verticalAlignmentMode = .center
        infoLbl.horizontalAlignmentMode = .center
        infoLbl.lineBreakMode = .byWordWrapping
        panel.addChild(infoLbl)
    }
    
    func updateInfo(){
        let panel = containerNode.childNode(withName: "bigInfoPanel")as! SKSpriteNode
        let infoLbl = panel.childNode(withName: "textInfo") as? SKLabelNode
        let info1 = panel.childNode(withName: "info1") as! SKSpriteNode
        let info2 = panel.childNode(withName: "info2") as! SKSpriteNode
        
        if currInfoPageNum == 1{
            panel.childNode(withName: "infoArrowLeft")?.setScale(0) //set the left arrow invisible
            infoLbl?.verticalAlignmentMode = .center
            infoLbl?.fontSize = 65.0
            infoLbl?.text = "On your path, you have to use your skills to collect diamonds and jump over different kinds of obstacles."
            info1.setScale(0)
            info2.setScale(0)
        } else if currInfoPageNum > 1 && currInfoPageNum < pageInfoNum {
            panel.childNode(withName: "infoArrowLeft")?.setScale(0.5) //set the left arrow visible
            panel.childNode(withName: "infoArrowRight")?.setScale(0.5) //set the right arrow visible
                if currInfoPageNum == 2{
                    infoLbl?.verticalAlignmentMode = .top
                    infoLbl?.fontSize = 50.0
                    infoLbl?.text = "The sharp ones will steal a life from you, while the smooth rocks and trees will cause you to lose a diamond.\n"
                    info1.setScale(0.5)
                    info2.setScale(0.5)
                }
        } else if currInfoPageNum == pageInfoNum {
            info1.setScale(0)
            info2.setScale(0)
            infoLbl?.verticalAlignmentMode = .center
            infoLbl?.fontSize = 65.0
            panel.childNode(withName: "infoArrowRight")?.setScale(0) //set the right arrow invisible
            infoLbl?.text = "Don't forget to check out our watch app for a better experience."
        }
    }
}
