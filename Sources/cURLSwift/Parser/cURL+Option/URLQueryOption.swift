//
//  File.swift
//  
//
//  Created by Jo on 2023/2/4.
//

import Foundation

extension cURL {
    /// --url-query <data>
    ///
    /// (all) This option adds a piece of data, usually a name + value pair, to the end of the URL query part. The syntax is identical to that used for `--data-urlencode` with one extension:
    /// If the argument starts with a '+' (plus), the rest of the string is provided as-is unencoded.
    /// The query part of a URL is the one following the question mark on the right end.
    /// `--url-query` can be used several times in a command line
    /// Examples:
    /// ```
    /// curl --url-query name=val https://example.com
    /// curl --url-query =encodethis http://example.net/foo
    /// curl --url-query name@file https://example.com
    /// curl --url-query @fileonly https://example.com
    /// curl --url-query "+name=%20foo" https://example.com
    /// ```
    ///
    /// See also `--data-urlencode` and `-G, --get`. Added in 7.87.0.
    class URLQueryOption: ArgOption {
        required init(option: OptionKey, unit: Options.Unit, arg: String) throws {
            try super.init(option: option, unit: unit, arg: arg)
        }
    }
}
