//
//  SKButton.swift
//  StreetOfCookies
//
//  Created by 黃健偉 on 2018/2/2.
//  Copyright © 2018年 黃健偉. All rights reserved.
//

import SpriteKit

class SKButton: SKNode {
    var defaultButton: SKSpriteNode
    var activeButton: SKSpriteNode
    var actionFunc: (Int) -> Void
    var size = CGSize()
    var isEnable = Bool()
    
    var level: Int = 0
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(defaultImage: String, activeImage: String,size: CGSize, action: @escaping (Int) -> Void) {
        defaultButton = SKSpriteNode(imageNamed: defaultImage)
        activeButton = SKSpriteNode(imageNamed: activeImage)
        defaultButton.size = size
        activeButton.size = size
        defaultButton.zPosition = -5
        activeButton.zPosition = -1
        activeButton.isHidden = true
        isEnable = true
        level = 0
        actionFunc = action

        super.init()

        isUserInteractionEnabled = true
        addChild(defaultButton)
        addChild(activeButton)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isEnable {
            guard let touch = touches.first else { return }
            let location = touch.location(in: self)
            
            if defaultButton.contains(location) {
                activeButton.isHidden = false
            } else {
                activeButton.isHidden = true
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isEnable {
            guard let touch = touches.first else { return }
            let location = touch.location(in: self)

            if defaultButton.contains(location) {
                activeButton.isHidden = false
            } else {
                activeButton.isHidden = true
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isEnable {
            guard let touch = touches.first else { return }
            let location = touch.location(in: self)

            if defaultButton.contains(location) {
                actionFunc(level)
            }
            activeButton.isHidden = true
            defaultButton.isHidden = false
        }
    }
    
}
