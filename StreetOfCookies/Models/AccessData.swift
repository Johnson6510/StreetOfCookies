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
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "LevelEntity")
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "level == %d", level)
        request.returnsObjectsAsFaults = false
        do {
            let levels = try context.fetch(request)
            print("Count", levels.count)
            if levels.count == 1 {
                print("Level Infornation Changed, Level: ", level)
                let change: LevelEntity = levels.first as! LevelEntity
                change.setValue(score, forKey: "score")
                change.setValue(combo, forKey: "combo")
                change.setValue(turn, forKey: "turn")
                print("Level: ", change)
            } else {
                print("Level Infornation Append, Level: ", level)
                let entity = NSEntityDescription.entity(forEntityName: "LevelEntity", in: context)
                let new = NSManagedObject(entity: entity!, insertInto: context)
                
                new.setValue(level, forKey: "level")
                new.setValue(score, forKey: "score")
                new.setValue(combo, forKey: "combo")
                new.setValue(turn, forKey: "turn")
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
    
    func loadLevel(level: Int) -> (Int, Int, Int, Int) {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "LevelEntity")
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "level == %d", level)
        request.returnsObjectsAsFaults = false
        do {
            let levels = try context.fetch(request)
            print("Count", levels.count)
            if levels.count == 1 {
                print("Level Infornation Changed, Level: ", level)
                let change: LevelEntity = levels.first as! LevelEntity
                let score = change.value(forKey: "score")
                let combo = change.value(forKey: "combo")
                let turn = change.value(forKey: "turn")
                print("Level: ", change)
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
