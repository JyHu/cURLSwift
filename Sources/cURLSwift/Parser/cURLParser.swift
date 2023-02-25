//
//  File.swift
//  
//
//  Created by Jo on 2022/12/13.
//

import Foundation

private extension Character {
    static let singleQuote = Character("'")
    static let doubleQuote = Character("\"")
    static let equalSign = Character("=")
    static let dashChar = Character("-")
    static let escapChar = Character("\\")
}

public struct cURLParser {
    /// 将curl拆分成一个个的词条
    static func tokens(of curl: String) throws -> [String] {
        let scanner = Scanner(string: curl.trimming)
        scanner.charactersToBeSkipped = nil
        
        /// 扫描所有连续的参数
        func scanParam() throws -> String? {
            /// 扫描内容暂存对象
            var buffer: [Character] = []
            /// 成对的符号栈结构，主要处理单引号、双引号
            var charStack: [Character] = []
            
            /// 如果不是在末尾，那么就继续遍历
            while !scanner.isAtEnd {
                /// 扫描当前位置的字符
                guard let character = scanner.scanCharacter() else { continue }
                
                /// 如果是单引号、双引号，那么需要处理一下前后成对匹配问题
                if character == .singleQuote || character == .doubleQuote {
                    /// 缓存字符
                    buffer.append(character)
                    
                    /// 如果栈里没有字符，说明是刚遇到单双引号，需要缓存入栈
                    if charStack.count == 0 {
                        charStack.append(character)
                    }
                    /// 如果栈顶字符与当前字符相同，说明出现了成对的单双引号，那就可以移除栈顶的字符
                    else if charStack.last == character {
                        charStack.removeLast()
                    }
                    /// 再次入栈
                    else {
                        charStack.append(character)
                    }
                }
                /// 如果是空白字符，说明可能是参数结尾位置
                else if character.isWhitespace || character.isNewline {
                    /// 如果栈里内容为空，并且有缓存，那么就返回结果
                    if charStack.count == 0 {
                        if buffer.count > 0 {
                            return String(buffer).trimmingContinuousSpace()
                        }
                    }
                    /// 如果不是换行符，才需要暂存
                    else if !character.isNewline {
                        buffer.append(character)
                    }
                }
                /// 暂存字符
                else {
                    buffer.append(character)
                }
            }
            
            if charStack.count > 0 {
                throw cURLError.notPair
            }
            
            if buffer.count > 0 {
                return String(buffer).trimmingContinuousSpace()
            }
            
            return nil
        }
        
        var tokens: [String] = []
        
        while !scanner.isAtEnd {
            if let token = try scanParam() {
                tokens.append(token)
            }
        }
        
        return tokens
    }
}
