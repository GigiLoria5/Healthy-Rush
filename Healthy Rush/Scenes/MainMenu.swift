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
    let logoScale: CGFloat = 0.2189             // (width, height) * scale = (w * scale, h * scale)
    let buttonScale: CGFloat = 0.79545
    let longButtonScale: CGFloat = 1.18
    let buttonZPos: CGFloat = 20.0              // nodes with larger z-position values are closer to the viewer
    var timePerFrameTheBoyAnimations: TimeInterval = 0.095 // Animations speed
    var timePerFrameCuteGirlAnimations: TimeInterval = 0.065 // Animations speed
    var timePerFrameDino : TimeInterval = 0.095
    var timePerFrameIndiana : TimeInterval = 0.075
    var arrowsScale = CGFloat(0.7) // for the left and right arrow of info and shop panel
    
    // For the info panel
    var currInfoPageNum : Int = 1
    var pageInfoNum : Int = 4
    
    // For the shop panel
    var currShopPageNum : Int = 1
    var prevShopPageNum : Int = 1
    var shopCharacters : Int = 4
    
    // # Diamonds label
    let numDiamondsLbl = SKLabelNode(fontNamed: "AmericanTypewriter-Bold") // number of diamonds label
    
    // For the top run panel
    var currTopRunPageNum : Int!
    var maxTopRunPageNum : Int!
    var maxTopRunElements : Int!
    let progressBar = CircularProgressBar()
    let panelHider = SKSpriteNode(imageNamed: "bigPanel") // to hide the other elements
    var startProgressBar : Bool = false
    var lastTime: TimeInterval = 0
    var progressSpeed = 25.0 // the completion speed of the progress bar
    
    // Gesture Captures
    var gestureCaptureIstance = GesturesCapture()
    
    // User Data (got by Firebase&FB)
    var currentUser: SparkUser!             // uid, email, name, profileImageUrl
    var currentUserStats: SparkUserStats!   // uid, diamonds, dinoUnlocked, ellieUnlocked, record
    
    // Facebook utilis
    var fbUserLogged : Bool!
    let facebookLoginLbl = SKLabelNode(fontNamed: "AmericanTypewriter-Bold") // login fb label
    let beforeLoginTxt = "To save your progress, login with Facebook"        // initial text
    let duringLoginTxt = "Signing in with Facebook..."                       // during signing text
    let afterLoginTxt  = "You are login as "                                 // after signed text
    let signingOutTxt = "You're about to be signed out..."                   // during signing out text
    let hud: JGProgressHUD = {                                               // Pop up loading type
        let hud = JGProgressHUD(style: .light)
        hud.interactionType = .blockTouchesOnHUDView
        return hud
    } ()
    
    //MARK: - Systems
    override func didMove(to view: SKView) {
        // Get current user data and stats
        if(fbUserLogged) {
            Spark.fetchCurrentSparkUser(completion: { message, err, sparkUser in
                self.currentUser = sparkUser
            })
            Spark.fetchCurrentSparkUserStats { message, err, sparkUserStats in
                self.currentUserStats = sparkUserStats
            }
        }
        // Setup Menu
        setupBG()       // Setup Background Image and Logo
        setupNodes()    // Setup Buttons and other panel
        
        SKTAudio.sharedInstance().playBGMusic("backgroundMusic.mp3") // play bg music
        // First time setting here
        // Tutorial
        if (UserDefaults.standard.object(forKey: "tutorialFirstTime") == nil) {
            cleanContainerNode() // Remove any other panel already active
            currInfoPageNum = 1  // Reset the page number
            setupInfoPanel()
            UserDefaults.standard.setValue(false, forKey: "tutorialFirstTime")
        }
    }
    
    //MARK: - Touches
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        // saves the initial touch point and the instant when it was pressed
        gestureCaptureIstance.startCapturing(touches, scene: self)
        
        guard let touch = touches.first else { return }
        let node = atPoint(touch.location(in: self))
        
        switch node.name {
        case "play": // Play button
            run(SKAction.playSoundFileNamed("buttonSound.wav"))
            let scene = GameScene(size: size)
            scene.scaleMode = scaleMode
            scene.fbUserLogged = self.fbUserLogged
            scene.currentUser = self.currentUser
            scene.currentUserStats = self.currentUserStats
            scene.viewController = self.viewController
            view!.presentScene(scene, transition: .doorsOpenVertical(withDuration: 0.3))
        case "highscore": // Highscore button
            run(SKAction.playSoundFileNamed("buttonSound.wav"))
            cleanContainerNode() // Remove any other panel already active
            setupHighscorePanel()
        case "setting": // Settings Button
            run(SKAction.playSoundFileNamed("buttonSound.wav"))
            cleanContainerNode() // Remove any other panel already active
            setupSettingPanel()
        case "music": // Music button inside Settings
            run(SKAction.playSoundFileNamed("buttonSound.wav"))
            let node = node as! SKSpriteNode
            SKTAudio.musicEnabled = !SKTAudio.musicEnabled
            node.texture = SKTexture(imageNamed: SKTAudio.musicEnabled ? "musicOn" : "musicOff")
            SKTAudio.sharedInstance().playBGMusic("backgroundMusic.mp3")
        case "effect": // Effect button inside Settings
            run(SKAction.playSoundFileNamed("buttonSound.wav"))
            let node = node as! SKSpriteNode
            effectEnabled = !effectEnabled
            node.texture = SKTexture(imageNamed: effectEnabled ? "effectOn" : "effectOff")
        case "facebookBtn": // Facebook login button inside Settings
            run(SKAction.playSoundFileNamed("buttonSound.wav"))
            fbUserLogged ? handleSignOutWithFacebookButtonTapped() : handleSignInWithFacebookButtonTapped()
            let node = node as! SKSpriteNode
            node.texture = SKTexture(imageNamed: fbUserLogged ? "facebookOn" : "facebookOff")
            facebookLoginLbl.text = fbUserLogged ? afterLoginTxt + (Auth.auth().currentUser?.displayName ?? "DISPLAY NAME NOT FOUND") : beforeLoginTxt
        case "controllerSelect": // Controller Selection button
            run(SKAction.playSoundFileNamed("buttonSound.wav"))
            cleanContainerNode() // Remove any other panel already active
            setupControllerChoicePanel()
        case "cameraImage": // Camera selection inside Controller Selection
            if #available(iOS 14.0, *) {
                run(SKAction.playSoundFileNamed("buttonSound.wav"))
                let cameraMode = ControllerSetting.sharedInstance.getCameraMode()
                ControllerSetting.sharedInstance.setCameraMode(!cameraMode) // update camera selection
                ControllerSetting.sharedInstance.setWatchMode(false) // watch deselected
                updateControllerChoicePanel()
            }
        case "watchImage": // Watch selection inside Controller Selection
            run(SKAction.playSoundFileNamed("buttonSound.wav"))
            let watchMode = ControllerSetting.sharedInstance.getWatchMode()
            ControllerSetting.sharedInstance.setWatchMode(!watchMode) // update watch selection
            ControllerSetting.sharedInstance.setCameraMode(false) // camera deselected
            updateControllerChoicePanel()
        case "shop": // Shop button
            run(SKAction.playSoundFileNamed("buttonSound.wav"))
            cleanContainerNode() // Remove any other panel already active
            setupShopPanel()
            setupDiamondsCounter()
        case "ShopArrowRight": // Right arrow inside shop
            if(currShopPageNum <= shopCharacters) {
                run(SKAction.playSoundFileNamed("buttonSound.wav"))
                prevShopPageNum = currShopPageNum
                currShopPageNum += 1
                updateShop()
            }
        case "ShopArrowLeft": // Left arrow inside shop
            if(currInfoPageNum >= 1) {
                run(SKAction.playSoundFileNamed("buttonSound.wav"))
                prevShopPageNum = currShopPageNum
                currShopPageNum -= 1
                updateShop()
            }
        case "Mike1", "Mike1L":  // for the character choice
            run(SKAction.playSoundFileNamed("playerSelect.mp3"))
            PlayerSetting.sharedInstance.setPlayerSelected(PlayerName.theBoy)
            updateCurrentShopPage(pageNum: currShopPageNum)
        case "Peach1","Peach1L":
            run(SKAction.playSoundFileNamed("playerSelect.mp3"))
            PlayerSetting.sharedInstance.setPlayerSelected(PlayerName.cuteGirl)
            updateCurrentShopPage(pageNum: currShopPageNum)
        case "Ellie1","Ellie1L":
            run(SKAction.playSoundFileNamed("playerSelect.mp3"))
            run(SKAction.playSoundFileNamed("indiana.wav"))
            PlayerSetting.sharedInstance.setPlayerSelected(PlayerName.ellie)
            updateCurrentShopPage(pageNum: currShopPageNum)
        case "Dino1","Dino1L":
            run(SKAction.playSoundFileNamed("playerSelect.mp3"))
            run(SKAction.playSoundFileNamed("trex.wav"))
            PlayerSetting.sharedInstance.setPlayerSelected(PlayerName.dino)
            updateCurrentShopPage(pageNum: currShopPageNum)
        case "Ellie3","Ellie3L": // buy a character
            buyCharacter(name: "Ellie")
        case "Dino3","Dino3L":
            buyCharacter(name: "Dino")
        case "info": // Info button
            run(SKAction.playSoundFileNamed("buttonSound.wav"))
            cleanContainerNode() // Remove any other panel already active
            currInfoPageNum = 1  // Reset the page number
            setupInfoPanel()
        case "infoArrowRight": // Right arrow inside info
            if(currInfoPageNum <= pageInfoNum) {
                run(SKAction.playSoundFileNamed("buttonSound.wav"))
                currInfoPageNum += 1
                updateInfo()
            }
        case "infoArrowLeft": // Left arrow inside info
            if(currInfoPageNum >= 1) {
                run(SKAction.playSoundFileNamed("buttonSound.wav"))
                currInfoPageNum -= 1
                updateInfo()
            }
        case "container": // General container
            run(SKAction.playSoundFileNamed("buttonSound.wav"))
            startProgressBar = false // to cancel the progress if necessary
            progressBar.parent?.removeAllChildren() // to kill the progress bar node
            progressBar.value = 100 // reset progress value
            containerNode.removeAllChildren()
            containerNode.removeFromParent()
        default:
            break
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        // Find and save the gesture
        gestureCaptureIstance.findGesture(touches, scene: self)
        
        // Catch the correct gesture inside the top run panel
        if let container = containerNode {
            container.enumerateChildNodes(withName: "HighscorePanel") { nodeHighscore, _ in
                nodeHighscore.enumerateChildNodes(withName: "TopRun") { node, _ in
                    let gesture = self.gestureCaptureIstance.getCurrentSwipe()
                    if(gesture == .up) {
                        print("Swipe up")
                        self.updateTopRun(nextPage: true)
                    } else if (gesture == .down) {
                        print("Swipe down")
                        self.updateTopRun(nextPage: false)
                    }
                }
            }
        }
    }
    
    func cleanContainerNode() { // Remove any other panel already active
        if(containerNode != nil) {
            containerNode.removeAllChildren()
            containerNode.removeFromParent()
        }
    }
    
    //MARK: - Update
    override func update(_ currentTime: TimeInterval) {
        // Progress Bar is live
        if (startProgressBar) {
            // Calculate the current delta time
            let deltaTime = currentTime - lastTime
            lastTime = currentTime
            
            // Applying an increasing value
            progressBar.value += (progressBar.value < 100 ? progressSpeed * deltaTime : -100)
            
            // Catch the progress bar completation
            if (progressBar.value >= 100) {
                startProgressBar = false // reset progress value start
                if let container = containerNode {
                    container.enumerateChildNodes(withName: "HighscorePanelHider") { nodeHider, _ in
                        nodeHider.removeAllChildren()
                        nodeHider.removeFromParent()
                        self.run(SKAction.playSoundFileNamed("buttonSound.wav"))
                    }
                }
            }
        }
    }
    
}

//MARK: - Configurations
extension MainMenu {
    
    func setupBG() {
        // Background
        let bgNode = SKSpriteNode(imageNamed: "menu_background")
        bgNode.zPosition = -1.0
        bgNode.anchorPoint = .zero
        bgNode.size = self.size
        bgNode.position = .zero
        addChild(bgNode)
        
        // Logo
        let bgLogo = SKSpriteNode(imageNamed: "logoMenu")
        bgLogo.setScale(logoScale)
        bgLogo.position = CGPoint(x: size.width/2.0, y: size.height/2.0 + bgLogo.frame.height/1.75)
        addChild(bgLogo)
    }
    
    func setupNodes() {
        // Info Button
        let info = SKSpriteNode(imageNamed: "info")
        info.name = "info"
        info.setScale(buttonScale)
        info.zPosition = buttonZPos
        info.position = CGPoint(x: info.frame.width*3/4, y: size.height*3/4)
        addChild(info)
        
        // Play Long Button
        let play = SKSpriteNode(imageNamed: "play")
        play.name = "play"
        play.setScale(longButtonScale)
        play.zPosition = buttonZPos
        play.position = CGPoint(x: size.width/2.0, y: size.height/2.0 - play.frame.height/2.0)
        addChild(play)
        
        // Highscore button
        let highscore = SKSpriteNode(imageNamed: "highscore")
        highscore.name = "highscore"
        highscore.setScale(buttonScale)
        highscore.zPosition = buttonZPos
        highscore.position = CGPoint(x: size.width/2.0 - highscore.frame.width*2,
                                     y: play.position.y - highscore.frame.height*3/2)
        addChild(highscore)
        
        // Controller Selection Button
        let isControllerSelected = ControllerSetting.sharedInstance.getCameraMode() || ControllerSetting.sharedInstance.getWatchMode()
        let controllerSelect = SKSpriteNode(imageNamed: isControllerSelected ? "controllerOn" : "controllerOff")
        controllerSelect.name = "controllerSelect"
        controllerSelect.setScale(buttonScale)
        controllerSelect.zPosition = buttonZPos
        controllerSelect.position = CGPoint(x: size.width/2.0 - controllerSelect.frame.width/1.5,
                                            y: play.position.y - controllerSelect.frame.height*3/2)
        addChild(controllerSelect)
        
        // Settings Button
        let setting = SKSpriteNode(imageNamed: "setting")
        setting.name = "setting"
        setting.setScale(buttonScale)
        setting.zPosition = buttonZPos
        setting.position = CGPoint(x: size.width/2.0 + setting.frame.width/1.5,
                                   y: play.position.y - setting.frame.height*3/2)
        addChild(setting)
        
        // Shop button
        let shop = SKSpriteNode(imageNamed: "shop")
        shop.name = "shop"
        shop.setScale(buttonScale)
        shop.zPosition = buttonZPos
        shop.position = CGPoint(x: size.width/2.0 + shop.frame.width*2,
                                y: play.position.y - shop.frame.height*3/2)
        addChild(shop)
    }
    
    //MARK: - Input Controller Selection Panel
    func setupControllerChoicePanel() {
        // Create a Container
        setupContainer()
        
        // Create a panel inside the container
        let panel = SKSpriteNode(imageNamed: "bigPanel")
        panel.name = "controllerRoot"
        panel.setScale(1.25)
        panel.zPosition = 20.0
        panel.position = .zero
        containerNode.addChild(panel)
        
        // Heading
        let headingLbl = SKLabelNode(fontNamed: "AmericanTypewriter-Bold")
        headingLbl.name = "ControllerHead"
        headingLbl.text = "Choose a controller"
        headingLbl.fontSize = 60.0
        headingLbl.zPosition = 25.0
        headingLbl.fontColor = .black
        headingLbl.position = CGPoint(x: 0, y: panel.frame.height/3.7)
        panel.addChild(headingLbl)
        
        let cameraImage = SKSpriteNode(imageNamed: "camera")
        cameraImage.name = "cameraImage"
        cameraImage.setScale(0.891)
        cameraImage.zPosition = 21.0
        cameraImage.position = CGPoint(x: panel.size.width/6, y: panel.position.y/1.5)
        panel.addChild(cameraImage)
        
        let watchImage = SKSpriteNode(imageNamed: ControllerSetting.sharedInstance.getWatchMode() ? "watchApp" : "watchLogo")
        watchImage.name = "watchImage"
        watchImage.setScale(0.74)
        watchImage.zPosition = 21.0
        watchImage.position = CGPoint(x: -(panel.size.width/6), y: panel.position.y/1.5)
        panel.addChild(watchImage)
        
        let controllerLblcamera = SKLabelNode(fontNamed: "AmericanTypewriter-Bold")
        controllerLblcamera.name = "textControllerCamera"
        controllerLblcamera.text = "Initial text"
        controllerLblcamera.fontColor = .black
        controllerLblcamera.fontSize = 45.0
        controllerLblcamera.zPosition = 25.0
        controllerLblcamera.verticalAlignmentMode = .center
        controllerLblcamera.horizontalAlignmentMode = .center
        controllerLblcamera.position = CGPoint(x: cameraImage.position.x,
                                               y: headingLbl.position.y/1.3)
        
        let controllerLblWatch = SKLabelNode(fontNamed: "AmericanTypewriter-Bold")
        controllerLblWatch.name = "textControllerWatch"
        controllerLblWatch.text = "Initial text"
        controllerLblWatch.fontColor = .black
        controllerLblWatch.fontSize = 45.0
        controllerLblWatch.zPosition = 25.0
        controllerLblWatch.verticalAlignmentMode = .center
        controllerLblWatch.horizontalAlignmentMode = .center
        controllerLblWatch.position = CGPoint(x: watchImage.position.x,
                                              y: headingLbl.position.y/1.3)
        
        // Footer
        let footerLbl = SKLabelNode(fontNamed: "AmericanTypewriter-Bold")
        footerLbl.name = "ControllerFooter"
        footerLbl.text = "Initial text"
        footerLbl.fontSize = 40.0
        footerLbl.zPosition = 25.0
        footerLbl.fontColor = .black
        footerLbl.preferredMaxLayoutWidth = panel.frame.width/1.5
        footerLbl.numberOfLines = 2
        footerLbl.position = CGPoint(x: 0, y: controllerLblcamera.position.y - panel.frame.height/2)
        panel.addChild(footerLbl)
        
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
        let labelFooter = panel.childNode(withName: "ControllerFooter") as? SKLabelNode

        let blendFactor = CGFloat(0.4)
        
        let cameraMode = ControllerSetting.sharedInstance.getCameraMode()
        let watchMode = ControllerSetting.sharedInstance.getWatchMode()
        
        // Update Watch Image
        bgWatch?.texture = SKTexture(imageNamed: ControllerSetting.sharedInstance.getWatchMode() ? "watchApp" : "watchLogo")
        
        if(cameraMode){ // Camera tracking selected
            bgWatch?.colorBlendFactor = blendFactor
            bgCamera?.colorBlendFactor = 0
            labelCamera?.text = "Camera Selected"
            labelWatch?.text = "Apple Watch"
            labelFooter?.text = "Place the phone about 1m away from you and make sure no one else is around"
        }
        else if (watchMode){ // Watch tracking selected
            bgCamera?.colorBlendFactor = blendFactor
            bgWatch?.colorBlendFactor = 0
            labelWatch?.text = "Watch Selected"
            labelCamera?.text = "Camera Tracking"
            labelFooter?.text = "Before starting your game, activate the watch application (start tracking)"
        }
        else if(!cameraMode && !watchMode) { // No controller
            bgWatch?.colorBlendFactor = 0
            labelWatch?.text = "Apple Watch"
            if #available(iOS 14.0, *) {
                labelCamera?.text = "Camera Tracking"
                bgCamera?.colorBlendFactor = 0
            }
            labelFooter?.text = "No controller selected, you can control the character by pressing on the screen"
        }
                
        // Update controller selection icon
        let isControllerSelected = ControllerSetting.sharedInstance.getCameraMode() || ControllerSetting.sharedInstance.getWatchMode()
        let controllerIcon = self.childNode(withName: "controllerSelect") as? SKSpriteNode
        controllerIcon?.texture = SKTexture(imageNamed: isControllerSelected ? "controllerOn" : "controllerOff")
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
            // This panel hides all the elements
            self.panelHider.name = "HighscorePanelHider"
            self.panelHider.setScale(1.2)
            self.panelHider.zPosition = 100.0 // to hide the other elements
            self.panelHider.position = .zero
            self.containerNode.addChild(self.panelHider)
            
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
            Spark.fetchAllSparkUsersStats { (message, err, sparkUsersStats) in
                if let err = err {
                    print("Error: \(message) \(err.localizedDescription)")
                    return
                }
                guard let sparkUsersStats = sparkUsersStats else {
                    print("Failed to fetch user")
                    return
                }
                
                // Number of pages
                self.currTopRunPageNum = 1 // reset value to the first page
                let sparkUsersStatsArray = sparkUsersStats.compactMap({$0})
                self.maxTopRunElements = sparkUsersStatsArray.count
                self.maxTopRunPageNum = Int(ceil(Double(self.maxTopRunElements)/4.0))
            
                // Insert elements into the rank
                for (index, element) in sparkUsersStats {
                    //print(element.data())
                    self.insertIntoTopRun(index: index+1, panel: panel, sparkUserStats: element.data() as NSDictionary)
                }
                
                // Start a small counter in order to wait until the images are downloaded
                // and by doing so the user will not see the rank without the images
                self.progressBar.zPosition = 101.0 // to put the progress bar in top of the panel
                self.progressBar.setScale(1.2)
                self.panelHider.addChild(self.progressBar)
                self.startProgressBar = true // start the counter
            }
        } else { // Show only your scores saved locally
            // Show Highscore
            let highscoreLbl = SKLabelNode(fontNamed: "AmericanTypewriter-Bold")
            highscoreLbl.text = "Highscore: \(ScoreGenerator.sharedInstance.getHighscore())m"
            highscoreLbl.horizontalAlignmentMode = .center
            highscoreLbl.fontSize = 70.0
            highscoreLbl.zPosition = 25.0
            highscoreLbl.fontColor = .black
            highscoreLbl.position = CGPoint(x: 0.0, y: highscoreLbl.frame.height/2.0 - 20.0)
            panel.addChild(highscoreLbl)
            
            // Show Last Score
            let scoreLbl = SKLabelNode(fontNamed: "AmericanTypewriter-Bold")
            scoreLbl.text = "Last Score: \(ScoreGenerator.sharedInstance.getScore())m"
            scoreLbl.horizontalAlignmentMode = .center
            scoreLbl.fontSize = 65.0
            scoreLbl.zPosition = 25.0
            scoreLbl.fontColor = .black
            scoreLbl.position = CGPoint(x: 0.0, y: -scoreLbl.frame.height - 20.0)
            panel.addChild(scoreLbl)
        }
    }
    
    func insertIntoTopRun(index i: Int, panel: SKSpriteNode, sparkUserStats: NSDictionary) {
        // Get Spark User Data
        Spark.fetchSparkUser(sparkUserStats.value(forKey: "uid") as! String) { message, err, sparkUser in
            if let err = err {
                print("Error: \(message) \(err.localizedDescription)")
                return
            }
            guard let sparkUser = sparkUser else {
                print("Failed to fetch user")
                return
            }
        // Check if is currentUser
        let isCurrentUser:Bool = (sparkUser.uid) == self.currentUser.uid
        let userColor = UIColor(red: 0.25, green: 0.17, blue: 0.08, alpha: 1.00)
        let notUserColor = UIColor(red: 0.84, green: 0.68, blue: 0.31, alpha: 1.00)
        let rowColor = (isCurrentUser ? userColor : notUserColor)
        let rowFontColor = (isCurrentUser ? UIColor.white : UIColor.black)
        // Add new row
        let row = SKSpriteNode(color: rowColor, size: CGSize(width: panel.frame.width-450, height: 110.0))
        row.name = "row\(i)"
        row.zPosition = 22.0
        let indexPage = (((i - 1) % 4) + 1) // the position of an element in a page is from 1 to 4 for every page
        row.position = CGPoint(x: 0.0,
                               y: panel.frame.height/4.6 - (row.frame.height * CGFloat(indexPage-1)) - (10.0 * CGFloat(indexPage)))
        panel.addChild(row)
        row.drawBorder(color: .black, width: 2)
        if(i > 4) { // Show only the first page
            row.isHidden = true
        }
        // Add Position
        let rank = SKLabelNode(fontNamed: "AmericanTypewriter-Bold")
        rank.text = String(i)
        rank.fontSize = 40.0
        rank.zPosition = 25.0
        rank.fontColor = rowFontColor
        row.addChild(rank)
        rank.position = CGPoint(x: -row.frame.width/2.0 + 35,
                                y: -15.0)
        // Add Image
        // Fetch profile image
        Spark.fetchProfileImage(sparkUser: sparkUser) { (message, err, image) in
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
        // Add Name (only)
        let userName = SKLabelNode(fontNamed: "AmericanTypewriter-Bold")
        userName.text = (sparkUser.name).components(separatedBy: " ").first
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
        // Add Medal (1st, 2nd, 3rd)
        if(i == 1 || i == 2 || i == 3) {
            let userMedal = SKSpriteNode(imageNamed: "medal\(i)")
            userMedal.zPosition = 25.0
            userMedal.scale(to: CGSize(width: 70.0, height: 70.0))
            userMedal.position = CGPoint(x: userName.position.x + userName.frame.width + userMedal.frame.width/2.5,
                                    y: 0.0)
            row.addChild(userMedal)
        }
        // Add score
        let userScore = SKLabelNode(fontNamed: "AmericanTypewriter-Bold")
        let userScoreValue = sparkUserStats.value(forKey: "record") as! Int
        userScore.text = "\(userScoreValue)m"
        userScore.fontSize = 40.0
        userScore.zPosition = 25.0
        userScore.fontColor = rowFontColor
        userScore.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        userScore.position = CGPoint(x: row.frame.width/2.0 - 40 - userScore.frame.width,
                                     y: rank.position.y)
        row.addChild(userScore)
        }
    }
    
    // nextPage False => go to previous page
    // nextPage True => go to next page
    func updateTopRun(nextPage: Bool) {
        // Check new page number
        let newPageNum: Int!
        if(nextPage) { // next
            newPageNum = self.currTopRunPageNum + 1 > self.maxTopRunPageNum ? self.maxTopRunPageNum : self.currTopRunPageNum+1
        } else { // previous
            newPageNum = self.currTopRunPageNum - 1 < 1 ? 1 : self.currTopRunPageNum-1
        }
        
        // Check if the page is different from the current one
        if(newPageNum == currTopRunPageNum) {
            return // nothing has to change
        }
        
        // Calculates the number of elements in the new page and in the current one
        let currPageNumberElements = currTopRunPageNum == maxTopRunPageNum ? maxTopRunElements-((currTopRunPageNum-1)*4) : 4
        let newPageNumberElements = newPageNum == maxTopRunPageNum ? maxTopRunElements-((newPageNum-1)*4) : 4
        
        // Hide and unhide elements
        if let container = containerNode {
            container.enumerateChildNodes(withName: "HighscorePanel") { nodeHighscore, _ in
                // Hide elements in the current page
                // The rows are indexed from 1 to 4 in the first page, and so on
                for i in (self.currTopRunPageNum-1)*4..<((self.currTopRunPageNum-1)*4)+currPageNumberElements {
                    nodeHighscore.enumerateChildNodes(withName: "row\(i+1)") { nodeRow, _ in
                        nodeRow.run(SKAction.hide())
                        //nodeRow.isHidden = true
                    }
                }
                // Show elements in the new page
                for i in (newPageNum-1)*4..<((newPageNum-1)*4)+newPageNumberElements {
                    nodeHighscore.enumerateChildNodes(withName: "row\(i+1)") { nodeRow, _ in
                        nodeRow.run(SKAction.unhide())
                        //nodeRow.isHidden = false
                    }
                }
            }
        }
        
        // Play Sound
        run(SKAction.playSoundFileNamed("buttonSound.wav"))
        
        // Update Current Page Number
        self.currTopRunPageNum = newPageNum
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
            // We have the Spark user infos
            self.currentUser = sparkUser
            print("Successfully signed in with Facebook with Spark User: \(self.currentUser!)")
            SparkService.dismissHud(self.hud, text: "Success", detailText: "Successfully signed in with Facebook", delay: 3)
            
            // Update and get the Spark User Stats
            let uid = self.currentUser.uid
            let record = ScoreGenerator.sharedInstance.isHighscorePresent() ? ScoreGenerator.sharedInstance.getHighscore() : 0
            let diamonds = ScoreGenerator.sharedInstance.isDiamondsPresent() ? ScoreGenerator.sharedInstance.getDiamonds() : 0
            Spark.updateSparkUserStats(uid: uid, localRecord: record, diamondsToAdd: diamonds) { (message, err, sparkUserStats) in
                print(message)
                guard let sparkUserStats = sparkUserStats else {
                    print("Error: \(err!)")
                    return
                }
                // We have the Spark User Stats
                self.currentUserStats = sparkUserStats
                ScoreGenerator.sharedInstance.setHighscore(self.currentUserStats.record) // update record
                self.fbUserLogged = true   // Update login status
                print(self.currentUserStats!)
            }
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
                ScoreGenerator.sharedInstance.resetAll() // Reset local stats
                let currPlayerSelected = PlayerSetting.sharedInstance.getPlayerSelected()
                if !(currPlayerSelected == PlayerName.theBoy.rawValue || currPlayerSelected == PlayerName.cuteGirl.rawValue) {
                    PlayerSetting.sharedInstance.setPlayerSelected(PlayerName.theBoy)
                }
                SparkService.dismissHud(self.hud, text: "Success", detailText: "Successfully signed out", delay: 3)
            } else {
                SparkService.dismissHud(self.hud, text: "Sign Out Error",
                                        detailText: "Failed to sign out", delay: 1)
            }
        }
    }
    
    //MARK: - Diamonds Counter
    func setupDiamondsCounter() {
        // Numbers of diamonds
        let diamondsAmountContainer = SKSpriteNode(imageNamed: "diamondContainer")
        diamondsAmountContainer.zPosition = 30.0
        diamondsAmountContainer.name = "diamondsAmountContainer"
        diamondsAmountContainer.position = CGPoint(x: containerNode.frame.width/4.3 + diamondsAmountContainer.frame.width,
                                                   y: containerNode.frame.height/4.0)
        containerNode.addChild(diamondsAmountContainer)
        
        // #Diamonds label
        if fbUserLogged {
            Spark.fetchCurrentSparkUserStats { message, err, sparkUserStats in
                guard let sparkUserStats = sparkUserStats else {
                    print("Error: \(err!)")
                    return
                }
                self.numDiamondsLbl.text = String(sparkUserStats.diamonds)  // update label
                self.currentUserStats.diamonds = sparkUserStats.diamonds    // update current amount to avoid bugs
            }
        } else {
            let offDiamonds = ScoreGenerator.sharedInstance.isDiamondsPresent() ? "\(ScoreGenerator.sharedInstance.getDiamonds())" : "\(0)"
            numDiamondsLbl.text = String(offDiamonds)
        }
        numDiamondsLbl.zPosition = 35.0
        numDiamondsLbl.name = "diamondsAmountLbl"
        numDiamondsLbl.fontSize = 50
        numDiamondsLbl.position = CGPoint(x: diamondsAmountContainer.position.x + diamondsAmountContainer.frame.width/7.0,
                                          y: diamondsAmountContainer.position.y - diamondsAmountContainer.frame.height/7.0)
        containerNode.addChild(numDiamondsLbl)
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
        rightArrow.setScale(arrowsScale)
        rightArrow.zPosition = 20.0
        rightArrow.position = CGPoint(x: panel.position.x + panel.size.width/2 - 50,
                                      y: panel.position.y/2)
        
        panel.addChild(rightArrow)
        
        // add left arrow
        let leftArrow = SKSpriteNode(imageNamed: "leftArrow")
        leftArrow.name = "infoArrowLeft"
        leftArrow.setScale(0) // invisible arrow (no dimension)
        leftArrow.zPosition = 20.0
        leftArrow.position = CGPoint(x: -(panel.position.x + panel.size.width/2 - 50), y: panel.position.y/2)
        panel.addChild(leftArrow)
        
        // add info images to panel
        let info1 = SKSpriteNode(imageNamed: "infoImg1")
        info1.name = "info1"
        info1.zPosition = 30.0
        info1.position = CGPoint(x:panel.position.x - panel.size.width/4 + 20,y:panel.position.y + panel.size.height/4 - 40)
        info1.setScale(0) //invisible
        panel.addChild(info1)

        let info2 = SKSpriteNode(imageNamed: "infoImg2")
        info2.name = "info2"
        info2.position = CGPoint(x:panel.position.x + panel.size.width/4 - 20,y:panel.position.y + panel.size.height/4 - 40)
        info2.zPosition = 30.0
        info2.setScale(0) //invisible
        panel.addChild(info2)
        
        // Add text
        let infoLbl = SKLabelNode(fontNamed: "AmericanTypewriter-Bold")
        infoLbl.name = "textInfo"
        infoLbl.text = "Along your way, use your skills to collect diamonds and avoid different types of obstacles while trying to go as far as possible."
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
        let infoImg1 = panel.childNode(withName: "info1") as! SKSpriteNode
        let infoImg2 = panel.childNode(withName: "info2") as! SKSpriteNode
        
        switch currInfoPageNum {
        case 1:
            panel.childNode(withName: "infoArrowLeft")?.setScale(0) //set the left arrow invisible
            infoLbl?.verticalAlignmentMode = .center
            infoLbl?.fontSize = 65.0
            infoLbl?.text = "Along your way, use your skills to collect diamonds and avoid different types of obstacles while trying to go as far as possible."
            infoImg1.setScale(0)
            infoImg2.setScale(0)
        case 2:
            panel.childNode(withName: "infoArrowLeft")?.setScale(arrowsScale) //set the left arrow visible
            panel.childNode(withName: "infoArrowRight")?.setScale(arrowsScale) //set the right arrow visible
            infoLbl?.verticalAlignmentMode = .top
            infoLbl?.fontSize = 50.0
            infoLbl?.text = "Sharp objects will steal a life from you, while smooth rocks and trees will cause you to lose a diamond.\n"
            infoImg1.setScale(0.5)
            infoImg2.setScale(0.5)
        case 3:
            panel.childNode(withName: "infoArrowLeft")?.setScale(arrowsScale) //set the left arrow visible
            panel.childNode(withName: "infoArrowRight")?.setScale(arrowsScale) //set the right arrow visible
            infoLbl?.verticalAlignmentMode = .center
            infoLbl?.fontSize = 65.0
            infoLbl?.text = "By collecting diamonds along the way, you can unlock new characters in the shop."
            infoImg1.setScale(0)
            infoImg2.setScale(0)
        case pageInfoNum:
            infoImg1.setScale(0)
            infoImg2.setScale(0)
            infoLbl?.verticalAlignmentMode = .center
            infoLbl?.fontSize = 65.0
            panel.childNode(withName: "infoArrowRight")?.setScale(0) //set the right arrow invisible
            infoLbl?.text = "For a better experience it is recommended to use one of the two controllers (Apple Watch or Internal Camera)."
        default:
            break
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
        rightArrow.setScale(arrowsScale)
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
            let theBoy = SKSpriteNode(imageNamed: "\(PlayerName.theBoy.rawValue)/Idle (1)")
            theBoy.name = "theBoy"
            theBoy.zPosition = 10.0
            theBoy.position = CGPoint(x: -3*theBoy.frame.width/4, y:panel.position.y/2)
            panel.addChild(theBoy)
            // Add animations
            var theBoyFrames = [SKTexture]()
            for i in 2...PlayerSetting.sharedInstance.getPlayerIdleIndex(PlayerName.theBoy) {
                let frameName = "\(PlayerName.theBoy.rawValue)/Idle (\(i))"
                theBoyFrames.append(SKTexture(imageNamed: frameName))
            }
            // Animation activated
            theBoy.run(SKAction.repeatForever(SKAction.animate(with: theBoyFrames, timePerFrame: timePerFrameTheBoyAnimations)), withKey: "theBoyAnimation")
            
            loadNameCharacter(Labelname: "boyname", CharacterName: "Mike")
            loadHeartsCharacter(amount: 3, pagenum: pageNum)
            
            loadSelectionCharacter(name: "Mike")
            
        //        pagina dedicata a girl
        case 2:
            // Setup the girl
            let cuteGirl = SKSpriteNode(imageNamed: "\(PlayerName.cuteGirl.rawValue)/Idle (1)")
            cuteGirl.name = "cuteGirl"
            cuteGirl.zPosition = 10.0
            cuteGirl.position = CGPoint(x: -3*cuteGirl.frame.width/4, y:panel.position.y/2)
            panel.addChild(cuteGirl)
            // Add animations
            var cuteGirlFrames = [SKTexture]()
            for i in 2...PlayerSetting.sharedInstance.getPlayerIdleIndex(PlayerName.cuteGirl) {
                let frameName = "\(PlayerName.cuteGirl.rawValue)/Idle (\(i))"
                cuteGirlFrames.append(SKTexture(imageNamed: frameName))
            }
            // Animation activated
            cuteGirl.run(SKAction.repeatForever(SKAction.animate(with: cuteGirlFrames, timePerFrame: timePerFrameCuteGirlAnimations)), withKey: "cuteGirlAnimation")
            
            loadNameCharacter(Labelname: "girlname", CharacterName: "Peach")
            loadHeartsCharacter(amount: 3, pagenum: pageNum)
            
            loadSelectionCharacter(name: "Peach")
        //        pagina dedicata a indiana
        case 3:
            let ellie = SKSpriteNode(imageNamed: "\(PlayerName.ellie.rawValue)/Idle (1)")
            ellie.name = "Indiana"
            ellie.zPosition = 10.0
            ellie.position = CGPoint(x: -3*ellie.frame.width/4, y:panel.position.y/2)
            panel.addChild(ellie)
            // Add animations
            var indianaFrames = [SKTexture]()
            for i in 2...PlayerSetting.sharedInstance.getPlayerIdleIndex(PlayerName.ellie) {
                let frameName = "\(PlayerName.ellie.rawValue)/Idle (\(i))"
                indianaFrames.append(SKTexture(imageNamed: frameName))
            }
            // Animation activated
            ellie.run(SKAction.repeatForever(SKAction.animate(with: indianaFrames, timePerFrame: timePerFrameIndiana)), withKey: "IndianaAnimation")
            
            loadNameCharacter(Labelname: "indianame", CharacterName: "Ellie")
            loadHeartsCharacter(amount: 4, pagenum: pageNum)
            
            loadSelectionCharacter(name: "Ellie")
        //        pagina dedicata a dino
        case 4:
            let dino = SKSpriteNode(imageNamed: "\(PlayerName.dino.rawValue)/Idle (1)")
            dino.name = "Dino"
            dino.zPosition = 10.0
            dino.position = CGPoint(x: -dino.frame.width/2, y:panel.position.y/2)
            panel.addChild(dino)
            // Add animations
            var dinoFrames = [SKTexture]()
            for i in 2...PlayerSetting.sharedInstance.getPlayerIdleIndex(PlayerName.dino) {
                let frameName = "\(PlayerName.dino.rawValue)/Idle (\(i))"
                dinoFrames.append(SKTexture(imageNamed: frameName))
            }
            // Animation activated
            dino.run(SKAction.repeatForever(SKAction.animate(with: dinoFrames, timePerFrame: timePerFrameDino)), withKey: "DinoAnimation")
            
            loadNameCharacter(Labelname: "dinoname", CharacterName: "Dino")
            loadHeartsCharacter(amount: 5, pagenum: pageNum)
            
            loadSelectionCharacter(name: "Dino")
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
            unloadHeartsCharacter(amount: 3, pagenum: pageNum)
            removeShopSelect(name: "Mike")
        case 2:
            let girl = panel.childNode(withName: "cuteGirl") as? SKSpriteNode
            girl?.removeFromParent()
            unloadNameCharacter(Labelname: "girlname")
            unloadHeartsCharacter(amount: 3, pagenum: pageNum)
            removeShopSelect(name: "Peach")
        case 3:
            let indiana = panel.childNode(withName: "Indiana") as? SKSpriteNode
            indiana?.removeFromParent()
            unloadNameCharacter(Labelname: "indianame")
            unloadHeartsCharacter(amount: 4, pagenum: pageNum)
            removeShopSelect(name: "Ellie")
        case 4:
            let dino = panel.childNode(withName: "Dino") as? SKSpriteNode
            dino?.removeFromParent()
            unloadNameCharacter(Labelname: "dinoname")
            unloadHeartsCharacter(amount: 5, pagenum: pageNum)
            removeShopSelect(name: "Dino")
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
    func loadHeartsCharacter(amount: Int,  pagenum : Int){
        var livesSprites = [SKSpriteNode]()
        //add livesNumber hearts to the player
        for i in 0..<amount{
            livesSprites.append(SKSpriteNode(imageNamed: "life-on"))
            setupLifePos(livesSprites[i], i: CGFloat(i+1), j: CGFloat(i*8), pagenum: pagenum)
        }
    }
    //  to position the lives in the panel
    func setupLifePos(_ node: SKSpriteNode, i: CGFloat, j: CGFloat, pagenum : Int) {
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
        node.name = "life \(Int(i-1)) - \(pagenum)"
        panel.addChild(node)
    }
    //  to remove the hearts from the corresponding shop page
    func unloadHeartsCharacter(amount: Int, pagenum : Int){
        
        guard let panel = containerNode.childNode(withName: "ShopPanel") as? SKSpriteNode
        else{
            print("nope unload hearts")
            return
        }
        
        for i in 0..<amount{
            let node = panel.childNode(withName: "life \(i) - \(pagenum)")
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
            rightArrow.setScale(arrowsScale)
        }
        else if(currShopPageNum == shopCharacters){
            leftArrow.setScale(arrowsScale)
            rightArrow.setScale(0)
        }else{
            leftArrow.setScale(arrowsScale)
            rightArrow.setScale(arrowsScale)
        }
    }
    
    func loadSelectionCharacter(name: String) {
        
        let playerSelected = PlayerSetting.sharedInstance.getPlayerSelected()
        // returns theBoy, cuteGirl, ellie, dino
        
        switch name {
        case "Mike":
            if(playerSelected == "theBoy") {
                createShopSelect(type: "selected", selectBtnName: "Mike0", price: 0)
            } else {
                createShopSelect(type: "select", selectBtnName: "Mike1", price: 0)
            }
        case "Peach":
            if(playerSelected == "cuteGirl"){
                createShopSelect(type: "selected", selectBtnName: "Peach0", price: 0)
            }else{
                createShopSelect(type: "select", selectBtnName: "Peach1", price: 0)
            }
        case "Ellie":
            if(fbUserLogged){
                if(currentUserStats.ellieUnlocked) {
                    if(playerSelected == "ellie"){
                        createShopSelect(type: "selected", selectBtnName: "Ellie0", price: 0)
                    }
                    else{
                        createShopSelect(type: "select", selectBtnName: "Ellie1", price: 0)
                    }
                }
                else {
                    if(currentUserStats.diamonds >= playerPrice[name]!){
                        createShopSelect(type: "lockedWithMoney", selectBtnName: "Ellie3", price: playerPrice[name]!)
                    }
                    else{
                        createShopSelect(type: "lockedNoMoney", selectBtnName: "Ellie4", price: playerPrice[name]!)
                    }
                }
            }
            else{
                createShopSelect(type: "lockedFB", selectBtnName: "Ellie2", price: 0)
            }
            
        case "Dino":
            if(fbUserLogged){
                if(currentUserStats.dinoUnlocked) {
                    if(playerSelected == "dino"){
                        createShopSelect(type: "selected", selectBtnName: "Dino0", price: 0)
                    }
                    else{
                        createShopSelect(type: "select", selectBtnName: "Dino1", price: 0)
                    }
                }
                else{
                    if(currentUserStats.diamonds >= playerPrice[name]!) {
                        createShopSelect(type: "lockedWithMoney", selectBtnName: "Dino3", price: playerPrice[name]!)
                    }
                    else {
                        createShopSelect(type: "lockedNoMoney", selectBtnName: "Dino4", price: playerPrice[name]!)
                    }
                }
            }
            else{
                createShopSelect(type: "lockedFB", selectBtnName: "Dino2", price: 0)
            }
            
        default:
            return
        }
    }
    
    func createShopSelect(type: String, selectBtnName: String,price: Int){
        
        guard let panel = containerNode.childNode(withName: "ShopPanel") as? SKSpriteNode
        else{
            print("nope load selection")
            return
        }
        
        let position = CGPoint(x: panel.position.x + panel.size.width/4 - 40, y: panel.position.y-panel.size.height/4 + 20)
        
        let buttonLbl = SKLabelNode(fontNamed: "AmericanTypewriter-Bold")
        buttonLbl.fontColor = .black
        buttonLbl.fontSize = 68
        buttonLbl.position = CGPoint(x: 0, y: -15)
        buttonLbl.zPosition = 19
        buttonLbl.name = selectBtnName + "L"
        
        switch type {
        case "selected":
            let button = SKSpriteNode(imageNamed: "selectedBtn")
            button.name = selectBtnName
            button.position = position
            buttonLbl.text = "Selected"
            buttonLbl.fontColor = UIColor(red: 0.52, green: 0.68, blue: 0.00, alpha: 1.00)
            button.zPosition = 19
            button.addChild(buttonLbl)
            panel.addChild(button)
        case "select":
            let button = SKSpriteNode(imageNamed: "standardBtn")
            button.name = selectBtnName
            button.position = position
            buttonLbl.text = "Select"
            buttonLbl.fontColor = UIColor(red: 0.24, green: 0.55, blue: 0.00, alpha: 1.00)
            button.zPosition = 19
            button.addChild(buttonLbl)
            panel.addChild(button)
        case "lockedFB": //offline mode, should connect to fb
            let button = SKSpriteNode(imageNamed: "lockedBtn")
            button.name = selectBtnName
            button.position = position
            buttonLbl.text = "Login Needed"
            buttonLbl.fontColor = UIColor(red: 0.52, green: 0.59, blue: 0.59, alpha: 1.00)
            buttonLbl.fontSize = 42
            buttonLbl.position  = CGPoint(x: 0, y: -5)
            button.zPosition = 19
            button.addChild(buttonLbl)
            panel.addChild(button)
        case "lockedNoMoney": // need more money to buy the character
            let button = SKSpriteNode(imageNamed: "lockedBtn")
            let diamond = SKSpriteNode(imageNamed: "jewel/0")
            button.name = selectBtnName
            button.position = position
            buttonLbl.text = "\(price)"
            buttonLbl.fontColor = UIColor(red: 0.52, green: 0.59, blue: 0.59, alpha: 1.00)
            button.zPosition = 19
            
            diamond.setScale(0.8)
            diamond.position = CGPoint(x: position.x/2.5,y: 0)
            diamond.zPosition = 19
            buttonLbl.position.x -= 40
            
            button.addChild(buttonLbl)
            button.addChild(diamond)
            panel.addChild(button)
        case "lockedWithMoney": //can buy character
            let button = SKSpriteNode(imageNamed: "standardBtn")
            let diamond = SKSpriteNode(imageNamed: "jewel/0")
            button.name = selectBtnName
            button.position = position
            buttonLbl.text = "\(price)"
            buttonLbl.fontColor = UIColor(red: 0.24, green: 0.55, blue: 0.00, alpha: 1.00)
            button.zPosition = 19
            
            diamond.setScale(0.8)
            diamond.position = CGPoint(x: position.x/2.5,y: 0)
            diamond.zPosition = 19
            buttonLbl.position.x -= 40
            
            button.addChild(buttonLbl)
            button.addChild(diamond)
            panel.addChild(button)
        default:
            return
        }
    }
    
    func removeShopSelect(name: String){
        
        guard let panel = containerNode.childNode(withName: "ShopPanel") as? SKSpriteNode
        else{
            print("nope load selection")
            return
        }
        
        for i in 0...4{
            let btnName = name + i.description
            let button = panel.childNode(withName: btnName)
            button?.removeAllChildren()
            button?.removeFromParent()
        }
    }
    
    func buyCharacter(name : String) {
        switch name {
        case "Ellie":
            currentUserStats.diamonds -= playerPrice[name]!
            numDiamondsLbl.text = String(currentUserStats.diamonds)
            currentUserStats.ellieUnlocked = true
            run(SKAction.playSoundFileNamed("indiana.wav"))
            if(!Spark.saveSparkUserStats(sparkUserStats: currentUserStats)){
                //rollback in caso di errore
                currentUserStats.diamonds += playerPrice[name]!
                currentUserStats.ellieUnlocked = false
            }
            //aggiorna lo shop per consentire la selezione del personaggio Ellie
            updateCurrentShopPage(pageNum: currShopPageNum)
        case "Dino":
            currentUserStats.diamonds -= playerPrice[name]!
            numDiamondsLbl.text = String(currentUserStats.diamonds)
            currentUserStats.dinoUnlocked = true
            run(SKAction.playSoundFileNamed("trex.wav"))
            if(!Spark.saveSparkUserStats(sparkUserStats: currentUserStats)) {
                //rollback in caso di errore
                currentUserStats.diamonds += playerPrice[name]!
                currentUserStats.dinoUnlocked = false
            }
           updateCurrentShopPage(pageNum: currShopPageNum)
        default:
            break
        }
    }
    
    func updateCurrentShopPage(pageNum: Int) {
        //aggiorna lo shop per consentire la selezione del personaggio Dino
        unloadShopPage(pageNum: currShopPageNum)
        loadShopPage(pageNum: currShopPageNum)
    }
}

