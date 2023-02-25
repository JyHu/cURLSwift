//
//  File.swift
//  
//
//  Created by Jo on 2023/2/3.
//

import Foundation

public extension cURL {
    class Option {
        public private(set) var option: OptionKey = ._a
        public private(set) var unit: Options.Unit!
        
        init(option: OptionKey, unit: Options.Unit) throws {
            self.option = option
            self.unit = unit
        }
    }
    
    class ArgOption: Option {
        public private(set) var arg: String = ""
        required init(option: OptionKey, unit: Options.Unit, arg: String) throws {
            try super.init(option: option, unit: unit)
            self.arg = arg
        }
    }
    
    /// 时间类型的参数
    class IntervalOption: ArgOption {
        public private(set) var timeInterval: TimeInterval = 0
        required init(option: OptionKey, unit: Options.Unit, arg: String) throws {
            try super.init(option: option, unit: unit, arg: arg)
            guard let timeInterval = TimeInterval(arg) else {
                throw cURLError.argumentsError(err: "\(option.rawValue)参数\(arg)转换时间戳失败。")
            }
            self.timeInterval = timeInterval
        }
    }
    
    /// 整数类型的参数
    class IntegerOption: ArgOption {
        public private(set) var num: Int = 0
        required init(option: OptionKey, unit: Options.Unit, arg: String) throws {
            try super.init(option: option, unit: unit, arg: arg)
            guard let num = Int(arg) else {
                throw cURLError.argumentsError(err: "\(option.rawValue)参数\(arg)转换数值失败。")
            }
            self.num = num
        }
    }
    
    /// host[:port] 类型的参数
    class HostOption: ArgOption {
        public private(set) var host: String = ""
        public private(set) var port: Int?
        
        required init(option: OptionKey, unit: Options.Unit, arg: String) throws {
            try super.init(option: option, unit: unit, arg: arg)
            let (host, portVal) = arg.divide(separator: ":", options: .backwards)
            self.host = host
            if let portVal = portVal, let port = Int(portVal) {
                self.port = port
            }
        }
    }
    
    class FileSizeOption: ArgOption {
        public enum SizeUnit {
            case b, k, m, g, t, p
            
            init?(rawValue: String) {
                if rawValue == "" {
                    self = .b
                } else if rawValue == "k" || rawValue == "K" {
                    self = .k
                } else if rawValue == "m" || rawValue == "M" {
                    self = .m
                } else if rawValue == "g" || rawValue == "G" {
                    self = .g
                } else if rawValue == "t" || rawValue == "T" {
                    self = .t
                } else if rawValue == "p" || rawValue == "P" {
                    self = .p
                }
                
                return nil
            }
        }
        
        public struct FileSize {
            var num: Int
            var unit: SizeUnit
        }
        
        public private(set) var fileSize: FileSize!
        
        required init(option: OptionKey, unit: Options.Unit, arg: String) throws {
            try super.init(option: option, unit: unit, arg: arg)
            /// warning
            /// 100K 10m 434G
            guard let components = arg.groupValues(of: "^(\\d+)(\\w?)$"), components.count == 2,
                let num = Int(components[0]), let sizeUnit = SizeUnit(rawValue: components[1]) else {
                throw cURLError.argumentsError(err: "\(option.rawValue)参数\(arg)转换失败。")
            }
            
            self.fileSize = FileSize(num: num, unit: sizeUnit)
        }
    }
}
