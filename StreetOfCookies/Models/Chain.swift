//
//  Chain.swift
//  StreetOfCookies
//
//  Created by 黃健偉 on 2018/1/28.
//  Copyright © 2018年 黃健偉. All rights reserved.
//

func ==(lhs: Chain, rhs: Chain) -> Bool {
    return lhs.cookies == rhs.cookies
}

class Chain: Hashable, CustomStringConvertible {
    var cookies = [Cookie]()
    
    func add(cookie: Cookie) {
        cookies.append(cookie)
    }

    func firstCookie() -> Cookie {
        return cookies[0]
    }
    
    func lastCookie() -> Cookie {
        return cookies[cookies.count - 1]
    }
    
    var length: Int {
        return cookies.count
    }
    
    var description: String {
        return "cookies:\(cookies)"
    }
    
    var hashValue: Int {
        return cookies.reduce (0) { $0.hashValue ^ $1.hashValue }
    }
}

