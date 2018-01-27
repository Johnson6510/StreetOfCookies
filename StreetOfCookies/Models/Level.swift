//
//  Level.swift
//  StreetOfCookies
//
//  Created by 黃健偉 on 2018/1/26.
//  Copyright © 2018年 黃健偉. All rights reserved.
//

import Foundation

let maxCol = 9
let maxRow = 9

class Level {
    fileprivate var cookies = Array2D<Cookie>(col: maxCol, row: maxRow)
    fileprivate var tiles = Array2D<Tile>(col: maxCol, row: maxRow)

    init(filename: String) {
        guard let dictionary = Dictionary<String, AnyObject>.loadJSONFromBundle(filename: filename) else { return }
        guard let tilesArray = dictionary["tiles"] as? [[Int]] else { return }
        for (row, rowArray) in tilesArray.enumerated() {
            let tileRow = maxRow - row - 1
            for (col, value) in rowArray.enumerated() {
                if value == 1 {
                    tiles[col, tileRow] = Tile()
                }
            }
        }
    }

    func cookieAt(col: Int, row: Int) -> Cookie? {
        assert(col >= 0 && col < maxCol)
        assert(row >= 0 && row < maxRow)
        return cookies[col, row]
    }

    func tileAt(col: Int, row: Int) -> Tile? {
        assert(col >= 0 && col < maxCol)
        assert(row >= 0 && row < maxRow)
        return tiles[col, row]
    }

    func shuffle() -> Set<Cookie> {
        return createInitialCookies()
    }
    
    private func createInitialCookies() -> Set<Cookie> {
        var set = Set<Cookie>()
        
        for row in 0..<maxRow {
            for col in 0..<maxCol {
                if tiles[col, row] != nil {
                    var cookieType = CookieType.random() // Keep 'var'. Will be mutated later
                    let cookie = Cookie(col: col, row: row, cookieType: cookieType)
                    cookies[col, row] = cookie
                    set.insert(cookie)
                }
            }
        }
        return set
    }
    
    func performSwap(swap: Swap) {
        let colA = swap.cookieA.col
        let rowA = swap.cookieA.row
        let colB = swap.cookieB.col
        let rowB = swap.cookieB.row
        
        cookies[colA, rowA] = swap.cookieB
        swap.cookieB.col = colA
        swap.cookieB.row = rowA
        
        cookies[colB, rowB] = swap.cookieA
        swap.cookieA.col = colB
        swap.cookieA.row = rowB
    }

}

struct Array2D<T> {
    let col: Int
    let row: Int
    fileprivate var array: Array<T?>
    
    init(col: Int, row: Int) {
        self.col = col
        self.row = row
        array = Array<T?>(repeating: nil, count: row * col)
    }
    
    subscript(x: Int, y: Int) -> T? {
        get {
            return array[x * col + y]
        }
        set {
            array[x * col + y] = newValue
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


