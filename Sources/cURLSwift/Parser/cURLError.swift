//
//  File.swift
//  
//
//  Created by Jo on 2023/2/3.
//

import Foundation

public enum cURLError: Error {
    /// curl参数没有有效的入参
    case noOptionArg(String)
    /// 解析curl的时候，括号前后不匹配
    case notPair
    /// 无效的url
    case invalidURL(String)
    /// 解析curl的时候遇到无法解析的参数
    case invalidOption(option: String)
    /// 索引越界，无法找到有效的入参
    case indexOverFlow(index: Int)
    /// 无法通过option找到有效的uuid
    case noValidUUID(option: String)
    /// 无法通过option找到有效的unit
    case noValidUnit(option: String)
    /// 参数类型没有有效的参数类
    case noValidArgType(option: String)
    /// 创建参数对象的时候，转换入参失败
    case argumentsError(err: String)
}
