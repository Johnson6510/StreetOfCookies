//
//  GameScene.swift
//  StreetOfCookies
//
//  Created by 黃健偉 on 2018/1/26.
//  Copyright © 2018年 黃健偉. All rights reserved.
//

import SpriteKit
//import GameplayKit

class GameScene: SKScene {
    var level: Level!
    
    let tileWidth: CGFloat = 32
    let tileHeight: CGFloat = 36
    
    let gameLayer = SKNode()
    let cookiesLayer = SKNode()
    let tilesLayer = SKNode()

    private var swipeFromCol: Int?
    private var swipeFromRow: Int?

    private var swipeFrom: CGPoint?

    var selectionSprite = SKSpriteNode()

    var swipeHandler: ((Swap) -> ())?
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder) is not used in this app")
    }
    
    override init(size: CGSize) {
        super.init(size: size)

        swipeFromCol = nil
        swipeFromRow = nil
        swipeFrom = nil

        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        let background = SKSpriteNode(imageNamed: "Background")
        background.size = size
        addChild(background)
        
        addChild(gameLayer)
        
        let layerPosition = CGPoint(x: -tileWidth * CGFloat(maxCol) / 2, y: -tileHeight * CGFloat(maxRow) / 2)
            
        tilesLayer.position = layerPosition
        gameLayer.addChild(tilesLayer)

        cookiesLayer.position = layerPosition
        gameLayer.addChild(cookiesLayer)

        //view -+- background             +- tileNode(col*row)
        //      +- gameLayer -+- tilesLayer
        //                   -+- cookiesLayer
        //                                  +- cookieNode(col*row)
    }
    
    override func didMove(to view: SKView) {
        //did this func when first time move atcion
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: cookiesLayer)
        let (success, col, row) = convertPoint(location)
        if success {
            if let cookie = level.cookieAt(col: col, row: row) {
                showSelectionIndicator(for: cookie)
                swipeFromCol = col
                swipeFromRow = row
                swipeFrom = location
            }
        }
        print("Begin (\(swipeFromRow ?? -1), \(swipeFromCol ?? -1))")
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard swipeFromCol != nil else { return }
        guard let touch = touches.first else { return }
        let location = touch.location(in: cookiesLayer)
        let (temp, oriCol, oriRow) = convertPoint(swipeFrom!)
        if temp {
            let (success, col, row) = convertPoint(location)
            if success && !(swipeFromCol == col && swipeFromRow == row) {
                var horzDelta = 0
                var vertDelta = 0
                if location.x - (swipeFrom?.x)! > tileWidth * 0.5 || (swipeFrom?.x)! - location.x > tileWidth * 0.5 {
                    horzDelta = col - swipeFromCol!
                    print("X moved")
                }
                if location.y - (swipeFrom?.y)! > tileHeight * 0.5 || (swipeFrom?.y)! - location.y  > tileHeight * 0.5 {
                    vertDelta = row - swipeFromRow!
                    print("Y moved")
                }
                if horzDelta != 0 || vertDelta != 0 {
                    print("Move (\(row), \(col))")
                    trySwap(horizontal: horzDelta, vertical: vertDelta)
                    if horzDelta == 0 {
                        swipeFromCol = oriCol
                    } else {
                        swipeFromCol = col
                    }
                    if vertDelta == 0 {
                        swipeFromRow = oriRow
                    } else {
                        swipeFromRow = row
                    }
                    swipeFrom = location
                }
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if selectionSprite.parent != nil && swipeFromCol != nil {
            hideSelectionIndicator()
        }
        swipeFromCol = nil
        swipeFromRow = nil
        swipeFrom = nil
        print("End (\(swipeFromRow ?? -1), \(swipeFromCol ?? -1))")
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }

    func addTiles() {
        for row in 0..<maxRow {
            for col in 0..<maxCol{
                if level.tileAt(col: col, row: row) != nil {
                    let tileNode = SKSpriteNode(imageNamed: "Tile")
                    tileNode.size = CGSize(width: tileWidth, height: tileHeight)
                    tileNode.position = pointFor(col: col, row: row)
                    tilesLayer.addChild(tileNode)
                }
            }
        }
    }

    func addCookies(for cookies: Set<Cookie>) {
        for cookie in cookies {
            let sprite = SKSpriteNode(imageNamed: cookie.cookieType.cookieName)
            sprite.size = CGSize(width: tileWidth, height: tileHeight)
            sprite.position = pointFor(col: cookie.col, row: cookie.row)
            cookiesLayer.addChild(sprite)
            cookie.sprite = sprite
        }
    }

    func pointFor(col: Int, row: Int) -> CGPoint {
        return CGPoint(x: CGFloat(col) * tileWidth + tileWidth / 2, y: CGFloat(row) * tileHeight + tileHeight / 2)
    }

    func convertPoint(_ point: CGPoint) -> (success: Bool, col: Int, row: Int) {
        if point.x >= 0 && point.x < CGFloat(maxCol) * tileWidth && point.y >= 0 && point.y < CGFloat(maxRow) * tileHeight {
            return (true, Int(point.x / tileWidth), Int(point.y / tileHeight))
        } else {
            return (false, 0, 0)
        }
    }
    
    func trySwap(horizontal horzDelta: Int, vertical vertDelta: Int) {
        let toCol = swipeFromCol! + horzDelta
        let toRow = swipeFromRow! + vertDelta
        guard toCol >= 0 && toCol < maxCol && toRow >= 0 && toRow < maxRow else { return }
        if let toCookie = level.cookieAt(col: toCol, row: toRow),
            let fromCookie = level.cookieAt(col: swipeFromCol!, row: swipeFromRow!) {
            print("Swapping (\(swipeFromRow ?? -1), \(swipeFromCol ?? -1)) <-> (\(toRow), \(toCol))")
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
        
        let duration: TimeInterval = 0.2
        
        let moveA = SKAction.move(to: spriteB.position, duration: duration)
        moveA.timingMode = .easeOut
        spriteA.run(moveA, completion: completion)
        
        let moveB = SKAction.move(to: spriteA.position, duration: duration)
        moveB.timingMode = .easeOut
        spriteB.run(moveB)
    }

    func showSelectionIndicator(for cookie: Cookie) {
        if selectionSprite.parent != nil {
            selectionSprite.removeFromParent()
        }
        if let sprite = cookie.sprite {
            let texture = SKTexture(imageNamed: cookie.cookieType.cookieName)
            selectionSprite.size = CGSize(width: tileWidth * 1.5, height: tileHeight * 1.5)
            selectionSprite.run(SKAction.setTexture(texture))
            
            sprite.addChild(selectionSprite)
            selectionSprite.alpha = 1.0
        }
    }

    func hideSelectionIndicator() {
        selectionSprite.run(SKAction.sequence([SKAction.fadeOut(withDuration: 0.03), SKAction.removeFromParent()]))
    }


}
