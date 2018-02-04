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
let maxHealth: Int = 1000
let maxTime: Double = 20.0
let maxDice: Int = 6
let maxLevels: Int = 50

class Level {
    fileprivate var cookies = Array2D<Cookie>(x: maxX, y: maxY)
    fileprivate var tiles = Array2D<Tile>(x: maxY, y: maxY)

    var lealth: Int = 0
    var moveTime: Double = 0
    var dice: Int = 0

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
        dice = dictionary["Dice"] as! Int
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
                        cookieType = CookieType.random(dice)
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
    
    //DFS
    private func detectMatches() -> Set<Chain> {
        struct Node {
            var x: Int
            var y: Int
            var dir: Int
        }
        
        var set = Set<Chain>()
        var defectMap = [[CookieType]]()
        var nodeMap = [[Bool]]()
        let isDebug = false

        func printDebug(_ isEnable: Bool, _ string: String) {
            if isEnable {
                print(string)
            }
        }

        //建立可更動的defectMap
        for x in 0..<maxX {
            defectMap.append([CookieType]())
            nodeMap.append([Bool]())
            for y in 0..<maxY {
                defectMap[x].append((cookies[x, y]?.cookieType)!)
                nodeMap[x].append(false)
            }
        }

        //搜尋defectMap 所有的元素, 從(0, 0)開始
        var xx = 0
        var yy = 0
        while xx < maxX || yy < maxY {
            var x = xx
            var y = yy
        
            //取得要比對的Cookie Type
            if let type = cookies[x, y]?.cookieType {
                var point = Set<String>()
                var route = [Node]()

                for i in 0..<maxX {
                    for j in 0..<maxY {
                        nodeMap[i][j] = false
                    }
                }
                
                //建立起始點
                route.append(Node(x: x, y: y, dir: 16))
                printDebug(isDebug, "Add node: (\(x), \(y)) - Root")
                nodeMap[x][y] = true
                //往上左右下，找不到退回原方向
                repeat {
                    var match = false
                    
                    if route[route.count - 1].dir == 0 {
                        printDebug(isDebug, "Remove node: (\(route[route.count - 1].x), \(route[route.count - 1].y))")
                        route.remove(at: route.count - 1)
                    }

                    if !route.isEmpty {
                        x = route[route.count - 1].x
                        y = route[route.count - 1].y
                    } else {
                        printDebug(isDebug, "Remove Root - Finish")
                        print("")
                        break
                    }
                    
                    //Center (for special pattern: cross, double-hori, double-vert, etc...)
                    if route[route.count - 1].dir == 16 {
                        route[route.count - 1].dir = 8
                        printDebug(isDebug, "Change node: (\(route[route.count - 1].x), \(route[route.count - 1].y)) - Up")
                        func addNode(_ x: Int, _ y: Int) {
                            let idx = String(x) + " " + String(y)
                            point.insert(idx)
                            if !nodeMap[x][y] {
                                route.append(Node(x: x, y: y, dir: 16))
                                printDebug(isDebug, "Add node: (\(x), \(y)) - Center")
                                nodeMap[x][y] = true
                            }
                        }
                        //HHH
                        //  HCH
                        if x >= 3 && y >= 0 && x < maxX-1 && y < maxY-1 {
                            if defectMap[x-1][y] == type && defectMap[x+1][y] == type && defectMap[x-3][y+1] == type && defectMap[x-2][y+1] == type && defectMap[x-1][y+1] == type {
                                match = true
                                addNode(x - 1, y)
                                addNode(x + 1, y)
                                addNode(x - 3, y + 1)
                                addNode(x - 2, y + 1)
                                addNode(x - 1, y + 1)
                            }
                        }
                        //HHH
                        // HCH
                        if x >= 2 && y >= 0 && x < maxX-1 && y < maxY-1 {
                            if defectMap[x-1][y] == type && defectMap[x+1][y] == type && defectMap[x-2][y+1] == type && defectMap[x-1][y+1] == type && defectMap[x][y+1] == type {
                                match = true
                                addNode(x - 1, y)
                                addNode(x + 1, y)
                                addNode(x - 2, y + 1)
                                addNode(x - 1, y + 1)
                                addNode(x    , y + 1)
                            }
                        }
                        //HHH
                        //HCH
                        if x >= 1 && y >= 0 && x < maxX-1 && y < maxY-1 {
                            if defectMap[x-1][y] == type && defectMap[x+1][y] == type && defectMap[x-1][y+1] == type && defectMap[x][y+1] == type && defectMap[x+1][y+1] == type {
                                match = true
                                addNode(x - 1, y)
                                addNode(x + 1, y)
                                addNode(x - 1, y + 1)
                                addNode(x    , y + 1)
                                addNode(x + 1, y + 1)
                            }
                        }
                        // HHH
                        //HCH
                        if x >= 1 && y >= 0 && x < maxX-2 && y < maxY-1 {
                            if defectMap[x-1][y] == type && defectMap[x+1][y] == type && defectMap[x][y+1] == type && defectMap[x+1][y+1] == type && defectMap[x+2][y+1] == type {
                                match = true
                                addNode(x - 1, y)
                                addNode(x + 1, y)
                                addNode(x    , y + 1)
                                addNode(x + 1, y + 1)
                                addNode(x + 2, y + 1)
                            }
                        }
                        //  HHH
                        //HCH
                        if x >= 1 && y >= 0 && x < maxX-3 && y < maxY-1 {
                            if defectMap[x-1][y] == type && defectMap[x+1][y] == type && defectMap[x+1][y+1] == type && defectMap[x+2][y+1] == type && defectMap[x+3][y+1] == type {
                                match = true
                                addNode(x - 1, y)
                                addNode(x + 1, y)
                                addNode(x + 1, y + 1)
                                addNode(x + 2, y + 1)
                                addNode(x + 3, y + 1)
                            }
                        }
                        //HCH
                        if x >= 1 && x < maxX-1 {
                            if defectMap[x-1][y] == type && defectMap[x+1][y] == type {
                                match = true
                                addNode(x - 1, y)
                                addNode(x + 1, y)
                            }
                        }
                        // V
                        // V
                        //VV
                        //C
                        //V
                        if x >= 0 && y >= 1 && x < maxX-1 && y < maxY-3 {
                            if defectMap[x][y-1] == type && defectMap[x][y+1] == type && defectMap[x+1][y+1] == type && defectMap[x+1][y+2] == type  && defectMap[x+1][y+3] == type {
                                match = true
                                addNode(x    , y - 1)
                                addNode(x    , y + 1)
                                addNode(x + 1, y + 1)
                                addNode(x + 1, y + 2)
                                addNode(x + 1, y + 3)
                            }
                        }
                        // V
                        //VV
                        //CV
                        //V
                        if x >= 0 && y >= 1 && x < maxX-1 && y < maxY-2 {
                            if defectMap[x][y-1] == type && defectMap[x][y+1] == type && defectMap[x+1][y] == type && defectMap[x+1][y+1] == type  && defectMap[x+1][y+2] == type {
                                match = true
                                addNode(x    , y - 1)
                                addNode(x    , y + 1)
                                addNode(x + 1, y)
                                addNode(x + 1, y + 1)
                                addNode(x + 1, y + 2)
                            }
                        }
                        //VV
                        //CV
                        //VV
                        if x >= 0 && y >= 1 && x < maxX-1 && y < maxY-1 {
                            if defectMap[x][y-1] == type && defectMap[x][y+1] == type && defectMap[x+1][y-1] == type && defectMap[x+1][y] == type  && defectMap[x+1][y+1] == type {
                                match = true
                                addNode(x    , y - 1)
                                addNode(x    , y + 1)
                                addNode(x + 1, y - 1)
                                addNode(x + 1, y)
                                addNode(x + 1, y + 1)
                            }
                        }
                        //V
                        //VV
                        //VC
                        // V
                        if x >= 1 && y >= 1 && x < maxX && y < maxY-2 {
                            if defectMap[x][y-1] == type && defectMap[x][y+1] == type && defectMap[x-1][y] == type && defectMap[x-1][y+1] == type  && defectMap[x-1][y+2] == type {
                                match = true
                                addNode(x    , y - 1)
                                addNode(x    , y + 1)
                                addNode(x - 1, y)
                                addNode(x - 1, y + 1)
                                addNode(x - 1, y + 2)
                            }
                        }
                        //
                        //V
                        //VV
                        // C
                        // V
                        if x >= 1 && y >= 1 && x < maxX && y < maxY-3 {
                            if defectMap[x][y-1] == type && defectMap[x][y+1] == type && defectMap[x-1][y+1] == type && defectMap[x-1][y+2] == type  && defectMap[x-1][y+3] == type {
                                match = true
                                addNode(x    , y - 1)
                                addNode(x    , y + 1)
                                addNode(x - 1, y + 1)
                                addNode(x - 1, y + 2)
                                addNode(x - 1, y + 3)
                            }
                        }
                        //V
                        //C
                        //V
                        if y >= 1 && y < maxY-1 {
                            if defectMap[x][y-1] == type && defectMap[x][y+1] == type {
                                match = true
                                addNode(x    , y - 1)
                                addNode(x    , y + 1)
                            }
                        }
                    }
                    if match {
                        continue
                    }
                    
                    //Up
                    if route[route.count - 1].dir == 8 {
                        route[route.count - 1].dir = 4
                        printDebug(isDebug, "Change node: (\(route[route.count - 1].x), \(route[route.count - 1].y)) - Left")
                        if y < maxY-2 {
                            if defectMap[x][y+1] == type && defectMap[x][y+2] == type {
                                match = true
                                repeat {
                                    let idx = String(x) + " " + String(y)
                                    point.insert(idx)
                                    if y < maxY {
                                        if !nodeMap[x][y] {
                                            route.append(Node(x: x, y: y, dir: 16))
                                            printDebug(isDebug, "Add node: (\(x), \(y)) - Center")
                                            nodeMap[x][y] = true
                                        }
                                    }
                                    y += 1
                                } while y < maxY && defectMap[x][y] == type
                                y -= 1
                            }
                        }
                    }
                    if match {
                        continue
                    }

                    //Left
                    if route[route.count - 1].dir == 4 {
                        route[route.count - 1].dir = 2
                        printDebug(isDebug, "Change node: (\(route[route.count - 1].x), \(route[route.count - 1].y)) - Down")
                        if x >= 2 {
                            if defectMap[x-1][y] == type && defectMap[x-2][y] == type {
                                match = true
                                repeat {
                                    let idx = String(x) + " " + String(y)
                                    point.insert(idx)
                                    if x >= 0 {
                                        if !nodeMap[x][y] {
                                            route.append(Node(x: x, y: y, dir: 16))
                                            printDebug(isDebug, "Add node: (\(x), \(y)) - Center")
                                            nodeMap[x][y] = true
                                        }
                                    }
                                    x -= 1
                                } while x >= 0 && defectMap[x][y] == type
                                x += 1
                            }
                        }
                    }
                    if match {
                        continue
                    }
                    
                    //Down
                    if route[route.count - 1].dir == 2 {
                        route[route.count - 1].dir = 1
                        printDebug(isDebug, "Change node: (\(route[route.count - 1].x), \(route[route.count - 1].y)) - Right")
                        if y >= 2 {
                            if defectMap[x][y-1] == type && defectMap[x][y-2] == type {
                                match = true
                                repeat {
                                    let idx = String(x) + " " + String(y)
                                    point.insert(idx)
                                    if y >= 0 {
                                        if !nodeMap[x][y] {
                                            route.append(Node(x: x, y: y, dir: 16))
                                            printDebug(isDebug, "Add node: (\(x), \(y)) - Center")
                                            nodeMap[x][y] = true
                                        }
                                    }
                                    y -= 1
                                } while y >= 0 && defectMap[x][y] == type
                                y += 1
                            }
                        }
                    }
                    if match {
                        continue
                    }
                    
                    //Right
                    if route[route.count - 1].dir == 1 {
                        route[route.count - 1].dir = 0
                        printDebug(isDebug, "Change node: (\(route[route.count - 1].x), \(route[route.count - 1].y)) - Finish")
                        if x < maxX-2 {
                            if defectMap[x+1][y] == type && defectMap[x+2][y] == type{
                                match = true
                                repeat {
                                    let idx = String(x) + " " + String(y)
                                    point.insert(idx)
                                    if x < maxX {
                                        if !nodeMap[x][y] {
                                            route.append(Node(x: x, y: y, dir: 16))
                                            printDebug(isDebug, "Add node: (\(x), \(y)) - Center")
                                            nodeMap[x][y] = true
                                        }
                                    }
                                    x += 1
                                } while x < maxX && defectMap[x][y] == type
                                x -= 1
                            }
                        }
                    }
                    
                    if route.isEmpty {
                        printDebug(isDebug, "Remove Root - Finish")
                        print("")
                    }
                } while !route.isEmpty
                if !point.isEmpty {
                    let chain = Chain()
                    for idx in point {
                        let xy = idx.split(separator: " ")
                        let x = Int(xy[0]) ?? 0
                        let y = Int(xy[1]) ?? 0
                        chain.add(cookie: cookies[x, y]!)
                        printDebug(isDebug, "Match Chain: (\(x), \(y))")
                        defectMap[x][y] = CookieType.unknown
                    }
                    printDebug(isDebug, "")
                    if chain.length != 0 {
                        set.insert(chain)
                    }
                }
            }
            xx += 1
            if xx == maxX && yy == maxY-1 {
                break
            } else if xx == maxX {
                xx = 0
                yy += 1
            }
        }
        
        return set
    }

    func removeMatches() -> Set<Chain> {
        let chains = detectMatches()
        removeCookies(chains: chains)

        return chains
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
            let chain = Chain()
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
                        newCookieType = CookieType.random(dice)
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


