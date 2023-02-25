//
//  File.swift
//  
//
//  Created by Jo on 2023/2/4.
//

import Foundation

extension cURL {
    /// --json <data>
    ///
    /// (HTTP) Sends the specified JSON data in a POST request to the HTTP server. `--json` works as a shortcut for passing on these three options:
    ///
    /// ```
    /// --data [arg]
    /// --header "Content-Type: application/json"
    /// --header "Accept: application/json"
    /// ```
    ///
    /// There is no verification that the passed in data is actual JSON or that the syntax is correct.
    /// If you start the data with the letter @, the rest should be a file name to read the data from, or a single dash (-) if you want curl to read the data from stdin. Posting data from a file named 'foobar' would thus be done with `--json` @foobar and to instead read the data from stdin, use `--json` @-.
    /// If this option is used more than once on the same command line, the additional data pieces will be concatenated to the previous before sending.
    /// The headers this option sets can be overridden with `-H, --header` as usual.
    /// `--json` can be used several times in a command line
    /// Examples:
    /// ```
    /// curl --json '{ "drink": "coffe" }' https://example.com
    /// curl --json '{ "drink":' --json ' "coffe" }' https://example.com
    /// curl --json @prepared https://example.com
    /// curl --json @- https://example.com < json.txt
    /// ```
    ///
    /// See also `--data-binary` and `--data-raw`. This option is mutually exclusive to `-F, --form` and `-I, --head` and `-T, --upload-file`. Added in 7.82.0.
    class JSONOption: ArgOption {
        required init(option: OptionKey, unit: Options.Unit, arg: String) throws {
            try super.init(option: option, unit: unit, arg: arg)

        }
    }
}
