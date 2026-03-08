//
//  File.swift
//  
//
//  Created by Jo on 2024/4/9.
//

import Foundation

public extension cURL {
    enum Response: Error {
        case error
    }
    
    func request() throws -> Any {
        guard let urlString = url, let url = URL(string: urlString) else { throw Response.error }
        
        var request = URLRequest(url: url)
        
        let uuid = try Options.shared.uuid(of: ._connectTimeout)
        
        if let options = optionMap[uuid] {
            
        }
        
        request.timeoutInterval = 23
        
        
        throw Response.error
    }
}

private extension cURL {
    
}
