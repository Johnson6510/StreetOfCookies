//
//  GameViewController.swift
//  StreetOfCookies
//
//  Created by 黃健偉 on 2018/1/26.
//  Copyright © 2018年 黃健偉. All rights reserved.
//
//  https://www.raywenderlich.com/125311/make-game-like-candy-crush-spritekit-swift-part-1
//  https://www.raywenderlich.com/132114/make-game-like-candy-crush-spritekit-swift-part-2
//  https://www.raywenderlich.com/132117/make-game-like-candy-crush-spritekit-swift-part-3
//  https://www.raywenderlich.com/125313/make-game-like-candy-crush-spritekit-swift-part-4
//

import UIKit
import SpriteKit
//import GameplayKit
import AVFoundation

class GameViewController: UIViewController {

    var scene: GameScene!
    var level: Level!
    
    lazy var backgroundMusic: AVAudioPlayer? = {
        guard let url = Bundle.main.url(forResource: "Mining by Moonlight", withExtension: "mp3") else {
            return nil
        }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            return player
        } catch {
            return nil
        }
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let view = self.view as! SKView? {
            view.isMultipleTouchEnabled = false
            view.showsFPS = true
            view.showsNodeCount = true

            // Create and configure the scene.
            scene = GameScene(size: view.bounds.size)
            scene.scaleMode = .aspectFill

            level = Level(filename: "Level_0")
            scene.level = level
            scene.swipeHandler = handleSwipe
            scene.moveDoneHandler = handleMoveDone
            scene.addTiles()

            // Present the scene.
            view.presentScene(scene)

            beginGame()
            backgroundMusic?.play()
        }
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    func beginGame() {
        shuffle()
    }
    
    func shuffle() {
        let newCookies = level.shuffle()
        scene.addCookies(for: newCookies)
    }
    
    func handleSwipe(_ swap: Swap) {
        view.isUserInteractionEnabled = false
        level.performSwap(swap: swap)
        scene.animate(swap, completion: {})
    }
    
    func handleMoveDone() {
        self.handleMatches()
    }
    
    func handleMatches() {
        view.isUserInteractionEnabled = false
        
        let chains = level.removeMatches()
        scene.chain += chains.count

        if chains.count == 0 {
            beginNextTurn()
            return
        }

        scene.animateMatchedCookies(for: chains) {
            let array2D = self.level.fillHoles()
            self.scene.animateFallingCookies(array2D: array2D) {
                let array2D = self.level.topUpCookies()
                self.scene.animateNewCookies(array2D) {
                    self.handleMatches()
                }
            }
        }
    }
    
    func beginNextTurn() {
        view.isUserInteractionEnabled = true
        scene.chain = 0
        
        if scene.playerHP == 0 {
            print("Game Over!!")
        } else if scene.playerHP == maxHealth {
            print("Next Level Open!!")
        }
        
    }

}
