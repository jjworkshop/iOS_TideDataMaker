//
//  ViewController.swift
//  TideDataMaker
//
//  Created by Mitsuhiro Shirai on 2022/03/02.
//

import UIKit

class ViewController: UIViewController {

    let fm = FileManager.default
    let db = TideDB.sharedInstance
    let calendar = Calendar(identifier: .gregorian)
    let tideTable = TideTableWrapper()
    var histryArray: Array<TD2item> = []
    
    let JCG = "jcg"
    let from_year = 2022
    let to_year   = 2022        // TODO: DEBUG: 2041
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // データのルートパスを作成
        let dataRootPath = Com.getCachePath() + "/data"
        do {
            if fm.fileExists(atPath: dataRootPath) {
                // 既に存在している場合は一旦全部削除
                try fm.removeItem(atPath: dataRootPath)
            }
            try fm.createDirectory(atPath: dataRootPath, withIntermediateDirectories: false, attributes: nil)
        }
        catch let error as NSError {
            Com.XLOG(error)
        }

        
        // 場所データリスト取得
        var placeList: Array<LocationItem> = []
        // TODO: DEBUG: for sno in 1...80 {
        for sno in 12...12 {
            placeList += db.getLocationName(sno: sno)
        }
                
        // 場所毎データ作成の処理
        let jcgDataPath = dataRootPath + "/\(JCG)"
        do {
            try fm.createDirectory(atPath: jcgDataPath, withIntermediateDirectories: false, attributes: nil)
        }
        catch let error as NSError {
            Com.XLOG(error)
        }
        for place in placeList {
            makeData(place: place, dataPath: jcgDataPath)
        }
        
        // 潮汐名データ作成
        makeShioData(dataPath: dataRootPath)
    }


    // 場所毎のデータを作成
    func makeData(place: LocationItem, dataPath: String) {
        // タイド計算用に UserDefaults にデータを保存
        setTideDataForCalc(name: place.name)
        // 場所のタイドデータを作成
        let name = place.name.replacingOccurrences(of: "/", with: "_")
        Com.XLOG("PLACE: \(name)")
        let placePath = dataPath + "/\(name)"
        do {
            try fm.createDirectory(atPath: placePath, withIntermediateDirectories: false, attributes: nil)
            // 場所の info.dt 作成
            makeInfoDT(place: place, dataPath: placePath)
            for year in from_year...to_year {
                let yearPath = placePath + "/\(year)"
                try fm.createDirectory(atPath: yearPath, withIntermediateDirectories: false, attributes: nil)
                for month in 1...12 {
                    let motnPaht = yearPath + "/" + String(format: "%02d", month)
                    try fm.createDirectory(atPath: motnPaht, withIntermediateDirectories: false, attributes: nil)
                    let firstDate = calendar.date(from: DateComponents(year: year, month: month))!
                    let add = DateComponents(month: 1, day: -1) // １ヶ月進めて１日戻すことにより月末日を取得
                    let lastDate = calendar.date(byAdding: add, to: firstDate)!
                    for day in 1...lastDate.day {
                        // タイド計算
                        let targetDate = calendar.date(from: DateComponents(year: year, month: month, day: day))!
                        tideTable.make(targetDate, load: day == 1)
                        let prefix = "\(motnPaht)/" + String(format: "%02d", day)
                        // 場所の指定日付の DD_event.dt 作成
                        let eventFilePath = "\(prefix)_event.dt"
                        fm.createFile(atPath: eventFilePath, contents: nil, attributes: nil)
                        var file = FileHandle(forWritingAtPath: eventFilePath)!
                        makeEventDT(file: file, date: targetDate)
                        file.closeFile()
                        // 場所の指定日付の DD_tide.dt 作成
                        let tideFilePath = "\(prefix)_tide.dt"
                        fm.createFile(atPath: tideFilePath, contents: nil, attributes: nil)
                        file = FileHandle(forWritingAtPath: tideFilePath)!
                        makeTideDT(file: file, date: targetDate)
                        file.closeFile()
                    }
                }
            }
        }
        catch let error as NSError {
            Com.XLOG(error)
        }
    }
    
    // 場所毎のデータを作成
    func makeShioData(dataPath: String) {
        let shioPath = dataPath + "/sio"
        do {
            try fm.createDirectory(atPath: shioPath, withIntermediateDirectories: false, attributes: nil)
            for year in from_year...to_year {
                let yearPath = shioPath + "/\(year)"
                try fm.createDirectory(atPath: yearPath, withIntermediateDirectories: false, attributes: nil)
                for month in 1...12 {
                    let monthPaht = yearPath + "/" + String(format: "%02d", month)
                    try fm.createDirectory(atPath: monthPaht, withIntermediateDirectories: false, attributes: nil)
                    // 月毎の sio.dt 作成
                    let shioFilePath = "\(monthPaht)/sio.dt"
                    fm.createFile(atPath: shioFilePath, contents: nil, attributes: nil)
                    let file = FileHandle(forWritingAtPath: shioFilePath)!
                    makeSioDT(file: file, year: year, month: month)
                    file.closeFile()
                }
            }
        }
        catch let error as NSError {
            Com.XLOG(error)
        }
    }
    
    // 場所の info.dt 作成
    func makeInfoDT(place: LocationItem, dataPath: String) {
        let infoFilePath = "\(dataPath)/info.dt"
        fm.createFile(atPath: infoFilePath, contents: nil, attributes: nil)
        let file = FileHandle(forWritingAtPath: infoFilePath)!
        let graphscale = tideTable.graphscale
        let detail = db.getLocationDetail(place.name)!
        let lat = db.FNDG(detail.lat)
        let lon = db.FNDG(detail.lon)
        let text = "\(place.name)\t\(round((lat)*10000)/10000)\t\(round((lon)*10000)/10000)\t\(detail.sno)\t\(graphscale)\r"
        let contentData = text.data(using: .utf8)!
        file.seekToEndOfFile()
        file.write(contentData)
        file.closeFile()
    }
    
    // 場所の指定日付の DD_event.dt 作成
    func makeEventDT(file: FileHandle, date: Date) {
        var dic: Dictionary<String, String> = [:]
        // 日の出
        let sunRise = Int(round(tideTable.sunRise))
        var hhmm = AppCom.minuteToHHMM(sunRise)
        var text = "\(hhmm)\t\(sunRise)\tSR\r"
        dic["\(hhmm)SR"] = text
        // 日の入り
        let sunSet = Int(round(tideTable.sunSet))
        hhmm = AppCom.minuteToHHMM(sunSet)
        text = "\(hhmm)\t\(sunSet)\tSS\r"
        dic["\(hhmm)SS"] = text
        // 満潮干潮
        let hiAndLowArray = tideTable.hiAndLowTextArray
        for i in 0..<6 {
            if (i < hiAndLowArray.count) {
                let params = hiAndLowArray[i].split(separator: ",")
                let hiLow  = params[0]
                let munute = Int(params[1])!
                hhmm = AppCom.minuteToHHMM(munute)
                let height = Float(params[2])!
                text = "\(hhmm)\t\(munute)\t\(hiLow)\t\(round(height*100)/100)\r"
                dic["\(hhmm)\(hiLow)"] = text
            }
        }
        // 月の出
        let moonEventArray = tideTable.mEventArray
        if (moonEventArray[0] != -1) {
            let moonRise = moonEventArray[0].intValue
            hhmm = AppCom.minuteToHHMM(moonRise)
            text = "\(hhmm)\t\(sunSet)\tMR\r"
            dic["\(hhmm)MR"] = text
        }
        // 月の入り
        if (moonEventArray[2] != -1) {
            let moonSet = moonEventArray[2].intValue
            hhmm = AppCom.minuteToHHMM(moonSet)
            text = "\(hhmm)\t\(sunSet)\tMS\r"
            dic["\(hhmm)MS"] = text
        }
        // ソート
        let sortDic = dic.sorted { $0.0 < $1.0 } .map { $0 }
        for (_, text) in sortDic {
            let contentData = text.data(using: .utf8)!
            file.seekToEndOfFile()
            file.write(contentData)
        }
    }
    
    // 場所の指定日付の DD_tide.dt 作成
    func makeTideDT(file: FileHandle, date: Date) {
        let yPosArray = tideTable.yPosArray
        for i in 0..<73 {
            // 20分単位
            let minute = i * 20
            let text = AppCom.minuteToHHMM(minute) + "\t\(minute)\tTD\t\(round(yPosArray[i].floatValue*100)/100)\r"
            let contentData = text.data(using: .utf8)!
            file.seekToEndOfFile()
            file.write(contentData)
        }
    }

    // 月毎の sio.dt 作成
    func makeSioDT(file: FileHandle, year: Int, month: Int) {
        // ワーク用タイド情報の設定
        let sioNames = ["大潮", "中潮", "小潮", "長潮", "若潮", "大潮*"]
        var text = ""
        setTideDataForCalc(name: "名洗-H4")
        let firstDate = calendar.date(from: DateComponents(year: year, month: month))!
        let add = DateComponents(month: 1, day: -1) // １ヶ月進めて１日戻すことにより月末日を取得
        let lastDate = calendar.date(byAdding: add, to: firstDate)!
        for day in 1...lastDate.day {
            let date = calendar.date(from: DateComponents(year: year, month: month, day: day))!
            tideTable.make(date, load: day == 1)
            let idx = getSioIndex()
            if (!text.isEmpty) { text += "\t"}
            text += sioNames[idx]
        }
        let contentData = text.data(using: .utf8)!
        file.seekToEndOfFile()
        file.write(contentData)
    }
    
    // 潮回りを取得
    func getSioIndex() -> Int {

        var index = -1
        if (tideTable.age >= 0    && 1.5 >= tideTable.age) {
            index = 0
        }
        else if (tideTable.age >= 1.5    && 5.5 >= tideTable.age) {
            index = 1
        }
        else if (tideTable.age >= 5.5    && 8.5 >= tideTable.age) {
            index = 2
        }
        else if (tideTable.age >= 8.5    && 9.5 >= tideTable.age) {
            index = 3
        }
        else if (tideTable.age >= 9.5    && 10.5 >= tideTable.age) {
            index = 4
        }
        else if (tideTable.age >= 10.5    && 12.5 >= tideTable.age) {
            index = 1
        }
        else if (tideTable.age >= 12.5    && 16.5 >= tideTable.age) {
            index = 0
        }
        else if (tideTable.age >= 16.5    && 20.5 >= tideTable.age) {
            index = 1
        }
        else if (tideTable.age >= 20.5    && 23.5 >= tideTable.age) {
            index = 2
        }
        else if (tideTable.age >= 23.5    && 24.5 >= tideTable.age) {
            index = 3
        }
        else if (tideTable.age >= 24.5    && 25.5 >= tideTable.age) {
            index = 4
        }
        else if (tideTable.age >= 25.5    && 27.5 >= tideTable.age) {
            index = 1
        }
        else if (tideTable.age >= 27.5    && 30.5 >= tideTable.age) {
            index = 0
        }
        if (index == 0 && tideTable.ilum >= 50.0) {
            // 大潮（満月）
            index = 5
        }
        return index
    }

    
    // 計算用のタイドデータを設定
    func setTideDataForCalc(name: String) {
        // タイド計算用に UserDefaults にデータを保存
        let td2Detail = db.getLocationDetail(name)!
        let item = TD2item()
        item.np = td2Detail.NP
        item.title = td2Detail.NP
        item.lat = String(format: "%.2f", td2Detail.lat)
        item.lon = String(format: "%.2f", td2Detail.lon)
        item.tc0 = String(format: "%.1f", td2Detail.TC0)
        item.wN = td2Detail.wN_tbl
        item.hr = td2Detail.HR_tbl
        item.pl = td2Detail.PL_tbl
        histryArray.insert(item, at: 0)
        let userDefaults = UserDefaults.standard
        if let archive = try? NSKeyedArchiver.archivedData(withRootObject: histryArray, requiringSecureCoding: true) {
            userDefaults.set(archive, forKey: AppCom.USER_DEFKAY_TD2_HISTRIES)
        }
    }
    
}

