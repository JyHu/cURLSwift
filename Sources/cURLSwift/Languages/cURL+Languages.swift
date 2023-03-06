//
//  File.swift
//  
//
//  Created by Jo on 2023/2/9.
//

import Foundation

public extension cURL {
    enum Language: String, CaseIterable {
        case Swift
        case objC = "Objective-C"
        case JAVA
    }
    
    func code(of language: Language) -> String? {
        switch language {
        case .Swift: return swiftCode
        case .objC: return objcCode
        case .JAVA: return javaCode
        }
    }
}

public extension cURLs {
    func code(of language: cURL.Language) -> String {
        return curlObjs.compactMap({ $0.code(of: language) }).joined(separator: "\n\n\n")
    }
}
