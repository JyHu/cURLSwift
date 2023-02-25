//
//  Options.swift
//  
//
//  Created by Jo on 2023/2/2.
//

#if canImport(Cocoa)
import Cocoa
#elseif canImport(UIKit)
import UIKit
#endif

import Foundation

/// curl参数列表
public struct Options {
    
    /// curl支持的参数列表
    public private(set) var units: [Unit] = []
    
    /// curl支持的参数列表，key为随机生成的uuid，因为很多参数有多种表示，如 -I,--head
    public private(set) var unitsMap: [OptionUUID: Unit] = [:]
    
    /// 随机uuid和curl参数的对应关系，如
    /// {"-I": uuid1, "--head": "uuid1"}
    /// 可能多个参数对应一个uuid
    private var keyMap: [OptionKey: OptionUUID] = [:]
    
    /// 单例对象
    public private(set) static var shared = Options()
    
    private init() {
        guard let data = NSDataAsset(name: "curl_options", bundle: Bundle.module)?.data,
              let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { return }
        
        var sortIndex: Int = 0
        
        for keyValues in json {
            guard let options = keyValues["options"] as? [String],
                    let description = keyValues["description"] as? String else {
                continue
            }
            
            var optionKeys: [OptionKey] = []
            for option in options {
                guard let optionKey = OptionKey(rawValue: option) else { return }
                optionKeys.append(optionKey)
            }
            
            var unit = Unit(options: optionKeys, arg: keyValues["arg"] as? String, description: description)
            unit.sortIndex = sortIndex
            units.append(unit)
            unitsMap[unit.identifier] = unit
            
            for option in unit.options {
                keyMap[option] = unit.identifier
            }
            
            sortIndex += 1
        }
        
        print("")
    }
    
    /// 根据一个curl参数获取对应的unit
    public func unit(of option: OptionKey) throws -> Unit {
        /// 先转换为对应的uuid
        guard let un = unitsMap[try uuid(of: option)] else {
            throw cURLError.noValidUnit(option: option.rawValue)
        }
        
        /// 然后获取对应的unit
        return un
    }
    
    public func uuid(of option: OptionKey) throws -> String {
        if let id = keyMap[option] { return id }
        throw cURLError.noValidUUID(option: option.rawValue)
    }
    
    /// curl参数对象
    public struct Unit {
        /// 随机uuid，唯一标识
        public fileprivate(set) var identifier: String = UUID().uuidString
        /// 参数类型
        public fileprivate(set) var options: [OptionKey]
        /// 使用时的入参
        public fileprivate(set) var arg: String?
        /// 描述说明内容
        public fileprivate(set) var description: String
        /// 初始的排序顺序
        public fileprivate(set) var sortIndex: Int = 0
        
        /// 是否有入参
        public var hasArg: Bool {
            return arg != nil
        }
        
        public private(set) var sample: String = ""
        public private(set) var searchedSample: String = ""
        
        init(options: [OptionKey], arg: String? = nil, description: String) {
            self.options = options
            self.arg = arg
            self.description = description
            
            
            let optStr = options.map({ $0.rawValue }).joined(separator: ", ")
            if let arg = arg {
                self.sample = "\(optStr) <\(arg)>"
            } else {
                self.sample = optStr
            }
            
            searchedSample = self.sample.uppercased()
        }
        
        public func attributedDescription(
            optionAttributes: [NSAttributedString.Key: Any]? = nil,
            descriptionAttributes: [NSAttributedString.Key: Any]? = nil,
            codeAttributes: [NSAttributedString.Key: Any]? = nil
        ) -> NSMutableAttributedString {
            
            let optionAttributes = optionAttributes ?? defaultTitleAttributes()
            
            let attrTitle = NSAttributedString(string: sample, attributes: optionAttributes)
            
            let descriptionAttributes = descriptionAttributes ?? defaultDescriptionAttributes()
            
            let desc = description.replacingOccurrences(of: "\n{2,}", with: "\n", options: .regularExpression)
            let attrDesc = NSMutableAttributedString(string: desc, attributes: descriptionAttributes)
            
            let nslink = NSString(string: desc)
            let linkReg = try? NSRegularExpression(pattern: "##(.+?)##")
            let linkResults = linkReg?.matches(in: desc, range: NSMakeRange(0, desc.count)) ?? []
            
            for linkResult in linkResults.reversed() {
                let range = linkResult.range(at: 1)
                let link = nslink.substring(with: range)
                attrDesc.replaceCharacters(in: linkResult.range, with: link)
                
                if let unit = getUint(of: link) {
                    attrDesc.addAttributes([
                        .link: unit
                    ], range: NSMakeRange(linkResult.range.location, range.length))
                }
            }
            
            let codeReg = try? NSRegularExpression(pattern: "```([\\s\\S]+?)```")
            let codeResults = codeReg?.matches(in: attrDesc.string, range: NSMakeRange(0, attrDesc.string.count)) ?? []
            let nscodes = NSString(string: attrDesc.string)
            
            let codeAttributes = codeAttributes ?? defaultCodeAttributes()
            
            for codeResult in codeResults.reversed() {
                let range = codeResult.range(at: 1)
                let code = nscodes.substring(with: range).trimming.components(separatedBy: "\n").map({ $0.trimming }).joined(separator: "\n")
                attrDesc.replaceCharacters(in: codeResult.range, with: code)
                attrDesc.addAttributes(codeAttributes, range: NSMakeRange(codeResult.range.location, code.count))
            }
            
            let attr = NSMutableAttributedString(attributedString: attrTitle)
            attr.append(NSAttributedString(string: "\n"))
            attr.append(attrDesc)
            
            return attr
        }
        
        private func defaultTitleAttributes() -> [NSAttributedString.Key: Any] {
            var attributes: [NSAttributedString.Key: Any] = [ .font: NSFont.monospacedSystemFont(ofSize: 18, weight: .bold) ]
            #if canImport(Cocoa)
            attributes[.foregroundColor] = NSColor.textColor
            #elseif canImport(UIKit)
            attributes[.foregroundColor] = UIColor.label
            #endif
            return attributes
        }
        
        private func defaultDescriptionAttributes() -> [NSAttributedString.Key: Any] {
            var attributes: [NSAttributedString.Key: Any] = [ .font: NSFont.monospacedSystemFont(ofSize: 14, weight: .regular) ]
            #if canImport(Cocoa)
            attributes[.foregroundColor] = NSColor.textColor
            #elseif canImport(UIKit)
            attributes[.foregroundColor] = UIColor.label
            #endif
            return attributes
        }
        
        private func defaultCodeAttributes() -> [NSAttributedString.Key: Any] {
            var attributes: [NSAttributedString.Key: Any] = [ .font: NSFont.monospacedSystemFont(ofSize: 16, weight: .regular) ]
            #if canImport(Cocoa)
            attributes[.backgroundColor] = NSColor.separatorColor
            attributes[.foregroundColor] = NSColor.systemRed
            #elseif canImport(iOS)
            attributes[.backgroundColor] = UIColor.separatorColor
            attributes[.foregroundColor] = UIColor.systemRed
            #endif
            return attributes
        }
        
        private func getUint(of optionStr: String) -> Options.Unit? {
            guard let option = optionStr.components(separatedBy: ",").map({ $0.trimming }).last,
                  let opk = OptionKey(rawValue: option) else { return nil }
            return try? Options.shared.unit(of: opk)
        }
    }
}

