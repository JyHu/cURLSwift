//
//  File.swift
//  
//
//  Created by Jo on 2023/2/3.
//

import Foundation

public extension cURL {
    /// --aws-sigv4 <provider1[:provider2[:region[:service]]]>
    /// curl --aws-sigv4 "aws:amz:east-2:es" --user "key:secret" https://example.com
    class AwsSigv4Option: ArgOption {
        public private(set) var provider1: String = ""
        public private(set) var provider2: String?
        public private(set) var region: String?
        public private(set) var service: String?
        
        required init(option: OptionKey, unit: Options.Unit, arg: String) throws {
            try super.init(option: option, unit: unit, arg: arg)
            let components = arg.components(separatedBy: ":")
            guard components.count > 0 else {
                throw cURLError.argumentsError(err: "\(option.rawValue)参数\(arg)转换失败，无法有效拆分。")
            }
            provider1 = components[0]
            
            if components.count >= 2 {
                provider2 = components[1]
            }
            
            if components.count >= 3 {
                region = components[2]
            }
            
            if components.count >= 4 {
                service = components[3]
            }
        }
    }
    
    /// -E,--cert <certificate[:password]>
    /// curl --cert certfile --key keyfile https://example.com
    class CertOption: ArgOption {
        public private(set) var certificate: String = ""
        public private(set) var password: String?
        
        required init(option: OptionKey, unit: Options.Unit, arg: String) throws {
            try super.init(option: option, unit: unit, arg: arg)
            let components = arg.components(separatedBy: ":")
            guard components.count > 0 else {
                throw cURLError.argumentsError(err: "\(option.rawValue)参数\(arg)转换失败。")
            }
            certificate = components[0]
            
            if components.count >= 2 {
                password = components[1]
            }
        }
    }
    
    /// --connect-to <HOST1:PORT1:HOST2:PORT2>
    /// curl --connect-to example.com:443:example.net:8443 https://example.com
    class ConnectToOption: ArgOption {
        public private(set) var host1: String = ""
        public private(set) var port1: Int = 0
        public private(set) var host2: String = ""
        public private(set) var port2: Int = 0
        
        required init(option: OptionKey, unit: Options.Unit, arg: String) throws {
            try super.init(option: option, unit: unit, arg: arg)
            let components = arg.components(separatedBy: ":")
            guard components.count == 4, let port1 = Int(components[1]), let port2 = Int(components[3]) else { return }
            self.host1 = components[0]
            self.port1 = port1
            self.host2 = components[2]
            self.port2 = port2
        }
    }
    
    class DelegationOption: ArgOption {
        public enum Level: String {
            case none, policy, always
        }
        
        public private(set) var level: Level = .none
        
        required init(option: OptionKey, unit: Options.Unit, arg: String) throws {
            try super.init(option: option, unit: unit, arg: arg)
            guard let level = Level(rawValue: arg) else { return }
            self.level = level
        }
    }
    
    /// --dns-servers <addresses>
    /// curl --dns-servers 192.168.0.1,192.168.0.2 https://example.com
    class DNSServersOption: ArgOption {
        public struct IPAddress {
            var address: String
            var port: Int?
        }
        
        public private(set) var addresses: [IPAddress] = []
        
        required init(option: OptionKey, unit: Options.Unit, arg: String) throws {
            try super.init(option: option, unit: unit, arg: arg)
            
            let components = arg.components(separatedBy: ",")
            guard components.count > 0 else { return }
            
            // port可选
            // 192.11.1.0:8888,192.11.1.0
            
            for ipaddress in components {
                let (address, portVal) = ipaddress.divide(separator: ":")
                if let portVal = portVal {
                    addresses.append(IPAddress(address: address, port: Int(portVal)))
                } else {
                    addresses.append(IPAddress(address: address, port: nil))
                }
            }
        }
    }
    
    class FTPMethodOption: ArgOption {
        public enum Method: String {
            case multicwd, nocwd, singlecwd
        }
        
        public private(set) var method: Method = .multicwd
        
        required init(option: OptionKey, unit: Options.Unit, arg: String) throws {
            try super.init(option: option, unit: unit, arg: arg)
            guard let method = Method(rawValue: arg) else { return }
            self.method = method
        }
    }
    
    class FTPSSLCCCModeOption: ArgOption {
        public enum Mode: String {
            case active, passive
        }
        
        public private(set) var mode: Mode = .active
        
        required init(option: OptionKey, unit: Options.Unit, arg: String) throws {
            try super.init(option: option, unit: unit, arg: arg)
            guard let mode = Mode(rawValue: arg) else { return }
            self.mode = mode
        }
    }
    
    class KeyTypeOption: ArgOption {
        public enum KeyType: String {
            case DER, PEM, ENG
        }
        
        public private(set) var keyType: KeyType = .PEM
        required init(option: OptionKey, unit: Options.Unit, arg: String) throws {
            try super.init(option: option, unit: unit, arg: arg)
            guard let keyType = KeyType(rawValue: arg) else { return }
            self.keyType = keyType
        }
    }
    
    class KrbOption: ArgOption {
        public enum Level: String {
            case clear
            case safe
            case confidential
            case `private`
        }
        
        public private(set) var level: Level = .private
        required init(option: OptionKey, unit: Options.Unit, arg: String) throws {
            try super.init(option: option, unit: unit, arg: arg)
            guard let level = Level(rawValue: arg) else { return }
            self.level = level
        }
    }
    
    class LocalPortOption: ArgOption {
        public private(set) var from: Int = 0
        public private(set) var to: Int?
        required init(option: OptionKey, unit: Options.Unit, arg: String) throws {
            try super.init(option: option, unit: unit, arg: arg)
            let ports = arg.components(separatedBy: "-")
            guard ports.count >= 1 else { return }
            guard let from = Int(ports[0]) else { return }
            self.from = from
            
            if ports.count == 2, let to = Int(ports[1]) {
                self.to = to
            }
        }
    }
    
    /// --max-filesize <bytes>
    /// curl --max-filesize 100K https://example.com
    class MaxFileSizeOption: ArgOption {
        public enum SizeUnit {
            case k, m, g
            
            init?(rawValue: String) {
                if rawValue == "k" || rawValue == "K" {
                    self = .k
                } else if rawValue == "m" || rawValue == "M" {
                    self = .m
                } else if rawValue == "g" || rawValue == "G" {
                    self = .g
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
            guard let components = arg.groupValues(of: "^(\\d+)([kKmMgG])"), components.count == 2,
                let num = Int(components[0]), let sizeUnit = SizeUnit(rawValue: components[1]) else { return }
            
            self.fileSize = FileSize(num: num, unit: sizeUnit)
        }
    }
    
    /// --preproxy --proxy
    class ProxyOption: ArgOption {
        public private(set) var `protocol`: String = ""
        public private(set) var host: String = ""
        public private(set) var port: Int?
        
        required init(option: OptionKey, unit: Options.Unit, arg: String) throws {
            try super.init(option: option, unit: unit, arg: arg)
            let (pto, url) = arg.divide(separator: "://")
            guard let url = url else { return }
            let (host, portNum) = url.divide(separator: ":")
            self.protocol = pto
            self.host = host
            if let portNum = portNum, let port = Int(portNum) {
                self.port = port
            }
        }
    }

    class ProxyUserOption: ArgOption {
        public private(set) var name: String = ""
        public private(set) var password: String = ""
        required init(option: OptionKey, unit: Options.Unit, arg: String) throws {
            try super.init(option: option, unit: unit, arg: arg)
            let (name, password) = arg.divide(separator: ":")
            guard let password = password else { return }
            self.name = name
            self.password = password
        }
    }
    
    class RangeOption: ArgOption {
        public private(set) var from: Int = 0
        public private(set) var to: Int = 0
        required init(option: OptionKey, unit: Options.Unit, arg: String) throws {
            try super.init(option: option, unit: unit, arg: arg)
            let (fromNum, toNum) = arg.divide(separator: "-")
            guard let from = Int(fromNum), let toNum = toNum, let to = Int(toNum) else { return }
            self.from = from
            self.to = to
        }
    }
    
    class RateOption: ArgOption {
        public enum TimeUnit: String {
            case s, m, h, d
        }
        
        public private(set) var num: Int = 0
        public private(set) var timeUnit: TimeUnit = .h
        
        required init(option: OptionKey, unit: Options.Unit, arg: String) throws {
            try super.init(option: option, unit: unit, arg: arg)
            let (numVal, unitVal) = arg.divide(separator: "/")
            guard let num = Int(numVal) else { return }
            self.num = num
            if let unitVal = unitVal, let timeUnit = TimeUnit(rawValue: unitVal) {
                self.timeUnit = timeUnit
            }
        }
    }
    
    class TLSMaxOption: ArgOption {
        public private(set) var ver: Double = 1.3
        
        required init(option: OptionKey, unit: Options.Unit, arg: String) throws {
            try super.init(option: option, unit: unit, arg: arg)
            guard let ver = Double(arg) else { return }
            self.ver = ver
        }
    }
    
    class TLSAuthTypeOption: ArgOption {
        public enum AuthType: String {
            case SRP
            case TLS_SRP = "TLS-SRP"
        }
        
        public private(set) var authType: AuthType = .SRP
        
        required init(option: OptionKey, unit: Options.Unit, arg: String) throws {
            try super.init(option: option, unit: unit, arg: arg)
            guard let authType = AuthType(rawValue: arg) else { return }
            self.authType = authType
        }
    }
    
    class UserOption: ArgOption {
        public private(set) var user: String = ""
        public private(set) var password: String = ""
        required init(option: OptionKey, unit: Options.Unit, arg: String) throws {
            try super.init(option: option, unit: unit, arg: arg)
            let (user, password) = arg.divide(separator: ":")
            guard let password = password else { return }
            self.user = user
            self.password = password
        }
    }
}
