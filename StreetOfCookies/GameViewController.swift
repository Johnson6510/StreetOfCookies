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
import CoreData

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
    
    // for CoreData
    var appDelegate: AppDelegate!
    var context: NSManagedObjectContext!

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
        
        appDelegate = UIApplication.shared.delegate as! AppDelegate
        context = appDelegate.persistentContainer.viewContext
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
        scene.animateLevel(levelNum)
        
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
        scene.maxCombo = max(scene.maxCombo, scene.combo)
        scene.combo = 0
        scene.lastCombo = 0
        scene.totalEatCookies = 0
        scene.moveTime = level.moveTime

        if scene.playerHP == 0 {
            print("Game Over!!")
            let chains = level.removeAllCookies()
            scene.animateRemoveAllCookiesAtDie(for: chains) {
                self.gameOverPanel.image = UIImage(named: "GameOver")
                self.showGameOver()
            }
        } else if scene.playerHP == maxHealth {
            print("Next Level Open!!")
            let chains = level.removeAllCookies()
            scene.animateRemoveAllCookiesAtFinish(for: chains) {
                self.saveLevelClearInformation()
                self.gameOverPanel.image = UIImage(named: "LevelComplete")
                self.showGameOver()
                self.currentLevel = self.currentLevel < maxLevels ? self.currentLevel + 1 : 1
            }
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

        setupLevel(levelNum: currentLevel)
        
        print("Re-Start Game!!")
    }

    func saveLevelClearInformation() {
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "LevelEntity")
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "level == %d", currentLevel)
        request.returnsObjectsAsFaults = false
        do {
            let levels = try context.fetch(request)
            print("Count", levels.count)
            if levels.count == 1 {
                print("Level Infornation Changed, Level: ", currentLevel)
                let change: LevelEntity = levels.first as! LevelEntity
                change.setValue(scene.score, forKey: "score")
                change.setValue(scene.maxCombo, forKey: "combo")
                change.setValue(scene.turn, forKey: "turn")
                print("Level: ", change)
            } else {
                print("Level Infornation Append, Level: ", currentLevel)
                let entity = NSEntityDescription.entity(forEntityName: "LevelEntity", in: context)
                let new = NSManagedObject(entity: entity!, insertInto: context)
                
                new.setValue(currentLevel, forKey: "level")
                new.setValue(scene.score, forKey: "score")
                new.setValue(scene.maxCombo, forKey: "combo")
                new.setValue(scene.turn, forKey: "turn")
                print("Level: ", new)
            }
            
        } catch {
            print("Failed")
        }

        do {
            try context.save()
        } catch {
            print("Failed saving")
        }
    }


}
