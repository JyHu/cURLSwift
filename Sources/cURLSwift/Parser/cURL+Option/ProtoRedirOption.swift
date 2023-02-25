//
//  File.swift
//  
//
//  Created by Jo on 2023/2/4.
//

import Foundation

extension cURL {
    /// --proto-redir <protocols>
    ///
    /// Tells curl to limit what protocols it may use on redirect. Protocols denied by `--proto` are not overridden by this option. See `--proto` for how protocols are represented.
    /// Example, allow only HTTP and HTTPS on redirect:
    ///
    /// ```
    /// curl --proto-redir -all,http,https http://example.com
    /// ```
    ///
    /// By default curl will only allow HTTP, HTTPS, FTP and FTPS on redirect (since 7.65.2). Specifying all or +all enables all protocols on redirects, which is not good for security.
    /// If `--proto-redir` is provided several times, the last set value will be used.
    /// Example:
    /// ```
    /// curl --proto-redir =http,https https://example.com
    /// ```
    ///
    /// See also `--proto`.
    class ProtoRedirOption: ArgOption {
        var protocols: [String] = []
        required init(option: OptionKey, unit: Options.Unit, arg: String) throws {
            try super.init(option: option, unit: unit, arg: arg)
            
        }
    }
}
