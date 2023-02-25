//
//  File.swift
//  
//
//  Created by Jo on 2023/2/4.
//

import Foundation

extension cURL {
    /// -t,--telnet-option <opt=val>
    ///
    /// Pass options to the telnet protocol. Supported options are:
    /// TTYPE=<term> Sets the terminal type.
    /// XDISPLOC=<X display> Sets the X display location.
    /// NEW_ENV=<var,val> Sets an environment variable.
    /// `-t, --telnet-option` can be used several times in a command line
    /// Example:
    /// ```
    /// curl -t TTYPE=vt100 telnet://example.com/
    /// ```
    ///
    /// See also `-K, --config`.
    
    class TelnetOptionOption: ArgOption {
        enum TOption {
            case TYPE(term: String)
            case XDISPLOC(xdisplay: Int)
            case NEW_ENV(`var`: String, val: String)
        }
        
        var top: TOption = .TYPE(term: "")
        
        required init(option: OptionKey, unit: Options.Unit, arg: String) throws {
            try super.init(option: option, unit: unit, arg: arg)
            
            let (arg, val) = arg.divide(separator: "=")
            guard let val = val else { return }
            if arg == "TYPE" {
                top = .TYPE(term: val)
            } else if arg == "XDISPLOC" {
                guard let x = Int(val) else { return }
                top = .XDISPLOC(xdisplay: x)
            } else if arg == "NEW_ENV" {
                let (r, l) = arg.divide(separator: ",")
                guard let l = l else { return }
                top = .NEW_ENV(var: r, val: l)
            }
        }
    }
}
