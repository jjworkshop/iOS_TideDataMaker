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
    let dateFormatter = DateFormatter()
    let tideTable = TideTableWrapper()
    var histryArray: Array<TD2item> = []
    
    let JCG = "jcg"
    let PLACE = "place"
    let PLACE_DT = "jcg_places.dt"
    let from_year = 2022
    let to_year   = 2041
    
    var jcgDataPath: String = ""
    var placeDataPath: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        
        dateFormatter.calendar = calendar
        dateFormatter.locale = Locale(identifier: "ja_JP")
        dateFormatter.timeZone = TimeZone(identifier:  "Asia/Tokyo")

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

        
        // 場所データリスト取得（都道府県毎のループですべての場所を取得）
        var placeList: Array<LocationItem> = []
        for sno in 1...80 {
            placeList += db.getLocationName(sno: sno)
        }
                
        // 場所毎データ作成の処理
        jcgDataPath = dataRootPath + "/\(JCG)"
        placeDataPath = dataRootPath + "/\(PLACE)"
        do {
            try fm.createDirectory(atPath: jcgDataPath, withIntermediateDirectories: false, attributes: nil)
            try fm.createDirectory(atPath: placeDataPath, withIntermediateDirectories: false, attributes: nil)
            for year in from_year...to_year {
                let yearPath = jcgDataPath + "/\(year)"
                try fm.createDirectory(atPath: yearPath, withIntermediateDirectories: false, attributes: nil)
            }
        }
        catch let error as NSError {
            Com.XLOG(error)
        }
        for (idx, place) in placeList.enumerated() {
            // if place.name != "名洗-H4" { continue }   // TODO: DEBUG
            let TK = seqToTK(seq: idx + 1)
            makeData(TK: TK, place: place)
            Thread.sleep(forTimeInterval: 0.05)
            
        }
        
        // 潮汐名データ作成
        makeShioData(dataPath: dataRootPath)
    }

    // シーケンス番号からをTK（地点記号）を生成
    func seqToTK(seq: Int) -> String {
        let TK_CODES = ["A","B","C","D","E","F","G","H","J","K","L","M","N","P","Q","R","S","T","U","V","W","X","Y","Z"]
        let listCount = TK_CODES.count
        let idx1 = Int(seq / listCount)
        let idx2 = seq % listCount
        return TK_CODES[idx1] + TK_CODES[idx2]
    }

    // 場所毎のデータを作成（場所毎の処理）
    var max_tide = 0  // 満潮時の最大潮高
    var min_tide = 0  // 干潮時の最小調光
    func makeData(TK: String, place: LocationItem) {
        var addPlaceInfoFlg = false
        // タイド計算用に UserDefaults にデータを保存
        setTideDataForCalc(name: place.name)
        // 場所のタイドデータを作成
        let name = place.name.replacingOccurrences(of: "/", with: "／")
        Com.XLOG("TK:\(TK)  PLACE: \(name)")
        // 年毎のループ
        for year in from_year...to_year {
            max_tide = 0
            min_tide = 0
            // 月毎のループ
            for month in 1...12 {
                let firstDate = calendar.date(from: DateComponents(year: year, month: month))!
                let add = DateComponents(month: 1, day: -1) // １ヶ月進めて１日戻すことにより月末日を取得
                let lastDate = calendar.date(byAdding: add, to: firstDate)!
                // 日」毎のループ
                for day in 1...lastDate.day {
                    // タイド計算
                    let targetDate = calendar.date(from: DateComponents(year: year, month: month, day: day))!
                    tideTable.make(targetDate, load: day == 1)
                    // タイドデータ作成（999.DT）フォーマットは、気象庁の潮位表データフォーマットにあわせている
                    addPlaceTideData(TK: TK, date: targetDate)
                    if !addPlaceInfoFlg {
                        // 場所情報（jcg_places.dt）に追加
                        addPlaceInfo(TK: TK, name: name, place: place)
                        addPlaceInfoFlg = true
                    }
                }
            }
        }
    }
    
    // 場所情報を jcg_places.dt に追加
    func addPlaceInfo(TK: String, name:String, place: LocationItem) {
        let infoFilePath = "\(placeDataPath)/\(PLACE_DT)"
        if !fm.fileExists(atPath: infoFilePath) {
            fm.createFile(atPath: infoFilePath, contents: nil, attributes: nil)
        }
        let file = FileHandle(forWritingAtPath: infoFilePath)!
        let detail = db.getLocationDetail(place.name)!
        let lat = round((db.FNDG(detail.lat))*10000)/10000
        let lon = round((db.FNDG(detail.lon))*10000)/10000
        let lat_str = String(format: "%.04f", lat)
        let lon_str = String(format: "%.04f", lon)
        let ele_str = String(format: "%.01f", round((getElevation(lat: lat, lon: lon))*10)/10)
        let msl_str = String(format: "%.2f", detail.TC0)
        // let todoufuken = db.getStateName(sno: detail.sno)
        let sno = detail.sno
        let graphscale = tideTable.graphscale
        let text = "\(TK)\t\(name)\t\(lat_str)\t\(lon_str)\t\(ele_str)\t\(msl_str)\t\(sno)\t\(graphscale)\r"
        let contentData = text.data(using: .utf8)!
        file.seekToEndOfFile()
        file.write(contentData)
        file.closeFile()
        // Com.XLOG("\tADDED TK:\(TK)  max=\(max_tide) min=\(min_tide)差: \(max_tide - min_tide) GS:\(graphscale)")
    }
    
    // 標高を取得
    var semaphore : DispatchSemaphore!
    var elevation: Double = 0
    func getElevation(lat: Double, lon: Double) -> Double {
        elevation = 0
        let urlStr = "https://cyberjapandata2.gsi.go.jp/general/dem/scripts/getelevation.php?lat=\(lat)&lon=\(lon)&outtype=JSON"
        semaphore = DispatchSemaphore(value: 0)
        var request = URLRequest(url: URL(string: urlStr)!)
        request.httpMethod = "GET"
        URLSession.shared.dataTask(with: request, completionHandler: requestCompleteHandler).resume()
        semaphore.wait()
        return elevation
    }
    func requestCompleteHandler(data:Data?,res:URLResponse?,err:Error?)
    {
        if err == nil {
            if let data = data, let _ = res{
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as! [String:Any]
                    let num = json["elevation"] as? Double ?? 0
                    elevation = num
                }
                catch {}
            }
        }
        semaphore.signal()
    }

    
    // タイドデータ作成（999.dt）フォーマットは、気象庁の潮位表データフォーマットにあわせている
    func addPlaceTideData(TK: String, date: Date) {
        dateFormatter.dateFormat = "yy"
        let dataFilePath = "\(jcgDataPath)/\(date.year)/\(TK).dt"
        if !fm.fileExists(atPath: dataFilePath) {
            fm.createFile(atPath: dataFilePath, contents: nil, attributes: nil)
        }
        let file = FileHandle(forWritingAtPath: dataFilePath)!
        let tideDataHead = " 72 20"    // 件数（24H x 3）と毎分（20分毎）
        let tideData = makeTideData(date: date)
        let yymmdd = dateFormatter.string(from: date) + String(format: "%2d", date.month) + String(format: "%2d", date.day)
        let hi_low = makeTideHiLowData(date: date)
        let text = "\(tideDataHead)\(tideData)\(yymmdd)\(TK)\(hi_low)\r"
        let contentData = text.data(using: .utf8)!
        file.seekToEndOfFile()
        file.write(contentData)
        file.closeFile()
    }
    
    // 指定日時の潮位データ（固定長：1〜72カラム）を作成
    func makeTideData(date: Date) -> String {
        // 毎時潮位データ ：３桁×２４時間（０時から２３時）
        // 潮位３桁の先頭にゼロは入れない
        // 3*24*3 の 216 byte
        var tideTableStr = ""
        let yPosArray = tideTable.yPosArray
        for i in 0..<72 {       // 最後のデータと、翌日の最初のデータが同じなので、最後のデータはCUTしている
            // 20分単位
            let hight:Int = Int(round(yPosArray[i].floatValue))
            tideTableStr += String(format: "%3d", hight)
        }
        return tideTableStr
    }
    
    // 指定日時の満潮／館長データ（固定長：81〜108カラムと81〜108カラム）を作成
    func makeTideHiLowData(date: Date) -> String {
        // 満潮時刻・潮位 ：時刻４桁（時分）、潮位３桁（ｃｍ）
        // 干潮時刻・潮位 ：時刻４桁（時分）、潮位３桁（ｃｍ）
        // 満（干）潮が予測されない場合、満（干）潮時刻を「9999」、潮位を「999」
        // 時間（時と分）、潮位３桁ともに選択にゼロは入れない
        // (4+3)*8 の 56 byte
        // 満潮干潮
        var hightTideStr = ""
        var lowTideStr = ""
        let hiAndLowArray = tideTable.hiAndLowTextArray
        for i in 0..<6 {
            if (i < hiAndLowArray.count) {
                let params = hiAndLowArray[i].split(separator: ",")
                let hiLow  = params[0]
                let munute = Int(params[1])!
                let hhmm2 = AppCom.minuteToHHMM2(munute)
                let hight = Int(params[2])!
                if hiLow == "H" {
                    hightTideStr += hhmm2 + String(format: "%3d", hight)
                    if max_tide < hight { max_tide =  hight }
                }
                else {
                    lowTideStr += hhmm2 + String(format: "%3d", hight)
                    if min_tide > hight { min_tide =  hight }
                }
            }
        }
        hightTideStr = hightTideStr + String(repeating: "*", count: (4+3)*4 - hightTideStr.count)
        lowTideStr = lowTideStr + String(repeating: "*", count: (4+3)*4 - lowTideStr.count)
        return "\(hightTideStr)\(lowTideStr)"
    }
    
    // 潮汐名データ作成
    func makeShioData(dataPath: String) {
        let shioPath = dataPath + "/sio"
        do {
            try fm.createDirectory(atPath: shioPath, withIntermediateDirectories: false, attributes: nil)
            for year in from_year...to_year {
                // 年毎の sio.dt 作成
                let yearPath = shioPath + "/\(year)"
                try fm.createDirectory(atPath: yearPath, withIntermediateDirectories: false, attributes: nil)
                let shioFilePath = "\(yearPath)/sio.dt"
                fm.createFile(atPath: shioFilePath, contents: nil, attributes: nil)
                let file = FileHandle(forWritingAtPath: shioFilePath)!
                for month in 1...12 {
                    addSioDT(file: file, year: year, month: month)
                }
                file.closeFile()
            }
        }
        catch let error as NSError {
            Com.XLOG(error)
        }
    }
    
    // 月毎に sio.dt に追加
    func addSioDT(file: FileHandle, year: Int, month: Int) {
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
        text = "\(month)\t\(lastDate.day)\t\(text)\n"
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

