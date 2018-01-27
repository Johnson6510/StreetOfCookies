//
//  Cookie.swift
//  StreetOfCookies
//
//  Created by 黃健偉 on 2018/1/26.
//  Copyright © 2018年 黃健偉. All rights reserved.
//

import SpriteKit

enum CookieType: Int, CustomStringConvertible {
    case unknown = 0
    case croissant = 1
    case cupcake = 2
    case danish = 3
    case donut = 4
    case macaroon = 5
    case sugarCookie = 6
    
    var cookieName: String {
        let cookieName = [
            "Croissant",
            "Cupcake",
            "Danish",
            "Donut",
            "Macaroon",
            "SugarCookie"]
        
        return cookieName[rawValue - 1]
    }

    var description: String {
        return cookieName
    }

    static func random() -> CookieType {
        return CookieType(rawValue: Int(arc4random_uniform(6)) + 1)!
    }

}

func ==(lhs: Cookie, rhs: Cookie) -> Bool {
    return lhs.x == rhs.x && lhs.y == rhs.y
}

class Cookie: CustomStringConvertible, Hashable {
    var x: Int
    var y: Int
    let cookieType: CookieType
    var sprite: SKSpriteNode?
    

    init(x: Int, y: Int, cookieType: CookieType) {
        self.x = x
        self.y = y
        self.cookieType = cookieType
    }
    
    var description: String {
        return "type:\(cookieType) square:(\(x),\(y))"
    }
    
    var hashValue: Int {
        return y * 10 + x
    }
}

class Tile {
}

struct Swap: CustomStringConvertible {
    let cookieA: Cookie
    let cookieB: Cookie
    
    init(cookieA: Cookie, cookieB: Cookie) {
        self.cookieA = cookieA
        self.cookieB = cookieB
    }
    
    var description: String {
        return "swap \(cookieA) with \(cookieB)"
    }
}

