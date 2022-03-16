//
//  TideDbManager.swift
//  SurfTideDelta
//
//  Created by Mitsuhiro Shirai on 2018/07/02.
//  Copyright © 2018年 Mitsuhiro Shirai. All rights reserved.
//

import UIKit
import FMDB

// 場所アイテム（地域、都道府県、タイド場所で共有）
struct LocationItem {
    var level: Int
    var rno: Int
    var sno: Int
    var name: String
    init(level: Int, rno: Int, sno: Int, name: String) {
        self.level = level
        self.rno = rno
        self.sno = sno
        self.name = name
    }
}

// 場所データ詳細
struct LocationRecord {
    var sno: Int
    var NP: String
    var lat: Double
    var lon: Double
    var TC0: Double
    var wN_tbl: String
    var HR_tbl: String
    var PL_tbl: String
    init(sno:Int, NP: String, lat: Double, lon: Double, TC0: Double, wN:String, HR: String, PL: String) {
        self.sno = sno
        self.NP = NP
        self.lat = lat
        self.lon = lon
        self.TC0 = TC0
        self.wN_tbl = wN
        self.HR_tbl = HR
        self.PL_tbl = PL
    }
}


class TideDB: NSObject {
    
    static let sharedInstance = TideDB()   // シングルトン
    var db : FMDatabase? = nil
    static let db_file: String = "tide.sqlite"
    
    override init() {
        Com.XLOG("TideDB:init")
        super.init()
        DbOpen()
    }
    deinit {
        Com.XLOG("TideDB:deinit")
        db?.close()
    }
    
    // DBのパスを取得
    static public func getTideDBPath() -> String {
        return "\(Com.getLibraryPath())/\(db_file)"
    }
    
    // Place-DBを「/Library」パスへコピー
    private func copyOriginal() -> Bool {
        var letCopy = false
        let dbPath = TideDB.getTideDBPath()
        Com.XLOG("TideDB Paht:\n \(dbPath)")
        let fm = FileManager.default
        if (fm.fileExists(atPath: dbPath)) {
            Com.XLOG("Already copy: \(TideDB.db_file)")
            let newerMark = "date: 2018/7/2"  // 注意：導入するDBの設定に合わせること
            let comment: String = getDbVersionComment()
            if (comment.contains(newerMark)) {
                Com.XLOG("\tIt's NEW...")
            }
            else {
                // アップデートのためコピー
                Com.XLOG("\tIt's OLD... so Update copy")
                letCopy = true
            }
        }
        else {
            // コピー
            Com.XLOG("\tIt's initial COPY...")
            letCopy = true
        }
        if (letCopy)    {
            let orgPath = "\(Bundle.main.bundlePath)/\(TideDB.db_file)"
            do {
                if (fm.fileExists(atPath: dbPath)) {
                    try! fm.removeItem(atPath: dbPath)
                }
                try fm.copyItem(atPath: orgPath, toPath: dbPath)
                Com.XLOG("Copyed: \(TideDB.db_file)")
            }
            catch let error as NSError {
                // エラー
                Com.XLOG(error)
            }
        }
        return letCopy
    }
    
    // DBオープン
    public func DbOpen() {
        DbClose()
        let copied = copyOriginal()
        let dbPath = TideDB.getTideDBPath()
        db = FMDatabase(path: dbPath)
        db?.open()
        if (copied) {
            // コピー後に何か必要ならここにコードを書く
        }
    }
    
    // DBクローズ
    public func DbClose() {
        db?.close()
        db = nil
    }
    
    // DBオープンしている？
    public func isOpen() -> Bool {
        return (db != nil)
    }
    
    // このDBのバージョン情報を取得
    public func getDbVersionComment() -> String! {
        // これはOpenしていない状態で処理される
        assert(!isOpen(), "TideDB has been opened.(getDbVersionComment)")
        var comment: String = "none"
        let dbPath = TideDB.getTideDBPath()
        let wkdb: FMDatabase = FMDatabase(path: dbPath)
        wkdb.open()
        let sql = "select * from version where idx=0"
        do {
            let rs = try wkdb.executeQuery(sql, values: nil)
            while (rs.next()) {
                comment = rs.string(forColumn: "comment")!
            }
        }
        catch let error as NSError {
            // エラー
            Com.XLOG(error)
        }
        wkdb.close()
        return comment
    }
    
    // このDBのバージョン情報を取得（オープン後）
    public func getVersion() -> String? {
        // これはOpenしていない状態で処理される
        assert(isOpen(), "TideDB has been opened.(getVersion)")
        let sql = "select * from version where idx=0"
        do {
            let rs = try db?.executeQuery(sql, values: nil)
            while (rs?.next())! {
                return rs?.string(forColumn: "comment")!
            }
        }
        catch let error as NSError {
            // エラー
            Com.XLOG(error)
        }
        return nil
    }
    
    
    // 地域を読込（関東,中国…等）
    public func getRegion() -> Array<LocationItem> {
        assert(isOpen(), "TideDB has not been opened.(getRegion)")
        var list = Array<LocationItem>()
        let sql = "select * from region order by rno"
        do {
            let rs = try db?.executeQuery(sql, values: nil)
            while (rs?.next())! {
                let rec = LocationItem(
                    level:  1,
                    rno:    Int(rs!.int(forColumn: "rno")),
                    sno:    -1,
                    name:   (rs?.string(forColumn: Com.isJapanese ? "name" : "roman"))!
                )
                list.append(rec)
            }
        }
        catch let error as NSError {
            // エラー
            Com.XLOG(error)
        }
        return list
    }
    
    // 都道府県を読込（北海道、青森、秋田…等）
    public func getState(rno: Int) -> Array<LocationItem> {
        assert(isOpen(), "TideDB has not been opened.(getState[rno=\(rno)])")
        var list = Array<LocationItem>()
        let sql = "select * from state where rno=? order by sno"
        do {
            let rs = try db?.executeQuery(sql, values: [rno])
            while (rs?.next())! {
                let rec = LocationItem(
                    level:  2,
                    rno:    Int(rs!.int(forColumn: "rno")),
                    sno:    Int(rs!.int(forColumn: "sno")),
                    name:   (rs?.string(forColumn: Com.isJapanese ? "name" : "roman"))!
                )
                list.append(rec)
            }
        }
        catch let error as NSError {
            // エラー
            Com.XLOG(error)
        }
        return list
    }
    
    // 都道府県を読込（北海道、青森、秋田…等）
    public func getStateName(sno: Int) -> String {
        assert(isOpen(), "TideDB has not been opened.(getStateName[rno=\(sno)])")
        var name = ""
        let sql = "select * from state where sno=?"
        do {
            let rs = try db?.executeQuery(sql, values: [sno])
            while (rs?.next())! {
                name =  (rs?.string(forColumn: Com.isJapanese ? "name" : "roman"))!
                break
            }
        }
        catch let error as NSError {
            // エラー
            Com.XLOG(error)
        }
        return name
    }

    
    // 場所名を読込（名洗-H4, 鹿島-H4 …等）
    public func getLocationName(sno: Int) -> Array<LocationItem>  {
        assert(isOpen(), "TideDB has not been opened.(getLocationName[sno=\(sno)])")
        var list = Array<LocationItem>()
        let sql = "select sno,NP from td2 where sno=? order by lat DESC, lon DESC"
        do {
            let rs = try db?.executeQuery(sql, values: [sno])
            while (rs?.next())! {
                let rec = LocationItem(
                    level:  3,
                    rno:    -1,
                    sno:    sno,
                    name:   (rs?.string(forColumn: "NP"))!
                )
                list.append(rec)
            }
        }
        catch let error as NSError {
            // エラー
            Com.XLOG(error)
        }
        return list
    }
    
    // ポイント詳細データを読込（名洗-H4, 鹿島-H4 …等）：NPでユニークなので対象は１件のみ
    public func getLocationDetail(_ NP : String) -> LocationRecord? {
        assert(isOpen(), "TideDB has not been opened.(getLocationDetail[NP=\(NP)])")
        let sql = "select * from td2 where NP=?"
        do {
            let rs = try db?.executeQuery(sql, values: [NP])
            while (rs?.next())! {
                let rec = LocationRecord(
                    sno:    Int(rs!.int(forColumn: "sno")),
                    NP:     (rs?.string(forColumn: "NP"))!,
                    lat:    rs!.double(forColumn: "lat"),
                    lon:    rs!.double(forColumn: "lon"),
                    TC0:    rs!.double(forColumn: "TC0"),
                    wN:     (rs?.string(forColumn: "wN_tbl"))!,
                    HR:     (rs?.string(forColumn: "HR_tbl"))!,
                    PL:     (rs?.string(forColumn: "PL_tbl"))!
                )
                return rec
            }
        }
        catch let error as NSError {
            // エラー
            Com.XLOG(error)
        }
        return nil;
    }
    
    // 場所の件数取得
    public func getLocationCount() -> Int {
        assert(isOpen(), "TideDB has not been opened.(getLocationCount)")
        let sql = "select count(*) as count from td2"
        var count = 0
        do {
            let rs = try db?.executeQuery(sql, values: nil)
            while (rs?.next())! {
                count = Int(rs!.int(forColumn: "count"))
                break
            }
        }
        catch let error as NSError {
            // エラー
            Com.XLOG(error)
        }
        return count;
    }
    
    // 指定ロケーションに一番近いタイドの場所を探す
    public func findNearbyPlace(lat: Double, lon: Double) -> String? {
        assert(isOpen(), "TideDB has not been opened.(findNearbyPlace[\(lat) - \(lon)])")
        var miniDistance: Double = -1
        var name: String? = nil
        let sql = "select NP,lat,lon from td2"
        do {
            let rs = try db?.executeQuery(sql, values: nil)
            while (rs?.next())! {
                let lat2 = FNDG(rs!.double(forColumn: "lat"))
                let lon2 = FNDG(rs!.double(forColumn: "lon"))
                let distance = hubenyCalc(lat1: lat, lon1: lon, lat2: lat2, lon2: lon2)
                if (miniDistance == -1) {
                    miniDistance = distance;
                    name = (rs?.string(forColumn: "NP"))!
                }
                else {
                    if (miniDistance > distance) {
                        miniDistance = distance;
                        name = (rs?.string(forColumn: "NP"))!
                    }
                }
            }
        }
        catch let error as NSError {
            // エラー
            Com.XLOG(error)
        }
        return name
    }
    
    // ヒュベニ２点間の距離計算（メートルで戻す）
    func hubenyCalc(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let M_PI = 3.14159265358979323846264338327950288
        let sirad = lat1 * M_PI / 180
        let skrad = lon1 * M_PI / 180
        let syirad = lat2 * M_PI / 180
        let sykrad = lon2 * M_PI / 180
        let aveirad = (sirad + syirad) / 2
        let deffirad = sirad - syirad
        let deffkrad = skrad - sykrad
        let temp = 1 - 0.006674 * (sin(aveirad) * sin(aveirad))
        let dmrad = 6334834 / sqrt(temp * temp * temp)
        let dvrad = 6377397 / sqrt(temp)
        let t1 = dmrad * deffirad
        let t2 = dvrad * cos(aveirad) * deffkrad
        return sqrt(t1 * t1 + t2 * t2)
    }

    // 度分表示形式（dd.mm）の角度を度の単位に直す
    public func FNDG(_ X: Double) -> Double {
        let intX: Double = Double(Int(X))
        return (intX + (X - intX) * 10 / 6);
    }
    
}

