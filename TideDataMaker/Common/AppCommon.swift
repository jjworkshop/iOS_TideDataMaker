//
//  AppCommon.swift
//  TideDataMaker
//
//  Created by Mitsuhiro Shirai on 2018/02/05.
//  Copyright © 2018年 Mitsuhiro Shirai. All rights reserved.
//

import UIKit

struct AppCom {
       
    static public let USER_DEFKAY_TD2_HISTRIES      = "TD2_HISTRIES"
    
    // URLエンコード
    static func urlEncode(_ text: String) -> String {
        var allowedCharacterSet = CharacterSet.alphanumerics
        allowedCharacterSet.insert(charactersIn: "-._~")
        return text.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet)!
    }
    
    // 長すぎる文字列をカットして「…」を付加する
    static func stringEllipsis(_ text: String, max: Int) -> String {
        if text.count > max {
            let start = text.index(text.startIndex, offsetBy: max)
            let end = text.endIndex
            let range = start..<end
            return text.replacingCharacters(in: range, with: "…")
        }
        return text
    }
    
    // ローカル日付フォーマット（年月日、曜日、時、分）
    static func msecToYmdE_HM(_ msec: UInt64, isJp: Bool) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: isJp ? "ja_JP" : "en_US")
        formatter.dateFormat = isJp ? "yyyy/MM/dd(EE) HH:mm": "EE, d MMM yyyy HH:mm"
        let date = Date(timeIntervalSince1970: TimeInterval(msec / 1000))
        return formatter.string(from: date)
    }
    
    // ローカル日付フォーマット（年月日、曜日、時、分）
    static func dateToYmdE_HM(_ date: Date, isJp: Bool) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: isJp ? "ja_JP" : "en_US")
        formatter.dateFormat = isJp ? "yyyy年M月d(EE) HH:mm": "EE, d MMM yyyy HH:mm"
        return formatter.string(from: date)
    }
    
    // ローカル日付フォーマット（月日時分ショートバージョン）
    static func dateToMd_HM_short(_ date: Date, isJp: Bool) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: isJp ? "ja_JP" : "en_US")
        formatter.dateFormat = isJp ? "M/d HH:mm": "M/d HH:mm"
        return formatter.string(from: date)
    }
    
    // ローカル日付フォーマット（年月日、曜日）
    static func dateToYmdE(_ date: Date, isJp: Bool) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: isJp ? "ja_JP" : "en_US")
        formatter.dateFormat = isJp ? "yyyy年M月d日(EE)": "EE, d MMM yyyy"
        return formatter.string(from: date)
    }

    // ローカル日付フォーマット（月日、曜日）
    static func dateToMdE(_ date: Date, isJp: Bool) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: isJp ? "ja_JP" : "en_US")
        formatter.dateFormat = isJp ? "M月d日(EE)": "EE, d MMM"
        return formatter.string(from: date)
    }

    // サーバのタイムスタンプをDateに変換（RFC 822, updated by RFC 1123）
    // 例: Fri, 13 Apr 2018 00:00:05 GMT
    static func dateFromRFC822(_ text: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "EEE, dd MM yyyy HH:mm:ss Z"
        return formatter.date(from: text)
    }
    
    // 分を HH:MM の文字列に変換
    static func minuteToHHMM(_ minute: CGFloat) -> String {
        return minuteToHHMM(Int(minute))
    }
    static func minuteToHHMM(_ minute: Int) -> String {
        let hh: Int = Int(minute / 60)
        let mm: Int = minute - hh * 60
        return String(format: "%02d:%02d", hh, mm)
    }
    static func minuteToHHMM2(_ minute: CGFloat) -> String {
        return minuteToHHMM2(Int(minute))
    }
    static func minuteToHHMM2(_ minute: Int) -> String {
        let hh: Int = Int(minute / 60)
        let mm: Int = minute - hh * 60
        return String(format: "%2d%2d", hh, mm)
    }

    // アプリと連携
    static func showOtherApp(urlScheme: String) -> Bool {
        let url = URL(string: urlScheme)
        if (UIApplication.shared.canOpenURL(url!)) {
            openUrl(url)
            return true
        }
        else {
            Com.XLOG("'\(urlScheme)' is not install.")
        }
        return false
    }
    
    // ダウンロード by AppStore
    static func downloadByAppStore(appleID: String) {
        let url =  URL(string: "itms-apps://itunes.apple.com/app/\(appleID)")
        openUrl(url)
    }
    
    // URLを開く
    static func openUrl(_ url: URL?) {
        if let url = url {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
            }
            else {
                Com.XLOG("Can not open URL!")
            }
        }
        else {
            Com.XLOG("URL is invalid")
        }
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
    return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
