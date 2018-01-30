//
//  Level.swift
//  StreetOfCookies
//
//  Created by 黃健偉 on 2018/1/26.
//  Copyright © 2018年 黃健偉. All rights reserved.
//

import Foundation

let maxX = 6
let maxY = 8
let maxLevels = 9
let maxHealth: Int = 1000
let maxTime: Double = 20.0

class Level {
    fileprivate var cookies = Array2D<Cookie>(x: maxX, y: maxY)
    fileprivate var tiles = Array2D<Tile>(x: maxY, y: maxY)

    var lealth: Int = 0
    var moveTime: Double = 0

    init(filename: String) {
        guard let dictionary = Dictionary<String, AnyObject>.loadJSONFromBundle(filename: filename) else { return }
        guard let tilesArray = dictionary["tiles"] as? [[Int]] else { return }
        for (yArrayIndex, yArrayValue) in tilesArray.enumerated() {
            let y = maxY - yArrayIndex - 1
            for (x, value) in yArrayValue.enumerated() {
                if value == 1 {
                    tiles[x, y] = Tile()
                }
            }
        }
        lealth = dictionary["Health"] as! Int
        moveTime = dictionary["Time"] as! Double
    }

    func cookieAt(x: Int, y: Int) -> Cookie? {
        assert(x >= 0 && x < maxX)
        assert(y >= 0 && y < maxY)
        return cookies[x, y]
    }

    func tileAt(x: Int, y: Int) -> Tile? {
        assert(x >= 0 && x < maxX)
        assert(y >= 0 && y < maxY)
        return tiles[x, y]
    }

    func shuffle() -> Set<Cookie> {
        return createInitialCookies()
    }
    
    private func createInitialCookies() -> Set<Cookie> {
        var set = Set<Cookie>()
        
        for y in 0..<maxY {
            for x in 0..<maxX {
                if tiles[x, y] != nil {
                    var cookieType: CookieType
                    repeat {
                        cookieType = CookieType.random()
                    } while (x >= 2 && cookies[x - 1, y]?.cookieType == cookieType && cookies[x - 2, y]?.cookieType == cookieType) || (y >= 2 && cookies[x, y - 1]?.cookieType == cookieType && cookies[x, y - 2]?.cookieType == cookieType)
                    let cookie = Cookie(x: x, y: y, cookieType: cookieType)
                    cookies[x, y] = cookie
                    set.insert(cookie)
                }
            }
        }
        
        return set
    }
    
    func performSwap(swap: Swap) {
        let xA = swap.cookieA.x
        let yA = swap.cookieA.y
        let xB = swap.cookieB.x
        let yB = swap.cookieB.y
        
        cookies[xA, yA] = swap.cookieB
        swap.cookieB.x = xA
        swap.cookieB.y = yA
        
        cookies[xB, yB] = swap.cookieA
        swap.cookieA.x = xB
        swap.cookieA.y = yB
    }
    
    private func detectHorizontalMatches() -> Set<Chain> {
        var set = Set<Chain>()
        for y in 0..<maxY {
            var x = 0
            while x < maxX-2 {
                if let cookie = cookies[x, y] {
                    let matchType = cookie.cookieType
                    if cookies[x + 1, y]?.cookieType == matchType && cookies[x + 2, y]?.cookieType == matchType {
                        let chain = Chain(chainType: .horizontal)
                        repeat {
                            chain.add(cookie: cookies[x, y]!)
                            x += 1
                        } while x < maxX && cookies[x, y]?.cookieType == matchType
                        
                        set.insert(chain)
                        continue
                    }
                }
                x += 1
            }
        }
        
        return set
    }
    
    private func detectVerticalMatches() -> Set<Chain> {
        var set = Set<Chain>()
        for x in 0..<maxX {
            var y = 0
            while y < maxY-2 {
                if let cookie = cookies[x, y] {
                    let matchType = cookie.cookieType
                    if cookies[x, y + 1]?.cookieType == matchType && cookies[x, y + 2]?.cookieType == matchType {
                        let chain = Chain(chainType: .vertical)
                        repeat {
                            chain.add(cookie: cookies[x, y]!)
                            y += 1
                        } while y < maxY && cookies[x, y]?.cookieType == matchType
                        
                        set.insert(chain)
                        continue
                    }
                }
                y += 1
            }
        }
        
        return set
    }
    
    private func detectCrossChains(horizontalChains: Set<Chain>, verticalChains: Set<Chain>) -> Set<Chain> {
        var set = Set<Chain>()
        var crossSet = Set<Chain>()
        
        var matchCookie: Bool = false
        var matchCookies: Bool = false
        var matchChain: Bool = false
        //var matchCount: Int = 0

        //如果H_chain在V_set中重複出現，H_chain不寫入set，但記錄有cross發生
        //如果H_chain沒有在V_set中出現，H_chain寫入chain
        //完成迴圈後，將V_set寫入set
        for horizontalChain in horizontalChains {
            for verticalChain in verticalChains {
                //如果H_chain和V_chain的cookieType一樣，開始比較，new一個chain
                //如果H_cookie在V_chain中重複出現，H_cookie不寫入chain，但記錄有cross發生
                //如果H_cookie沒有在V_chain中出現，H_cookie寫入chain
                //完成迴圈後，如果記錄有cross發生，將V_chain寫入chain，並寫入set中
                if horizontalChain.firstCookie().cookieType == verticalChain.firstCookie().cookieType {
                    let chain = Chain(chainType: .cross)
                    for horizontalCookie in horizontalChain.cookies {
                        for verticalCookie in verticalChain.cookies {
                            print("Compare:", horizontalCookie, verticalCookie)
                            if horizontalCookie == verticalCookie {
                                matchCookie = true
                                matchCookies = true
                                matchChain = true
                                //matchCount += 1
                            }
                        }
                        if !matchCookie {
                            chain.add(cookie: horizontalCookie)
                            print("Add_H_Cookie: ", horizontalCookie)
                        } else {
                            print("Match!!")
                            matchCookie = false
                        }
                    }
                    for verticalCookie in verticalChain.cookies {
                        chain.add(cookie: verticalCookie)
                        print("Add_V_Cookie: ", verticalCookie)
                    }
                    if matchCookies {
                        print("Add_chain!!!")
                        crossSet.insert(chain)
                        matchCookie = false
                    }
                }
            }
            if !matchChain {
                set.insert(horizontalChain)
            }
            matchChain = false
        }
        for verticalChain in verticalChains {
            for clossChain in crossSet {
                if verticalChain.firstCookie().cookieType == clossChain.firstCookie().cookieType {
                    for verticalCookie in verticalChain.cookies {
                        for clossCookie in clossChain.cookies {
                            if clossCookie == verticalCookie {
                                matchCookie = true
                                //matchCount += 1
                                break
                            }
                        }
                        if matchCookie { break }
                    }
                    if matchCookie { break }
                }
            }
            if !matchCookie {
                set.insert(verticalChain)
            } else {
                matchCookie = false
            }
        }
        
        //for clossChain in crossSet {
        //    set.insert(clossChain)
        //}
        //
        
//        //return set
//        if matchCount == 0 {
            set.formUnion(crossSet)
            return set
//        } else {
//            return detectCrossChains(horizontalChains: set, verticalChains: crossSet)
//        }
    }
    
    func removeMatches() -> Set<Chain> {
        let horizontalChains = detectHorizontalMatches()
        let verticalChains = detectVerticalMatches()
        let mergeChains = detectCrossChains(horizontalChains: horizontalChains, verticalChains: verticalChains)
        print(mergeChains)
        //removeCookies(chains: horizontalChains)
        //removeCookies(chains: verticalChains)
        removeCookies(chains: mergeChains)
        //print(mergeChains)

        return mergeChains
        //return horizontalChains.union(verticalChains)
    }
    
    private func removeCookies(chains: Set<Chain>) {
        for chain in chains {
            for cookie in chain.cookies {
                cookies[cookie.x, cookie.y] = nil
            }
        }
    }
    
    func removeAllCookies() -> Set<Chain> {
        var set = Set<Chain>()
        for y in 0..<maxY {
            let chain = Chain(chainType: .horizontal)
            for x in 0..<maxX {
                if tiles[x, y] != nil {
                    chain.add(cookie: cookies[x, y]!)
                    cookies[x, y] = nil
                }
            }
            set.insert(chain)
        }
        
        return set
    }
    
    func fillHoles() -> [[Cookie]] {
        var array2D = [[Cookie]]()
        for x in 0..<maxX {
            var array = [Cookie]()
            for y in 0..<maxY {
                if tiles[x, y] != nil && cookies[x, y] == nil {
                    for lookup in (y + 1)..<maxY {
                        if let cookie = cookies[x, lookup] {
                            cookies[x, y] = cookie
                            cookies[x, lookup] = nil
                            cookie.y = y
                            array.append(cookie)
                            break
                        }
                    }
                }
            }
            if !array.isEmpty {
                array2D.append(array)
            }
        }
        return array2D
    }
    
    func topUpCookies() -> [[Cookie]] {
        var array2D = [[Cookie]]()
        var cookieType: CookieType = .unknown
        for x in 0..<maxX {
            var array = [Cookie]()
            var y = maxY - 1
            while y >= 0 && cookies[x, y] == nil {
                if tiles[x, y] != nil {
                    var newCookieType: CookieType
                    repeat {
                        newCookieType = CookieType.random()
                    } while newCookieType == cookieType
                    cookieType = newCookieType
                    let cookie = Cookie(x: x, y: y, cookieType: cookieType)
                    cookies[x, y] = cookie
                    array.append(cookie)
                }
                y -= 1
            }
            if !array.isEmpty {
                array2D.append(array)
            }
        }
        return array2D
    }

}

struct Array2D<T> {
    let x: Int
    let y: Int
    fileprivate var array: Array<T?>
    
    init(x: Int, y: Int) {
        self.x = x
        self.y = y
        array = Array<T?>(repeating: nil, count: x * y)
    }
    
    subscript(x: Int, y: Int) -> T? {
        get {
            return array[y * maxX + x]
        }
        set {
            array[y * maxX + x] = newValue
        }
    }
}

extension Dictionary {
    static func loadJSONFromBundle(filename: String) -> Dictionary<String, AnyObject>? {
        var dataOK: Data
        var dictionaryOK: NSDictionary = NSDictionary()
        if let path = Bundle.main.path(forResource: filename, ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: NSData.ReadingOptions()) as Data!
                dataOK = data!
            }
            catch {
                print("Could not load level file: \(filename), error: \(error)")
                return nil
            }
            do {
                let dictionary = try JSONSerialization.jsonObject(with: dataOK, options: JSONSerialization.ReadingOptions()) as AnyObject!
                dictionaryOK = (dictionary as! NSDictionary as? Dictionary<String, AnyObject>)! as NSDictionary
            }
            catch {
                print("Level file '\(filename)' is not valid JSON: \(error)")
                return nil
            }
        }
        
        return dictionaryOK as? Dictionary<String, AnyObject>
    }
}


