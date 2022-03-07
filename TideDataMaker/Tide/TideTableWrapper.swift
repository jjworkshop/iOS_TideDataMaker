//
//  TideTableWrapper.swift
//  SurfTideDelta
//
//  Created by Mitsuhiro Shirai on 2018/07/18.
//  Copyright © 2018年 Mitsuhiro Shirai. All rights reserved.
//

import UIKit

class TideTableWrapper: NSObject {
    
    enum UpAndDown {
        case up
        case down
    }
    
    struct HightAndLow {
        var isHi: Bool
        var index: Int
        var high: Int
        var low: Int
        var p30: Int
        var p70: Int
        init(isHi: Bool, index: Int, high: Int, low: Int) {
            self.isHi = isHi
            self.index = index
            self.high = high
            self.low = low
            p30 = Int(round(Double(high - low) * 0.3))
            p70 = Int(round(Double(high - low) * 0.7))
        }
    }
    
    var currentDate: Date? = nil
    var tideTable = TideTable()                     // タイドテーブル
    
    // タイドテーブルを更新
    func make(_ date:Date, load:Bool) {
        if let tideTable = tideTable {
            tideTable.make(0, yy:Int32(date.year), mm: Int32(date.month), dd: Int32(date.day), load: load)
            currentDate = date
        }
    }
    func makeEx(_ date:Date) {
        if let tideTable = tideTable {
            tideTable.makeEx(Int32(date.year), mm: Int32(date.month), dd: Int32(date.day))
            currentDate = date
        }
    }
    func makeWk(_ date:Date, name: String) {
        if let tideTable = tideTable {
            tideTable.makeWk(name, yy:Int32(date.year), mm: Int32(date.month), dd: Int32(date.day))
            currentDate = date
        }
    }
    func makeWatch(_ date:Date, name: String) {
        if let tideTable = tideTable {
            tideTable.makeWatch(name, yy:Int32(date.year), mm: Int32(date.month), dd: Int32(date.day))
            currentDate = date
        }
    }

    
    // 上げ下げの３分７分のテーブルを作成（前後合わせて３日分のタイドテーブルから作成）
    func getFishingTable() -> Array<Int> {
        var array: Array<Int> = Array<Int>()
        for _ in 0..<73 { array.append(0) }
        if var dt = currentDate {
            var heightTbl: Array<Int> = Array<Int>()
            dt = dt.added(day:-1)
            let wkTbl = TideTableWrapper()
            wkTbl.make(dt, load: true)
            for _ in 0...2 {
                for i in 0..<73 {
                    heightTbl.append(wkTbl.yPosArray[i].intValue)
                }
                dt = dt.added(day:1)
                wkTbl.make(dt, load: false)
            }
            var direction  = heightTbl[0] < heightTbl[1] ? UpAndDown.up : UpAndDown.down
            var high:Int? = nil
            var low:Int? = nil
            var changeDirection = false
            var conditions: Array<HightAndLow> = Array<HightAndLow>()
            for i in 1..<219-1 {  // 73 × 3日分
                if (direction == UpAndDown.up) {
                    // 上げに動いている
                    if (heightTbl[i] > heightTbl[i+1]) {
                        // 下げに変わった
                        changeDirection = true
                        high = heightTbl[i]
                    }
                    
                }
                else {
                    // 下げに動いている
                    if (heightTbl[i] < heightTbl[i+1]) {
                        // 上げげに変わった
                        changeDirection = true
                        low = heightTbl[i]
                    }
                }
                if (changeDirection && high != nil && low != nil) {
                    // 上げ下げの条件がそろった
                    conditions.append(HightAndLow(isHi: direction == UpAndDown.up, index: i, high: high!, low: low!))
                }
                if (changeDirection) {
                    // 方向を変換
                    direction = direction == UpAndDown.up ? UpAndDown.down : UpAndDown.up
                }
                changeDirection = false
            }
            // 上げ下げの3分７分をアナライズ
            for condition in conditions {
                if (condition.index > 73) {
                    var i  = condition.index
                    let from = heightTbl[i]
                    if (condition.isHi) {
                        // 上げ方向にチェック
                        let to   = from - condition.p70
                        while (heightTbl.indices.contains(i) && heightTbl[i] >= to) {
                            let idx = i - 73
                            if (idx >= 0 && idx < 73 && (heightTbl[i] <= (from - condition.p30))) {
                                array[idx] = 1  // 上げに向かってる
                                //Com.XLOG("上方向[\(idx)] - [T:\(heightTbl[i])] hight:\(condition.high)) low:\(condition.low) 30％:\(condition.p30)) 70％:\(condition.p70)")
                            }
                            i -= 1
                        }
                    }
                    else {
                        // 下げ方向にチェック
                        let to   = from + condition.p70
                        while (heightTbl.indices.contains(i) && heightTbl[i] <= to) {
                            let idx = i - 73
                            if (idx >= 0 && idx < 73 && (heightTbl[i] >= (from + condition.p30))) {
                                array[idx] = -1  // 下げに向かってる
                                //Com.XLOG("下方向[\(idx)] - [T:\(heightTbl[i])] hight:\(condition.high)) low:\(condition.low) 30％:\(condition.p30)) 70％:\(condition.p70)")
                            }
                            i -= 1
                        }
                    }
                }
            }
        }
        return array
    }
    
    // 各種ゲッター
    var lat: CGFloat {
        get { return CGFloat(tideTable?.td2_lat() ?? 0) }
    }
    var lon: CGFloat {
        get { return CGFloat(tideTable?.td2_lon() ?? 0) }
    }
    var np: String {
        get { return tideTable?.td2_NP() ?? "" }
    }
    var sio: String {
        get { return tideTable?.coef_Sio() ?? "" }
    }
    var graphscale: CGFloat {
        get {
            return CGFloat(tideTable?.coef_graphscale() ?? 1)
        }
    }
    var tc0: CGFloat {
        get { return CGFloat(tideTable?.td2_TC0() ?? 0) }
    }
    var range: CGFloat {
        get { return CGFloat(tideTable?.coef_Range() ?? 0) }
    }
    var sunRise: CGFloat {
        get { return CGFloat(tideTable?.sunRise() ?? 0) }
    }
    var sunSet: CGFloat {
        get { return CGFloat(tideTable?.sunSet() ?? 0) }
    }
    var dr: CGFloat {
        get { return CGFloat(tideTable?.coef_DR() ?? 0) }
    }
    var smd12: CGFloat {
        get { return CGFloat(tideTable?.coef_SMD12() ?? 0) }
    }
    var yPosArray: [NSNumber] {
        get {
            return tideTable?.coef_yPosArray() as? [NSNumber] ?? []
        }
    }
    var hiAndLowTextArray: [String] {
        get {
            return tideTable?.coef_hiAndLowArray() as? [String] ?? []
        }
    }
    var sEventArray: [NSNumber] {
        get {
            return tideTable?.coef_SEventArray() as? [NSNumber] ?? []
        }
    }
    var age: CGFloat {
        get { return CGFloat(tideTable?.coef_AGE() ?? 0) }
    }
    var ilum: CGFloat {
        get { return CGFloat(tideTable?.coef_ILUM() ?? 0) }
    }
    var mEventArray: [NSNumber] {
        get {
            return tideTable?.coef_MEventArray() as? [NSNumber] ?? []
        }
    }
    var tInfoArray: [String] {
        get {
            return tideTable?.td2_TInfoArray() as? [String] ?? []
        }
    }
}
