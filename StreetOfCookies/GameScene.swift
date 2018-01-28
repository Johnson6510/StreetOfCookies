//
//  GameScene.swift
//  StreetOfCookies
//
//  Created by 黃健偉 on 2018/1/26.
//  Copyright © 2018年 黃健偉. All rights reserved.
//

import SpriteKit
//import GameplayKit
import AVFoundation

let maxHealth = 1000
let maxTime: Double = 3.0

class GameScene: SKScene {
    var level: Level!
    
    let tileWidth: CGFloat = 32 * 1.8
    let tileHeight: CGFloat = 36 * 1.8
    
    let gameLayer = SKNode()
    let cookiesLayer = SKNode()
    let tilesLayer = SKNode()
    
    let playerHealthBar = SKSpriteNode()
    var playerHP = maxHealth / 2

    let timerBar = SKSpriteNode()
    var time = maxTime
    weak var timer: Timer?

    var chain: Int = 0

    private var swipeFromX: Int?
    private var swipeFromY: Int?
    private var oriX = -1
    private var oriY = -1
    
    private var isMoved = false

    var selectionSprite = SKSpriteNode()

    var swipeHandler: ((Swap) -> ())?
    var moveDoneHandler: (() -> ())?

    // Pre-load sounds
    let scrapeSound = SKAction.playSoundFileNamed("Scrape.wav", waitForCompletion: false)
    let chompSound = SKAction.playSoundFileNamed("Chomp.wav", waitForCompletion: false)
    let dripSound = SKAction.playSoundFileNamed("Drip.wav", waitForCompletion: false)

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder) is not used in this app")
    }
    
    override init(size: CGSize) {
        super.init(size: size)

        swipeFromX = nil
        swipeFromY = nil

        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        timer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(advanceTimer), userInfo: nil, repeats: true)

        let background = SKSpriteNode(imageNamed: "Background")
        background.size = size
        addChild(background)
        
        addChild(gameLayer)
        
        let layerPosition = CGPoint(x: -tileWidth * CGFloat(maxX) / 2, y: -tileHeight * CGFloat(maxY) / 2)
            
        tilesLayer.position = layerPosition
        gameLayer.addChild(tilesLayer)

        cookiesLayer.position = layerPosition
        gameLayer.addChild(cookiesLayer)

        playerHealthBar.position = CGPoint(x: 0, y: 300)
        gameLayer.addChild(playerHealthBar)
        timerBar.position = CGPoint(x: 0, y: 295)
        gameLayer.addChild(timerBar)

        //view -+- background
        //      +- gameLayer -+- tilesLayer -+- tileNode(x*y)
        //                    |
        //                    +- cookiesLayer -+- cookieNode(x*y)
        //                    |
        //                    +- playerHealthBar
        //                    +- timerBar
    }
    
    override func didMove(to view: SKView) {
        //did this func when first time move atcion
        updateHealthBar(node: playerHealthBar, hp: playerHP)
        updateTimerBar(node: timerBar, time: time)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: cookiesLayer)
        let (success, x, y) = convertPoint(location)
        if success {
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
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard swipeFromX != nil && swipeFromY != nil else { return }
        guard let touch = touches.first else { return }
        let location = touch.location(in: cookiesLayer)
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
                trySwap(horizontal: horzDelta, vertical: vertDelta)
                swipeFromX = oriX
                swipeFromY = oriY
                isMoved = true
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if selectionSprite.parent != nil && swipeFromX != nil  && swipeFromY != nil {
            hideSelectionIndicator()
        }
        if swipeFromX != nil && swipeFromY != nil {
            if isMoved {
                playerHP = max(0, playerHP - 100)
            }
            if let handler = moveDoneHandler {
                handler()
                isMoved = false
                time = maxTime
            }
            swipeFromX = nil
            swipeFromY = nil
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        updateHealthBar(node: playerHealthBar, hp: playerHP)
        updateTimerBar(node: timerBar, time: time)
    }

    func addTiles() {
        for y in 0..<maxY {
            for x in 0..<maxX{
                if level.tileAt(x: x, y: y) != nil {
                    let tileNode = SKSpriteNode(imageNamed: "Tile")
                    tileNode.size = CGSize(width: tileWidth, height: tileHeight)
                    tileNode.position = pointFor(x: x, y: y)
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

    func animate(_ swap: Swap, completion: @escaping () -> ()) {
        let spriteA = swap.cookieA.sprite!
        let spriteB = swap.cookieB.sprite!
        
        spriteA.zPosition = 100
        spriteB.zPosition = 90
                
        let moveA = SKAction.move(to: spriteB.position, duration: 0.0)
        moveA.timingMode = .easeInEaseOut
        spriteA.run(moveA, completion: completion)
        
        let moveB = SKAction.move(to: spriteA.position, duration: 0.1)
        moveB.timingMode = .easeInEaseOut
        spriteB.run(moveB)

        run(scrapeSound)
    }

    func animateMatchedCookies(for chains: Set<Chain>, completion: @escaping () -> ()) {
        var removeCount = 0
        for chain in chains {
            for cookie in chain.cookies {
                if let sprite = cookie.sprite {
                    if sprite.action(forKey: "removing") == nil {
                        removeCount += 1
                        let scaleAction = SKAction.scale(to: 0.1, duration: 0.3)
                        scaleAction.timingMode = .easeOut
                        sprite.run(SKAction.sequence([scaleAction, SKAction.removeFromParent()]),
                                   withKey:"removing")
                    }
                }
            }
        }
        run(SKAction.wait(forDuration: 0.3), completion: completion)
        
        let addHp = (1 + chain) * removeCount
        print("Hp = ", playerHP, ", Chain = ", chain ,", Cookie = ", removeCount, ", Hp add ", addHp)
        playerHP = min(maxHealth, playerHP + addHp)
        print("Hp = ", playerHP)
        
        run(chompSound)
    }

    func animateFallingCookies(array2D: [[Cookie]], completion: @escaping () -> ()) {
        var longestDuration: TimeInterval = 0
        for array in array2D {
            for (idx, cookie) in array.enumerated() {
                let sprite = cookie.sprite!
                let newPosition = pointFor(x: cookie.x, y: cookie.y)
                let delay = 0.05 + 0.15 * TimeInterval(idx)
                let duration = TimeInterval(((sprite.position.y - newPosition.y) / tileHeight) * 0.1)
                longestDuration = max(longestDuration, duration + delay)
                let moveAction = SKAction.move(to: newPosition, duration: duration)
                moveAction.timingMode = .easeOut
                sprite.run(SKAction.sequence([SKAction.wait(forDuration: delay), SKAction.group([moveAction, dripSound])]))
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

    func updateHealthBar(node: SKSpriteNode, hp: Int) {
        let healthBarWidth: CGFloat = tileWidth * CGFloat(maxX)
        let healthBarHeight: CGFloat = 10
        
        let barSize = CGSize(width: healthBarWidth, height: healthBarHeight);
        
        let fillColor = UIColor(red: 200.0/255, green: 50.0/255, blue: 50.0/255, alpha:1)
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
        let barWidth = (barSize.width - 1) * CGFloat(hp) / CGFloat(maxHealth)
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

    func updateTimerBar(node: SKSpriteNode, time: Double) {
        let timerBarWidth: CGFloat = tileWidth * CGFloat(maxX)
        let timerBarHeight: CGFloat = 5
        
        let barSize = CGSize(width: timerBarWidth, height: timerBarHeight);
        
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
        let barWidth = (barSize.width - 1) * CGFloat(time) / CGFloat(maxTime)
        let barRect = CGRect(x: 0.5, y: 0.5, width: barWidth, height: barSize.height - 1)
        context!.fill(barRect)
        
        // extract image
        let spriteImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // set sprite texture and size
        node.texture = SKTexture(image: spriteImage!)
        node.size = barSize
    }

    @objc func advanceTimer() {
        if isMoved {
            time = max(0, time - 0.01)
        }

        if time == 0 {
            playerHP = max(0, playerHP - 100)
            if let handler = moveDoneHandler {
                hideSelectionIndicator()
                handler()
                isMoved = false
                time = maxTime
                swipeFromX = nil
                swipeFromY = nil
            }
        }
    }

    
}
