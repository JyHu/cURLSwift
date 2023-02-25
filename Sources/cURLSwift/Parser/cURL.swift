//
//  File.swift
//  
//
//  Created by Jo on 2023/2/3.
//

import Foundation

public struct cURL {
    
    /// 所有的请求参数
    public private(set) var options: [Option] = []
    /// 参数字典，用于合并相同类型的参数，key为curl参数对应的uuid
    public private(set) var optionMap: [OptionUUID: [Option]] = [:]
    /// 请求的url
    public private(set) var url: String?
    
    /// 初始化方法
    /// - Parameter curl: curl
    public init(curl: String) throws {
        /// 获取拆分curl中的所有的token
        let tokens = try cURLParser.tokens(of: curl)
        
        /// 遍历所有的token，并解析成curl option
        var index: Int = 1
        while index < tokens.count {
            let token = tokens[index].trimming
            
            if token.hasPrefix("-") {
                var (command, body) = token.divide()
                
                let optionKey = try OptionKey.from(command)
                let unit = try Options.shared.unit(of: optionKey)
                
                if unit.hasArg && body == nil {
                    index += 1
                    
                    guard index < tokens.count else {
                        throw cURLError.indexOverFlow(index: index)
                    }
                    
                    body = tokens[index]
                }
                
                let option = try OptionFactory.shared.makeOption(with: optionKey, unit: unit, arg: body)
                self.options.append(option)
                
                let identifier = option.unit.identifier
                var alikeOptions = self.optionMap[identifier] ?? []
                alikeOptions.append(option)
                self.optionMap[identifier] = alikeOptions
            } else {
                self.url = token
            }
            
            index += 1
        }
    }
    
    public var description: String {
        var result = "curl "
        if let url = url {
            result.append(url)
        }
        
        for option in options {
            if let option = option as? ArgOption {
                result.append("\n  \(option.option.rawValue) \(option.arg)")
            } else {
                result.append("\n  \(option.option.rawValue)")
            }
        }
        
        return result
    }
    
    public func options(for key: OptionKey) throws -> [Option]? {
        let uuid = try Options.shared.uuid(of: key)
        let optionList = optionMap[uuid]
        let argType = try ArgTypes.shared.argType(of: key)
        
        if argType == .lastOnly || argType == .unique {
            guard let option = optionList?.last else { return nil }
            return [option]
        }
        
        return optionList
    }
}
