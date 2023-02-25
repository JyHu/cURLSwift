//
//  File.swift
//  
//
//  Created by Jo on 2023/2/5.
//

import Foundation

extension cURL {
    /// -w,--write-out <format>
    ///
    /// Make curl display information on stdout after a completed transfer. The format is a string that may contain plain text mixed with any number of variables. The format can be specified as a literal "string", or you can have curl read the format from a file with "@filename" and to tell curl to read the format from stdin you write "@-".
    /// The variables present in the output format will be substituted by the value or text that curl thinks fit, as described below. All variables are specified as %{variable_name} and to output a normal % you just write them as %%. You can output a newline by using &bsol;n, a carriage return with &bsol;r and a tab space with &bsol;t.
    /// The output will be written to standard output, but this can be switched to standard error by using %{stderr}.
    /// Output HTTP headers from the most recent request by using %header{name} where name is the case insensitive name of the header (without the trailing colon). The header contents are exactly as sent over the network, with leading and trailing whitespace trimmed. Added in curl 7.84.0.
    /// NOTE: In Windows the %-symbol is a special symbol used to expand environment variables. In batch files all occurrences of % must be doubled when using this option to properly escape. If this option is used at the command prompt then the % cannot be escaped and unintended expansion is possible.
    /// The variables available are:
    ///
    /// certs Output the certificate chain with details. Supported only by the OpenSSL, GnuTLS, Schannel, NSS, GSKit and Secure Transport backends (Added in 7.88.0)
    /// content_type The Content-Type of the requested document, if there was any.
    /// errormsg The error message. (Added in 7.75.0)
    /// exitcode The numerical exitcode of the transfer. (Added in 7.75.0)
    /// filename_effective The ultimate filename that curl writes out to. This is only meaningful if curl is told to write to a file with the `-O, --remote-name` or `-o, --output` option. It's most useful in combination with the `-J, --remote-header-name` option.
    /// ftp_entry_path The initial path curl ended up in when logging on to the remote FTP server.
    /// header_json A JSON object with all HTTP response headers from the recent transfer. Values are provided as arrays, since in the case of multiple headers there can be multiple values.
    /// The header names provided in lowercase, listed in order of appearance over the wire. Except for duplicated headers. They are grouped on the first occurrence of that header, each value is presented in the JSON array.
    /// http_code The numerical response code that was found in the last retrieved HTTP(S) or FTP(s) transfer.
    /// http_connect The numerical code that was found in the last response (from a proxy) to a curl CONNECT request.
    /// http_version The http version that was effectively used. (Added in 7.50.0)
    /// json A JSON object with all available keys.
    /// local_ip The IP address of the local end of the most recently done connection - can be either IPv4 or IPv6.
    /// local_port The local port number of the most recently done connection.
    /// method The http method used in the most recent HTTP request. (Added in 7.72.0)
    /// num_certs Number of server certificates received in the TLS handshake. Supported only by the OpenSSL, GnuTLS, Schannel, NSS, GSKit and Secure Transport backends (Added in 7.88.0)
    /// num_connects Number of new connects made in the recent transfer.
    /// num_headers The number of response headers in the most recent request (restarted at each redirect). Note that the status line IS NOT a header. (Added in 7.73.0)
    /// num_redirects Number of redirects that were followed in the request.
    /// onerror The rest of the output is only shown if the transfer returned a non-zero error (Added in 7.75.0)
    /// proxy_ssl_verify_result The result of the HTTPS proxy's SSL peer certificate verification that was requested. 0 means the verification was successful. (Added in 7.52.0)
    /// redirect_url When an HTTP request was made without `-L, --location` to follow redirects (or when `--max-redirs` is met), this variable will show the actual URL a redirect would have gone to.
    /// referer The Referer: header, if there was any. (Added in 7.76.0)
    /// remote_ip The remote IP address of the most recently done connection - can be either IPv4 or IPv6.
    /// remote_port The remote port number of the most recently done connection.
    /// response_code The numerical response code that was found in the last transfer (formerly known as "http_code").
    /// scheme The URL scheme (sometimes called protocol) that was effectively used. (Added in 7.52.0)
    /// size_download The total amount of bytes that were downloaded. This is the size of the body/data that was transferred, excluding headers.
    /// size_header The total amount of bytes of the downloaded headers.
    /// size_request The total amount of bytes that were sent in the HTTP request.
    /// size_upload The total amount of bytes that were uploaded. This is the size of the body/data that was transferred, excluding headers.
    /// speed_download The average download speed that curl measured for the complete download. Bytes per second.
    /// speed_upload The average upload speed that curl measured for the complete upload. Bytes per second.
    /// ssl_verify_result The result of the SSL peer certificate verification that was requested. 0 means the verification was successful.
    /// stderr From this point on, the `-w, --write-out` output will be written to standard error. (Added in 7.63.0)
    /// stdout From this point on, the `-w, --write-out` output will be written to standard output. This is the default, but can be used to switch back after switching to stderr. (Added in 7.63.0)
    /// time_appconnect The time, in seconds, it took from the start until the SSL/SSH/etc connect/handshake to the remote host was completed.
    /// time_connect The time, in seconds, it took from the start until the TCP connect to the remote host (or proxy) was completed.
    /// time_namelookup The time, in seconds, it took from the start until the name resolving was completed.
    /// time_pretransfer The time, in seconds, it took from the start until the file transfer was just about to begin. This includes all pre-transfer commands and negotiations that are specific to the particular protocol(s) involved.
    /// time_redirect The time, in seconds, it took for all redirection steps including name lookup, connect, pretransfer and transfer before the final transaction was started. time_redirect shows the complete execution time for multiple redirections.
    /// time_starttransfer The time, in seconds, it took from the start until the first byte was just about to be transferred. This includes time_pretransfer and also the time the server needed to calculate the result.
    /// time_total The total time, in seconds, that the full operation lasted.
    /// url The URL that was fetched. (Added in 7.75.0)
    /// urlnum The URL index number of this transfer, 0-indexed. De-globbed URLs share the same index number as the origin globbed URL. (Added in 7.75.0)
    /// url_effective The URL that was fetched last. This is most meaningful if you have told curl to follow location: headers.
    ///
    ///
    ///
    /// If `-w, --write-out` is provided several times, the last set value will be used.
    /// Example:
    /// ```
    /// curl -w '%{http_code}&bsol;n' https://example.com
    /// ```
    ///
    /// See also `-v, --verbose` and `-I, --head`.
    class WriteOutOption: ArgOption {
        required init(option: OptionKey, unit: Options.Unit, arg: String) throws {
            try super.init(option: option, unit: unit, arg: arg)
        }
    }
}
