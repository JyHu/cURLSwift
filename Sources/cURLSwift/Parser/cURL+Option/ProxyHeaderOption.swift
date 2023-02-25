//
//  File.swift
//  
//
//  Created by Jo on 2023/2/4.
//

import Foundation

extension cURL {
    /// --proxy-header <header/@file>
    ///
    /// (HTTP) Extra header to include in the request when sending HTTP to a proxy. You may specify any number of extra headers. This is the equivalent option to `-H, --header` but is for proxy communication only like in CONNECT requests when you want a separate header sent to the proxy to what is sent to the actual remote host.
    /// curl will make sure that each header you add/replace is sent with the proper end-of-line marker, you should thus not add that as a part of the header content: do not add newlines or carriage returns, they will only mess things up for you.
    /// Headers specified with this option will not be included in requests that curl knows will not be sent to a proxy.
    /// Starting in 7.55.0, this option can take an argument in @filename style, which then adds a header for each line in the input file. Using @- will make curl read the header file from stdin.
    /// This option can be used multiple times to add/replace/remove multiple headers.
    /// `--proxy-header` can be used several times in a command line
    /// Examples:
    /// ```
    /// curl --proxy-header "X-First-Name: Joe" -x http://proxy https://example.com
    /// curl --proxy-header "User-Agent: surprise" -x http://proxy https://example.com
    /// curl --proxy-header "Host:" -x http://proxy https://example.com
    /// ```
    ///
    /// See also `-x, --proxy`. Added in 7.37.0.
    class ProxyHeaderOption: ArgOption {
        required init(option: OptionKey, unit: Options.Unit, arg: String) throws {
            try super.init(option: option, unit: unit, arg: arg)
        }
    }
}
