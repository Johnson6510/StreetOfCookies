//
//  GameScene.swift
//  StreetOfCookies
//
//  Created by 黃健偉 on 2018/1/26.
//  Copyright © 2018年 黃健偉. All rights reserved.
//

// need to add:
// icon & Luanch Screen
// add achievement for each room
//

import SpriteKit
import AVFoundation

class GameScene: SKScene {
    var level: Level!
    
    var tileWidth: CGFloat = 32
    var tileHeight: CGFloat = 36

    let gameLayer = SKNode()
    let cookiesLayer = SKNode()
    let tilesLayer = SKNode()
    let cropLayer = SKCropNode()
    let maskLayer = SKNode()

    var moveTime: Double = 0
    let timerBar = SKSpriteNode()
    var timerBarHeight: CGFloat = 5
    weak var timer: Timer?

    var playerHP: Int = 0
    var healthBarHp: Int = 0
    let healthBar = SKSpriteNode()
    var healthBarHeight: CGFloat = 20
    var lastUpdateTime: TimeInterval = 0

    var turn: Int = 0
    var turnLabel: SKLabelNode? = nil

    var combo: Int = 0
    var lastCombo: Int = 0
    var maxCombo: Int = 0
    var totalEatCookies: Int = 0

    var score: Int = 0
    var scoreAdd: Int = 0
    var scoreLabel: SKLabelNode? = nil

    var levelLabel: SKLabelNode!
    var levelButton: SKButton!

    private var swipeFromX: Int?
    private var swipeFromY: Int?
    private var oriX = -1
    private var oriY = -1
    
    private var isMoved = false

    var selectionSprite = SKSpriteNode()
    
    var swipeHandler: ((Swap) -> ())?
    var moveDoneHandler: (() -> ())?
    var roomHandler: (() -> ())?

    // Pre-load sounds
    let scrapeSound = SKAction.playSoundFileNamed("Scrape.wav", waitForCompletion: false) //移動
    let chompSound = SKAction.playSoundFileNamed("Chomp.wav", waitForCompletion: false) //消珠
    let dripSound = SKAction.playSoundFileNamed("Drip.wav", waitForCompletion: false) //落珠
    let kaChingSound = SKAction.playSoundFileNamed("Ka-Ching.wav", waitForCompletion: false) //死亡一次消一排珠
    let MusicUpSound = SKAction.playSoundFileNamed("Music-Up.wav", waitForCompletion: false) //過關

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder) is not used in this app")
    }
    
    override init(size: CGSize) {
        super.init(size: size)

        tileHeight = size.height / 12
        tileWidth = tileHeight / 36 * 32

        swipeFromX = nil
        swipeFromY = nil

        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        let background = SKSpriteNode(imageNamed: "Background")
        background.size = size
        addChild(background)
        
        addChild(gameLayer)
        
        let layerPosition = CGPoint(x: -tileWidth * CGFloat(maxX) / 2, y: -tileHeight * CGFloat(maxY) / 2)

        tilesLayer.position = layerPosition
        gameLayer.addChild(tilesLayer)

        gameLayer.addChild(cropLayer)
        
        //// Disable Mask
        //maskLayer.position = layerPosition
        //cropLayer.maskNode = maskLayer

        cookiesLayer.position = layerPosition
        cropLayer.addChild(cookiesLayer)

        timerBarHeight = tileHeight * 0.12
        timerBar.position = CGPoint(x: 0, y: tileHeight * 4.25)
        gameLayer.addChild(timerBar)
        timer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(advanceTimer), userInfo: nil, repeats: true)

        healthBarHeight = tileHeight * 0.38
        healthBar.position = CGPoint(x: 0, y: tileHeight * 4.5)
        gameLayer.addChild(healthBar)

        turn = 0
        score = 0
        scoreAdd = 0
        maxCombo = 0
        healthBarHp = 0
        animateTurn()
        
        //view -+- background
        //      +- gameLayer -+- tilesLayer -+- tileNode(x*y)
        //                    |
        //                    +- cropLayer -+- cookiesLayer -+- cookieNode(x*y)
        //                    |             +- maskLayer -+- tileNode(x*y)
        //                    |
        //                    +- healthBar
        //                    +- timerBar
        //                    |
        //                    +- scoreLabel
        //                    +- turnLabel
        //                    +- levelLabel -+- levelButton
        //
    }
    
    override func didMove(to view: SKView) {
        //did this func when first time move atcion
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        var location = touch.location(in: cookiesLayer)
        let (success, x, y) = convertPoint(location)
        if success {
            if level.tileAt(x: x, y: y) != nil {
                if let cookie = level.cookieAt(x: x, y: y) {
                    showSelectionIndicator(for: cookie)
                    swipeFromX = x
                    swipeFromY = y
                    oriX = x
                    oriY = y
                }
            }
            isMoved = false
        }
        
        //for levelButton
        location = touch.location(in: gameLayer)
        if levelLabel.contains(location) {
            levelButton.activeButton.isHidden = false
        } else {
            levelButton.activeButton.isHidden = true
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard swipeFromX != nil && swipeFromY != nil else { return }
        guard let touch = touches.first else { return }
        var location = touch.location(in: cookiesLayer)
        let (success, x, y) = convertPoint(location)
        if success {
            var horzDelta = 0
            var vertDelta = 0
            
            if location.x > CGFloat(oriX) * tileWidth + tileWidth * 1.1 && location.y > CGFloat(oriY) * tileHeight + tileHeight * 1.1 {
                //print("Get Up-Right")
                horzDelta = 1
                vertDelta = 1
                oriX = x
                oriY = y
            } else if location.x < CGFloat(oriX) * tileWidth - tileWidth * 0.1 && location.y > CGFloat(oriY) * tileHeight + tileHeight * 1.1 {
                //print("Get Up-Left")
                horzDelta = -1
                vertDelta = 1
                oriX = x
                oriY = y
            } else if location.x > CGFloat(oriX) * tileWidth + tileWidth * 1.1 && location.y < CGFloat(oriY) * tileHeight - tileHeight * 0.1 {
                //print("Get Down-Right")
                horzDelta = 1
                vertDelta = -1
                oriX = x
                oriY = y
            } else if location.x < CGFloat(oriX) * tileWidth - tileWidth * 0.1 && location.y < CGFloat(oriY) * tileHeight - tileHeight * 0.1 {
                //print("Get Down-Left")
                horzDelta = -1
                vertDelta = -1
                oriX = x
                oriY = y
            } else if location.x > CGFloat(oriX) * tileWidth + tileWidth * 1.2 {
                //print("Get Right")
                horzDelta = 1
                oriX = x
            } else if location.x < CGFloat(oriX) * tileWidth - tileWidth * 0.2 {
                //print("Get Left")
                horzDelta = -1
                oriX = x
            } else if location.y > CGFloat(oriY) * tileHeight + tileHeight * 1.2 {
                //print("Get Up")
                vertDelta = 1
                oriY = y
            } else if location.y < CGFloat(oriY) * tileHeight - tileHeight * 0.2 {
                //print("Get Down")
                vertDelta = -1
                oriY = y
            }

            if horzDelta != 0 || vertDelta != 0 {
                if level.tileAt(x: oriX, y: oriY) != nil {
                    trySwap(horizontal: horzDelta, vertical: vertDelta)
                    swipeFromX = oriX
                    swipeFromY = oriY
                    if !isMoved {
                        playerHP = max(0, playerHP - 100)
                        turn += 1
                        animateTurn()
                    }
                    isMoved = true
                } else {
                    oriX = swipeFromX!
                    oriY = swipeFromY!
                }
            }
        }
        
        //for levelButton
        location = touch.location(in: gameLayer)
        if levelLabel.contains(location) {
            levelButton.activeButton.isHidden = false
        } else {
            levelButton.activeButton.isHidden = true
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if selectionSprite.parent != nil && swipeFromX != nil  && swipeFromY != nil {
            hideSelectionIndicator()
        }
        if swipeFromX != nil && swipeFromY != nil {
            if level.tileAt(x: oriX, y: oriY) != nil {

                if let handler = moveDoneHandler {
                    handler()
                    isMoved = false
                }
                swipeFromX = nil
                swipeFromY = nil
            }
        }
        
        
        //for levelButton
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        if levelLabel.contains(location) {
            levelButton.actionFunc(0)
        }
        levelButton.activeButton.isHidden = true
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        animateScore()
        updateTimerBar(node: timerBar)
    }

    override func didEvaluateActions() {
        let scale = 10
        if healthBarHp != playerHP {
            if healthBarHp > playerHP {
                if healthBarHp - playerHP > scale {
                    healthBarHp -= scale
                } else {
                    healthBarHp = playerHP
                }
            } else {
                if playerHP - healthBarHp > scale {
                    healthBarHp += scale
                } else {
                    healthBarHp = playerHP
                }
            }
        }
        updateHealthBar(node: healthBar)
    }

    
    func addTiles() {
        for y in 0..<maxY {
            for x in 0..<maxX {
                if level.tileAt(x: x, y: y) != nil {
                    //let tileNode = SKSpriteNode(imageNamed: "Tile")
                    let tileNode = SKSpriteNode(imageNamed: "MaskTile")
                    tileNode.size = CGSize(width: tileWidth, height: tileHeight)
                    tileNode.position = pointFor(x: x, y: y)
                    //tilesLayer.addChild(tileNode)
                    maskLayer.addChild(tileNode)
                }
            }
        }
        
        for y in 0..<maxY+1 {
            for x in 0..<maxX+1 {
                let topLeft     = (x > 0)    && (y < maxY) && level.tileAt(x: x - 1, y: y    ) != nil
                let bottomLeft  = (x > 0)    && (y > 0)    && level.tileAt(x: x - 1, y: y - 1) != nil
                let topRight    = (x < maxX) && (y < maxY) && level.tileAt(x: x,     y: y    ) != nil
                let bottomRight = (x < maxX) && (y > 0)    && level.tileAt(x: x,     y: y - 1) != nil
                
                // The tiles are named from 0 to 15, according to the bitmask that is
                // made by combining these four values.
                //from 0b0000 to 0b1111
                let value = String(Int(bottomRight.hashValue)) + String(Int(bottomLeft.hashValue)) + String(Int(topRight.hashValue)) + String(Int(topLeft.hashValue))

                // Values 0 (no tiles), 6 and 9 (two opposite tiles) are not drawn.
                if value != "0000" && value != "0110" && value != "1001" {
                    let name = "Tile_" + value
                    let tileNode = SKSpriteNode(imageNamed: name)
                    tileNode.size = CGSize(width: tileWidth, height: tileHeight)
                    var point = pointFor(x: x, y: y)
                    point.x -= tileWidth/2
                    point.y -= tileHeight/2
                    tileNode.position = point
                    tilesLayer.addChild(tileNode)
                }
            }
        }

    }

    func addCookies(for cookies: Set<Cookie>) {
        for cookie in cookies {
            let sprite = SKSpriteNode(imageNamed: cookie.cookieType.cookieName)
            sprite.size = CGSize(width: tileWidth, height: tileHeight)
            sprite.position = pointFor(x: cookie.x, y: cookie.y)
            cookiesLayer.addChild(sprite)
            cookie.sprite = sprite
        }
    }

    func pointFor(x: Int, y: Int) -> CGPoint {
        return CGPoint(x: CGFloat(x) * tileWidth + tileWidth / 2, y: CGFloat(y) * tileHeight + tileHeight / 2)
    }

    func convertPoint(_ point: CGPoint) -> (success: Bool, x: Int, y: Int) {
        if point.x >= 0 && point.x < CGFloat(maxX) * tileWidth && point.y >= 0 && point.y < CGFloat(maxY) * tileHeight {
            return (true, Int(point.x / tileWidth), Int(point.y / tileHeight))
        } else {
            return (false, -1, -1)
        }
    }
    
    func showSelectionIndicator(for cookie: Cookie) {
        if selectionSprite.parent != nil {
            selectionSprite.removeFromParent()
        }
        if let sprite = cookie.sprite {
            let texture = SKTexture(imageNamed: cookie.cookieType.cookieName)
            selectionSprite.size = CGSize(width: tileWidth * 1.5, height: tileHeight * 1.5)
            selectionSprite.zPosition = 300
            selectionSprite.run(SKAction.sequence([SKAction.setTexture(texture), SKAction.fadeIn(withDuration: 0.1)]))
            
            sprite.addChild(selectionSprite)
            selectionSprite.alpha = 1.0
        }
    }
    
    func hideSelectionIndicator() {
        selectionSprite.run(SKAction.sequence([SKAction.fadeOut(withDuration: 0.2), SKAction.removeFromParent()]))
    }

    func trySwap(horizontal horzDelta: Int, vertical vertDelta: Int) {
        let toX = swipeFromX! + horzDelta
        let toY = swipeFromY! + vertDelta
        guard toX >= 0 && toX < maxX && toY >= 0 && toY < maxY else { return }
        if let toCookie = level.cookieAt(x: toX, y: toY), let fromCookie = level.cookieAt(x: swipeFromX!, y: swipeFromY!) {
            if let handler = swipeHandler {
                let swap = Swap(cookieA: fromCookie, cookieB: toCookie)
                handler(swap)
            }
        }
    }

    func animateSwap(_ swap: Swap, completion: @escaping () -> ()) {
        let cookieA = swap.cookieA.sprite!
        let cookieB = swap.cookieB.sprite!
        
        cookieA.zPosition = 100
        cookieB.zPosition = 90
                
        let moveA = SKAction.move(to: cookieB.position, duration: 0.0)
        moveA.timingMode = .easeInEaseOut
        cookieA.run(moveA, completion: completion)
        
        let moveB = SKAction.move(to: cookieA.position, duration: 0.05)
        moveB.timingMode = .easeInEaseOut
        cookieB.run(moveB)

        run(scrapeSound)
    }

    func animateMatchedCookies(for chains: Set<Chain>, completion: @escaping () -> ()) {
        let durationMove: TimeInterval = 0.2
        let durationScale: TimeInterval = 0.2
        let durationCombo: TimeInterval = durationMove + durationScale

        var longestDuration: TimeInterval = 0
        var delay: TimeInterval

        for chain in chains {
            delay = TimeInterval(combo - lastCombo) * (durationMove + durationScale + durationCombo)
            for cookie in chain.cookies {
                let matchCookie = cookie.sprite!
                let moveAction = SKAction.move(by: CGVector(dx: 0, dy: 10), duration: durationMove)
                moveAction.timingMode = .easeIn
                matchCookie.run(moveAction)
                matchCookie.run(SKAction.sequence([SKAction.wait(forDuration: delay), moveAction, chompSound]))

                let scaleAction = SKAction.scale(to: 0.1, duration: durationScale)
                scaleAction.timingMode = .easeOut
                matchCookie.run(SKAction.sequence([SKAction.wait(forDuration: delay + durationMove), scaleAction, SKAction.removeFromParent()]))

                longestDuration = max(longestDuration, delay + durationCombo)
            }
            combo += 1
            let comboLabel = SKLabelNode(fontNamed: "Noteworthy-Bold")
            comboLabel.fontSize = tileHeight
            comboLabel.fontColor = SKColor.magenta
            comboLabel.text = "Combo  \(combo)"
            comboLabel.horizontalAlignmentMode = .center
            comboLabel.verticalAlignmentMode = .center
            comboLabel.position = CGPoint(x: 0, y: 0)
            comboLabel.zPosition = 300
            comboLabel.isHidden = true
            gameLayer.addChild(comboLabel)
            let comboAction = SKAction.move(by: CGVector(dx: 0, dy: 50), duration: durationCombo)
            comboAction.timingMode = .easeOut

            comboLabel.run(SKAction.sequence([SKAction.wait(forDuration: delay), SKAction.unhide(), comboAction, SKAction.removeFromParent()]))

            totalEatCookies += chain.cookies.count
            let addHp = (2 + combo) * totalEatCookies
            playerHP = min(maxHealth, playerHP + addHp)
            
            scoreAdd += 60 * (chain.cookies.count - 2)
        }
        lastCombo += chains.count
        run(SKAction.wait(forDuration: longestDuration), completion: completion)
    }

    func animateFallingCookies(array2D: [[Cookie]], completion: @escaping () -> ()) {
        var longestDuration: TimeInterval = 0
        for array in array2D {
            for (idx, cookie) in array.enumerated() {
                let fallingCookie = cookie.sprite!
                let newPosition = pointFor(x: cookie.x, y: cookie.y)
                let delay = 0.05 + 0.15 * TimeInterval(idx)
                let duration = TimeInterval(((fallingCookie.position.y - newPosition.y) / tileHeight) * 0.1)
                longestDuration = max(longestDuration, duration + delay)
                let moveAction = SKAction.move(to: newPosition, duration: duration)
                moveAction.timingMode = .easeOut
                fallingCookie.run(SKAction.sequence([SKAction.wait(forDuration: delay), SKAction.group([moveAction, dripSound])]))
            }
        }
        run(SKAction.wait(forDuration: longestDuration), completion: completion)
    }

    func animateNewCookies(_ array2D: [[Cookie]], completion: @escaping () -> ()) {
        var longestDuration: TimeInterval = 0
        for array in array2D {
            let startY = array[0].y + 1
            for (idx, cookie) in array.enumerated() {
                let newCookie = SKSpriteNode(imageNamed: cookie.cookieType.cookieName)
                newCookie.size = CGSize(width: tileWidth, height: tileHeight)
                newCookie.position = pointFor(x: cookie.x, y: startY)
                cookiesLayer.addChild(newCookie)
                cookie.sprite = newCookie
                let delay = 0.05 + 0.1 * TimeInterval(array.count - idx - 1)
                let duration = TimeInterval(startY - cookie.y) * 0.05
                longestDuration = max(longestDuration, duration + delay)
                let newPosition = pointFor(x: cookie.x, y: cookie.y)
                let moveAction = SKAction.move(to: newPosition, duration: duration)
                moveAction.timingMode = .easeOut
                newCookie.alpha = 0
                newCookie.run(SKAction.sequence([SKAction.wait(forDuration: delay), SKAction.group([SKAction.fadeIn(withDuration: 0.05), moveAction, dripSound])]))
            }
        }
        run(SKAction.wait(forDuration: longestDuration), completion: completion)
    }
    
    func animateRemoveAllCookiesAtDie(for chains: Set<Chain>, completion: @escaping () -> ()) {
        var longestDuration: TimeInterval = 0
        for chain in chains {
            for cookie in chain.cookies {
                let removeCookie = cookie.sprite!

                var totalDuration: TimeInterval = 0
                var duration: TimeInterval

                duration = 0.15
                totalDuration = totalDuration + duration
                let rotateAction1 = SKAction.rotate(toAngle: CGFloat(Double.pi / 8), duration: duration)
                removeCookie.run(rotateAction1)

                duration = 0.15
                totalDuration = totalDuration + duration
                let rotateAction2 = SKAction.rotate(toAngle: CGFloat(-Double.pi / 8), duration: duration)
                removeCookie.run(SKAction.sequence([SKAction.wait(forDuration: totalDuration), rotateAction2]))

                duration = 0.15
                totalDuration = totalDuration + duration
                let rotateAction3 = SKAction.rotate(toAngle: CGFloat(0), duration: duration)
                removeCookie.run(SKAction.sequence([SKAction.wait(forDuration: totalDuration), rotateAction3]))

                duration = TimeInterval(cookie.y) * 0.15
                totalDuration = totalDuration + duration
                let newPosition = pointFor(x: cookie.x, y: 0)
                let moveAction = SKAction.move(to: newPosition, duration: duration)
                moveAction.timingMode = .easeIn
                removeCookie.run(SKAction.sequence([SKAction.wait(forDuration: totalDuration), moveAction, kaChingSound]))
                
                duration = TimeInterval(cookie.y) * 0.10
                totalDuration = totalDuration + duration
                let scaleAction = SKAction.scale(to: 0.1, duration: duration)
                scaleAction.timingMode = .easeIn
                removeCookie.run(SKAction.sequence([SKAction.wait(forDuration: totalDuration), scaleAction, SKAction.removeFromParent()]))
                
                longestDuration = max(longestDuration, totalDuration)
            }
        }
        run(SKAction.wait(forDuration: longestDuration), completion: completion)
    }

    func animateRemoveAllCookiesAtFinish(for chains: Set<Chain>, completion: @escaping () -> ()) {
        run(MusicUpSound)

        var longestDuration: TimeInterval = 0
        for chain in chains {
            for cookie in chain.cookies.reversed() {
                let removeCookie = cookie.sprite!
                
                var totalDuration: TimeInterval = 0
                var duration: TimeInterval
                
                duration = TimeInterval(maxY - cookie.y) * 0.15
                totalDuration = totalDuration + duration
                let newPosition = pointFor(x: cookie.x, y: maxY - 1)
                let moveAction = SKAction.move(to: newPosition, duration: duration)
                moveAction.timingMode = .easeIn
                removeCookie.run(SKAction.sequence([SKAction.wait(forDuration: totalDuration), moveAction]))
                
                duration = TimeInterval(maxY - cookie.y) * 0.10
                totalDuration = totalDuration + duration
                let scaleAction = SKAction.scale(to: 0.1, duration: duration)
                scaleAction.timingMode = .easeIn
                removeCookie.run(SKAction.sequence([SKAction.wait(forDuration: totalDuration), scaleAction, SKAction.removeFromParent()]))
                
                longestDuration = max(longestDuration, totalDuration)
            }
        }
        run(SKAction.wait(forDuration: longestDuration), completion: completion)
    }
    
    func animateBeginGame(_ completion: @escaping () -> ()) {
        let action = SKAction.fadeIn(withDuration: 2.0)
        gameLayer.run(action, completion: completion)
    }
    
    func animateGameOver(_ completion: @escaping () -> ()) {
        let action = SKAction.fadeOut(withDuration: 1.0)
        gameLayer.run(action, completion: completion)
    }

    func animateTurn() {
        if turnLabel != nil {
            turnLabel?.removeFromParent()
        }
        turnLabel = SKLabelNode(fontNamed: "Noteworthy-Bold")
        turnLabel?.verticalAlignmentMode = .center
        turnLabel?.fontSize = tileHeight * 0.4
        turnLabel?.fontColor = SKColor.blue
        turnLabel?.text = "Turn \(turn)"
        turnLabel?.position = CGPoint(x: tileWidth * 2.2, y: tileHeight * 5)
        turnLabel?.zPosition = 300
        gameLayer.addChild(turnLabel!)
        
        var totalDuration: TimeInterval = 0
        var duration: TimeInterval

        duration = 0.5
        totalDuration = totalDuration + duration
        let moveAction = SKAction.move(by: CGVector(dx: 0, dy: 10), duration: duration)
        moveAction.timingMode = .linear
        let scaleAction = SKAction.scale(by: 2.0, duration: duration)
        scaleAction.timingMode = .linear
        turnLabel?.run(SKAction.group([moveAction, scaleAction]))
        
        duration = 0.5
        totalDuration = totalDuration + duration
        turnLabel?.run(SKAction.group([SKAction.wait(forDuration: totalDuration), moveAction.reversed(), scaleAction.reversed()]))
    }

    func animateScore() {
        if scoreAdd != 0 {
            // scoreAdd flying from buttom, and scale to 0.5 into score
            let scoreAddLabel = SKLabelNode(fontNamed: "Noteworthy-Bold")
            scoreAddLabel.verticalAlignmentMode = .center
            scoreAddLabel.fontSize = tileHeight * 0.4
            scoreAddLabel.fontColor = UIColor(red: 0.1, green: 0.9, blue: 0.1, alpha:0.9)
            scoreAddLabel.text = String(format: "+ %ld", scoreAdd)
            scoreAddLabel.position = CGPoint(x: 0, y:  tileHeight * 4)
            scoreAddLabel.zPosition = 350
            gameLayer.addChild(scoreAddLabel)
            
            let moveAction = SKAction.move(by: CGVector(dx: 0, dy: tileHeight), duration: 0.6)
            moveAction.timingMode = .easeOut
            let scaleAction = SKAction.scale(by: 0.5, duration: 0.6)
            scaleAction.timingMode = .easeOut
            scoreAddLabel.run(SKAction.sequence([SKAction.group([moveAction, scaleAction]),SKAction.removeFromParent()]))
        }

        if scoreLabel != nil {
            scoreLabel?.removeFromParent()
        }
        scoreLabel = SKLabelNode(fontNamed: "Noteworthy-Bold")
        scoreLabel?.verticalAlignmentMode = .center
        scoreLabel?.fontSize = tileHeight * 0.4
        scoreLabel?.fontColor = UIColor(red: 0.0, green: 0.8, blue: 0.0, alpha:1)
        score += scoreAdd
        scoreAdd = 0
        scoreLabel?.text = String(format: "%ld", score)
        scoreLabel?.position = CGPoint(x: 0, y:  tileHeight * 5)
        scoreLabel?.zPosition = 300
        gameLayer.addChild(scoreLabel!)
    }
    
    func showLevel(_ level: Int) {
        levelLabel = SKLabelNode(fontNamed: "Noteworthy-Bold")
        levelLabel.verticalAlignmentMode = .center
        levelLabel?.fontSize = tileHeight * 0.4
        levelLabel?.fontColor = SKColor.white
        levelLabel?.position = CGPoint(x: tileWidth * -2.2, y: tileHeight * 5)
        levelLabel?.zPosition = 300
        levelLabel?.text = String(format: "Lv %ld", level + 1)
        gameLayer.addChild(levelLabel)

        let size = CGSize(width: tileWidth * 1.5, height: tileHeight * 0.5)
        levelButton = SKButton(defaultImage: "Button", activeImage: "ButtonActive", size: size, action: loadLevelSelect)
        levelLabel.addChild(levelButton)
    }
    
    func loadLevelSelect(_: Int) {
        if let handler = roomHandler {
            handler()
            isMoved = false
        }
    }
    
    func updateTimerBar(node: SKSpriteNode) {
        let timerBarWidth: CGFloat = tileWidth * CGFloat(maxX)
        //let timerBarHeight: CGFloat = 5
        
        let barSize = CGSize(width: timerBarWidth, height: timerBarHeight)
        
        let fillColor = UIColor(red: 113.0/255, green: 202.0/255, blue: 53.0/255, alpha:1)
        let borderColor = UIColor(red: 35.0/255, green: 28.0/255, blue: 40.0/255, alpha:1)
        
        // create drawing context
        UIGraphicsBeginImageContextWithOptions(barSize, false, 0)
        let context = UIGraphicsGetCurrentContext()
        
        // draw the outline for the health bar
        borderColor.setStroke()
        let borderRect = CGRect(origin: .zero, size: barSize)
        context!.stroke(borderRect, width: 1)
        
        // draw the health bar with a colored rectangle
        fillColor.setFill()
        let barWidth = (barSize.width - 1) * CGFloat(moveTime) / CGFloat(level.moveTime)
        let barRect = CGRect(x: 0.5, y: 0.5, width: barWidth, height: barSize.height - 1)
        context!.fill(barRect)
        
        // extract image
        let spriteImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // set sprite texture and size
        node.texture = SKTexture(image: spriteImage!)
        node.size = barSize
    }

    func updateHealthBar(node: SKSpriteNode) {//}, completion: @escaping () -> ()) {
        let healthBarWidth: CGFloat = tileWidth * CGFloat(maxX)
        //let healthBarHeight: CGFloat = 20
        
        let barSize = CGSize(width: healthBarWidth, height: healthBarHeight)
        
        //255, 0, 0 -> red (hp = 0%)
        //125, 0 , 0 -> orange (hp = 50%)
        //255, 255, 0 -> yellow (hp = 100%)
        let fillColor = UIColor(red: 1.0, green: CGFloat(playerHP)/CGFloat(maxHealth), blue: 0.0, alpha:1)
        
        let borderColor = UIColor(red: 35.0/255, green: 28.0/255, blue: 40.0/255, alpha:1)
        
        // create drawing context
        UIGraphicsBeginImageContextWithOptions(barSize, false, 0)
        let context = UIGraphicsGetCurrentContext()
        
        // draw the outline for the health bar
        borderColor.setStroke()
        let borderRect = CGRect(origin: .zero, size: barSize)
        context!.stroke(borderRect, width: 1)
        
        // draw the health bar with a colored rectangle
        fillColor.setFill()
        let barWidth = (barSize.width - 1) * CGFloat(healthBarHp) / CGFloat(maxHealth)
        let barRect = CGRect(x: 0.5, y: 0.5, width: barWidth, height: barSize.height - 1)
        context!.fill(barRect)
        
        // extract image
        let spriteImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // set sprite texture and size
        node.texture = SKTexture(image: spriteImage!)
        node.size = barSize
        
        let action = SKAction.fadeIn(withDuration: 0.5)
        node.run(action)
    }

    @objc func advanceTimer() {
        if isMoved {
            moveTime = max(0, moveTime - 0.05)
        }

        if moveTime == 0 {
            playerHP = max(0, playerHP - 100)
            if let handler = moveDoneHandler {
                hideSelectionIndicator()
                handler()
                isMoved = false
                moveTime = level.moveTime
                swipeFromX = nil
                swipeFromY = nil
            }
        }
    }

    
}
