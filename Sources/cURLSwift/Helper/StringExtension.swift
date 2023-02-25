//
//  File.swift
//  
//
//  Created by Jo on 2023/2/3.
//

import Foundation

internal extension String {
    
    /// 去除首尾的空格字符
    var trimming: String {
        return trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// 将连续的空格替换为一个空格
    func trimmingContinuousSpace() -> String {
        return replacingOccurrences(of: "\\s{2,}", with: " ", options: .regularExpression)
    }
    
    /// 使用给定的分隔符，将字符串分割为两部分
    func divide(separator: String = "=", options: NSString.CompareOptions = []) -> (String, String?) {
        var prefix: String = self
        var surfix: String?
        
        if contains(separator) {
            let nsstring = NSString(string: self)
            let range = nsstring.range(of: separator, options: options)
            
            prefix = nsstring.substring(to: range.location)
            if nsstring.length > range.location + range.length {
                surfix = nsstring.substring(from: range.location + range.length)
            }
        }
        
        return (prefix.trimming, surfix?.trimming)
    }
    
    /// 使用正则获取字符串中所有匹配到的分组1内容
    /// - Parameters:
    ///   - pattern: 用于匹配的正则
    ///   - options: 匹配的正则属性
    /// - Returns: 匹配结果
    func groupValues(of pattern: String, options: NSRegularExpression.Options = []) -> [String]? {
        guard let reg = try? NSRegularExpression(pattern: pattern, options: options) else { return nil }
        guard let textCheckingResult = reg.firstMatch(in: self, range: NSMakeRange(0, count)) else { return nil }
        let nsstring = NSString(string: self)
        var results: [String] = []
        
        for index in 1..<textCheckingResult.numberOfRanges {
            let range = textCheckingResult.range(at: index)
            guard range.location != NSNotFound else { continue }
            results.append(nsstring.substring(with: range))
        }
        
        return results
    }
}
