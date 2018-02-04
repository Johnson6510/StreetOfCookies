//
//  RoomScene.swift
//  StreetOfCookies
//
//  Created by 黃健偉 on 2018/2/3.
//  Copyright © 2018年 黃健偉. All rights reserved.
//

import SpriteKit

class RoomScene: SKScene {
    
    var tileWidth: CGFloat = 32
    var tileHeight: CGFloat = 36

    let roomLayer = SKNode()

    var returnLabel: SKLabelNode!
    var returnButton: SKButton!
    
    var roomLabel = [SKLabelNode]()
    var roomButton = [SKButton]()

    var rightButton: SKButton!
    var leftButton: SKButton!
    var isRightBtnDisable: Bool = false
    var isLeftBtnDisable: Bool = false

    var returnHandler: ((Int) -> ())?
    var changeLevelHandler: ((Int) -> ())?
    
    var maxPassLevel: Int = 0
    var selectLevel: Int = 0
    
    var currectPage: Int = 0

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder) is not used in this app")
    }
    
    override init(size: CGSize) {
        super.init(size: size)

        tileHeight = size.height / 12
        tileWidth = tileHeight / 36 * 32

        anchorPoint = CGPoint(x: 0.5, y: 0.5)

        let background = SKSpriteNode(imageNamed: "Background")
        background.size = size
        background.alpha = 0.5
        addChild(background)
        addChild(roomLayer)

        returnLabel = SKLabelNode(fontNamed: "Noteworthy-Bold")
        returnLabel.verticalAlignmentMode = .center
        returnLabel?.fontSize = tileHeight * 0.4
        returnLabel?.fontColor = SKColor.white
        returnLabel?.position = CGPoint(x: tileWidth * -2.2, y: tileHeight * 5)
        returnLabel?.zPosition = 300
        returnLabel?.text = String("Return")
        roomLayer.addChild(returnLabel)

        let size = CGSize(width: tileWidth * 1.5, height: tileHeight * 0.5)
        returnButton = SKButton(defaultImage: "Button", activeImage: "ButtonActive", size: size, action: returnToGame)
        returnLabel.addChild(returnButton)

        currectPage = setupRoom()
        setupArrow()
        nextPage(page: currectPage)
        
        //view -+- background
        //      +- roomLayer -+- RoomLayer -+- RoomNode(maxRoom)
        //                    |
        //                    +- returnLabel -+- returnButton
        //                    |
        //                    +- rightButton
        //                    +- leftButton
        //

    }
    
    override func didMove(to view: SKView) {
        //did this func when first time move atcion
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        if returnLabel.contains(location) {
            returnButton.activeButton.isHidden = false
        } else {
            returnButton.activeButton.isHidden = true
        }
        
        for lv in 0...maxPassLevel {
            if roomLabel[lv].contains(location) {
                roomButton[lv].activeButton.isHidden = false
            } else {
                roomButton[lv].activeButton.isHidden = true
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        if returnLabel.contains(location) {
            returnButton.activeButton.isHidden = false
        } else {
            returnButton.activeButton.isHidden = true
        }
        
        for lv in 0...maxPassLevel {
            if roomLabel[lv].contains(location) {
                roomButton[lv].activeButton.isHidden = false
            } else {
                roomButton[lv].activeButton.isHidden = true
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        if returnLabel.contains(location) {
            returnButton.actionFunc(0)
        }
        returnButton.activeButton.isHidden = true
        
        for lv in 0...maxPassLevel {
            if roomLabel[lv].contains(location) || roomButton[lv].contains(location) {
                selectLevel = lv
                roomButton[lv].actionFunc(lv)
            }
            roomButton[lv].activeButton.isHidden = true
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }

    override func update(_ currentTime: TimeInterval) {
    }
    
    override func didEvaluateActions() {
    }
    
    func setupRoom() -> Int {
        let accessData = AccessData()
        
        let roomSize = CGSize(width: tileWidth * 1.5, height: tileHeight * 1.5)
        var x: CGFloat = 0
        var y: CGFloat = 0
        var currentLevel = true
        for lv in 0..<maxLevels {
            roomLabel.append(SKLabelNode(fontNamed: "Noteworthy-Bold"))
            roomLabel[lv].verticalAlignmentMode = .center
            roomLabel[lv].fontSize = tileHeight * 0.4
            roomLabel[lv].fontColor = SKColor.white
            
            x = tileWidth * 2.0 * CGFloat(lv % 12 % 3 - 1)
            y = tileWidth * 2.0 * (CGFloat(lv % 12 / 3) - 1.5) * -1
            
            roomLabel[lv].position = CGPoint(x: x, y: y)
            roomLabel[lv].zPosition = 300
            
            let (lvPass, _, _, _) = accessData.loadLevel(level: lv)
            roomLayer.addChild(roomLabel[lv])
            
            roomButton.append(SKButton(defaultImage: "IconWhite", activeImage: "IconActive", size: roomSize, action: changeLevel))
            roomLabel[lv].addChild(roomButton[lv])
            roomButton[lv].level = lv

            if lvPass != -1 {
                roomLabel[lv].text = String(lv+1)
            } else if currentLevel {
                roomLabel[lv].text = String(format: "[%ld]", lv+1)
                maxPassLevel = lv
                currentLevel = false
            } else {
                roomLabel[lv].text = "🔒\(lv+1)"
                roomButton[lv].isEnable = false
            }
            roomLabel[lv].position = CGPoint(x: roomLabel[lv].position.x + 1000, y: roomLabel[lv].position.y)
        }
        
        return maxPassLevel / 12
    }
    
    func setupArrow() {
        let size = CGSize(width: tileWidth * 0.6, height: tileHeight * 1)
        
        rightButton = SKButton(defaultImage: "RightArrow", activeImage: "RightArrowActive", size: size, action: pagePlus)
        rightButton.position = CGPoint(x: tileWidth * 3.3, y: tileHeight * 0)
        rightButton.zPosition = 300
        roomLayer.addChild(rightButton)
        
        leftButton = SKButton(defaultImage: "LeftArrow", activeImage: "LeftArrowActive", size: size, action: pageMinus)
        leftButton.position = CGPoint(x: tileWidth * -3.3, y: tileHeight * 0)
        leftButton.zPosition = 300
        roomLayer.addChild(leftButton)
    }
    
    func nextPage(page: Int) {
        for lv in 0..<maxLevels {
            if lv / 12 == page {
                roomLabel[lv].position = CGPoint(x: roomLabel[lv].position.x - 1000, y: roomLabel[lv].position.y)
            }
        }
        
        if page == 0  {
            leftButton.position = CGPoint(x: leftButton.position.x + 1000, y: leftButton.position.y)
            isLeftBtnDisable = true
        } else if page == maxLevels / 12 {
            rightButton.position = CGPoint(x: rightButton.position.x + 1000, y: rightButton.position.y)
            isRightBtnDisable = true
        } else {
            if isLeftBtnDisable {
                leftButton.position = CGPoint(x: leftButton.position.x - 1000, y: leftButton.position.y)
                isLeftBtnDisable = false
            }
            if isRightBtnDisable {
                rightButton.position = CGPoint(x: rightButton.position.x - 1000, y: rightButton.position.y)
                isRightBtnDisable = false
            }
        }
    }
    
    func pagePlus(_: Int) {
        for lv in 0..<maxLevels {
            if lv / 12 == currectPage {
                roomLabel[lv].position = CGPoint(x: roomLabel[lv].position.x + 1000, y: roomLabel[lv].position.y)
            }
        }
        currectPage += 1
        nextPage(page: currectPage)
    }
    
    func pageMinus(_: Int) {
        for lv in 0..<maxLevels {
            if lv / 12 == currectPage {
                roomLabel[lv].position = CGPoint(x: roomLabel[lv].position.x + 1000, y: roomLabel[lv].position.y)
            }
        }
        currectPage -= 1
        nextPage(page: currectPage)
    }
    
    func changeLevel(_ lv: Int) {
        if let handler = changeLevelHandler {
            handler(lv)
        }
    }

    func returnToGame(_: Int) {
        if let handler = returnHandler {
        handler(0)
        }
    }
    
}
