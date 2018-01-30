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
import AVFoundation

class GameViewController: UIViewController {

    var scene: GameScene!
    var level: Level!
    
    var currentLevel = 0
    
    var gameOverPanel: UIImageView!
    var tapGestureRecognizer: UITapGestureRecognizer!

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
            view.showsFPS = true
            view.showsNodeCount = true
        }
        
        gameOverPanel = UIImageView(frame: CGRect(x: 0, y: (view.bounds.size.height - 225) / 2, width: view.bounds.size.width, height: 225))
        view.addSubview(gameOverPanel)
        gameOverPanel.isHidden = true

        setupLevel(levelNum: currentLevel)
        backgroundMusic?.play()
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
    
    func setupLevel(levelNum: Int) {
        let view = self.view as! SKView
        view.isMultipleTouchEnabled = false
        
        scene = GameScene(size: view.bounds.size)
        scene.scaleMode = .aspectFill
        
        level = Level(filename: "Level_\(levelNum)")
        scene.level = level
        scene.addTiles()
        scene.swipeHandler = handleSwipe
        scene.moveDoneHandler = handleMoveDone

        gameOverPanel.isHidden = true
        
        view.presentScene(scene)
        beginGame()
    }

    func beginGame() {
        scene.playerHP = level.lealth
        scene.moveTime = level.moveTime
        shuffle()
    }

    func shuffle() {
        let newCookies = level.shuffle()
        scene.addCookies(for: newCookies)
    }
    
    func handleSwipe(_ swap: Swap) {
        view.isUserInteractionEnabled = false
        level.performSwap(swap: swap)
        scene.animateSwap(swap, completion: {})
    }
    
    func handleMoveDone() {
        self.handleMatches()
    }
    
    func handleMatches() {
        view.isUserInteractionEnabled = false
        
        let chains = level.removeMatches()
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
        scene.combo = 0
        scene.lastCombo = 0
        scene.totalEatCookies = 0
        scene.moveTime = level.moveTime

        if scene.playerHP == 0 {
            print("Game Over!!")
            let chains = level.removeAllCookies()
            scene.animateRemoveAllCookies(for: chains) {
                self.gameOverPanel.image = UIImage(named: "GameOver")
                self.showGameOver()
            }
        } else if scene.playerHP == maxHealth {
            print("Next Level Open!!")
        }
    }

    @objc func showGameOver() {
        gameOverPanel.isHidden = false
        scene.isUserInteractionEnabled = false
        
        self.tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideGameOver))
        self.view.addGestureRecognizer(self.tapGestureRecognizer)
    }
    
    @objc func hideGameOver() {
        view.removeGestureRecognizer(tapGestureRecognizer)
        tapGestureRecognizer = nil
        
        gameOverPanel.isHidden = true
        scene.isUserInteractionEnabled = true
        
        beginGame()
        
        print("Re-Start Game!!")
    }


}
