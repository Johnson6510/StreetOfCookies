//
//  AccessData.swift
//  StreetOfCookies
//
//  Created by 黃健偉 on 2018/2/4.
//  Copyright © 2018年 黃健偉. All rights reserved.
//

import UIKit
import CoreData

class AccessData {
    var appDelegate: AppDelegate!
    var context: NSManagedObjectContext!

    init() {
        appDelegate = UIApplication.shared.delegate as! AppDelegate
        context = appDelegate.persistentContainer.viewContext
    }

    func saveLevel(level: Int, score: Int, combo: Int, turn: Int) {
        print("Level", level, score, combo, turn)
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "LevelEntity")
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "level == %d", level)
        request.returnsObjectsAsFaults = false
        do {
            let levels = try context.fetch(request)
            if levels.count == 1 {
                let change: LevelEntity = levels.first as! LevelEntity
                
                let orgScore = change.value(forKey: "score") as! Int
                let orgCombo = change.value(forKey: "combo") as! Int
                let orgTurn = change.value(forKey: "turn") as! Int
                if score > orgScore {
                    change.setValue(score, forKey: "score")
                }
                if combo > orgCombo {
                    change.setValue(combo, forKey: "combo")
                }
                if turn > orgTurn {
                    change.setValue(turn, forKey: "turn")
                }
                
                print("Level Infornation Changed, Level: ", change)
            } else {
                let entity = NSEntityDescription.entity(forEntityName: "LevelEntity", in: context)
                let new = NSManagedObject(entity: entity!, insertInto: context)
                
                new.setValue(level, forKey: "level")
                new.setValue(score, forKey: "score")
                new.setValue(combo, forKey: "combo")
                new.setValue(turn, forKey: "turn")
                print("Level Infornation Append, Level: ", new)
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
    
    func loadLevel(level: Int) -> (Int, Int, Int, Int) {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "LevelEntity")
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "level == %d", level)
        request.returnsObjectsAsFaults = false
        do {
            let levels = try context.fetch(request)
            if levels.count == 1 {
                let change: LevelEntity = levels.first as! LevelEntity
                let score = change.value(forKey: "score")
                let combo = change.value(forKey: "combo")
                let turn = change.value(forKey: "turn")
                print("Level Infornation Loaded, Level: ", change)
                return (level, score as! Int, combo as! Int, turn as! Int)
            }
        } catch {
            print("Failed")
        }
        
        do {
            try context.save()
        } catch {
            print("Failed saving")
        }
        
        //access fail or no data
        return (-1, -1, -1, -1)
    }



}
