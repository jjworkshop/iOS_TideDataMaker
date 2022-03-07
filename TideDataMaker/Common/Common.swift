//
//  Common.swift
//  JJworkshop
//
//  Created by Mitsuhiro Shirai on 2017/04/24.
//  Copyright © 2017年 Mitsuhiro Shirai. All rights reserved.
//

import UIKit

struct Com {
    
    // デバッグプリント
    // 例：Com.XLOG(String(format: "abc - %d", 10))
    static func XLOG(_ obj: Any?,
                     file: String = #file,
                  function: String = #function,
                  line: Int = #line) {
        #if DEBUG
            // デバッグモードのみ出力（Build Setting内のOther Swift Flagsに「-DDEBUG」を設定）
            let pathItem = String(file).components(separatedBy: "/")
            let fname = pathItem[pathItem.count-1].components(separatedBy: ".")[0]
            if let obj = obj {
                print("D:[\(fname):\(function) #\(line)] : \(obj)")
            } else {
                print("D:[\(fname):\(function) #\(line)]")
            }
        #endif
    }
    
    // ドキュメントパスを取得
    static func getDocumentPath() -> String {
        return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    }
    
    // ライブラリパスを取得
    static func getLibraryPath() -> String {
        return NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)[0]
    }
    
    // ライブラリのキャッシュパスを取得
    static func getCachePath() -> String {
        return NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
    }

    // デフォルトのカレンダーを取得
    static func getCalendar() -> Calendar {
        return Calendar(identifier: .gregorian)
    }
    
    // 文字列が数値か？
    static func isNumericStr(_ str: String) -> Bool {
        let predicate = NSPredicate(format: "SELF MATCHES '\\\\d+'")
        return predicate.evaluate(with: str)
    }
    
    // pixelからpointに変換
    static func pix2Point(_ pix: CGFloat) -> Int {
        let screenScale = UIScreen.main.scale
        return Int(pix / screenScale)
    }
    
    // 日本語環境か？
    static let isJapanese: Bool = {
        guard let prefLang = Locale.preferredLanguages.first else {
            return false
        }
        return prefLang.hasPrefix("ja")
    }()
        
}
