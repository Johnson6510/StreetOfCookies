//
//  GameRoomScene.swift
//  StreetOfCookies
//
//  Created by 黃健偉 on 2018/2/3.
//  Copyright © 2018年 黃健偉. All rights reserved.
//

import SpriteKit

class GameRoomScene: SKScene {
    
    var tileWidth: CGFloat = 32
    var tileHeight: CGFloat = 36

    let gameRoomLayer = SKNode()

    var returnLabel: SKLabelNode!
    var returnButton: SKButton!
    
    var roomLabel = [SKLabelNode]()
    var roomButton = [SKButton]()


    var returnHandler: ((Int) -> ())?
    var changeLevelHandler: ((Int) -> ())?
    
    var maxPassLevel: Int = 0
    var selectLevel: Int = 0

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
        addChild(gameRoomLayer)

        returnLabel = SKLabelNode(fontNamed: "Noteworthy-Bold")
        returnLabel.verticalAlignmentMode = .center
        returnLabel?.fontSize = tileHeight * 0.4
        returnLabel?.fontColor = SKColor.white
        returnLabel?.position = CGPoint(x: tileWidth * -2.2, y: tileHeight * 5)
        returnLabel?.zPosition = 300
        returnLabel?.text = String("Return")
        gameRoomLayer.addChild(returnLabel)

        let size = CGSize(width: tileWidth * 1.5, height: tileHeight * 0.5)
        returnButton = SKButton(defaultImage: "Button", activeImage: "ButtonActive", size: size, action: returnToGame)        
        returnLabel.addChild(returnButton)

        setupRoom()
        
        //view -+- background
        //      +- gameRoomLayer -+- RoomLayer -+- RoomNode(x*y)
        //                        |
        //                        +- returnLabel -+- returnButton
        //                        |
        //                        +- last page (not finish yet)
        //                        +- next page (not finish yet)
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
    
    func setupRoom() {
        let accessData = AccessData()
        
        let roomSize = CGSize(width: tileWidth * 2, height: tileHeight * 2)
        var x: CGFloat = 0
        var y: CGFloat = 0
        var currentLevel = true
        for lv in 0..<maxLevels {
            roomLabel.append(SKLabelNode(fontNamed: "Noteworthy-Bold"))
            roomLabel[lv].verticalAlignmentMode = .center
            roomLabel[lv].fontSize = tileHeight * 0.4
            roomLabel[lv].fontColor = SKColor.white
            
            x = tileWidth * 2.4 * CGFloat(lv % 3 - 1)
            y = tileWidth * 2.4 * (CGFloat(lv / 3) - 1.5) * -1
            
            roomLabel[lv].position = CGPoint(x: x, y: y)
            roomLabel[lv].zPosition = 300
            
            let (lvPass, _, _, _) = accessData.loadLevel(level: lv)
            gameRoomLayer.addChild(roomLabel[lv])
            
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
                roomLabel[lv].text = "🔒"
                roomButton[lv].isEnable = false
            }
        }

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
