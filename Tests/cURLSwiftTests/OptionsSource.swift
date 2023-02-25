//
//  File.swift
//  
//
//  Created by Jo on 2023/1/31.
//

import Foundation

/// <p\s+class="level0"><a\s+name="(.*?)"></a><span\s+class="nroffip">(.*?)</span>
///
//<p class="level0"><a name="--preproxy"></a><span class="nroffip">--preproxy [protocol://]host[:port]</span>

private let optionPattern = "<p\\s+class=\"level0\"><a\\s+name=\"(.+?)\"></a><span\\s+class=\"nroffip\">(.+?)</span>"

private protocol TmpOptionProtocol {
    var options: [String] { get set }
    var description: String { get set }
}

struct TmpOption: TmpOptionProtocol {
    var options: [String]
    var description: String
}

private struct TmpArgOption: TmpOptionProtocol {
    var options: [String]
    var description: String
    var arg: String
}

private extension TmpOptionProtocol {
    var keyValues: [String: Any] {
        var result: [String: Any] = [
            "options": options,
            "description": description
        ]
        
        if let op = self as? TmpArgOption {
            result["arg"] = op.arg
        }
        
        return result
    }
}

struct Parser {
    static func parseOptions() {
        let string = NSString(string: optionSource)
        guard let optionReg = try? NSRegularExpression(pattern: optionPattern) else { return }
        let textCheckingResults = optionReg.matches(in: optionSource, range: NSMakeRange(0, optionSource.count))
        var options: [TmpOptionProtocol] = []
        
        for (index, textCheckingResult) in textCheckingResults.enumerated() {
            let optionString = string.substring(with: textCheckingResult.range(at: 2))
            var length: Int = 0
            let beginIndex = textCheckingResult.range.location + textCheckingResult.range.length
            if index < textCheckingResults.count - 1 {
                length = textCheckingResults[index + 1].range.location - beginIndex
            } else {
                length = string.length - beginIndex
            }
            let desc = string.substring(with: NSMakeRange(beginIndex, length))
            
            options.append(make(with: optionString, description: desc))
        }

        toCode(options)
        toJSON(options)
    }
    
    private static func toCode(_ options: [TmpOptionProtocol]) {
        func convert(option: String) -> String {
            var parts = option.replacing("^\\-+", target: "", options: .regularExpression).components(separatedBy: "-")
            let first = parts.removeFirst()
            if first == ":" {
                return "_colon"
            }
            if first == "#" {
                return "_progressBar2"
            }
            return "_\(first)\(parts.map({ $0.trimming.capitalized }).joined())".trimming.replacing(".", target: "_")
        }
        
        let ops = options.map {
            """
            /// \($0.options.joined(separator: ",")) \($0 is TmpArgOption ? "<\(($0 as! TmpArgOption).arg)>" : "")
            ///
            \($0.description.replacing("##", target: "`").components(separatedBy: "\n").map({ "/// \($0)" }).joined(separator: "\n"))
            \($0.options.map({ "static let \(convert(option: $0)) = \"\($0)\"" }).joined(separator: "\n"))
            """
        }.joined(separator: "\n\n")
        
        func joinspace(of option: String, type: String) -> String {
            let count = max(0, 23 - option.count)
            let spaces = Array(repeating: " ", count: count).joined()
            return "t(.\(option), \(spaces).\(type))"
        }
        
        let args = options.map {
            let key = convert(option: $0.options.last!)
            if $0.description.contains("the last set value will be used") {
                return joinspace(of: key, type: "lastOnly")
            }
            if $0.description.contains("multiple times has no extra effect") {
                return joinspace(of: key, type: "unique  ")
            }
            return joinspace(of: key, type: "multiple")
        }.joined(separator: "\n")
        print(args)
        print("")
    }
    
    private static func toJSON(_ options: [TmpOptionProtocol]) {
        guard let data = try? JSONSerialization.data(withJSONObject: options.map({ $0.keyValues }), options: .prettyPrinted),
              let jsonString = String(data: data, encoding: .utf8) else { return }
        
        print(jsonString)
    }
    
    private static func make(with optionString: String, description: String) -> TmpOptionProtocol {
        let optionString = optionString.replacing("&#35;", target: "#")
            .replacing("&lt;", target: "<")
            .replacing("&gt;", target: ">")
        
        let nstring = NSString(string: optionString.trimming)
        let lrange = nstring.range(of: "<")
        let rrange = nstring.range(of: ">")
        
        var optionStr = optionString
        var argStr: String?
        
        if lrange.location != NSNotFound && rrange.location != NSNotFound {
            optionStr = nstring.substring(to: lrange.location)
            argStr = nstring.substring(with: NSMakeRange(lrange.location + 1, rrange.location - lrange.location - 1)).trimming
        }
        
        let options = optionStr.components(separatedBy: ",").map({ $0.trimming })
        
        let description = description.replacing("<.*?>", target: "", options: .regularExpression)
            .replacing("&lt;", target: "<")
            .replacing("&gt;", target: ">")
            .replacing("&#39;", target: "'")
            .replacing("&#35;", target: "#")
            .replacing("&quot;", target: "\"")
            .trimming
                
        if let argStr = argStr, !argStr.isEmpty {
            return TmpArgOption(options: options, description: description, arg: argStr)
        } else {
            return TmpOption(options: options, description: description)
        }
    }
}

private extension String {
    func replacing(_ text: String, target: String, options: String.CompareOptions = .caseInsensitive) -> String {
        return replacingOccurrences(of: text, with: target, options: options)
    }
    
    var trimming: String {
        return trimmingCharacters(in: .whitespacesAndNewlines)
    }
}


///
/// --preproxy [protocol://]host[:port]
/// --proxy [protocol://]host[:port]
/// 需要把改成带有尖括号的普遍形式，如：
/// --preproxy &lt;[protocol://]host[:port]&gt;
/// --proxy &lt;[protocol://]host[:port]&gt;
///

private let optionSource =
"""
<p class="level0"><a name="--abstract-unix-socket"></a><span class="nroffip">--abstract-unix-socket &lt;path&gt;</span>
<p class="level1">(HTTP) Connect through an abstract Unix domain socket, instead of using the network. Note: netstat shows the path of an abstract socket prefixed with &#39;@&#39;, however the &lt;path&gt; argument should not have this leading character.
<p class="level1">If ##--abstract-unix-socket## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --abstract-unix-socket socketpath https://example.com
```
<p class="level1">
<p class="level1">See also ##--unix-socket##. Added in 7.53.0.

<p class="level0"><a name="--alt-svc"></a><span class="nroffip">--alt-svc &lt;file name&gt;</span>
<p class="level1">(HTTPS) This option enables the alt-svc parser in curl. If the file name points to an existing alt-svc cache file, that will be used. After a completed transfer, the cache will be saved to the file name again if it has been modified.
<p class="level1">Specify a &quot;&quot; file name (zero length) to avoid loading/saving and make curl just handle the cache in memory.
<p class="level1">If this option is used several times, curl will load contents from all the files but the last one will be used for saving.
<p class="level1">##--alt-svc## can be used several times in a command line
<p class="level1">Example:
```
curl --alt-svc svc.txt https://example.com
```
<p class="level1">
<p class="level1">See also ##--resolve## and ##--connect-to##. Added in 7.64.1.
<p class="level0"><a name="--anyauth"></a><span class="nroffip">--anyauth</span>
<p class="level1">(HTTP) Tells curl to figure out authentication method by itself, and use the most secure one the remote site claims to support. This is done by first doing a request and checking the response-headers, thus possibly inducing an extra network round-trip. This is used instead of setting a specific authentication method, which you can do with ##--basic##, ##--digest##, ##--ntlm##, and ##--negotiate##.
<p class="level1">Using ##--anyauth## is not recommended if you do uploads from stdin, since it may require data to be sent twice and then the client must be able to rewind. If the need should arise when uploading from stdin, the upload operation will fail.
<p class="level1">Used together with ##-u, --user##.
<p class="level1">Providing ##--anyauth## multiple times has no extra effect.
<p class="level1">Example:
```
curl --anyauth --user me:pwd https://example.com
```
<p class="level1">
<p class="level1">See also ##--proxy-anyauth##, ##--basic## and ##--digest##.
<p class="level0"><a name="-a"></a><span class="nroffip">-a, --append</span>
<p class="level1">(FTP SFTP) When used in an upload, this makes curl append to the target file instead of overwriting it. If the remote file does not exist, it will be created. Note that this flag is ignored by some SFTP servers (including OpenSSH).
<p class="level1">Providing ##-a, --append## multiple times has no extra effect. Disable it again with --no-append.
<p class="level1">Example:
```
curl --upload-file local --append ftp://example.com/
```
<p class="level1">
<p class="level1">See also ##-r, --range## and ##-C, --continue-at##.
<p class="level0"><a name="--aws-sigv4"></a><span class="nroffip">--aws-sigv4 &lt;provider1[:provider2[:region[:service]]]&gt;</span>
<p class="level1">Use AWS V4 signature authentication in the transfer.
<p class="level1">The provider argument is a string that is used by the algorithm when creating outgoing authentication headers.
<p class="level1">The region argument is a string that points to a geographic area of a resources collection (region-code) when the region name is omitted from the endpoint.
<p class="level1">The service argument is a string that points to a function provided by a cloud (service-code) when the service name is omitted from the endpoint.
<p class="level1">If ##--aws-sigv4## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --aws-sigv4 &quot;aws:amz:east-2:es&quot; --user &quot;key:secret&quot; https://example.com
```
<p class="level1">
<p class="level1">See also ##--basic## and ##-u, --user##. Added in 7.75.0.
<p class="level0"><a name="--basic"></a><span class="nroffip">--basic</span>
<p class="level1">(HTTP) Tells curl to use HTTP Basic authentication with the remote host. This is the default and this option is usually pointless, unless you use it to override a previously set option that sets a different authentication method (such as ##--ntlm##, ##--digest##, or ##--negotiate##).
<p class="level1">Used together with ##-u, --user##.
<p class="level1">Providing ##--basic## multiple times has no extra effect.
<p class="level1">Example:
```
curl -u name:password --basic https://example.com
```
<p class="level1">
<p class="level1">See also ##--proxy-basic##.
<p class="level0"><a name="--cacert"></a><span class="nroffip">--cacert &lt;file&gt;</span>
<p class="level1">(TLS) Tells curl to use the specified certificate file to verify the peer. The file may contain multiple CA certificates. The certificate(s) must be in PEM format. Normally curl is built to use a default file for this, so this option is typically used to alter that default file.
<p class="level1">curl recognizes the environment variable named &#39;CURL_CA_BUNDLE&#39; if it is set, and uses the given path as a path to a CA cert bundle. This option overrides that variable.
<p class="level1">The windows version of curl will automatically look for a CA certs file named &apos;curl-ca-bundle.crt&#39;, either in the same directory as curl.exe, or in the Current Working Directory, or in any folder along your PATH.
<p class="level1">If curl is built against the NSS SSL library, the NSS PEM PKCS&#35;11 module (libnsspem.so) needs to be available for this option to work properly.
<p class="level1">(iOS and macOS only) If curl is built against Secure Transport, then this option is supported for backward compatibility with other SSL engines, but it should not be set. If the option is not set, then curl will use the certificates in the system and user Keychain to verify the peer, which is the preferred method of verifying the peer&#39;s certificate chain.
<p class="level1">(Schannel only) This option is supported for Schannel in Windows 7 or later with libcurl 7.60 or later. This option is supported for backward compatibility with other SSL engines; instead it is recommended to use Windows&#39; store of root certificates (the default for Schannel).
<p class="level1">If ##--cacert## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --cacert CA-file.txt https://example.com
```
<p class="level1">
<p class="level1">See also ##--capath## and ##-k, --insecure##.
<p class="level0"><a name="--capath"></a><span class="nroffip">--capath &lt;dir&gt;</span>
<p class="level1">(TLS) Tells curl to use the specified certificate directory to verify the peer. Multiple paths can be provided by separating them with &quot;:&quot; (e.g. &quot;path1:path2:path3&quot;). The certificates must be in PEM format, and if curl is built against OpenSSL, the directory must have been processed using the c_rehash utility supplied with OpenSSL. Using ##--capath## can allow OpenSSL-powered curl to make SSL-connections much more efficiently than using ##--cacert## if the ##--cacert## file contains many CA certificates.
<p class="level1">If this option is set, the default capath value will be ignored.
<p class="level1">If ##--capath## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --capath /local/directory https://example.com
```
<p class="level1">
<p class="level1">See also ##--cacert## and ##-k, --insecure##.
<p class="level0"><a name="--cert-status"></a><span class="nroffip">--cert-status</span>
<p class="level1">(TLS) Tells curl to verify the status of the server certificate by using the Certificate Status Request (aka. OCSP stapling) TLS extension.
<p class="level1">If this option is enabled and the server sends an invalid (e.g. expired) response, if the response suggests that the server certificate has been revoked, or no response at all is received, the verification fails.
<p class="level1">This is currently only implemented in the OpenSSL, GnuTLS and NSS backends.
<p class="level1">Providing ##--cert-status## multiple times has no extra effect. Disable it again with --no-cert-status.
<p class="level1">Example:
```
curl --cert-status https://example.com
```
<p class="level1">
<p class="level1">See also ##--pinnedpubkey##. Added in 7.41.0.
<p class="level0"><a name="--cert-type"></a><span class="nroffip">--cert-type &lt;type&gt;</span>
<p class="level1">(TLS) Tells curl what type the provided client certificate is using. PEM, DER, ENG and P12 are recognized types.
<p class="level1">The default type depends on the TLS backend and is usually PEM, however for Secure Transport and Schannel it is P12. If ##-E, --cert## is a pkcs11: URI then ENG is the default type.
<p class="level1">If ##--cert-type## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --cert-type PEM --cert file https://example.com
```
<p class="level1">
<p class="level1">See also ##-E, --cert##, ##--key## and ##--key-type##.
<p class="level0"><a name="-E"></a><span class="nroffip">-E, --cert &lt;certificate[:password]&gt;</span>
<p class="level1">(TLS) Tells curl to use the specified client certificate file when getting a file with HTTPS, FTPS or another SSL-based protocol. The certificate must be in PKCS&#35;12 format if using Secure Transport, or PEM format if using any other engine. If the optional password is not specified, it will be queried for on the terminal. Note that this option assumes a certificate file that is the private key and the client certificate concatenated. See ##-E, --cert## and ##--key## to specify them independently.
<p class="level1">In the &lt;certificate&gt; portion of the argument, you must escape the character &quot;:&quot; as &quot;&bsol;:&quot; so that it is not recognized as the password delimiter. Similarly, you must escape the character &quot;&bsol;&quot; as &quot;&bsol;&bsol;&quot; so that it is not recognized as an escape character.
<p class="level1">If curl is built against the NSS SSL library then this option can tell curl the nickname of the certificate to use within the NSS database defined by the environment variable SSL_DIR (or by default /etc/pki/nssdb). If the NSS PEM PKCS&#35;11 module (libnsspem.so) is available then PEM files may be loaded.
<p class="level1">If you provide a path relative to the current directory, you must prefix the path with &quot;./&quot; in order to avoid confusion with an NSS database nickname.
<p class="level1">If curl is built against OpenSSL library, and the engine pkcs11 is available, then a PKCS&#35;11 URI (RFC 7512) can be used to specify a certificate located in a PKCS&#35;11 device. A string beginning with &quot;pkcs11:&quot; will be interpreted as a PKCS&#35;11 URI. If a PKCS&#35;11 URI is provided, then the ##--engine## option will be set as &quot;pkcs11&quot; if none was provided and the ##--cert-type## option will be set as &quot;ENG&quot; if none was provided.
<p class="level1">(iOS and macOS only) If curl is built against Secure Transport, then the certificate string can either be the name of a certificate/private key in the system or user keychain, or the path to a PKCS&#35;12-encoded certificate and private key. If you want to use a file from the current directory, please precede it with &quot;./&quot; prefix, in order to avoid confusion with a nickname.
<p class="level1">(Schannel only) Client certificates must be specified by a path expression to a certificate store. (Loading PFX is not supported; you can import it to a store first). You can use &quot;&lt;store location&gt;&bsol;&lt;store name&gt;&bsol;&lt;thumbprint&gt;&quot; to refer to a certificate in the system certificates store, for example, &quot;CurrentUser&bsol;MY&bsol;934a7ac6f8a5d579285a74fa61e19f23ddfe8d7a&quot;. Thumbprint is usually a SHA-1 hex string which you can see in certificate details. Following store locations are supported: CurrentUser, LocalMachine, CurrentService, Services, CurrentUserGroupPolicy, LocalMachineGroupPolicy, LocalMachineEnterprise.
<p class="level1">If ##-E, --cert## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --cert certfile --key keyfile https://example.com
```
<p class="level1">
<p class="level1">See also ##--cert-type##, ##--key## and ##--key-type##.
<p class="level0"><a name="--ciphers"></a><span class="nroffip">--ciphers &lt;list of ciphers&gt;</span>
<p class="level1">(TLS) Specifies which ciphers to use in the connection. The list of ciphers must specify valid ciphers. Read up on SSL cipher list details on this URL:
<p class="level1">
```
https://curl.se/docs/ssl-ciphers.html
```
<p class="level1">
<p class="level1">If ##--ciphers## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --ciphers ECDHE-ECDSA-AES256-CCM8 https://example.com
```
<p class="level1">
<p class="level1">See also ##--tlsv1.3##.
<p class="level0"><a name="--compressed-ssh"></a><span class="nroffip">--compressed-ssh</span>
<p class="level1">(SCP SFTP) Enables built-in SSH compression. This is a request, not an order; the server may or may not do it.
<p class="level1">Providing ##--compressed-ssh## multiple times has no extra effect. Disable it again with --no-compressed-ssh.
<p class="level1">Example:
```
curl --compressed-ssh sftp://example.com/
```
<p class="level1">
<p class="level1">See also ##--compressed##. Added in 7.56.0.
<p class="level0"><a name="--compressed"></a><span class="nroffip">--compressed</span>
<p class="level1">(HTTP) Request a compressed response using one of the algorithms curl supports, and automatically decompress the content. Headers are not modified.
<p class="level1">If this option is used and the server sends an unsupported encoding, curl will report an error. This is a request, not an order; the server may or may not deliver data compressed.
<p class="level1">Providing ##--compressed## multiple times has no extra effect. Disable it again with --no-compressed.
<p class="level1">Example:
```
curl --compressed https://example.com
```
<p class="level1">
<p class="level1">See also ##--compressed-ssh##.
<p class="level0"><a name="-K"></a><span class="nroffip">-K, --config &lt;file&gt;</span>
<p class="level1">Specify a text file to read curl arguments from. The command line arguments found in the text file will be used as if they were provided on the command line.
<p class="level1">Options and their parameters must be specified on the same line in the file, separated by whitespace, colon, or the equals sign. Long option names can optionally be given in the config file without the initial double dashes and if so, the colon or equals characters can be used as separators. If the option is specified with one or two dashes, there can be no colon or equals character between the option and its parameter.
<p class="level1">If the parameter contains whitespace (or starts with : or =), the parameter must be enclosed within quotes. Within double quotes, the following escape sequences are available: &bsol;&bsol;, &bsol;&quot;, &bsol;t, &bsol;n, &bsol;r and &bsol;v. A backslash preceding any other letter is ignored.
<p class="level1">If the first column of a config line is a &#39;&#35;&#39; character, the rest of the line will be treated as a comment.
<p class="level1">Only write one option per physical line in the config file.
<p class="level1">Specify the filename to ##-K, --config## as &#39;-&#39; to make curl read the file from stdin.
<p class="level1">Note that to be able to specify a URL in the config file, you need to specify it using the ##--url## option, and not by simply writing the URL on its own line. So, it could look similar to this:
<p class="level1">url = &quot;<a href="https://curl.se/docs/&quot;">https://curl.se/docs/&quot;</a>
<p class="level1">
```
&#35; --- Example file ---
&#35; this is a comment
url = &quot;example.com&quot;
output = &quot;curlhere.html&quot;
user-agent = &quot;superagent/1.0&quot;
```
<p class="level1">
<p class="level1">
```
&#35; and fetch another URL too
url = &quot;example.com/docs/manpage.html&quot;
-O
referer = &quot;http://nowhereatall.example.com/&quot;
&#35; --- End of example file ---
```
<p class="level1">
<p class="level1">When curl is invoked, it (unless ##-q, --disable## is used) checks for a default config file and uses it if found, even when ##-K, --config## is used. The default config file is checked for in the following places in this order:
<p class="level1">1) &quot;$CURL_HOME/.curlrc&quot;
<p class="level1">2) &quot;$XDG_CONFIG_HOME/.curlrc&quot; (Added in 7.73.0)
<p class="level1">3) &quot;$HOME/.curlrc&quot;
<p class="level1">4) Windows: &quot;%USERPROFILE%&bsol;.curlrc&quot;
<p class="level1">5) Windows: &quot;%APPDATA%&bsol;.curlrc&quot;
<p class="level1">6) Windows: &quot;%USERPROFILE%&bsol;Application Data&bsol;.curlrc&quot;
<p class="level1">7) Non-Windows: use getpwuid to find the home directory
<p class="level1">8) On Windows, if it finds no .curlrc file in the sequence described above, it checks for one in the same dir the curl executable is placed.
<p class="level1">On Windows two filenames are checked per location: .curlrc and _curlrc, preferring the former. Older versions on Windows checked for _curlrc only.
<p class="level1">##-K, --config## can be used several times in a command line
<p class="level1">Example:
```
curl --config file.txt https://example.com
```
<p class="level1">
<p class="level1">See also ##-q, --disable##.
<p class="level0"><a name="--connect-timeout"></a><span class="nroffip">--connect-timeout &lt;fractional seconds&gt;</span>
<p class="level1">Maximum time in seconds that you allow curl&#39;s connection to take.  This only limits the connection phase, so if curl connects within the given period it will continue - if not it will exit.  Since version 7.32.0, this option accepts decimal values.
<p class="level1">The &quot;connection phase&quot; is considered complete when the requested TCP, TLS or QUIC handshakes are done.
<p class="level1">The decimal value needs to provided using a dot (.) as decimal separator - not the local version even if it might be using another separator.
<p class="level1">If ##--connect-timeout## is provided several times, the last set value will be used.
<p class="level1">Examples:
```
curl --connect-timeout 20 https://example.com
curl --connect-timeout 3.14 https://example.com
```
<p class="level1">
<p class="level1">See also ##-m, --max-time##.
<p class="level0"><a name="--connect-to"></a><span class="nroffip">--connect-to &lt;HOST1:PORT1:HOST2:PORT2&gt;</span>
<p class="level1">
<p class="level1">For a request to the given HOST1:PORT1 pair, connect to HOST2:PORT2 instead. This option is suitable to direct requests at a specific server, e.g. at a specific cluster node in a cluster of servers. This option is only used to establish the network connection. It does NOT affect the hostname/port that is used for TLS/SSL (e.g. SNI, certificate verification) or for the application protocols. &quot;HOST1&quot; and &quot;PORT1&quot; may be the empty string, meaning &quot;any host/port&quot;. &quot;HOST2&quot; and &quot;PORT2&quot; may also be the empty string, meaning &quot;use the request&#39;s original host/port&quot;.
<p class="level1">A &quot;host&quot; specified to this option is compared as a string, so it needs to match the name used in request URL. It can be either numerical such as &quot;127.0.0.1&quot; or the full host name such as &quot;example.org&quot;.
<p class="level1">##--connect-to## can be used several times in a command line
<p class="level1">Example:
```
curl --connect-to example.com:443:example.net:8443 https://example.com
```
<p class="level1">
<p class="level1">See also ##--resolve## and ##-H, --header##. Added in 7.49.0.
<p class="level0"><a name="-C"></a><span class="nroffip">-C, --continue-at &lt;offset&gt;</span>
<p class="level1">Continue/Resume a previous file transfer at the given offset. The given offset is the exact number of bytes that will be skipped, counting from the beginning of the source file before it is transferred to the destination. If used with uploads, the FTP server command SIZE will not be used by curl.
<p class="level1">Use &quot;-C -&quot; to tell curl to automatically find out where/how to resume the transfer. It then uses the given output/input files to figure that out.
<p class="level1">If ##-C, --continue-at## is provided several times, the last set value will be used.
<p class="level1">Examples:
```
curl -C - https://example.com
curl -C 400 https://example.com
```
<p class="level1">
<p class="level1">See also ##-r, --range##.
<p class="level0"><a name="-c"></a><span class="nroffip">-c, --cookie-jar &lt;filename&gt;</span>
<p class="level1">(HTTP) Specify to which file you want curl to write all cookies after a completed operation. Curl writes all cookies from its in-memory cookie storage to the given file at the end of operations. If no cookies are known, no data will be written. The file will be written using the Netscape cookie file format. If you set the file name to a single dash, &quot;-&quot;, the cookies will be written to stdout.
<p class="level1">This command line option will activate the cookie engine that makes curl record and use cookies. Another way to activate it is to use the ##-b, --cookie## option.
<p class="level1">If the cookie jar cannot be created or written to, the whole curl operation will not fail or even report an error clearly. Using ##-v, --verbose## will get a warning displayed, but that is the only visible feedback you get about this possibly lethal situation.
<p class="level1">If ##-c, --cookie-jar## is provided several times, the last set value will be used.
<p class="level1">Examples:
```
curl -c store-here.txt https://example.com
curl -c store-here.txt -b read-these https://example.com
```
<p class="level1">
<p class="level1">See also ##-b, --cookie##.
<p class="level0"><a name="-b"></a><span class="nroffip">-b, --cookie &lt;data|filename&gt;</span>
<p class="level1">(HTTP) Pass the data to the HTTP server in the Cookie header. It is supposedly the data previously received from the server in a &quot;Set-Cookie:&quot; line. The data should be in the format &quot;NAME1=VALUE1; NAME2=VALUE2&quot;. This makes curl use the cookie header with this content explicitly in all outgoing request(s). If multiple requests are done due to authentication, followed redirects or similar, they will all get this cookie passed on.
<p class="level1">If no &#39;=&#39; symbol is used in the argument, it is instead treated as a filename to read previously stored cookie from. This option also activates the cookie engine which will make curl record incoming cookies, which may be handy if you are using this in combination with the ##-L, --location## option or do multiple URL transfers on the same invoke. If the file name is exactly a minus (&quot;-&quot;), curl will instead read the contents from stdin.
<p class="level1">The file format of the file to read cookies from should be plain HTTP headers (Set-Cookie style) or the Netscape/Mozilla cookie file format.
<p class="level1">The file specified with ##-b, --cookie## is only used as input. No cookies will be written to the file. To store cookies, use the ##-c, --cookie-jar## option.
<p class="level1">If you use the Set-Cookie file format and do not specify a domain then the cookie is not sent since the domain will never match. To address this, set a domain in Set-Cookie line (doing that will include sub-domains) or preferably: use the Netscape format.
<p class="level1">Users often want to both read cookies from a file and write updated cookies back to a file, so using both ##-b, --cookie## and ##-c, --cookie-jar## in the same command line is common.
<p class="level1">##-b, --cookie## can be used several times in a command line
<p class="level1">Examples:
```
curl -b cookiefile https://example.com
curl -b cookiefile -c cookiefile https://example.com
```
<p class="level1">
<p class="level1">See also ##-c, --cookie-jar## and ##-j, --junk-session-cookies##.
<p class="level0"><a name="--create-dirs"></a><span class="nroffip">--create-dirs</span>
<p class="level1">When used in conjunction with the ##-o, --output## option, curl will create the necessary local directory hierarchy as needed. This option creates the directories mentioned with the ##-o, --output## option, nothing else. If the ##-o, --output## file name uses no directory, or if the directories it mentions already exist, no directories will be created.
<p class="level1">Created dirs are made with mode 0750 on unix style file systems.
<p class="level1">To create remote directories when using FTP or SFTP, try ##--ftp-create-dirs##.
<p class="level1">Providing ##--create-dirs## multiple times has no extra effect. Disable it again with --no-create-dirs.
<p class="level1">Example:
```
curl --create-dirs --output local/dir/file https://example.com
```
<p class="level1">
<p class="level1">See also ##--ftp-create-dirs## and ##--output-dir##.
<p class="level0"><a name="--create-file-mode"></a><span class="nroffip">--create-file-mode &lt;mode&gt;</span>
<p class="level1">(SFTP SCP FILE) When curl is used to create files remotely using one of the supported protocols, this option allows the user to set which &#39;mode&#39; to set on the file at creation time, instead of the default 0644.
<p class="level1">This option takes an octal number as argument.
<p class="level1">If ##--create-file-mode## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --create-file-mode 0777 -T localfile sftp://example.com/new
```
<p class="level1">
<p class="level1">See also ##--ftp-create-dirs##. Added in 7.75.0.
<p class="level0"><a name="--crlf"></a><span class="nroffip">--crlf</span>
<p class="level1">(FTP SMTP) Convert LF to CRLF in upload. Useful for MVS (OS/390).
<p class="level1">(SMTP added in 7.40.0)
<p class="level1">Providing ##--crlf## multiple times has no extra effect. Disable it again with --no-crlf.
<p class="level1">Example:
```
curl --crlf -T file ftp://example.com/
```
<p class="level1">
<p class="level1">See also ##-B, --use-ascii##.
<p class="level0"><a name="--crlfile"></a><span class="nroffip">--crlfile &lt;file&gt;</span>
<p class="level1">(TLS) Provide a file using PEM format with a Certificate Revocation List that may specify peer certificates that are to be considered revoked.
<p class="level1">If ##--crlfile## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --crlfile rejects.txt https://example.com
```
<p class="level1">
<p class="level1">See also ##--cacert## and ##--capath##.
<p class="level0"><a name="--curves"></a><span class="nroffip">--curves &lt;algorithm list&gt;</span>
<p class="level1">(TLS) Tells curl to request specific curves to use during SSL session establishment according to <a href="http://www.ietf.org/rfc/rfc8422.txt">RFC 8422</a>, 5.1.  Multiple algorithms can be provided by separating them with &quot;:&quot; (e.g.  &quot;X25519:P-521&quot;).  The parameter is available identically in the &quot;openssl s_client/s_server&quot; utilities.
<p class="level1">##--curves## allows a OpenSSL powered curl to make SSL-connections with exactly the (EC) curve requested by the client, avoiding nontransparent client/server negotiations.
<p class="level1">If this option is set, the default curves list built into openssl will be ignored.
<p class="level1">If ##--curves## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --curves X25519 https://example.com
```
<p class="level1">
<p class="level1">See also ##--ciphers##. Added in 7.73.0.
<p class="level0"><a name="--data-ascii"></a><span class="nroffip">--data-ascii &lt;data&gt;</span>
<p class="level1">(HTTP) This is just an alias for ##-d, --data##.
<p class="level1">##--data-ascii## can be used several times in a command line
<p class="level1">Example:
```
curl --data-ascii @file https://example.com
```
<p class="level1">
<p class="level1">See also ##--data-binary##, ##--data-raw## and ##--data-urlencode##.
<p class="level0"><a name="--data-binary"></a><span class="nroffip">--data-binary &lt;data&gt;</span>
<p class="level1">(HTTP) This posts data exactly as specified with no extra processing whatsoever.
<p class="level1">If you start the data with the letter @, the rest should be a filename. Data is posted in a similar manner as ##-d, --data## does, except that newlines and carriage returns are preserved and conversions are never done.
<p class="level1">Like ##-d, --data## the default content-type sent to the server is application/x-www-form-urlencoded. If you want the data to be treated as arbitrary binary data by the server then set the content-type to octet-stream: -H &quot;Content-Type: application/octet-stream&quot;.
<p class="level1">If this option is used several times, the ones following the first will append data as described in ##-d, --data##.
<p class="level1">##--data-binary## can be used several times in a command line
<p class="level1">Example:
```
curl --data-binary @filename https://example.com
```
<p class="level1">
<p class="level1">See also ##--data-ascii##.
<p class="level0"><a name="--data-raw"></a><span class="nroffip">--data-raw &lt;data&gt;</span>
<p class="level1">(HTTP) This posts data similarly to ##-d, --data## but without the special interpretation of the @ character.
<p class="level1">##--data-raw## can be used several times in a command line
<p class="level1">Examples:
```
curl --data-raw &quot;hello&quot; https://example.com
curl --data-raw &quot;@at@at@&quot; https://example.com
```
<p class="level1">
<p class="level1">See also ##-d, --data##. Added in 7.43.0.
<p class="level0"><a name="--data-urlencode"></a><span class="nroffip">--data-urlencode &lt;data&gt;</span>
<p class="level1">(HTTP) This posts data, similar to the other ##-d, --data## options with the exception that this performs URL-encoding.
<p class="level1">To be CGI-compliant, the &lt;data&gt; part should begin with a <span Class="emphasis">name</span> followed by a separator and a content specification. The &lt;data&gt; part can be passed to curl using one of the following syntaxes:
<p class="level2">
<p class="level1"><a name="content"></a><span class="nroffip">content</span>
<p class="level2">This will make curl URL-encode the content and pass that on. Just be careful so that the content does not contain any = or @ symbols, as that will then make the syntax match one of the other cases below!
<p class="level1"><a name="content"></a><span class="nroffip">=content</span>
<p class="level2">This will make curl URL-encode the content and pass that on. The preceding = symbol is not included in the data.
<p class="level1"><a name="namecontent"></a><span class="nroffip">name=content</span>
<p class="level2">This will make curl URL-encode the content part and pass that on. Note that the name part is expected to be URL-encoded already.
<p class="level1"><a name="filename"></a><span class="nroffip">@filename</span>
<p class="level2">This will make curl load data from the given file (including any newlines), URL-encode that data and pass it on in the POST.
<p class="level1"><a name="namefilename"></a><span class="nroffip">name@filename</span>
<p class="level2">This will make curl load data from the given file (including any newlines), URL-encode that data and pass it on in the POST. The name part gets an equal sign appended, resulting in <span Class="emphasis">name=urlencoded-file-content</span>. Note that the name is expected to be URL-encoded already.
<p class="level1">
<p class="level1">##--data-urlencode## can be used several times in a command line
<p class="level1">Examples:
```
curl --data-urlencode name=val https://example.com
curl --data-urlencode =encodethis https://example.com
curl --data-urlencode name@file https://example.com
curl --data-urlencode @fileonly https://example.com
```
<p class="level1">
<p class="level1">See also ##-d, --data## and ##--data-raw##.
<p class="level0"><a name="-d"></a><span class="nroffip">-d, --data &lt;data&gt;</span>
<p class="level1">(HTTP MQTT) Sends the specified data in a POST request to the HTTP server, in the same way that a browser does when a user has filled in an HTML form and presses the submit button. This will cause curl to pass the data to the server using the content-type application/x-www-form-urlencoded. Compare to ##-F, --form##.
<p class="level1">##--data-raw## is almost the same but does not have a special interpretation of the @ character. To post data purely binary, you should instead use the ##--data-binary## option. To URL-encode the value of a form field you may use ##--data-urlencode##.
<p class="level1">If any of these options is used more than once on the same command line, the data pieces specified will be merged with a separating &amp;-symbol. Thus, using &apos;-d name=daniel -d skill=lousy&#39; would generate a post chunk that looks like &apos;name=daniel&amp;skill=lousy&#39;.
<p class="level1">If you start the data with the letter @, the rest should be a file name to read the data from, or - if you want curl to read the data from stdin. Posting data from a file named &#39;foobar&#39; would thus be done with ##-d, --data## @foobar. When ##-d, --data## is told to read from a file like that, carriage returns and newlines will be stripped out. If you do not want the @ character to have a special interpretation use ##--data-raw## instead.
<p class="level1">##-d, --data## can be used several times in a command line
<p class="level1">Examples:
```
curl -d &quot;name=curl&quot; https://example.com
curl -d &quot;name=curl&quot; -d &quot;tool=cmdline&quot; https://example.com
curl -d @filename https://example.com
```
<p class="level1">
<p class="level1">See also ##--data-binary##, ##--data-urlencode## and ##--data-raw##. This option is mutually exclusive to ##-F, --form## and ##-I, --head## and ##-T, --upload-file##.
<p class="level0"><a name="--delegation"></a><span class="nroffip">--delegation &lt;LEVEL&gt;</span>
<p class="level1">(GSS/kerberos) Set LEVEL to tell the server what it is allowed to delegate when it comes to user credentials.
<p class="level2">
<p class="level1"><a name="none"></a><span class="nroffip">none</span>
<p class="level2">Do not allow any delegation.
<p class="level1"><a name="policy"></a><span class="nroffip">policy</span>
<p class="level2">Delegates if and only if the OK-AS-DELEGATE flag is set in the Kerberos service ticket, which is a matter of realm policy.
<p class="level1"><a name="always"></a><span class="nroffip">always</span>
<p class="level2">Unconditionally allow the server to delegate.
<p class="level1">
<p class="level1">If ##--delegation## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --delegation &quot;none&quot; https://example.com
```
<p class="level1">
<p class="level1">See also ##-k, --insecure## and ##--ssl##.
<p class="level0"><a name="--digest"></a><span class="nroffip">--digest</span>
<p class="level1">(HTTP) Enables HTTP Digest authentication. This is an authentication scheme that prevents the password from being sent over the wire in clear text. Use this in combination with the normal ##-u, --user## option to set user name and password.
<p class="level1">Providing ##--digest## multiple times has no extra effect. Disable it again with --no-digest.
<p class="level1">Example:
```
curl -u name:password --digest https://example.com
```
<p class="level1">
<p class="level1">See also ##-u, --user##, ##--proxy-digest## and ##--anyauth##. This option is mutually exclusive to ##--basic## and ##--ntlm## and ##--negotiate##.
<p class="level0"><a name="--disable-eprt"></a><span class="nroffip">--disable-eprt</span>
<p class="level1">(FTP) Tell curl to disable the use of the EPRT and LPRT commands when doing active FTP transfers. Curl will normally always first attempt to use EPRT, then LPRT before using PORT, but with this option, it will use PORT right away. EPRT and LPRT are extensions to the original FTP protocol, and may not work on all servers, but they enable more functionality in a better way than the traditional PORT command.
<p class="level1">--eprt can be used to explicitly enable EPRT again and --no-eprt is an alias for ##--disable-eprt##.
<p class="level1">If the server is accessed using IPv6, this option will have no effect as EPRT is necessary then.
<p class="level1">Disabling EPRT only changes the active behavior. If you want to switch to passive mode you need to not use ##-P, --ftp-port## or force it with ##--ftp-pasv##.
<p class="level1">Providing ##--disable-eprt## multiple times has no extra effect. Disable it again with --no-disable-eprt.
<p class="level1">Example:
```
curl --disable-eprt ftp://example.com/
```
<p class="level1">
<p class="level1">See also ##--disable-epsv## and ##-P, --ftp-port##.
<p class="level0"><a name="--disable-epsv"></a><span class="nroffip">--disable-epsv</span>
<p class="level1">(FTP) Tell curl to disable the use of the EPSV command when doing passive FTP transfers. Curl will normally always first attempt to use EPSV before PASV, but with this option, it will not try using EPSV.
<p class="level1">--epsv can be used to explicitly enable EPSV again and --no-epsv is an alias for ##--disable-epsv##.
<p class="level1">If the server is an IPv6 host, this option will have no effect as EPSV is necessary then.
<p class="level1">Disabling EPSV only changes the passive behavior. If you want to switch to active mode you need to use ##-P, --ftp-port##.
<p class="level1">Providing ##--disable-epsv## multiple times has no extra effect. Disable it again with --no-disable-epsv.
<p class="level1">Example:
```
curl --disable-epsv ftp://example.com/
```
<p class="level1">
<p class="level1">See also ##--disable-eprt## and ##-P, --ftp-port##.
<p class="level0"><a name="-q"></a><span class="nroffip">-q, --disable</span>
<p class="level1">If used as the first parameter on the command line, the <span Class="emphasis">curlrc</span> config file will not be read and used. See the ##-K, --config## for details on the default config file search path.
<p class="level1">Providing ##-q, --disable## multiple times has no extra effect. Disable it again with --no-disable.
<p class="level1">Example:
```
curl -q https://example.com
```
<p class="level1">
<p class="level1">See also ##-K, --config##.
<p class="level0"><a name="--disallow-username-in-url"></a><span class="nroffip">--disallow-username-in-url</span>
<p class="level1">(HTTP) This tells curl to exit if passed a URL containing a username. This is probably most useful when the URL is being provided at runtime or similar.
<p class="level1">Providing ##--disallow-username-in-url## multiple times has no extra effect. Disable it again with --no-disallow-username-in-url.
<p class="level1">Example:
```
curl --disallow-username-in-url https://example.com
```
<p class="level1">
<p class="level1">See also ##--proto##. Added in 7.61.0.
<p class="level0"><a name="--dns-interface"></a><span class="nroffip">--dns-interface &lt;interface&gt;</span>
<p class="level1">(DNS) Tell curl to send outgoing DNS requests through &lt;interface&gt;. This option is a counterpart to ##--interface## (which does not affect DNS). The supplied string must be an interface name (not an address).
<p class="level1">If ##--dns-interface## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --dns-interface eth0 https://example.com
```
<p class="level1">
<p class="level1">See also ##--dns-ipv4-addr## and ##--dns-ipv6-addr##. ##--dns-interface## requires that the underlying libcurl was built to support c-ares. Added in 7.33.0.
<p class="level0"><a name="--dns-ipv4-addr"></a><span class="nroffip">--dns-ipv4-addr &lt;address&gt;</span>
<p class="level1">(DNS) Tell curl to bind to &lt;ip-address&gt; when making IPv4 DNS requests, so that the DNS requests originate from this address. The argument should be a single IPv4 address.
<p class="level1">If ##--dns-ipv4-addr## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --dns-ipv4-addr 10.1.2.3 https://example.com
```
<p class="level1">
<p class="level1">See also ##--dns-interface## and ##--dns-ipv6-addr##. ##--dns-ipv4-addr## requires that the underlying libcurl was built to support c-ares. Added in 7.33.0.
<p class="level0"><a name="--dns-ipv6-addr"></a><span class="nroffip">--dns-ipv6-addr &lt;address&gt;</span>
<p class="level1">(DNS) Tell curl to bind to &lt;ip-address&gt; when making IPv6 DNS requests, so that the DNS requests originate from this address. The argument should be a single IPv6 address.
<p class="level1">If ##--dns-ipv6-addr## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --dns-ipv6-addr 2a04:4e42::561 https://example.com
```
<p class="level1">
<p class="level1">See also ##--dns-interface## and ##--dns-ipv4-addr##. ##--dns-ipv6-addr## requires that the underlying libcurl was built to support c-ares. Added in 7.33.0.
<p class="level0"><a name="--dns-servers"></a><span class="nroffip">--dns-servers &lt;addresses&gt;</span>
<p class="level1">Set the list of DNS servers to be used instead of the system default. The list of IP addresses should be separated with commas. Port numbers may also optionally be given as <span Class="emphasis">:&lt;port-number&gt;</span> after each IP address.
<p class="level1">If ##--dns-servers## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --dns-servers 192.168.0.1,192.168.0.2 https://example.com
```
<p class="level1">
<p class="level1">See also ##--dns-interface## and ##--dns-ipv4-addr##. ##--dns-servers## requires that the underlying libcurl was built to support c-ares. Added in 7.33.0.
<p class="level0"><a name="--doh-cert-status"></a><span class="nroffip">--doh-cert-status</span>
<p class="level1">Same as ##--cert-status## but used for DoH (DNS-over-HTTPS).
<p class="level1">Providing ##--doh-cert-status## multiple times has no extra effect. Disable it again with --no-doh-cert-status.
<p class="level1">Example:
```
curl --doh-cert-status --doh-url https://doh.example https://example.com
```
<p class="level1">
<p class="level1">See also ##--doh-insecure##. Added in 7.76.0.
<p class="level0"><a name="--doh-insecure"></a><span class="nroffip">--doh-insecure</span>
<p class="level1">Same as ##-k, --insecure## but used for DoH (DNS-over-HTTPS).
<p class="level1">Providing ##--doh-insecure## multiple times has no extra effect. Disable it again with --no-doh-insecure.
<p class="level1">Example:
```
curl --doh-insecure --doh-url https://doh.example https://example.com
```
<p class="level1">
<p class="level1">See also ##--doh-url##. Added in 7.76.0.
<p class="level0"><a name="--doh-url"></a><span class="nroffip">--doh-url &lt;URL&gt;</span>
<p class="level1">Specifies which DNS-over-HTTPS (DoH) server to use to resolve hostnames, instead of using the default name resolver mechanism. The URL must be HTTPS.
<p class="level1">Some SSL options that you set for your transfer will apply to DoH since the name lookups take place over SSL. However, the certificate verification settings are not inherited and can be controlled separately via ##--doh-insecure## and ##--doh-cert-status##.
<p class="level1">This option is unset if an empty string &quot;&quot; is used as the URL. (Added in 7.85.0)
<p class="level1">If ##--doh-url## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --doh-url https://doh.example https://example.com
```
<p class="level1">
<p class="level1">See also ##--doh-insecure##. Added in 7.62.0.
<p class="level0"><a name="-D"></a><span class="nroffip">-D, --dump-header &lt;filename&gt;</span>
<p class="level1">(HTTP FTP) Write the received protocol headers to the specified file. If no headers are received, the use of this option will create an empty file.
<p class="level1">When used in FTP, the FTP server response lines are considered being &quot;headers&quot; and thus are saved there.
<p class="level1">Having multiple transfers in one set of operations (i.e. the URLs in one ##-:, --next## clause), will append them to the same file, separated by a blank line.
<p class="level1">If ##-D, --dump-header## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --dump-header store.txt https://example.com
```
<p class="level1">
<p class="level1">See also ##-o, --output##.
<p class="level0"><a name="--egd-file"></a><span class="nroffip">--egd-file &lt;file&gt;</span>
<p class="level1">(TLS) Deprecated option. This option is ignored by curl since 7.84.0. Prior to that it only had an effect on curl if built to use old versions of OpenSSL.
<p class="level1">Specify the path name to the Entropy Gathering Daemon socket. The socket is used to seed the random engine for SSL connections.
<p class="level1">If ##--egd-file## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --egd-file /random/here https://example.com
```
<p class="level1">
<p class="level1">See also ##--random-file##.
<p class="level0"><a name="--engine"></a><span class="nroffip">--engine &lt;name&gt;</span>
<p class="level1">(TLS) Select the OpenSSL crypto engine to use for cipher operations. Use ##--engine## list to print a list of build-time supported engines. Note that not all (and possibly none) of the engines may be available at runtime.
<p class="level1">If ##--engine## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --engine flavor https://example.com
```
<p class="level1">
<p class="level1">See also ##--ciphers## and ##--curves##.
<p class="level0"><a name="--etag-compare"></a><span class="nroffip">--etag-compare &lt;file&gt;</span>
<p class="level1">(HTTP) This option makes a conditional HTTP request for the specific ETag read from the given file by sending a custom If-None-Match header using the stored ETag.
<p class="level1">For correct results, make sure that the specified file contains only a single line with the desired ETag. An empty file is parsed as an empty ETag.
<p class="level1">Use the option ##--etag-save## to first save the ETag from a response, and then use this option to compare against the saved ETag in a subsequent request.
<p class="level1">If ##--etag-compare## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --etag-compare etag.txt https://example.com
```
<p class="level1">
<p class="level1">See also ##--etag-save## and ##-z, --time-cond##. Added in 7.68.0.
<p class="level0"><a name="--etag-save"></a><span class="nroffip">--etag-save &lt;file&gt;</span>
<p class="level1">(HTTP) This option saves an HTTP ETag to the specified file. An ETag is a caching related header, usually returned in a response.
<p class="level1">If no ETag is sent by the server, an empty file is created.
<p class="level1">If ##--etag-save## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --etag-save storetag.txt https://example.com
```
<p class="level1">
<p class="level1">See also ##--etag-compare##. Added in 7.68.0.
<p class="level0"><a name="--expect100-timeout"></a><span class="nroffip">--expect100-timeout &lt;seconds&gt;</span>
<p class="level1">(HTTP) Maximum time in seconds that you allow curl to wait for a 100-continue response when curl emits an Expects: 100-continue header in its request. By default curl will wait one second. This option accepts decimal values! When curl stops waiting, it will continue as if the response has been received.
<p class="level1">The decimal value needs to provided using a dot (.) as decimal separator - not the local version even if it might be using another separator.
<p class="level1">If ##--expect100-timeout## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --expect100-timeout 2.5 -T file https://example.com
```
<p class="level1">
<p class="level1">See also ##--connect-timeout##. Added in 7.47.0.
<p class="level0"><a name="--fail-early"></a><span class="nroffip">--fail-early</span>
<p class="level1">Fail and exit on the first detected transfer error.
<p class="level1">When curl is used to do multiple transfers on the command line, it will attempt to operate on each given URL, one by one. By default, it will ignore errors if there are more URLs given and the last URL&#39;s success will determine the error code curl returns. So early failures will be &quot;hidden&quot; by subsequent successful transfers.
<p class="level1">Using this option, curl will instead return an error on the first transfer that fails, independent of the amount of URLs that are given on the command line. This way, no transfer failures go undetected by scripts and similar.
<p class="level1">This option is global and does not need to be specified for each use of ##-:, --next##.
<p class="level1">This option does not imply ##-f, --fail##, which causes transfers to fail due to the server&#39;s HTTP status code. You can combine the two options, however note ##-f, --fail## is not global and is therefore contained by ##-:, --next##.
<p class="level1">Providing ##--fail-early## multiple times has no extra effect. Disable it again with --no-fail-early.
<p class="level1">Example:
```
curl --fail-early https://example.com https://two.example
```
<p class="level1">
<p class="level1">See also ##-f, --fail## and ##--fail-with-body##. Added in 7.52.0.
<p class="level0"><a name="--fail-with-body"></a><span class="nroffip">--fail-with-body</span>
<p class="level1">(HTTP) Return an error on server errors where the HTTP response code is 400 or greater). In normal cases when an HTTP server fails to deliver a document, it returns an HTML document stating so (which often also describes why and more). This flag will still allow curl to output and save that content but also to return error 22.
<p class="level1">This is an alternative option to ##-f, --fail## which makes curl fail for the same circumstances but without saving the content.
<p class="level1">Providing ##--fail-with-body## multiple times has no extra effect. Disable it again with --no-fail-with-body.
<p class="level1">Example:
```
curl --fail-with-body https://example.com
```
<p class="level1">
<p class="level1">See also ##-f, --fail##. This option is mutually exclusive to ##-f, --fail##. Added in 7.76.0.
<p class="level0"><a name="-f"></a><span class="nroffip">-f, --fail</span>
<p class="level1">(HTTP) Fail fast with no output at all on server errors. This is useful to enable scripts and users to better deal with failed attempts. In normal cases when an HTTP server fails to deliver a document, it returns an HTML document stating so (which often also describes why and more). This flag will prevent curl from outputting that and return error 22.
<p class="level1">This method is not fail-safe and there are occasions where non-successful response codes will slip through, especially when authentication is involved (response codes 401 and 407).
<p class="level1">Providing ##-f, --fail## multiple times has no extra effect. Disable it again with --no-fail.
<p class="level1">Example:
```
curl --fail https://example.com
```
<p class="level1">
<p class="level1">See also ##--fail-with-body##. This option is mutually exclusive to ##--fail-with-body##.
<p class="level0"><a name="--false-start"></a><span class="nroffip">--false-start</span>
<p class="level1">(TLS) Tells curl to use false start during the TLS handshake. False start is a mode where a TLS client will start sending application data before verifying the server&#39;s Finished message, thus saving a round trip when performing a full handshake.
<p class="level1">This is currently only implemented in the NSS and Secure Transport (on iOS 7.0 or later, or OS X 10.9 or later) backends.
<p class="level1">Providing ##--false-start## multiple times has no extra effect. Disable it again with --no-false-start.
<p class="level1">Example:
```
curl --false-start https://example.com
```
<p class="level1">
<p class="level1">See also ##--tcp-fastopen##. Added in 7.42.0.
<p class="level0"><a name="--form-escape"></a><span class="nroffip">--form-escape</span>
<p class="level1">(HTTP) Tells curl to pass on names of multipart form fields and files using backslash-escaping instead of percent-encoding.
<p class="level1">If ##--form-escape## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --form-escape -F &#39;field&bsol;name=curl&#39; -F &#39;file=@load&quot;this&#39; https://example.com
```
<p class="level1">
<p class="level1">See also ##-F, --form##. Added in 7.81.0.
<p class="level0"><a name="--form-string"></a><span class="nroffip">--form-string &lt;name=string&gt;</span>
<p class="level1">(HTTP SMTP IMAP) Similar to ##-F, --form## except that the value string for the named parameter is used literally. Leading &#39;@&#39; and &#39;&lt;&#39; characters, and the &#39;;type=&#39; string in the value have no special meaning. Use this in preference to ##-F, --form## if there&#39;s any possibility that the string value may accidentally trigger the &apos;@&#39; or &#39;&lt;&#39; features of ##-F, --form##.
<p class="level1">##--form-string## can be used several times in a command line
<p class="level1">Example:
```
curl --form-string &quot;data&quot; https://example.com
```
<p class="level1">
<p class="level1">See also ##-F, --form##.
<p class="level0"><a name="-F"></a><span class="nroffip">-F, --form &lt;name=content&gt;</span>
<p class="level1">(HTTP SMTP IMAP) For HTTP protocol family, this lets curl emulate a filled-in form in which a user has pressed the submit button. This causes curl to POST data using the Content-Type multipart/form-data according to <a href="http://www.ietf.org/rfc/rfc2388.txt">RFC 2388</a>.
<p class="level1">For SMTP and IMAP protocols, this is the means to compose a multipart mail message to transmit.
<p class="level1">This enables uploading of binary files etc. To force the &#39;content&#39; part to be a file, prefix the file name with an @ sign. To just get the content part from a file, prefix the file name with the symbol &lt;. The difference between @ and &lt; is then that @ makes a file get attached in the post as a file upload, while the &lt; makes a text field and just get the contents for that text field from a file.
<p class="level1">Tell curl to read content from stdin instead of a file by using - as filename. This goes for both @ and &lt; constructs. When stdin is used, the contents is buffered in memory first by curl to determine its size and allow a possible resend. Defining a part&#39;s data from a named non-regular file (such as a named pipe or similar) is unfortunately not subject to buffering and will be effectively read at transmission time; since the full size is unknown before the transfer starts, such data is sent as chunks by HTTP and rejected by IMAP.
<p class="level1">Example: send an image to an HTTP server, where &#39;profile&#39; is the name of the form-field to which the file portrait.jpg will be the input:
<p class="level1">
```
curl -F profile=@portrait.jpg https://example.com/upload.cgi
```
<p class="level1">
<p class="level1">Example: send your name and shoe size in two text fields to the server:
<p class="level1">
```
curl -F name=John -F shoesize=11 https://example.com/
```
<p class="level1">
<p class="level1">Example: send your essay in a text field to the server. Send it as a plain text field, but get the contents for it from a local file:
<p class="level1">
```
curl -F &quot;story=&lt;hugefile.txt&quot; https://example.com/
```
<p class="level1">
<p class="level1">You can also tell curl what Content-Type to use by using &#39;type=&#39;, in a manner similar to:
<p class="level1">
```
curl -F &quot;web=@index.html;type=text/html&quot; example.com
```
<p class="level1">
<p class="level1">or
<p class="level1">
```
curl -F &quot;name=daniel;type=text/foo&quot; example.com
```
<p class="level1">
<p class="level1">You can also explicitly change the name field of a file upload part by setting filename=, like this:
<p class="level1">
```
curl -F &quot;file=@localfile;filename=nameinpost&quot; example.com
```
<p class="level1">
<p class="level1">If filename/path contains &#39;,&#39; or &#39;;&#39;, it must be quoted by double-quotes like:
<p class="level1">
```
curl -F &quot;file=@&bsol;&quot;local,file&bsol;&quot;;filename=&bsol;&quot;name;in;post&bsol;&quot;&quot; example.com
```
<p class="level1">
<p class="level1">or
<p class="level1">
```
curl -F &#39;file=@&quot;local,file&quot;;filename=&quot;name;in;post&quot;&#39; example.com
```
<p class="level1">
<p class="level1">Note that if a filename/path is quoted by double-quotes, any double-quote or backslash within the filename must be escaped by backslash.
<p class="level1">Quoting must also be applied to non-file data if it contains semicolons, leading/trailing spaces or leading double quotes:
<p class="level1">
```
curl -F &#39;colors=&quot;red; green; blue&quot;;type=text/x-myapp&#39; example.com
```
<p class="level1">
<p class="level1">You can add custom headers to the field by setting headers=, like
<p class="level1">
```
 curl -F &quot;submit=OK;headers=&bsol;&quot;X-submit-type: OK&bsol;&quot;&quot; example.com
```
<p class="level1">
<p class="level1">or
<p class="level1">
```
 curl -F &quot;submit=OK;headers=@headerfile&quot; example.com
```
<p class="level1">
<p class="level1">The headers= keyword may appear more that once and above notes about quoting apply. When headers are read from a file, Empty lines and lines starting with &#39;&#35;&#39; are comments and ignored; each header can be folded by splitting between two words and starting the continuation line with a space; embedded carriage-returns and trailing spaces are stripped. Here is an example of a header file contents:
<p class="level1">
```
 &#35; This file contain two headers.
 X-header-1: this is a header
```
<p class="level1">
<p class="level1">
```
 &#35; The following header is folded.
 X-header-2: this is
  another header
```
<p class="level1">
<p class="level1">To support sending multipart mail messages, the syntax is extended as follows: <br>- name can be omitted: the equal sign is the first character of the argument, <br>- if data starts with &#39;(&#39;, this signals to start a new multipart: it can be followed by a content type specification. <br>- a multipart can be terminated with a &#39;=)&#39; argument.
<p class="level1">Example: the following command sends an SMTP mime email consisting in an inline part in two alternative formats: plain text and HTML. It attaches a text file:
<p class="level1">
```
curl -F &#39;=(;type=multipart/alternative&#39; &bsol;
     -F &#39;=plain text message&#39; &bsol;
     -F &#39;= &lt;body&gt;HTML message&lt;/body&gt;;type=text/html&#39; &bsol;
     -F &#39;=)&#39; -F &#39;=@textfile.txt&#39; ...  smtp://example.com
```
<p class="level1">
<p class="level1">Data can be encoded for transfer using encoder=. Available encodings are <span Class="emphasis">binary</span> and <span Class="emphasis">8bit</span> that do nothing else than adding the corresponding Content-Transfer-Encoding header, <span Class="emphasis">7bit</span> that only rejects 8-bit characters with a transfer error, <span Class="emphasis">quoted-printable</span> and <span Class="emphasis">base64</span> that encodes data according to the corresponding schemes, limiting lines length to 76 characters.
<p class="level1">Example: send multipart mail with a quoted-printable text message and a base64 attached file:
<p class="level1">
```
curl -F &#39;=text message;encoder=quoted-printable&#39; &bsol;
     -F &#39;=@localfile;encoder=base64&#39; ... smtp://example.com
```
<p class="level1">
<p class="level1">See further examples and details in the MANUAL.
<p class="level1">##-F, --form## can be used several times in a command line
<p class="level1">Example:
```
curl --form &quot;name=curl&quot; --form &quot;file=@loadthis&quot; https://example.com
```
<p class="level1">
<p class="level1">See also ##-d, --data##, ##--form-string## and ##--form-escape##. This option is mutually exclusive to ##-d, --data## and ##-I, --head## and ##-T, --upload-file##.
<p class="level0"><a name="--ftp-account"></a><span class="nroffip">--ftp-account &lt;data&gt;</span>
<p class="level1">(FTP) When an FTP server asks for &quot;account data&quot; after user name and password has been provided, this data is sent off using the ACCT command.
<p class="level1">If ##--ftp-account## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --ftp-account &quot;mr.robot&quot; ftp://example.com/
```
<p class="level1">
<p class="level1">See also ##-u, --user##.
<p class="level0"><a name="--ftp-alternative-to-user"></a><span class="nroffip">--ftp-alternative-to-user &lt;command&gt;</span>
<p class="level1">(FTP) If authenticating with the USER and PASS commands fails, send this command. When connecting to Tumbleweed&#39;s Secure Transport server over FTPS using a client certificate, using &quot;SITE AUTH&quot; will tell the server to retrieve the username from the certificate.
<p class="level1">If ##--ftp-alternative-to-user## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --ftp-alternative-to-user &quot;U53r&quot; ftp://example.com
```
<p class="level1">
<p class="level1">See also ##--ftp-account## and ##-u, --user##.
<p class="level0"><a name="--ftp-create-dirs"></a><span class="nroffip">--ftp-create-dirs</span>
<p class="level1">(FTP SFTP) When an FTP or SFTP URL/operation uses a path that does not currently exist on the server, the standard behavior of curl is to fail. Using this option, curl will instead attempt to create missing directories.
<p class="level1">Providing ##--ftp-create-dirs## multiple times has no extra effect. Disable it again with --no-ftp-create-dirs.
<p class="level1">Example:
```
curl --ftp-create-dirs -T file ftp://example.com/remote/path/file
```
<p class="level1">
<p class="level1">See also ##--create-dirs##.
<p class="level0"><a name="--ftp-method"></a><span class="nroffip">--ftp-method &lt;method&gt;</span>
<p class="level1">(FTP) Control what method curl should use to reach a file on an FTP(S) server. The method argument should be one of the following alternatives:
<p class="level2">
<p class="level1"><a name="multicwd"></a><span class="nroffip">multicwd</span>
<p class="level2">curl does a single CWD operation for each path part in the given URL. For deep hierarchies this means many commands. This is how <a href="http://www.ietf.org/rfc/rfc1738.txt">RFC 1738</a> says it should be done. This is the default but the slowest behavior.
<p class="level1"><a name="nocwd"></a><span class="nroffip">nocwd</span>
<p class="level2">curl does no CWD at all. curl will do SIZE, RETR, STOR etc and give a full path to the server for all these commands. This is the fastest behavior.
<p class="level1"><a name="singlecwd"></a><span class="nroffip">singlecwd</span>
<p class="level2">curl does one CWD with the full target directory and then operates on the file &quot;normally&quot; (like in the multicwd case). This is somewhat more standards compliant than &#39;nocwd&#39; but without the full penalty of &#39;multicwd&#39;.
<p class="level1">
<p class="level1">If ##--ftp-method## is provided several times, the last set value will be used.
<p class="level1">Examples:
```
curl --ftp-method multicwd ftp://example.com/dir1/dir2/file
curl --ftp-method nocwd ftp://example.com/dir1/dir2/file
curl --ftp-method singlecwd ftp://example.com/dir1/dir2/file
```
<p class="level1">
<p class="level1">See also ##-l, --list-only##.
<p class="level0"><a name="--ftp-pasv"></a><span class="nroffip">--ftp-pasv</span>
<p class="level1">(FTP) Use passive mode for the data connection. Passive is the internal default behavior, but using this option can be used to override a previous ##-P, --ftp-port## option.
<p class="level1">Reversing an enforced passive really is not doable but you must then instead enforce the correct ##-P, --ftp-port## again.
<p class="level1">Passive mode means that curl will try the EPSV command first and then PASV, unless ##--disable-epsv## is used.
<p class="level1">Providing ##--ftp-pasv## multiple times has no extra effect. Disable it again with --no-ftp-pasv.
<p class="level1">Example:
```
curl --ftp-pasv ftp://example.com/
```
<p class="level1">
<p class="level1">See also ##--disable-epsv##.
<p class="level0"><a name="-P"></a><span class="nroffip">-P, --ftp-port &lt;address&gt;</span>
<p class="level1">(FTP) Reverses the default initiator/listener roles when connecting with FTP. This option makes curl use active mode. curl then tells the server to connect back to the client&#39;s specified address and port, while passive mode asks the server to setup an IP address and port for it to connect to. &lt;address&gt; should be one of:
<p class="level2">
<p class="level1"><a name="interface"></a><span class="nroffip">interface</span>
<p class="level2">e.g. &quot;eth0&quot; to specify which interface&#39;s IP address you want to use (Unix only)
<p class="level1"><a name="IP"></a><span class="nroffip">IP address</span>
<p class="level2">e.g. &quot;192.168.10.1&quot; to specify the exact IP address
<p class="level1"><a name="host"></a><span class="nroffip">host name</span>
<p class="level2">e.g. &quot;my.host.domain&quot; to specify the machine
<p class="level1"><a name="-"></a><span class="nroffip">-</span>
<p class="level2">make curl pick the same IP address that is already used for the control connection
<p class="level1">
<p class="level1">Disable the use of PORT with ##--ftp-pasv##. Disable the attempt to use the EPRT command instead of PORT by using ##--disable-eprt##. EPRT is really PORT++.
<p class="level1">You can also append &quot;:[start]-[end]&quot; to the right of the address, to tell curl what TCP port range to use. That means you specify a port range, from a lower to a higher number. A single number works as well, but do note that it increases the risk of failure since the port may not be available.
<p class="level1">
<p class="level1">If ##-P, --ftp-port## is provided several times, the last set value will be used.
<p class="level1">Examples:
```
curl -P - ftp:/example.com
curl -P eth0 ftp:/example.com
curl -P 192.168.0.2 ftp:/example.com
```
<p class="level1">
<p class="level1">See also ##--ftp-pasv## and ##--disable-eprt##.
<p class="level0"><a name="--ftp-pret"></a><span class="nroffip">--ftp-pret</span>
<p class="level1">(FTP) Tell curl to send a PRET command before PASV (and EPSV). Certain FTP servers, mainly drftpd, require this non-standard command for directory listings as well as up and downloads in PASV mode.
<p class="level1">Providing ##--ftp-pret## multiple times has no extra effect. Disable it again with --no-ftp-pret.
<p class="level1">Example:
```
curl --ftp-pret ftp://example.com/
```
<p class="level1">
<p class="level1">See also ##-P, --ftp-port## and ##--ftp-pasv##.
<p class="level0"><a name="--ftp-skip-pasv-ip"></a><span class="nroffip">--ftp-skip-pasv-ip</span>
<p class="level1">(FTP) Tell curl to not use the IP address the server suggests in its response to curl&#39;s PASV command when curl connects the data connection. Instead curl will re-use the same IP address it already uses for the control connection.
<p class="level1">Since curl 7.74.0 this option is enabled by default.
<p class="level1">This option has no effect if PORT, EPRT or EPSV is used instead of PASV.
<p class="level1">Providing ##--ftp-skip-pasv-ip## multiple times has no extra effect. Disable it again with --no-ftp-skip-pasv-ip.
<p class="level1">Example:
```
curl --ftp-skip-pasv-ip ftp://example.com/
```
<p class="level1">
<p class="level1">See also ##--ftp-pasv##.
<p class="level0"><a name="--ftp-ssl-ccc-mode"></a><span class="nroffip">--ftp-ssl-ccc-mode &lt;active/passive&gt;</span>
<p class="level1">(FTP) Sets the CCC mode. The passive mode will not initiate the shutdown, but instead wait for the server to do it, and will not reply to the shutdown from the server. The active mode initiates the shutdown and waits for a reply from the server.
<p class="level1">Providing ##--ftp-ssl-ccc-mode## multiple times has no extra effect. Disable it again with --no-ftp-ssl-ccc-mode.
<p class="level1">Example:
```
curl --ftp-ssl-ccc-mode active --ftp-ssl-ccc ftps://example.com/
```
<p class="level1">
<p class="level1">See also ##--ftp-ssl-ccc##.
<p class="level0"><a name="--ftp-ssl-ccc"></a><span class="nroffip">--ftp-ssl-ccc</span>
<p class="level1">(FTP) Use CCC (Clear Command Channel) Shuts down the SSL/TLS layer after authenticating. The rest of the control channel communication will be unencrypted. This allows NAT routers to follow the FTP transaction. The default mode is passive.
<p class="level1">Providing ##--ftp-ssl-ccc## multiple times has no extra effect. Disable it again with --no-ftp-ssl-ccc.
<p class="level1">Example:
```
curl --ftp-ssl-ccc ftps://example.com/
```
<p class="level1">
<p class="level1">See also ##--ssl## and ##--ftp-ssl-ccc-mode##.
<p class="level0"><a name="--ftp-ssl-control"></a><span class="nroffip">--ftp-ssl-control</span>
<p class="level1">(FTP) Require SSL/TLS for the FTP login, clear for transfer.  Allows secure authentication, but non-encrypted data transfers for efficiency.  Fails the transfer if the server does not support SSL/TLS.
<p class="level1">Providing ##--ftp-ssl-control## multiple times has no extra effect. Disable it again with --no-ftp-ssl-control.
<p class="level1">Example:
```
curl --ftp-ssl-control ftp://example.com
```
<p class="level1">
<p class="level1">See also ##--ssl##.
<p class="level0"><a name="-G"></a><span class="nroffip">-G, --get</span>
<p class="level1">When used, this option will make all data specified with ##-d, --data##, ##--data-binary## or ##--data-urlencode## to be used in an HTTP GET request instead of the POST request that otherwise would be used. The data will be appended to the URL with a &#39;?&#39; separator.
<p class="level1">If used in combination with ##-I, --head##, the POST data will instead be appended to the URL with a HEAD request.
<p class="level1">Providing ##-G, --get## multiple times has no extra effect. Disable it again with --no-get.
<p class="level1">Examples:
```
curl --get https://example.com
curl --get -d &quot;tool=curl&quot; -d &quot;age=old&quot; https://example.com
curl --get -I -d &quot;tool=curl&quot; https://example.com
```
<p class="level1">
<p class="level1">See also ##-d, --data## and ##-X, --request##.
<p class="level0"><a name="-g"></a><span class="nroffip">-g, --globoff</span>
<p class="level1">This option switches off the &quot;URL globbing parser&quot;. When you set this option, you can specify URLs that contain the letters {}[] without having curl itself interpret them. Note that these letters are not normal legal URL contents but they should be encoded according to the URI standard.
<p class="level1">Providing ##-g, --globoff## multiple times has no extra effect. Disable it again with --no-globoff.
<p class="level1">Example:
```
curl -g &quot;https://example.com/{[]}}}}&quot;
```
<p class="level1">
<p class="level1">See also ##-K, --config## and ##-q, --disable##.
<p class="level0"><a name="--happy-eyeballs-timeout-ms"></a><span class="nroffip">--happy-eyeballs-timeout-ms &lt;milliseconds&gt;</span>
<p class="level1">Happy Eyeballs is an algorithm that attempts to connect to both IPv4 and IPv6 addresses for dual-stack hosts, giving IPv6 a head-start of the specified number of milliseconds. If the IPv6 address cannot be connected to within that time, then a connection attempt is made to the IPv4 address in parallel. The first connection to be established is the one that is used.
<p class="level1">The range of suggested useful values is limited. Happy Eyeballs <a href="http://www.ietf.org/rfc/rfc6555.txt">RFC 6555</a> says &quot;It is RECOMMENDED that connection attempts be paced 150-250 ms apart to balance human factors against network load.&quot; libcurl currently defaults to 200 ms. Firefox and Chrome currently default to 300 ms.
<p class="level1">If ##--happy-eyeballs-timeout-ms## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --happy-eyeballs-timeout-ms 500 https://example.com
```
<p class="level1">
<p class="level1">See also ##-m, --max-time## and ##--connect-timeout##. Added in 7.59.0.
<p class="level0"><a name="--haproxy-protocol"></a><span class="nroffip">--haproxy-protocol</span>
<p class="level1">(HTTP) Send a HAProxy PROXY protocol v1 header at the beginning of the connection. This is used by some load balancers and reverse proxies to indicate the client&#39;s true IP address and port.
<p class="level1">This option is primarily useful when sending test requests to a service that expects this header.
<p class="level1">Providing ##--haproxy-protocol## multiple times has no extra effect. Disable it again with --no-haproxy-protocol.
<p class="level1">Example:
```
curl --haproxy-protocol https://example.com
```
<p class="level1">
<p class="level1">See also ##-x, --proxy##. Added in 7.60.0.
<p class="level0"><a name="-I"></a><span class="nroffip">-I, --head</span>
<p class="level1">(HTTP FTP FILE) Fetch the headers only! HTTP-servers feature the command HEAD which this uses to get nothing but the header of a document. When used on an FTP or FILE file, curl displays the file size and last modification time only.
<p class="level1">Providing ##-I, --head## multiple times has no extra effect. Disable it again with --no-head.
<p class="level1">Example:
```
curl -I https://example.com
```
<p class="level1">
<p class="level1">See also ##-G, --get##, ##-v, --verbose## and ##--trace-ascii##.
<p class="level0"><a name="-H"></a><span class="nroffip">-H, --header &lt;header/@file&gt;</span>
<p class="level1">(HTTP IMAP SMTP) Extra header to include in information sent. When used within an HTTP request, it is added to the regular request headers.
<p class="level1">For an IMAP or SMTP MIME uploaded mail built with ##-F, --form## options, it is prepended to the resulting MIME document, effectively including it at the mail global level. It does not affect raw uploaded mails (Added in 7.56.0).
<p class="level1">You may specify any number of extra headers. Note that if you should add a custom header that has the same name as one of the internal ones curl would use, your externally set header will be used instead of the internal one. This allows you to make even trickier stuff than curl would normally do. You should not replace internally set headers without knowing perfectly well what you are doing. Remove an internal header by giving a replacement without content on the right side of the colon, as in: -H &quot;Host:&quot;. If you send the custom header with no-value then its header must be terminated with a semicolon, such as -H &quot;X-Custom-Header;&quot; to send &quot;X-Custom-Header:&quot;.
<p class="level1">curl will make sure that each header you add/replace is sent with the proper end-of-line marker, you should thus <span Class="bold">not</span> add that as a part of the header content: do not add newlines or carriage returns, they will only mess things up for you.
<p class="level1">This option can take an argument in @filename style, which then adds a header for each line in the input file. Using @- will make curl read the header file from stdin. Added in 7.55.0.
<p class="level1">Please note that most anti-spam utilities check the presence and value of several MIME mail headers: these are &quot;From:&quot;, &quot;To:&quot;, &quot;Date:&quot; and &quot;Subject:&quot; among others and should be added with this option.
<p class="level1">You need ##--proxy-header## to send custom headers intended for an HTTP proxy. Added in 7.37.0.
<p class="level1">Passing on a &quot;Transfer-Encoding: chunked&quot; header when doing an HTTP request with a request body, will make curl send the data using chunked encoding.
<p class="level1"><span Class="bold">WARNING</span>: headers set with this option will be set in all HTTP requests - even after redirects are followed, like when told with ##-L, --location##. This can lead to the header being sent to other hosts than the original host, so sensitive headers should be used with caution combined with following redirects.
<p class="level1">##-H, --header## can be used several times in a command line
<p class="level1">Examples:
```
curl -H &quot;X-First-Name: Joe&quot; https://example.com
curl -H &quot;User-Agent: yes-please/2000&quot; https://example.com
curl -H &quot;Host:&quot; https://example.com
```
<p class="level1">
<p class="level1">See also ##-A, --user-agent## and ##-e, --referer##.
<p class="level0"><a name="-h"></a><span class="nroffip">-h, --help &lt;category&gt;</span>
<p class="level1">Usage help. This lists all commands of the &lt;category&gt;. If no arg was provided, curl will display the most important command line arguments. If the argument &quot;all&quot; was provided, curl will display all options available. If the argument &quot;category&quot; was provided, curl will display all categories and their meanings.
<p class="level1">Providing ##-h, --help## multiple times has no extra effect. Disable it again with --no-help.
<p class="level1">Example:
```
curl --help all
```
<p class="level1">
<p class="level1">See also ##-v, --verbose##.
<p class="level0"><a name="--hostpubmd5"></a><span class="nroffip">--hostpubmd5 &lt;md5&gt;</span>
<p class="level1">(SFTP SCP) Pass a string containing 32 hexadecimal digits. The string should be the 128 bit MD5 checksum of the remote host&#39;s key, curl will refuse the connection with the host unless the md5sums match.
<p class="level1">If ##--hostpubmd5## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --hostpubmd5 e5c1c49020640a5ab0f2034854c321a8 sftp://example.com/
```
<p class="level1">
<p class="level1">See also ##--hostpubsha256##.
<p class="level0"><a name="--hostpubsha256"></a><span class="nroffip">--hostpubsha256 &lt;sha256&gt;</span>
<p class="level1">(SFTP SCP) Pass a string containing a Base64-encoded SHA256 hash of the remote host&#39;s key. Curl will refuse the connection with the host unless the hashes match.
<p class="level1">This feature requires libcurl to be built with libssh2 and does not work with other SSH backends.
<p class="level1">If ##--hostpubsha256## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --hostpubsha256 NDVkMTQxMGQ1ODdmMjQ3MjczYjAyOTY5MmRkMjVmNDQ= sftp://example.com/
```
<p class="level1">
<p class="level1">See also ##--hostpubmd5##. Added in 7.80.0.
<p class="level0"><a name="--hsts"></a><span class="nroffip">--hsts &lt;file name&gt;</span>
<p class="level1">(HTTPS) This option enables HSTS for the transfer. If the file name points to an existing HSTS cache file, that will be used. After a completed transfer, the cache will be saved to the file name again if it has been modified.
<p class="level1">If curl is told to use HTTP:// for a transfer involving a host name that exists in the HSTS cache, it upgrades the transfer to use HTTPS. Each HSTS cache entry has an individual life time after which the upgrade is no longer performed.
<p class="level1">Specify a &quot;&quot; file name (zero length) to avoid loading/saving and make curl just handle HSTS in memory.
<p class="level1">If this option is used several times, curl will load contents from all the files but the last one will be used for saving.
<p class="level1">##--hsts## can be used several times in a command line
<p class="level1">Example:
```
curl --hsts cache.txt https://example.com
```
<p class="level1">
<p class="level1">See also ##--proto##. Added in 7.74.0.
<p class="level0"><a name="--http09"></a><span class="nroffip">--http0.9</span>
<p class="level1">(HTTP) Tells curl to be fine with HTTP version 0.9 response.
<p class="level1">HTTP/0.9 is a completely headerless response and therefore you can also connect with this to non-HTTP servers and still get a response since curl will simply transparently downgrade - if allowed.
<p class="level1">Since curl 7.66.0, HTTP/0.9 is disabled by default.
<p class="level1">Providing ##--http0.9## multiple times has no extra effect. Disable it again with --no-http0.9.
<p class="level1">Example:
```
curl --http0.9 https://example.com
```
<p class="level1">
<p class="level1">See also ##--http1.1##, ##--http2## and ##--http3##. Added in 7.64.0.
<p class="level0"><a name="-0"></a><span class="nroffip">-0, --http1.0</span>
<p class="level1">(HTTP) Tells curl to use HTTP version 1.0 instead of using its internally preferred HTTP version.
<p class="level1">Providing ##-0, --http1.0## multiple times has no extra effect.
<p class="level1">Example:
```
curl --http1.0 https://example.com
```
<p class="level1">
<p class="level1">See also ##--http0.9## and ##--http1.1##. This option is mutually exclusive to ##--http1.1## and ##--http2## and ##--http2-prior-knowledge## and ##--http3##.
<p class="level0"><a name="--http11"></a><span class="nroffip">--http1.1</span>
<p class="level1">(HTTP) Tells curl to use HTTP version 1.1.
<p class="level1">Providing ##--http1.1## multiple times has no extra effect.
<p class="level1">Example:
```
curl --http1.1 https://example.com
```
<p class="level1">
<p class="level1">See also ##-0, --http1.0## and ##--http0.9##. This option is mutually exclusive to ##-0, --http1.0## and ##--http2## and ##--http2-prior-knowledge## and ##--http3##. Added in 7.33.0.
<p class="level0"><a name="--http2-prior-knowledge"></a><span class="nroffip">--http2-prior-knowledge</span>
<p class="level1">(HTTP) Tells curl to issue its non-TLS HTTP requests using HTTP/2 without HTTP/1.1 Upgrade. It requires prior knowledge that the server supports HTTP/2 straight away. HTTPS requests will still do HTTP/2 the standard way with negotiated protocol version in the TLS handshake.
<p class="level1">Providing ##--http2-prior-knowledge## multiple times has no extra effect. Disable it again with --no-http2-prior-knowledge.
<p class="level1">Example:
```
curl --http2-prior-knowledge https://example.com
```
<p class="level1">
<p class="level1">See also ##--http2## and ##--http3##. ##--http2-prior-knowledge## requires that the underlying libcurl was built to support HTTP/2. This option is mutually exclusive to ##--http1.1## and ##-0, --http1.0## and ##--http2## and ##--http3##. Added in 7.49.0.
<p class="level0"><a name="--http2"></a><span class="nroffip">--http2</span>
<p class="level1">(HTTP) Tells curl to use HTTP version 2.
<p class="level1">For HTTPS, this means curl will attempt to negotiate HTTP/2 in the TLS handshake. curl does this by default.
<p class="level1">For HTTP, this means curl will attempt to upgrade the request to HTTP/2 using the Upgrade: request header.
<p class="level1">When curl uses HTTP/2 over HTTPS, it does not itself insist on TLS 1.2 or higher even though that is required by the specification. A user can add this version requirement with ##--tlsv1.2##.
<p class="level1">Providing ##--http2## multiple times has no extra effect.
<p class="level1">Example:
```
curl --http2 https://example.com
```
<p class="level1">
<p class="level1">See also ##--http1.1## and ##--http3##. ##--http2## requires that the underlying libcurl was built to support HTTP/2. This option is mutually exclusive to ##--http1.1## and ##-0, --http1.0## and ##--http2-prior-knowledge## and ##--http3##. Added in 7.33.0.
<p class="level0"><a name="--http3-only"></a><span class="nroffip">--http3-only</span>
<p class="level1">(HTTP) **WARNING**: this option is experimental. Do not use in production.
<p class="level1">Instructs curl to use HTTP/3 to the host in the URL, with no fallback to earlier HTTP versions. HTTP/3 can only be used for HTTPS and not for HTTP URLs. For HTTP, this option will trigger an error.
<p class="level1">This option allows a user to avoid using the Alt-Svc method of upgrading to HTTP/3 when you know that the target speaks HTTP/3 on the given host and port.
<p class="level1">This option will make curl fail if a QUIC connection cannot be established, it will not attempt any other HTTP version on its own. Use ##--http3## for similar fuctionality <span Class="emphasis">with</span> a fallback.
<p class="level1">Providing ##--http3-only## multiple times has no extra effect.
<p class="level1">Example:
```
curl --http3-only https://example.com
```
<p class="level1">
<p class="level1">See also ##--http1.1##, ##--http2## and ##--http3##. ##--http3-only## requires that the underlying libcurl was built to support HTTP/3. This option is mutually exclusive to ##--http1.1## and ##-0, --http1.0## and ##--http2## and ##--http2-prior-knowledge## and ##--http3##. Added in 7.88.0.
<p class="level0"><a name="--http3"></a><span class="nroffip">--http3</span>
<p class="level1">(HTTP) **WARNING**: this option is experimental. Do not use in production.
<p class="level1">Tells curl to try HTTP/3 to the host in the URL, but fallback to earlier HTTP versions if the HTTP/3 connection establishement fails. HTTP/3 is only available for HTTPS and not for HTTP URLs.
<p class="level1">This option allows a user to avoid using the Alt-Svc method of upgrading to HTTP/3 when you know that the target speaks HTTP/3 on the given host and port.
<p class="level1">When asked to use HTTP/3, curl will issue a separate attempt to use older HTTP versions with a slight delay, so if the HTTP/3 transfer fails or is very slow, curl will still try to proceed with an older HTTP version.
<p class="level1">Use ##--http3-only## for similar fuctionality <span Class="emphasis">without</span> a fallback.
<p class="level1">Providing ##--http3## multiple times has no extra effect.
<p class="level1">Example:
```
curl --http3 https://example.com
```
<p class="level1">
<p class="level1">See also ##--http1.1## and ##--http2##. ##--http3## requires that the underlying libcurl was built to support HTTP/3. This option is mutually exclusive to ##--http1.1## and ##-0, --http1.0## and ##--http2## and ##--http2-prior-knowledge## and ##--http3-only##. Added in 7.66.0.
<p class="level0"><a name="--ignore-content-length"></a><span class="nroffip">--ignore-content-length</span>
<p class="level1">(FTP HTTP) For HTTP, Ignore the Content-Length header. This is particularly useful for servers running Apache 1.x, which will report incorrect Content-Length for files larger than 2 gigabytes.
<p class="level1">For FTP (since 7.46.0), skip the RETR command to figure out the size before downloading a file.
<p class="level1">This option does not work for HTTP if libcurl was built to use hyper.
<p class="level1">Providing ##--ignore-content-length## multiple times has no extra effect. Disable it again with --no-ignore-content-length.
<p class="level1">Example:
```
curl --ignore-content-length https://example.com
```
<p class="level1">
<p class="level1">See also ##--ftp-skip-pasv-ip##.
<p class="level0"><a name="-i"></a><span class="nroffip">-i, --include</span>
<p class="level1">Include the HTTP response headers in the output. The HTTP response headers can include things like server name, cookies, date of the document, HTTP version and more...
<p class="level1">To view the request headers, consider the ##-v, --verbose## option.
<p class="level1">Providing ##-i, --include## multiple times has no extra effect. Disable it again with --no-include.
<p class="level1">Example:
```
curl -i https://example.com
```
<p class="level1">
<p class="level1">See also ##-v, --verbose##.
<p class="level0"><a name="-k"></a><span class="nroffip">-k, --insecure</span>
<p class="level1">(TLS SFTP SCP) By default, every secure connection curl makes is verified to be secure before the transfer takes place. This option makes curl skip the verification step and proceed without checking.
<p class="level1">When this option is not used for protocols using TLS, curl verifies the server&#39;s TLS certificate before it continues: that the certificate contains the right name which matches the host name used in the URL and that the certificate has been signed by a CA certificate present in the cert store. See this online resource for further details:
```
https://curl.se/docs/sslcerts.html
```
<p class="level1">
<p class="level1">For SFTP and SCP, this option makes curl skip the <span Class="emphasis">known_hosts</span> verification. <span Class="emphasis">known_hosts</span> is a file normally stored in the user&#39;s home directory in the &quot;.ssh&quot; subdirectory, which contains host names and their keys.
<p class="level1"><span Class="bold">WARNING</span>: using this option makes the transfer insecure.
<p class="level1">When curl uses secure protocols it trusts responses and allows for example HSTS and Alt-Svc information to be stored and used subsequently. Using ##-k, --insecure## can make curl trust and use such information from malicious servers.
<p class="level1">Providing ##-k, --insecure## multiple times has no extra effect. Disable it again with --no-insecure.
<p class="level1">Example:
```
curl --insecure https://example.com
```
<p class="level1">
<p class="level1">See also ##--proxy-insecure##, ##--cacert## and ##--capath##.
<p class="level0"><a name="--interface"></a><span class="nroffip">--interface &lt;name&gt;</span>
<p class="level1">Perform an operation using a specified interface. You can enter interface name, IP address or host name. An example could look like:
<p class="level1">
```
curl --interface eth0:1 https://www.example.com/
```
<p class="level1">
<p class="level1">On Linux it can be used to specify a VRF, but the binary needs to either have CAP_NET_RAW or to be run as root. More information about Linux VRF: <a href="https://www.kernel.org/doc/Documentation/networking/vrf.txt">https://www.kernel.org/doc/Documentation/networking/vrf.txt</a>
<p class="level1">If ##--interface## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --interface eth0 https://example.com
```
<p class="level1">
<p class="level1">See also ##--dns-interface##.
<p class="level0"><a name="-4"></a><span class="nroffip">-4, --ipv4</span>
<p class="level1">This option tells curl to use IPv4 addresses only, and not for example try IPv6.
<p class="level1">Providing ##-4, --ipv4## multiple times has no extra effect. Disable it again with --no-ipv4.
<p class="level1">Example:
```
curl --ipv4 https://example.com
```
<p class="level1">
<p class="level1">See also ##--http1.1## and ##--http2##. This option is mutually exclusive to ##-6, --ipv6##.
<p class="level0"><a name="-6"></a><span class="nroffip">-6, --ipv6</span>
<p class="level1">This option tells curl to use IPv6 addresses only, and not for example try IPv4.
<p class="level1">Providing ##-6, --ipv6## multiple times has no extra effect. Disable it again with --no-ipv6.
<p class="level1">Example:
```
curl --ipv6 https://example.com
```
<p class="level1">
<p class="level1">See also ##--http1.1## and ##--http2##. This option is mutually exclusive to ##-4, --ipv4##.
<p class="level0"><a name="--json"></a><span class="nroffip">--json &lt;data&gt;</span>
<p class="level1">(HTTP) Sends the specified JSON data in a POST request to the HTTP server. ##--json## works as a shortcut for passing on these three options:
<p class="level1">
```
--data [arg]
--header &quot;Content-Type: application/json&quot;
--header &quot;Accept: application/json&quot;
```
<p class="level1">
<p class="level1">There is <a class="emphasis" href="#"></a>no verification<a class="emphasis" href="#"></a> that the passed in data is actual JSON or that the syntax is correct.
<p class="level1">If you start the data with the letter @, the rest should be a file name to read the data from, or a single dash (-) if you want curl to read the data from stdin. Posting data from a file named &#39;foobar&#39; would thus be done with ##--json## @foobar and to instead read the data from stdin, use ##--json## @-.
<p class="level1">If this option is used more than once on the same command line, the additional data pieces will be concatenated to the previous before sending.
<p class="level1">The headers this option sets can be overridden with ##-H, --header## as usual.
<p class="level1">##--json## can be used several times in a command line
<p class="level1">Examples:
```
curl --json &#39;{ &quot;drink&quot;: &quot;coffe&quot; }&#39; https://example.com
curl --json &#39;{ &quot;drink&quot;:&#39; --json &#39; &quot;coffe&quot; }&#39; https://example.com
curl --json @prepared https://example.com
curl --json @- https://example.com &lt; json.txt
```
<p class="level1">
<p class="level1">See also ##--data-binary## and ##--data-raw##. This option is mutually exclusive to ##-F, --form## and ##-I, --head## and ##-T, --upload-file##. Added in 7.82.0.
<p class="level0"><a name="-j"></a><span class="nroffip">-j, --junk-session-cookies</span>
<p class="level1">(HTTP) When curl is told to read cookies from a given file, this option will make it discard all &quot;session cookies&quot;. This will basically have the same effect as if a new session is started. Typical browsers always discard session cookies when they are closed down.
<p class="level1">Providing ##-j, --junk-session-cookies## multiple times has no extra effect. Disable it again with --no-junk-session-cookies.
<p class="level1">Example:
```
curl --junk-session-cookies -b cookies.txt https://example.com
```
<p class="level1">
<p class="level1">See also ##-b, --cookie## and ##-c, --cookie-jar##.
<p class="level0"><a name="--keepalive-time"></a><span class="nroffip">--keepalive-time &lt;seconds&gt;</span>
<p class="level1">This option sets the time a connection needs to remain idle before sending keepalive probes and the time between individual keepalive probes. It is currently effective on operating systems offering the TCP_KEEPIDLE and TCP_KEEPINTVL socket options (meaning Linux, recent AIX, HP-UX and more). Keepalives are used by the TCP stack to detect broken networks on idle connections. The number of missed keepalive probes before declaring the connection down is OS dependent and is commonly 9 or 10. This option has no effect if ##--no-keepalive## is used.
<p class="level1">If unspecified, the option defaults to 60 seconds.
<p class="level1">If ##--keepalive-time## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --keepalive-time 20 https://example.com
```
<p class="level1">
<p class="level1">See also ##--no-keepalive## and ##-m, --max-time##.
<p class="level0"><a name="--key-type"></a><span class="nroffip">--key-type &lt;type&gt;</span>
<p class="level1">(TLS) Private key file type. Specify which type your ##--key## provided private key is. DER, PEM, and ENG are supported. If not specified, PEM is assumed.
<p class="level1">If ##--key-type## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --key-type DER --key here https://example.com
```
<p class="level1">
<p class="level1">See also ##--key##.
<p class="level0"><a name="--key"></a><span class="nroffip">--key &lt;key&gt;</span>
<p class="level1">(TLS SSH) Private key file name. Allows you to provide your private key in this separate file. For SSH, if not specified, curl tries the following candidates in order: &apos;~/.ssh/id_rsa&#39;, &#39;~/.ssh/id_dsa&#39;, &#39;./id_rsa&#39;, &#39;./id_dsa&#39;.
<p class="level1">If curl is built against OpenSSL library, and the engine pkcs11 is available, then a PKCS&#35;11 URI (RFC 7512) can be used to specify a private key located in a PKCS&#35;11 device. A string beginning with &quot;pkcs11:&quot; will be interpreted as a PKCS&#35;11 URI. If a PKCS&#35;11 URI is provided, then the ##--engine## option will be set as &quot;pkcs11&quot; if none was provided and the ##--key-type## option will be set as &quot;ENG&quot; if none was provided.
<p class="level1">If curl is built against Secure Transport or Schannel then this option is ignored for TLS protocols (HTTPS, etc). Those backends expect the private key to be already present in the keychain or PKCS&#35;12 file containing the certificate.
<p class="level1">If ##--key## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --cert certificate --key here https://example.com
```
<p class="level1">
<p class="level1">See also ##--key-type## and ##-E, --cert##.
<p class="level0"><a name="--krb"></a><span class="nroffip">--krb &lt;level&gt;</span>
<p class="level1">(FTP) Enable Kerberos authentication and use. The level must be entered and should be one of &#39;clear&#39;, &#39;safe&#39;, &#39;confidential&#39;, or &#39;private&#39;. Should you use a level that is not one of these, &#39;private&#39; will instead be used.
<p class="level1">If ##--krb## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --krb clear ftp://example.com/
```
<p class="level1">
<p class="level1">See also ##--delegation## and ##--ssl##. ##--krb## requires that the underlying libcurl was built to support Kerberos.
<p class="level0"><a name="--libcurl"></a><span class="nroffip">--libcurl &lt;file&gt;</span>
<p class="level1">Append this option to any ordinary curl command line, and you will get libcurl-using C source code written to the file that does the equivalent of what your command-line operation does!
<p class="level1">This option is global and does not need to be specified for each use of ##-:, --next##.
<p class="level1">If ##--libcurl## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --libcurl client.c https://example.com
```
<p class="level1">
<p class="level1">See also ##-v, --verbose##.
<p class="level0"><a name="--limit-rate"></a><span class="nroffip">--limit-rate &lt;speed&gt;</span>
<p class="level1">Specify the maximum transfer rate you want curl to use - for both downloads and uploads. This feature is useful if you have a limited pipe and you would like your transfer not to use your entire bandwidth. To make it slower than it otherwise would be.
<p class="level1">The given speed is measured in bytes/second, unless a suffix is appended. Appending &#39;k&#39; or &#39;K&#39; will count the number as kilobytes, &#39;m&#39; or &#39;M&#39; makes it megabytes, while &#39;g&#39; or &#39;G&#39; makes it gigabytes. The suffixes (k, M, G, T, P) are 1024 based. For example 1k is 1024. Examples: 200K, 3m and 1G.
<p class="level1">The rate limiting logic works on averaging the transfer speed to no more than the set threshold over a period of multiple seconds.
<p class="level1">If you also use the ##-Y, --speed-limit## option, that option will take precedence and might cripple the rate-limiting slightly, to help keeping the speed-limit logic working.
<p class="level1">If ##--limit-rate## is provided several times, the last set value will be used.
<p class="level1">Examples:
```
curl --limit-rate 100K https://example.com
curl --limit-rate 1000 https://example.com
curl --limit-rate 10M https://example.com
```
<p class="level1">
<p class="level1">See also ##--rate##, ##-Y, --speed-limit## and ##-y, --speed-time##.
<p class="level0"><a name="-l"></a><span class="nroffip">-l, --list-only</span>
<p class="level1">(FTP POP3) (FTP) When listing an FTP directory, this switch forces a name-only view. This is especially useful if the user wants to machine-parse the contents of an FTP directory since the normal directory view does not use a standard look or format. When used like this, the option causes an NLST command to be sent to the server instead of LIST.
<p class="level1">Note: Some FTP servers list only files in their response to NLST; they do not include sub-directories and symbolic links.
<p class="level1">(POP3) When retrieving a specific email from POP3, this switch forces a LIST command to be performed instead of RETR. This is particularly useful if the user wants to see if a specific message-id exists on the server and what size it is.
<p class="level1">Note: When combined with ##-X, --request##, this option can be used to send a UIDL command instead, so the user may use the email&#39;s unique identifier rather than its message-id to make the request.
<p class="level1">Providing ##-l, --list-only## multiple times has no extra effect. Disable it again with --no-list-only.
<p class="level1">Example:
```
curl --list-only ftp://example.com/dir/
```
<p class="level1">
<p class="level1">See also ##-Q, --quote## and ##-X, --request##.
<p class="level0"><a name="--local-port"></a><span class="nroffip">--local-port &lt;num/range&gt;</span>
<p class="level1">Set a preferred single number or range (FROM-TO) of local port numbers to use for the connection(s).  Note that port numbers by nature are a scarce resource that will be busy at times so setting this range to something too narrow might cause unnecessary connection setup failures.
<p class="level1">If ##--local-port## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --local-port 1000-3000 https://example.com
```
<p class="level1">
<p class="level1">See also ##-g, --globoff##.
<p class="level0"><a name="--location-trusted"></a><span class="nroffip">--location-trusted</span>
<p class="level1">(HTTP) Like ##-L, --location##, but will allow sending the name + password to all hosts that the site may redirect to. This may or may not introduce a security breach if the site redirects you to a site to which you will send your authentication info (which is plaintext in the case of HTTP Basic authentication).
<p class="level1">Providing ##--location-trusted## multiple times has no extra effect. Disable it again with --no-location-trusted.
<p class="level1">Example:
```
curl --location-trusted -u user:password https://example.com
```
<p class="level1">
<p class="level1">See also ##-u, --user##.
<p class="level0"><a name="-L"></a><span class="nroffip">-L, --location</span>
<p class="level1">(HTTP) If the server reports that the requested page has moved to a different location (indicated with a Location: header and a 3XX response code), this option will make curl redo the request on the new place. If used together with ##-i, --include## or ##-I, --head##, headers from all requested pages will be shown. When authentication is used, curl only sends its credentials to the initial host. If a redirect takes curl to a different host, it will not be able to intercept the user+password. See also ##--location-trusted## on how to change this. You can limit the amount of redirects to follow by using the ##--max-redirs## option.
<p class="level1">When curl follows a redirect and if the request is a POST, it will send the following request with a GET if the HTTP response was 301, 302, or 303. If the response code was any other 3xx code, curl will re-send the following request using the same unmodified method.
<p class="level1">You can tell curl to not change POST requests to GET after a 30x response by using the dedicated options for that: ##--post301##, ##--post302## and ##--post303##.
<p class="level1">The method set with ##-X, --request## overrides the method curl would otherwise select to use.
<p class="level1">Providing ##-L, --location## multiple times has no extra effect. Disable it again with --no-location.
<p class="level1">Example:
```
curl -L https://example.com
```
<p class="level1">
<p class="level1">See also ##--resolve## and ##--alt-svc##.
<p class="level0"><a name="--login-options"></a><span class="nroffip">--login-options &lt;options&gt;</span>
<p class="level1">(IMAP LDAP POP3 SMTP) Specify the login options to use during server authentication.
<p class="level1">You can use login options to specify protocol specific options that may be used during authentication. At present only IMAP, POP3 and SMTP support login options. For more information about login options please see RFC 2384, <a href="http://www.ietf.org/rfc/rfc5092.txt">RFC 5092</a> and IETF draft draft-earhart-url-smtp-00.txt
<p class="level1">If ##--login-options## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --login-options &#39;AUTH=*&#39; imap://example.com
```
<p class="level1">
<p class="level1">See also ##-u, --user##. Added in 7.34.0.
<p class="level0"><a name="--mail-auth"></a><span class="nroffip">--mail-auth &lt;address&gt;</span>
<p class="level1">(SMTP) Specify a single address. This will be used to specify the authentication address (identity) of a submitted message that is being relayed to another server.
<p class="level1">If ##--mail-auth## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --mail-auth user@example.come -T mail smtp://example.com/
```
<p class="level1">
<p class="level1">See also ##--mail-rcpt## and ##--mail-from##.
<p class="level0"><a name="--mail-from"></a><span class="nroffip">--mail-from &lt;address&gt;</span>
<p class="level1">(SMTP) Specify a single address that the given mail should get sent from.
<p class="level1">If ##--mail-from## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --mail-from user@example.com -T mail smtp://example.com/
```
<p class="level1">
<p class="level1">See also ##--mail-rcpt## and ##--mail-auth##.
<p class="level0"><a name="--mail-rcpt-allowfails"></a><span class="nroffip">--mail-rcpt-allowfails</span>
<p class="level1">(SMTP) When sending data to multiple recipients, by default curl will abort SMTP conversation if at least one of the recipients causes RCPT TO command to return an error.
<p class="level1">The default behavior can be changed by passing ##--mail-rcpt-allowfails## command-line option which will make curl ignore errors and proceed with the remaining valid recipients.
<p class="level1">If all recipients trigger RCPT TO failures and this flag is specified, curl will still abort the SMTP conversation and return the error received from to the last RCPT TO command.
<p class="level1">Providing ##--mail-rcpt-allowfails## multiple times has no extra effect. Disable it again with --no-mail-rcpt-allowfails.
<p class="level1">Example:
```
curl --mail-rcpt-allowfails --mail-rcpt dest@example.com smtp://example.com
```
<p class="level1">
<p class="level1">See also ##--mail-rcpt##. Added in 7.69.0.
<p class="level0"><a name="--mail-rcpt"></a><span class="nroffip">--mail-rcpt &lt;address&gt;</span>
<p class="level1">(SMTP) Specify a single email address, user name or mailing list name. Repeat this option several times to send to multiple recipients.
<p class="level1">When performing an address verification (VRFY command), the recipient should be specified as the user name or user name and domain (as per Section 3.5 of <a href="http://www.ietf.org/rfc/rfc5321.txt">RFC 5321</a>). (Added in 7.34.0)
<p class="level1">When performing a mailing list expand (EXPN command), the recipient should be specified using the mailing list name, such as &quot;Friends&quot; or &quot;London-Office&quot;. (Added in 7.34.0)
<p class="level1">##--mail-rcpt## can be used several times in a command line
<p class="level1">Example:
```
curl --mail-rcpt user@example.net smtp://example.com
```
<p class="level1">
<p class="level1">See also ##--mail-rcpt-allowfails##.
<p class="level0"><a name="-M"></a><span class="nroffip">-M, --manual</span>
<p class="level1">Manual. Display the huge help text.
<p class="level1">Providing ##-M, --manual## multiple times has no extra effect. Disable it again with --no-manual.
<p class="level1">Example:
```
curl --manual
```
<p class="level1">
<p class="level1">See also ##-v, --verbose##, ##--libcurl## and ##--trace##.
<p class="level0"><a name="--max-filesize"></a><span class="nroffip">--max-filesize &lt;bytes&gt;</span>
<p class="level1">(FTP HTTP MQTT) Specify the maximum size (in bytes) of a file to download. If the file requested is larger than this value, the transfer will not start and curl will return with exit code 63.
<p class="level1">A size modifier may be used. For example, Appending &#39;k&#39; or &#39;K&#39; will count the number as kilobytes, &#39;m&#39; or &#39;M&#39; makes it megabytes, while &#39;g&#39; or &#39;G&#39; makes it gigabytes. Examples: 200K, 3m and 1G. (Added in 7.58.0)
<p class="level1"><span Class="bold">NOTE</span>: The file size is not always known prior to download, and for such files this option has no effect even if the file transfer ends up being larger than this given limit. If ##--max-filesize## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --max-filesize 100K https://example.com
```
<p class="level1">
<p class="level1">See also ##--limit-rate##.
<p class="level0"><a name="--max-redirs"></a><span class="nroffip">--max-redirs &lt;num&gt;</span>
<p class="level1">(HTTP) Set maximum number of redirections to follow. When ##-L, --location## is used, to prevent curl from following too many redirects, by default, the limit is set to 50 redirects. Set this option to -1 to make it unlimited.
<p class="level1">If ##--max-redirs## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --max-redirs 3 --location https://example.com
```
<p class="level1">
<p class="level1">See also ##-L, --location##.
<p class="level0"><a name="-m"></a><span class="nroffip">-m, --max-time &lt;fractional seconds&gt;</span>
<p class="level1">Maximum time in seconds that you allow each transfer to take.  This is useful for preventing your batch jobs from hanging for hours due to slow networks or links going down.  Since 7.32.0, this option accepts decimal values, but the actual timeout will decrease in accuracy as the specified timeout increases in decimal precision.
<p class="level1">If you enable retrying the transfer (##--retry##) then the maximum time counter is reset each time the transfer is retried. You can use ##--retry-max-time## to limit the retry time.
<p class="level1">The decimal value needs to provided using a dot (.) as decimal separator - not the local version even if it might be using another separator.
<p class="level1">If ##-m, --max-time## is provided several times, the last set value will be used.
<p class="level1">Examples:
```
curl --max-time 10 https://example.com
curl --max-time 2.92 https://example.com
```
<p class="level1">
<p class="level1">See also ##--connect-timeout## and ##--retry-max-time##.
<p class="level0"><a name="--metalink"></a><span class="nroffip">--metalink</span>
<p class="level1">This option was previously used to specify a metalink resource. Metalink support has been disabled in curl since 7.78.0 for security reasons.
<p class="level1">If ##--metalink## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --metalink file https://example.com
```
<p class="level1">
<p class="level1">See also ##-Z, --parallel##.
<p class="level0"><a name="--negotiate"></a><span class="nroffip">--negotiate</span>
<p class="level1">(HTTP) Enables Negotiate (SPNEGO) authentication.
<p class="level1">This option requires a library built with GSS-API or SSPI support. Use ##-V, --version## to see if your curl supports GSS-API/SSPI or SPNEGO.
<p class="level1">When using this option, you must also provide a fake ##-u, --user## option to activate the authentication code properly. Sending a &#39;-u :&#39; is enough as the user name and password from the ##-u, --user## option are not actually used.
<p class="level1">If this option is used several times, only the first one is used.
<p class="level1">Providing ##--negotiate## multiple times has no extra effect.
<p class="level1">Example:
```
curl --negotiate -u : https://example.com
```
<p class="level1">
<p class="level1">See also ##--basic##, ##--ntlm##, ##--anyauth## and ##--proxy-negotiate##.
<p class="level0"><a name="--netrc-file"></a><span class="nroffip">--netrc-file &lt;filename&gt;</span>
<p class="level1">This option is similar to ##-n, --netrc##, except that you provide the path (absolute or relative) to the netrc file that curl should use. You can only specify one netrc file per invocation.
<p class="level1">It will abide by ##--netrc-optional## if specified.
<p class="level1">If ##--netrc-file## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --netrc-file netrc https://example.com
```
<p class="level1">
<p class="level1">See also ##-n, --netrc##, ##-u, --user## and ##-K, --config##. This option is mutually exclusive to ##-n, --netrc##.
<p class="level0"><a name="--netrc-optional"></a><span class="nroffip">--netrc-optional</span>
<p class="level1">Similar to ##-n, --netrc##, but this option makes the .netrc usage <span Class="bold">optional</span> and not mandatory as the ##-n, --netrc## option does.
<p class="level1">Providing ##--netrc-optional## multiple times has no extra effect. Disable it again with --no-netrc-optional.
<p class="level1">Example:
```
curl --netrc-optional https://example.com
```
<p class="level1">
<p class="level1">See also ##--netrc-file##. This option is mutually exclusive to ##-n, --netrc##.
<p class="level0"><a name="-n"></a><span class="nroffip">-n, --netrc</span>
<p class="level1">Makes curl scan the <span Class="emphasis">.netrc</span> (<span Class="emphasis">_netrc</span> on Windows) file in the user&#39;s home directory for login name and password. This is typically used for FTP on Unix. If used with HTTP, curl will enable user authentication. See <span Class="emphasis">netrc(5)</span> and <span Class="emphasis">ftp(1)</span> for details on the file format. Curl will not complain if that file does not have the right permissions (it should be neither world- nor group-readable). The environment variable &quot;HOME&quot; is used to find the home directory.
<p class="level1">A quick and simple example of how to setup a <span Class="emphasis">.netrc</span> to allow curl to FTP to the machine host.domain.com with user name &#39;myself&#39; and password &#39;secret&#39; could look similar to:
<p class="level1">
```
machine host.domain.com
login myself
password secret
```
<p class="level1">
<p class="level1">Providing ##-n, --netrc## multiple times has no extra effect. Disable it again with --no-netrc.
<p class="level1">Example:
```
curl --netrc https://example.com
```
<p class="level1">
<p class="level1">See also ##--netrc-file##, ##-K, --config## and ##-u, --user##. This option is mutually exclusive to ##--netrc-file## and ##--netrc-optional##.
<p class="level0"><a name="-"></a><span class="nroffip">-:, --next</span>
<p class="level1">Tells curl to use a separate operation for the following URL and associated options. This allows you to send several URL requests, each with their own specific options, for example, such as different user names or custom requests for each.
<p class="level1">##-:, --next## will reset all local options and only global ones will have their values survive over to the operation following the ##-:, --next## instruction. Global options include ##-v, --verbose##, ##--trace##, ##--trace-ascii## and ##--fail-early##.
<p class="level1">For example, you can do both a GET and a POST in a single command line:
<p class="level1">
```
curl www1.example.com --next -d postthis www2.example.com
```
<p class="level1">
<p class="level1">##-:, --next## can be used several times in a command line
<p class="level1">Examples:
```
curl https://example.com --next -d postthis www2.example.com
curl -I https://example.com --next https://example.net/
```
<p class="level1">
<p class="level1">See also ##-Z, --parallel## and ##-K, --config##. Added in 7.36.0.
<p class="level0"><a name="--no-alpn"></a><span class="nroffip">--no-alpn</span>
<p class="level1">(HTTPS) Disable the ALPN TLS extension. ALPN is enabled by default if libcurl was built with an SSL library that supports ALPN. ALPN is used by a libcurl that supports HTTP/2 to negotiate HTTP/2 support with the server during https sessions.
<p class="level1">Providing ##--no-alpn## multiple times has no extra effect. Disable it again with --alpn.
<p class="level1">Example:
```
curl --no-alpn https://example.com
```
<p class="level1">
<p class="level1">See also ##--no-npn## and ##--http2##. ##--no-alpn## requires that the underlying libcurl was built to support TLS. Added in 7.36.0.
<p class="level0"><a name="-N"></a><span class="nroffip">-N, --no-buffer</span>
<p class="level1">Disables the buffering of the output stream. In normal work situations, curl will use a standard buffered output stream that will have the effect that it will output the data in chunks, not necessarily exactly when the data arrives. Using this option will disable that buffering.
<p class="level1">Providing ##-N, --no-buffer## multiple times has no extra effect. Disable it again with --buffer.
<p class="level1">Example:
```
curl --no-buffer https://example.com
```
<p class="level1">
<p class="level1">See also <span Class="emphasis">-&#35;, --progress-bar</span>.
<p class="level0"><a name="--no-clobber"></a><span class="nroffip">--no-clobber</span>
<p class="level1">When used in conjunction with the ##-o, --output##, ##-J, --remote-header-name##, ##-O, --remote-name##, or ##--remote-name-all## options, curl avoids overwriting files that already exist. Instead, a dot and a number gets appended to the name of the file that would be created, up to filename.100 after which it will not create any file.
<p class="level1">Note that this is the negated option name documented.  You can thus use --clobber to enforce the clobbering, even if ##-J, --remote-header-name## or -J is specified.
<p class="level1">Providing ##--no-clobber## multiple times has no extra effect. Disable it again with --clobber.
<p class="level1">Example:
```
curl --no-clobber --output local/dir/file https://example.com
```
<p class="level1">
<p class="level1">See also ##-o, --output## and ##-O, --remote-name##. Added in 7.83.0.
<p class="level0"><a name="--no-keepalive"></a><span class="nroffip">--no-keepalive</span>
<p class="level1">Disables the use of keepalive messages on the TCP connection. curl otherwise enables them by default.
<p class="level1">Note that this is the negated option name documented. You can thus use --keepalive to enforce keepalive.
<p class="level1">Providing ##--no-keepalive## multiple times has no extra effect. Disable it again with --keepalive.
<p class="level1">Example:
```
curl --no-keepalive https://example.com
```
<p class="level1">
<p class="level1">See also ##--keepalive-time##.
<p class="level0"><a name="--no-npn"></a><span class="nroffip">--no-npn</span>
<p class="level1">(HTTPS) In curl 7.86.0 and later, curl never uses NPN.
<p class="level1">Disable the NPN TLS extension. NPN is enabled by default if libcurl was built with an SSL library that supports NPN. NPN is used by a libcurl that supports HTTP/2 to negotiate HTTP/2 support with the server during https sessions.
<p class="level1">Providing ##--no-npn## multiple times has no extra effect. Disable it again with --npn.
<p class="level1">Example:
```
curl --no-npn https://example.com
```
<p class="level1">
<p class="level1">See also ##--no-alpn## and ##--http2##. ##--no-npn## requires that the underlying libcurl was built to support TLS. Added in 7.36.0.
<p class="level0"><a name="--no-progress-meter"></a><span class="nroffip">--no-progress-meter</span>
<p class="level1">Option to switch off the progress meter output without muting or otherwise affecting warning and informational messages like ##-s, --silent## does.
<p class="level1">Note that this is the negated option name documented. You can thus use --progress-meter to enable the progress meter again.
<p class="level1">Providing ##--no-progress-meter## multiple times has no extra effect. Disable it again with --progress-meter.
<p class="level1">Example:
```
curl --no-progress-meter -o store https://example.com
```
<p class="level1">
<p class="level1">See also ##-v, --verbose## and ##-s, --silent##. Added in 7.67.0.
<p class="level0"><a name="--no-sessionid"></a><span class="nroffip">--no-sessionid</span>
<p class="level1">(TLS) Disable curl&#39;s use of SSL session-ID caching. By default all transfers are done using the cache. Note that while nothing should ever get hurt by attempting to reuse SSL session-IDs, there seem to be broken SSL implementations in the wild that may require you to disable this in order for you to succeed.
<p class="level1">Note that this is the negated option name documented. You can thus use --sessionid to enforce session-ID caching.
<p class="level1">Providing ##--no-sessionid## multiple times has no extra effect. Disable it again with --sessionid.
<p class="level1">Example:
```
curl --no-sessionid https://example.com
```
<p class="level1">
<p class="level1">See also ##-k, --insecure##.
<p class="level0"><a name="--noproxy"></a><span class="nroffip">--noproxy &lt;no-proxy-list&gt;</span>
<p class="level1">Comma-separated list of hosts for which not to use a proxy, if one is specified. The only wildcard is a single * character, which matches all hosts, and effectively disables the proxy. Each name in this list is matched as either a domain which contains the hostname, or the hostname itself. For example, local.com would match local.com, local.com:80, and www.local.com, but not www.notlocal.com.
<p class="level1">Since 7.53.0, This option overrides the environment variables that disable the proxy (&#39;no_proxy&#39; and &#39;NO_PROXY&#39;). If there&#39;s an environment variable disabling a proxy, you can set the noproxy list to &quot;&quot; to override it.
<p class="level1">Since 7.86.0, IP addresses specified to this option can be provided using CIDR notation: an appended slash and number specifies the number of &quot;network bits&quot; out of the address to use in the comparison. For example &quot;192.168.0.0/16&quot; would match all addresses starting with &quot;192.168&quot;.
<p class="level1">If ##--noproxy## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --noproxy &quot;www.example&quot; https://example.com
```
<p class="level1">
<p class="level1">See also ##-x, --proxy##.
<p class="level0"><a name="--ntlm-wb"></a><span class="nroffip">--ntlm-wb</span>
<p class="level1">(HTTP) Enables NTLM much in the style ##--ntlm## does, but hand over the authentication to the separate binary ntlmauth application that is executed when needed.
<p class="level1">Providing ##--ntlm-wb## multiple times has no extra effect.
<p class="level1">Example:
```
curl --ntlm-wb -u user:password https://example.com
```
<p class="level1">
<p class="level1">See also ##--ntlm## and ##--proxy-ntlm##.
<p class="level0"><a name="--ntlm"></a><span class="nroffip">--ntlm</span>
<p class="level1">(HTTP) Enables NTLM authentication. The NTLM authentication method was designed by Microsoft and is used by IIS web servers. It is a proprietary protocol, reverse-engineered by clever people and implemented in curl based on their efforts. This kind of behavior should not be endorsed, you should encourage everyone who uses NTLM to switch to a and documented authentication method instead, such as Digest.
<p class="level1">If you want to enable NTLM for your proxy authentication, then use ##--proxy-ntlm##.
<p class="level1">If this option is used several times, only the first one is used.
<p class="level1">Providing ##--ntlm## multiple times has no extra effect.
<p class="level1">Example:
```
curl --ntlm -u user:password https://example.com
```
<p class="level1">
<p class="level1">See also ##--proxy-ntlm##. ##--ntlm## requires that the underlying libcurl was built to support TLS. This option is mutually exclusive to ##--basic## and ##--negotiate## and ##--digest## and ##--anyauth##.
<p class="level0"><a name="--oauth2-bearer"></a><span class="nroffip">--oauth2-bearer &lt;token&gt;</span>
<p class="level1">(IMAP LDAP POP3 SMTP HTTP) Specify the Bearer Token for OAUTH 2.0 server authentication. The Bearer Token is used in conjunction with the user name which can be specified as part of the ##--url## or ##-u, --user## options.
<p class="level1">The Bearer Token and user name are formatted according to <a href="http://www.ietf.org/rfc/rfc6750.txt">RFC 6750</a>.
<p class="level1">If ##--oauth2-bearer## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --oauth2-bearer &quot;mF_9.B5f-4.1JqM&quot; https://example.com
```
<p class="level1">
<p class="level1">See also ##--basic##, ##--ntlm## and ##--digest##. Added in 7.33.0.
<p class="level0"><a name="--output-dir"></a><span class="nroffip">--output-dir &lt;dir&gt;</span>
<p class="level1">This option specifies the directory in which files should be stored, when ##-O, --remote-name## or ##-o, --output## are used.
<p class="level1">The given output directory is used for all URLs and output options on the command line, up until the first ##-:, --next##.
<p class="level1">If the specified target directory does not exist, the operation will fail unless ##--create-dirs## is also used.
<p class="level1">If ##--output-dir## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --output-dir &quot;tmp&quot; -O https://example.com
```
<p class="level1">
<p class="level1">See also ##-O, --remote-name## and ##-J, --remote-header-name##. Added in 7.73.0.
<p class="level0"><a name="-o"></a><span class="nroffip">-o, --output &lt;file&gt;</span>
<p class="level1">Write output to &lt;file&gt; instead of stdout. If you are using {} or [] to fetch multiple documents, you should quote the URL and you can use &#39;&#35;&#39; followed by a number in the &lt;file&gt; specifier. That variable will be replaced with the current string for the URL being fetched. Like in:
<p class="level1">
```
curl &quot;http://{one,two}.example.com&quot; -o &quot;file_&#35;1.txt&quot;
```
<p class="level1">
<p class="level1">or use several variables like:
<p class="level1">
```
curl &quot;http://{site,host}.host[1-5].com&quot; -o &quot;&#35;1_&#35;2&quot;
```
<p class="level1">
<p class="level1">You may use this option as many times as the number of URLs you have. For example, if you specify two URLs on the same command line, you can use it like this:
<p class="level1">
```
 curl -o aa example.com -o bb example.net
```
<p class="level1">
<p class="level1">and the order of the -o options and the URLs does not matter, just that the first -o is for the first URL and so on, so the above command line can also be written as
<p class="level1">
```
 curl example.com example.net -o aa -o bb
```
<p class="level1">
<p class="level1">See also the ##--create-dirs## option to create the local directories dynamically. Specifying the output as &#39;-&#39; (a single dash) will force the output to be done to stdout.
<p class="level1">To suppress response bodies, you can redirect output to /dev/null:
<p class="level1">
```
 curl example.com -o /dev/null
```
<p class="level1">
<p class="level1">Or for Windows use nul:
<p class="level1">
```
 curl example.com -o nul
```
<p class="level1">
<p class="level1">##-o, --output## can be used several times in a command line
<p class="level1">Examples:
```
curl -o file https://example.com
curl &quot;http://{one,two}.example.com&quot; -o &quot;file_&#35;1.txt&quot;
curl &quot;http://{site,host}.host[1-5].com&quot; -o &quot;&#35;1_&#35;2&quot;
curl -o file https://example.com -o file2 https://example.net
```
<p class="level1">
<p class="level1">See also ##-O, --remote-name##, ##--remote-name-all## and ##-J, --remote-header-name##.
<p class="level0"><a name="--parallel-immediate"></a><span class="nroffip">--parallel-immediate</span>
<p class="level1">When doing parallel transfers, this option will instruct curl that it should rather prefer opening up more connections in parallel at once rather than waiting to see if new transfers can be added as multiplexed streams on another connection.
<p class="level1">This option is global and does not need to be specified for each use of ##-:, --next##.
<p class="level1">Providing ##--parallel-immediate## multiple times has no extra effect. Disable it again with --no-parallel-immediate.
<p class="level1">Example:
```
curl --parallel-immediate -Z https://example.com -o file1 https://example.com -o file2
```
<p class="level1">
<p class="level1">See also ##-Z, --parallel## and ##--parallel-max##. Added in 7.68.0.
<p class="level0"><a name="--parallel-max"></a><span class="nroffip">--parallel-max &lt;num&gt;</span>
<p class="level1">When asked to do parallel transfers, using ##-Z, --parallel##, this option controls the maximum amount of transfers to do simultaneously.
<p class="level1">This option is global and does not need to be specified for each use of ##-:, --next##.
<p class="level1">The default is 50.
<p class="level1">If ##--parallel-max## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --parallel-max 100 -Z https://example.com ftp://example.com/
```
<p class="level1">
<p class="level1">See also ##-Z, --parallel##. Added in 7.66.0.
<p class="level0"><a name="-Z"></a><span class="nroffip">-Z, --parallel</span>
<p class="level1">Makes curl perform its transfers in parallel as compared to the regular serial manner.
<p class="level1">This option is global and does not need to be specified for each use of ##-:, --next##.
<p class="level1">Providing ##-Z, --parallel## multiple times has no extra effect. Disable it again with --no-parallel.
<p class="level1">Example:
```
curl --parallel https://example.com -o file1 https://example.com -o file2
```
<p class="level1">
<p class="level1">See also ##-:, --next## and ##-v, --verbose##. Added in 7.66.0.
<p class="level0"><a name="--pass"></a><span class="nroffip">--pass &lt;phrase&gt;</span>
<p class="level1">(SSH TLS) Passphrase for the private key.
<p class="level1">If ##--pass## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --pass secret --key file https://example.com
```
<p class="level1">
<p class="level1">See also ##--key## and ##-u, --user##.
<p class="level0"><a name="--path-as-is"></a><span class="nroffip">--path-as-is</span>
<p class="level1">Tell curl to not handle sequences of /../ or /./ in the given URL path. Normally curl will squash or merge them according to standards but with this option set you tell it not to do that.
<p class="level1">Providing ##--path-as-is## multiple times has no extra effect. Disable it again with --no-path-as-is.
<p class="level1">Example:
```
curl --path-as-is https://example.com/../../etc/passwd
```
<p class="level1">
<p class="level1">See also ##--request-target##. Added in 7.42.0.
<p class="level0"><a name="--pinnedpubkey"></a><span class="nroffip">--pinnedpubkey &lt;hashes&gt;</span>
<p class="level1">(TLS) Tells curl to use the specified key file (or hashes) to verify the peer. This can be a path to a file which contains a single key in PEM or DER format, or any number of base64 encoded sha256 hashes preceded by &apos;sha256//&#39; and separated by &#39;;&#39;.
<p class="level1">When negotiating a TLS or SSL connection, the server sends a certificate indicating its identity. A key is extracted from this certificate and if it does not exactly match the key provided to this option, curl will abort the connection before sending or receiving any data.
<p class="level1">PEM/DER support:
<p class="level1">7.39.0: OpenSSL, GnuTLS and GSKit
<p class="level1">7.43.0: NSS and wolfSSL
<p class="level1">7.47.0: mbedtls
<p class="level1">sha256 support:
<p class="level1">7.44.0: OpenSSL, GnuTLS, NSS and wolfSSL
<p class="level1">7.47.0: mbedtls
<p class="level1">Other SSL backends not supported.
<p class="level1">If ##--pinnedpubkey## is provided several times, the last set value will be used.
<p class="level1">Examples:
```
curl --pinnedpubkey keyfile https://example.com
curl --pinnedpubkey &#39;sha256//ce118b51897f4452dc&#39; https://example.com
```
<p class="level1">
<p class="level1">See also ##--hostpubsha256##. Added in 7.39.0.
<p class="level0"><a name="--post301"></a><span class="nroffip">--post301</span>
<p class="level1">(HTTP) Tells curl to respect <a href="http://www.ietf.org/rfc/rfc7231.txt">RFC 7231</a>/6.4.2 and not convert POST requests into GET requests when following a 301 redirection. The non-RFC behavior is ubiquitous in web browsers, so curl does the conversion by default to maintain consistency. However, a server may require a POST to remain a POST after such a redirection. This option is meaningful only when using ##-L, --location##.
<p class="level1">Providing ##--post301## multiple times has no extra effect. Disable it again with --no-post301.
<p class="level1">Example:
```
curl --post301 --location -d &quot;data&quot; https://example.com
```
<p class="level1">
<p class="level1">See also ##--post302##, ##--post303## and ##-L, --location##.
<p class="level0"><a name="--post302"></a><span class="nroffip">--post302</span>
<p class="level1">(HTTP) Tells curl to respect <a href="http://www.ietf.org/rfc/rfc7231.txt">RFC 7231</a>/6.4.3 and not convert POST requests into GET requests when following a 302 redirection. The non-RFC behavior is ubiquitous in web browsers, so curl does the conversion by default to maintain consistency. However, a server may require a POST to remain a POST after such a redirection. This option is meaningful only when using ##-L, --location##.
<p class="level1">Providing ##--post302## multiple times has no extra effect. Disable it again with --no-post302.
<p class="level1">Example:
```
curl --post302 --location -d &quot;data&quot; https://example.com
```
<p class="level1">
<p class="level1">See also ##--post301##, ##--post303## and ##-L, --location##.
<p class="level0"><a name="--post303"></a><span class="nroffip">--post303</span>
<p class="level1">(HTTP) Tells curl to violate <a href="http://www.ietf.org/rfc/rfc7231.txt">RFC 7231</a>/6.4.4 and not convert POST requests into GET requests when following 303 redirections. A server may require a POST to remain a POST after a 303 redirection. This option is meaningful only when using ##-L, --location##.
<p class="level1">Providing ##--post303## multiple times has no extra effect. Disable it again with --no-post303.
<p class="level1">Example:
```
curl --post303 --location -d &quot;data&quot; https://example.com
```
<p class="level1">
<p class="level1">See also ##--post302##, ##--post301## and ##-L, --location##.
<p class="level0"><a name="--preproxy"></a><span class="nroffip">--preproxy &lt;[protocol://]host[:port]&gt;></span>
<p class="level1">Use the specified SOCKS proxy before connecting to an HTTP or HTTPS ##-x, --proxy##. In such a case curl first connects to the SOCKS proxy and then connects (through SOCKS) to the HTTP or HTTPS proxy. Hence pre proxy.
<p class="level1">The pre proxy string should be specified with a protocol:// prefix to specify alternative proxy protocols. Use socks4://, socks4a://, socks5:// or socks5h:// to request the specific SOCKS version to be used. No protocol specified will make curl default to SOCKS4.
<p class="level1">If the port number is not specified in the proxy string, it is assumed to be 1080.
<p class="level1">User and password that might be provided in the proxy string are URL decoded by curl. This allows you to pass in special characters such as @ by using %40 or pass in a colon with %3a.
<p class="level1">If ##--preproxy## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --preproxy socks5://proxy.example -x http://http.example https://example.com
```
<p class="level1">
<p class="level1">See also ##-x, --proxy## and ##--socks5##. Added in 7.52.0.
<p class="level0"><a name="-"></a><span class="nroffip">-&#35;, --progress-bar</span>
<p class="level1">Make curl display transfer progress as a simple progress bar instead of the standard, more informational, meter.
<p class="level1">This progress bar draws a single line of &#39;&#35;&#39; characters across the screen and shows a percentage if the transfer size is known. For transfers without a known size, there will be space ship (-=o=-) that moves back and forth but only while data is being transferred, with a set of flying hash sign symbols on top.
<p class="level1">This option is global and does not need to be specified for each use of ##-:, --next##.
<p class="level1">Providing <span Class="emphasis">-&#35;, --progress-bar</span> multiple times has no extra effect. Disable it again with --no-progress-bar.
<p class="level1">Example:
```
curl -&#35; -O https://example.com
```
<p class="level1">
<p class="level1">See also ##--styled-output##.
<p class="level0"><a name="--proto-default"></a><span class="nroffip">--proto-default &lt;protocol&gt;</span>
<p class="level1">Tells curl to use <span Class="emphasis">protocol</span> for any URL missing a scheme name.
<p class="level1">An unknown or unsupported protocol causes error <span Class="emphasis">CURLE_UNSUPPORTED_PROTOCOL</span> (1).
<p class="level1">This option does not change the default proxy protocol (http).
<p class="level1">Without this option set, curl guesses protocol based on the host name, see ##--url## for details.
<p class="level1">If ##--proto-default## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --proto-default https ftp.example.com
```
<p class="level1">
<p class="level1">See also ##--proto## and ##--proto-redir##. Added in 7.45.0.
<p class="level0"><a name="--proto-redir"></a><span class="nroffip">--proto-redir &lt;protocols&gt;</span>
<p class="level1">Tells curl to limit what protocols it may use on redirect. Protocols denied by ##--proto## are not overridden by this option. See ##--proto## for how protocols are represented.
<p class="level1">Example, allow only HTTP and HTTPS on redirect:
<p class="level1">
```
curl --proto-redir -all,http,https http://example.com
```
<p class="level1">
<p class="level1">By default curl will only allow HTTP, HTTPS, FTP and FTPS on redirect (since 7.65.2). Specifying <span Class="emphasis">all</span> or <span Class="emphasis">+all</span> enables all protocols on redirects, which is not good for security.
<p class="level1">If ##--proto-redir## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --proto-redir =http,https https://example.com
```
<p class="level1">
<p class="level1">See also ##--proto##.
<p class="level0"><a name="--proto"></a><span class="nroffip">--proto &lt;protocols&gt;</span>
<p class="level1">Tells curl to limit what protocols it may use for transfers. Protocols are evaluated left to right, are comma separated, and are each a protocol name or &apos;all&#39;, optionally prefixed by zero or more modifiers. Available modifiers are:
<p class="level2">
<p class="level2"><a class="bold" href="#">+</a> Permit this protocol in addition to protocols already permitted (this is the default if no modifier is used).
<p class="level2"><a class="bold" href="#-">-</a> Deny this protocol, removing it from the list of protocols already permitted.
<p class="level2"><a class="bold" href="#">=</a> Permit only this protocol (ignoring the list already permitted), though subject to later modification by subsequent entries in the comma separated list.
<p class="level1">
<p class="level0"><a name=""></a><span class="nroffip"></span>
<p class="level1">For example:
<p class="level2">
<p class="level2"><a class="bold" href="#--proto">--proto -ftps</a> uses the default protocols, but disables ftps
<p class="level2"><a class="bold" href="#--proto">--proto -all,https,+http</a> only enables http and https
<p class="level2"><a class="bold" href="#--proto">--proto =http,https</a> also only enables http and https
<p class="level1">
<p class="level0"><a name=""></a><span class="nroffip"></span>
<p class="level1">Unknown and disabled protocols produce a warning. This allows scripts to safely rely on being able to disable potentially dangerous protocols, without relying upon support for that protocol being built into curl to avoid an error.
<p class="level1">This option can be used multiple times, in which case the effect is the same as concatenating the protocols into one instance of the option.
<p class="level1">If ##--proto## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --proto =http,https,sftp https://example.com
```
<p class="level1">
<p class="level1">See also ##--proto-redir## and ##--proto-default##.
<p class="level0"><a name="--proxy-anyauth"></a><span class="nroffip">--proxy-anyauth</span>
<p class="level1">Tells curl to pick a suitable authentication method when communicating with the given HTTP proxy. This might cause an extra request/response round-trip.
<p class="level1">Providing ##--proxy-anyauth## multiple times has no extra effect.
<p class="level1">Example:
```
curl --proxy-anyauth --proxy-user user:passwd -x proxy https://example.com
```
<p class="level1">
<p class="level1">See also ##-x, --proxy##, ##--proxy-basic## and ##--proxy-digest##.
<p class="level0"><a name="--proxy-basic"></a><span class="nroffip">--proxy-basic</span>
<p class="level1">Tells curl to use HTTP Basic authentication when communicating with the given proxy. Use ##--basic## for enabling HTTP Basic with a remote host. Basic is the default authentication method curl uses with proxies.
<p class="level1">Providing ##--proxy-basic## multiple times has no extra effect.
<p class="level1">Example:
```
curl --proxy-basic --proxy-user user:passwd -x proxy https://example.com
```
<p class="level1">
<p class="level1">See also ##-x, --proxy##, ##--proxy-anyauth## and ##--proxy-digest##.
<p class="level0"><a name="--proxy-cacert"></a><span class="nroffip">--proxy-cacert &lt;file&gt;</span>
<p class="level1">Same as ##--cacert## but used in HTTPS proxy context.
<p class="level1">If ##--proxy-cacert## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --proxy-cacert CA-file.txt -x https://proxy https://example.com
```
<p class="level1">
<p class="level1">See also ##--proxy-capath##, ##--cacert##, ##--capath## and ##-x, --proxy##. Added in 7.52.0.
<p class="level0"><a name="--proxy-capath"></a><span class="nroffip">--proxy-capath &lt;dir&gt;</span>
<p class="level1">Same as ##--capath## but used in HTTPS proxy context.
<p class="level1">If ##--proxy-capath## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --proxy-capath /local/directory -x https://proxy https://example.com
```
<p class="level1">
<p class="level1">See also ##--proxy-cacert##, ##-x, --proxy## and ##--capath##. Added in 7.52.0.
<p class="level0"><a name="--proxy-cert-type"></a><span class="nroffip">--proxy-cert-type &lt;type&gt;</span>
<p class="level1">Same as ##--cert-type## but used in HTTPS proxy context.
<p class="level1">If ##--proxy-cert-type## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --proxy-cert-type PEM --proxy-cert file -x https://proxy https://example.com
```
<p class="level1">
<p class="level1">See also ##--proxy-cert##. Added in 7.52.0.
<p class="level0"><a name="--proxy-cert"></a><span class="nroffip">--proxy-cert &lt;cert[:passwd]&gt;</span>
<p class="level1">Same as ##-E, --cert## but used in HTTPS proxy context.
<p class="level1">If ##--proxy-cert## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --proxy-cert file -x https://proxy https://example.com
```
<p class="level1">
<p class="level1">See also ##--proxy-cert-type##. Added in 7.52.0.
<p class="level0"><a name="--proxy-ciphers"></a><span class="nroffip">--proxy-ciphers &lt;list&gt;</span>
<p class="level1">Same as ##--ciphers## but used in HTTPS proxy context.
<p class="level1">If ##--proxy-ciphers## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --proxy-ciphers ECDHE-ECDSA-AES256-CCM8 -x https://proxy https://example.com
```
<p class="level1">
<p class="level1">See also ##--ciphers##, ##--curves## and ##-x, --proxy##. Added in 7.52.0.
<p class="level0"><a name="--proxy-crlfile"></a><span class="nroffip">--proxy-crlfile &lt;file&gt;</span>
<p class="level1">Same as ##--crlfile## but used in HTTPS proxy context.
<p class="level1">If ##--proxy-crlfile## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --proxy-crlfile rejects.txt -x https://proxy https://example.com
```
<p class="level1">
<p class="level1">See also ##--crlfile## and ##-x, --proxy##. Added in 7.52.0.
<p class="level0"><a name="--proxy-digest"></a><span class="nroffip">--proxy-digest</span>
<p class="level1">Tells curl to use HTTP Digest authentication when communicating with the given proxy. Use ##--digest## for enabling HTTP Digest with a remote host.
<p class="level1">Providing ##--proxy-digest## multiple times has no extra effect.
<p class="level1">Example:
```
curl --proxy-digest --proxy-user user:passwd -x proxy https://example.com
```
<p class="level1">
<p class="level1">See also ##-x, --proxy##, ##--proxy-anyauth## and ##--proxy-basic##.
<p class="level0"><a name="--proxy-header"></a><span class="nroffip">--proxy-header &lt;header/@file&gt;</span>
<p class="level1">(HTTP) Extra header to include in the request when sending HTTP to a proxy. You may specify any number of extra headers. This is the equivalent option to ##-H, --header## but is for proxy communication only like in CONNECT requests when you want a separate header sent to the proxy to what is sent to the actual remote host.
<p class="level1">curl will make sure that each header you add/replace is sent with the proper end-of-line marker, you should thus <span Class="bold">not</span> add that as a part of the header content: do not add newlines or carriage returns, they will only mess things up for you.
<p class="level1">Headers specified with this option will not be included in requests that curl knows will not be sent to a proxy.
<p class="level1">Starting in 7.55.0, this option can take an argument in @filename style, which then adds a header for each line in the input file. Using @- will make curl read the header file from stdin.
<p class="level1">This option can be used multiple times to add/replace/remove multiple headers.
<p class="level1">##--proxy-header## can be used several times in a command line
<p class="level1">Examples:
```
curl --proxy-header &quot;X-First-Name: Joe&quot; -x http://proxy https://example.com
curl --proxy-header &quot;User-Agent: surprise&quot; -x http://proxy https://example.com
curl --proxy-header &quot;Host:&quot; -x http://proxy https://example.com
```
<p class="level1">
<p class="level1">See also ##-x, --proxy##. Added in 7.37.0.
<p class="level0"><a name="--proxy-insecure"></a><span class="nroffip">--proxy-insecure</span>
<p class="level1">Same as ##-k, --insecure## but used in HTTPS proxy context.
<p class="level1">Providing ##--proxy-insecure## multiple times has no extra effect. Disable it again with --no-proxy-insecure.
<p class="level1">Example:
```
curl --proxy-insecure -x https://proxy https://example.com
```
<p class="level1">
<p class="level1">See also ##-x, --proxy## and ##-k, --insecure##. Added in 7.52.0.
<p class="level0"><a name="--proxy-key-type"></a><span class="nroffip">--proxy-key-type &lt;type&gt;</span>
<p class="level1">Same as ##--key-type## but used in HTTPS proxy context.
<p class="level1">If ##--proxy-key-type## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --proxy-key-type DER --proxy-key here -x https://proxy https://example.com
```
<p class="level1">
<p class="level1">See also ##--proxy-key## and ##-x, --proxy##. Added in 7.52.0.
<p class="level0"><a name="--proxy-key"></a><span class="nroffip">--proxy-key &lt;key&gt;</span>
<p class="level1">Same as ##--key## but used in HTTPS proxy context.
<p class="level1">If ##--proxy-key## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --proxy-key here -x https://proxy https://example.com
```
<p class="level1">
<p class="level1">See also ##--proxy-key-type## and ##-x, --proxy##. Added in 7.52.0.
<p class="level0"><a name="--proxy-negotiate"></a><span class="nroffip">--proxy-negotiate</span>
<p class="level1">Tells curl to use HTTP Negotiate (SPNEGO) authentication when communicating with the given proxy. Use ##--negotiate## for enabling HTTP Negotiate (SPNEGO) with a remote host.
<p class="level1">Providing ##--proxy-negotiate## multiple times has no extra effect.
<p class="level1">Example:
```
curl --proxy-negotiate --proxy-user user:passwd -x proxy https://example.com
```
<p class="level1">
<p class="level1">See also ##--proxy-anyauth## and ##--proxy-basic##.
<p class="level0"><a name="--proxy-ntlm"></a><span class="nroffip">--proxy-ntlm</span>
<p class="level1">Tells curl to use HTTP NTLM authentication when communicating with the given proxy. Use ##--ntlm## for enabling NTLM with a remote host.
<p class="level1">Providing ##--proxy-ntlm## multiple times has no extra effect.
<p class="level1">Example:
```
curl --proxy-ntlm --proxy-user user:passwd -x http://proxy https://example.com
```
<p class="level1">
<p class="level1">See also ##--proxy-negotiate## and ##--proxy-anyauth##.
<p class="level0"><a name="--proxy-pass"></a><span class="nroffip">--proxy-pass &lt;phrase&gt;</span>
<p class="level1">Same as ##--pass## but used in HTTPS proxy context.
<p class="level1">If ##--proxy-pass## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --proxy-pass secret --proxy-key here -x https://proxy https://example.com
```
<p class="level1">
<p class="level1">See also ##-x, --proxy## and ##--proxy-key##. Added in 7.52.0.
<p class="level0"><a name="--proxy-pinnedpubkey"></a><span class="nroffip">--proxy-pinnedpubkey &lt;hashes&gt;</span>
<p class="level1">(TLS) Tells curl to use the specified key file (or hashes) to verify the proxy. This can be a path to a file which contains a single key in PEM or DER format, or any number of base64 encoded sha256 hashes preceded by &apos;sha256//&#39; and separated by &#39;;&#39;.
<p class="level1">When negotiating a TLS or SSL connection, the server sends a certificate indicating its identity. A key is extracted from this certificate and if it does not exactly match the key provided to this option, curl will abort the connection before sending or receiving any data.
<p class="level1">If ##--proxy-pinnedpubkey## is provided several times, the last set value will be used.
<p class="level1">Examples:
```
curl --proxy-pinnedpubkey keyfile https://example.com
curl --proxy-pinnedpubkey &#39;sha256//ce118b51897f4452dc&#39; https://example.com
```
<p class="level1">
<p class="level1">See also ##--pinnedpubkey## and ##-x, --proxy##. Added in 7.59.0.
<p class="level0"><a name="--proxy-service-name"></a><span class="nroffip">--proxy-service-name &lt;name&gt;</span>
<p class="level1">This option allows you to change the service name for proxy negotiation.
<p class="level1">If ##--proxy-service-name## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --proxy-service-name &quot;shrubbery&quot; -x proxy https://example.com
```
<p class="level1">
<p class="level1">See also ##--service-name## and ##-x, --proxy##. Added in 7.43.0.
<p class="level0"><a name="--proxy-ssl-allow-beast"></a><span class="nroffip">--proxy-ssl-allow-beast</span>
<p class="level1">Same as ##--ssl-allow-beast## but used in HTTPS proxy context.
<p class="level1">Providing ##--proxy-ssl-allow-beast## multiple times has no extra effect. Disable it again with --no-proxy-ssl-allow-beast.
<p class="level1">Example:
```
curl --proxy-ssl-allow-beast -x https://proxy https://example.com
```
<p class="level1">
<p class="level1">See also ##--ssl-allow-beast## and ##-x, --proxy##. Added in 7.52.0.
<p class="level0"><a name="--proxy-ssl-auto-client-cert"></a><span class="nroffip">--proxy-ssl-auto-client-cert</span>
<p class="level1">Same as ##--ssl-auto-client-cert## but used in HTTPS proxy context.
<p class="level1">Providing ##--proxy-ssl-auto-client-cert## multiple times has no extra effect. Disable it again with --no-proxy-ssl-auto-client-cert.
<p class="level1">Example:
```
curl --proxy-ssl-auto-client-cert -x https://proxy https://example.com
```
<p class="level1">
<p class="level1">See also ##--ssl-auto-client-cert## and ##-x, --proxy##. Added in 7.77.0.
<p class="level0"><a name="--proxy-tls13-ciphers"></a><span class="nroffip">--proxy-tls13-ciphers &lt;ciphersuite list&gt;</span>
<p class="level1">(TLS) Specifies which cipher suites to use in the connection to your HTTPS proxy when it negotiates TLS 1.3. The list of ciphers suites must specify valid ciphers. Read up on TLS 1.3 cipher suite details on this URL:
<p class="level1">
```
https://curl.se/docs/ssl-ciphers.html
```
<p class="level1">
<p class="level1">This option is currently used only when curl is built to use OpenSSL 1.1.1 or later. If you are using a different SSL backend you can try setting TLS 1.3 cipher suites by using the ##--proxy-ciphers## option.
<p class="level1">If ##--proxy-tls13-ciphers## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --proxy-tls13-ciphers TLS_AES_128_GCM_SHA256 -x proxy https://example.com
```
<p class="level1">
<p class="level1">See also ##--tls13-ciphers## and ##--curves##. Added in 7.61.0.
<p class="level0"><a name="--proxy-tlsauthtype"></a><span class="nroffip">--proxy-tlsauthtype &lt;type&gt;</span>
<p class="level1">Same as ##--tlsauthtype## but used in HTTPS proxy context.
<p class="level1">If ##--proxy-tlsauthtype## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --proxy-tlsauthtype SRP -x https://proxy https://example.com
```
<p class="level1">
<p class="level1">See also ##-x, --proxy## and ##--proxy-tlsuser##. Added in 7.52.0.
<p class="level0"><a name="--proxy-tlspassword"></a><span class="nroffip">--proxy-tlspassword &lt;string&gt;</span>
<p class="level1">Same as ##--tlspassword## but used in HTTPS proxy context.
<p class="level1">If ##--proxy-tlspassword## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --proxy-tlspassword passwd -x https://proxy https://example.com
```
<p class="level1">
<p class="level1">See also ##-x, --proxy## and ##--proxy-tlsuser##. Added in 7.52.0.
<p class="level0"><a name="--proxy-tlsuser"></a><span class="nroffip">--proxy-tlsuser &lt;name&gt;</span>
<p class="level1">Same as ##--tlsuser## but used in HTTPS proxy context.
<p class="level1">If ##--proxy-tlsuser## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --proxy-tlsuser smith -x https://proxy https://example.com
```
<p class="level1">
<p class="level1">See also ##-x, --proxy## and ##--proxy-tlspassword##. Added in 7.52.0.
<p class="level0"><a name="--proxy-tlsv1"></a><span class="nroffip">--proxy-tlsv1</span>
<p class="level1">Same as ##-1, --tlsv1## but used in HTTPS proxy context.
<p class="level1">Providing ##--proxy-tlsv1## multiple times has no extra effect.
<p class="level1">Example:
```
curl --proxy-tlsv1 -x https://proxy https://example.com
```
<p class="level1">
<p class="level1">See also ##-x, --proxy##. Added in 7.52.0.
<p class="level0"><a name="-U"></a><span class="nroffip">-U, --proxy-user &lt;user:password&gt;</span>
<p class="level1">Specify the user name and password to use for proxy authentication.
<p class="level1">If you use a Windows SSPI-enabled curl binary and do either Negotiate or NTLM authentication then you can tell curl to select the user name and password from your environment by specifying a single colon with this option: &quot;-U :&quot;.
<p class="level1">On systems where it works, curl will hide the given option argument from process listings. This is not enough to protect credentials from possibly getting seen by other users on the same system as they will still be visible for a moment before cleared. Such sensitive data should be retrieved from a file instead or similar and never used in clear text in a command line.
<p class="level1">If ##-U, --proxy-user## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --proxy-user name:pwd -x proxy https://example.com
```
<p class="level1">
<p class="level1">See also ##--proxy-pass##.
<p class="level0"><a name="-x"></a><span class="nroffip">-x, --proxy &lt;[protocol://]host[:port]&gt;</span>
<p class="level1">Use the specified proxy.
<p class="level1">The proxy string can be specified with a protocol:// prefix. No protocol specified or http:// will be treated as HTTP proxy. Use socks4://, socks4a://, socks5:// or socks5h:// to request a specific SOCKS version to be used.
<p class="level1">
<p class="level1">Unix domain sockets are supported for socks proxy. Set localhost for the host part. e.g. socks5h://localhost/path/to/socket.sock
<p class="level1">HTTPS proxy support via https:// protocol prefix was added in 7.52.0 for OpenSSL, GnuTLS and NSS.
<p class="level1">Unrecognized and unsupported proxy protocols cause an error since 7.52.0. Prior versions may ignore the protocol and use http:// instead.
<p class="level1">If the port number is not specified in the proxy string, it is assumed to be 1080.
<p class="level1">This option overrides existing environment variables that set the proxy to use. If there&#39;s an environment variable setting a proxy, you can set proxy to &quot;&quot; to override it.
<p class="level1">All operations that are performed over an HTTP proxy will transparently be converted to HTTP. It means that certain protocol specific operations might not be available. This is not the case if you can tunnel through the proxy, as one with the ##-p, --proxytunnel## option.
<p class="level1">User and password that might be provided in the proxy string are URL decoded by curl. This allows you to pass in special characters such as @ by using %40 or pass in a colon with %3a.
<p class="level1">The proxy host can be specified the same way as the proxy environment variables, including the protocol prefix (<a href="http://)">http://)</a> and the embedded user + password.
<p class="level1">When a proxy is used, the active FTP mode as set with ##-P, --ftp-port##, cannot be used.
<p class="level1">If ##-x, --proxy## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --proxy http://proxy.example https://example.com
```
<p class="level1">
<p class="level1">See also ##--socks5## and ##--proxy-basic##.
<p class="level0"><a name="--proxy10"></a><span class="nroffip">--proxy1.0 &lt;host[:port]&gt;</span>
<p class="level1">Use the specified HTTP 1.0 proxy. If the port number is not specified, it is assumed at port 1080.
<p class="level1">The only difference between this and the HTTP proxy option ##-x, --proxy##, is that attempts to use CONNECT through the proxy will specify an HTTP 1.0 protocol instead of the default HTTP 1.1.
<p class="level1">Providing ##--proxy1.0## multiple times has no extra effect.
<p class="level1">Example:
```
curl --proxy1.0 -x http://proxy https://example.com
```
<p class="level1">
<p class="level1">See also ##-x, --proxy##, ##--socks5## and ##--preproxy##.
<p class="level0"><a name="-p"></a><span class="nroffip">-p, --proxytunnel</span>
<p class="level1">When an HTTP proxy is used ##-x, --proxy##, this option will make curl tunnel through the proxy. The tunnel approach is made with the HTTP proxy CONNECT request and requires that the proxy allows direct connect to the remote port number curl wants to tunnel through to.
<p class="level1">To suppress proxy CONNECT response headers when curl is set to output headers use ##--suppress-connect-headers##.
<p class="level1">Providing ##-p, --proxytunnel## multiple times has no extra effect. Disable it again with --no-proxytunnel.
<p class="level1">Example:
```
curl --proxytunnel -x http://proxy https://example.com
```
<p class="level1">
<p class="level1">See also ##-x, --proxy##.
<p class="level0"><a name="--pubkey"></a><span class="nroffip">--pubkey &lt;key&gt;</span>
<p class="level1">(SFTP SCP) key file name. Allows you to provide your key in this separate file.
<p class="level1">(As of 7.39.0, curl attempts to automatically extract the key from the private key file, so passing this option is generally not required. Note that this key extraction requires libcurl to be linked against a copy of libssh2 1.2.8 or higher that is itself linked against OpenSSL.)
<p class="level1">If ##--pubkey## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --pubkey file.pub sftp://example.com/
```
<p class="level1">
<p class="level1">See also ##--pass##.
<p class="level0"><a name="-Q"></a><span class="nroffip">-Q, --quote &lt;command&gt;</span>
<p class="level1">(FTP SFTP) Send an arbitrary command to the remote FTP or SFTP server. Quote commands are sent BEFORE the transfer takes place (just after the initial PWD command in an FTP transfer, to be exact). To make commands take place after a successful transfer, prefix them with a dash &#39;-&#39;.
<p class="level1">(FTP only) To make commands be sent after curl has changed the working directory, just before the file transfer command(s), prefix the command with a &apos;+&#39;. This is not performed when a directory listing is performed.
<p class="level1">You may specify any number of commands.
<p class="level1">By default curl will stop at first failure. To make curl continue even if the command fails, prefix the command with an asterisk (*). Otherwise, if the server returns failure for one of the commands, the entire operation will be aborted.
<p class="level1">You must send syntactically correct FTP commands as <a href="http://www.ietf.org/rfc/rfc959.txt">RFC 959</a> defines to FTP servers, or one of the commands listed below to SFTP servers.
<p class="level1">This option can be used multiple times.
<p class="level1">SFTP is a binary protocol. Unlike for FTP, curl interprets SFTP quote commands itself before sending them to the server. File names may be quoted shell-style to embed spaces or special characters. Following is the list of all supported SFTP quote commands:
<p class="level2">
<p class="level1"><a name="atime"></a><span class="nroffip">atime date file</span>
<p class="level2">The atime command sets the last access time of the file named by the file operand. The &lt;date expression&gt; can be all sorts of date strings, see the <span Class="emphasis">curl_getdate(3)</span> man page for date expression details. (Added in 7.73.0)
<p class="level1"><a name="chgrp"></a><span class="nroffip">chgrp group file</span>
<p class="level2">The chgrp command sets the group ID of the file named by the file operand to the group ID specified by the group operand. The group operand is a decimal integer group ID.
<p class="level1"><a name="chmod"></a><span class="nroffip">chmod mode file</span>
<p class="level2">The chmod command modifies the file mode bits of the specified file. The mode operand is an octal integer mode number.
<p class="level1"><a name="chown"></a><span class="nroffip">chown user file</span>
<p class="level2">The chown command sets the owner of the file named by the file operand to the user ID specified by the user operand. The user operand is a decimal integer user ID.
<p class="level1"><a name="ln"></a><span class="nroffip">ln source_file target_file</span>
<p class="level2">The ln and symlink commands create a symbolic link at the target_file location pointing to the source_file location.
<p class="level1"><a name="mkdir"></a><span class="nroffip">mkdir directory_name</span>
<p class="level2">The mkdir command creates the directory named by the directory_name operand.
<p class="level1"><a name="mtime"></a><span class="nroffip">mtime date file</span>
<p class="level2">The mtime command sets the last modification time of the file named by the file operand. The &lt;date expression&gt; can be all sorts of date strings, see the <span Class="emphasis">curl_getdate(3)</span> man page for date expression details. (Added in 7.73.0)
<p class="level1"><a name="pwd"></a><span class="nroffip">pwd</span>
<p class="level2">The pwd command returns the absolute pathname of the current working directory.
<p class="level1"><a name="rename"></a><span class="nroffip">rename source target</span>
<p class="level2">The rename command renames the file or directory named by the source operand to the destination path named by the target operand.
<p class="level1"><a name="rm"></a><span class="nroffip">rm file</span>
<p class="level2">The rm command removes the file specified by the file operand.
<p class="level1"><a name="rmdir"></a><span class="nroffip">rmdir directory</span>
<p class="level2">The rmdir command removes the directory entry specified by the directory operand, provided it is empty.
<p class="level1"><a name="symlink"></a><span class="nroffip">symlink source_file target_file</span>
<p class="level2">See ln.
<p class="level1">
<p class="level1">##-Q, --quote## can be used several times in a command line
<p class="level1">Example:
```
curl --quote &quot;DELE file&quot; ftp://example.com/foo
```
<p class="level1">
<p class="level1">See also ##-X, --request##.
<p class="level0"><a name="--random-file"></a><span class="nroffip">--random-file &lt;file&gt;</span>
<p class="level1">Deprecated option. This option is ignored by curl since 7.84.0. Prior to that it only had an effect on curl if built to use old versions of OpenSSL.
<p class="level1">Specify the path name to file containing what will be considered as random data. The data may be used to seed the random engine for SSL connections.
<p class="level1">If ##--random-file## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --random-file rubbish https://example.com
```
<p class="level1">
<p class="level1">See also ##--egd-file##.
<p class="level0"><a name="-r"></a><span class="nroffip">-r, --range &lt;range&gt;</span>
<p class="level1">(HTTP FTP SFTP FILE) Retrieve a byte range (i.e. a partial document) from an HTTP/1.1, FTP or SFTP server or a local FILE. Ranges can be specified in a number of ways.
<p class="level2">
<p class="level2"><span Class="bold">0-499</span> specifies the first 500 bytes
<p class="level2"><span Class="bold">500-999</span> specifies the second 500 bytes
<p class="level2"><span Class="bold">-500</span> specifies the last 500 bytes
<p class="level2"><span Class="bold">9500-</span> specifies the bytes from offset 9500 and forward
<p class="level2"><span Class="bold">0-0,-1</span> specifies the first and last byte only(*)(HTTP)
<p class="level2"><span Class="bold">100-199,500-599</span> specifies two separate 100-byte ranges(*) (HTTP)
<p class="level1">
<p class="level0"><a name=""></a><span class="nroffip"></span>
<p class="level1">(*) = NOTE that this will cause the server to reply with a multipart response, which will be returned as-is by curl! Parsing or otherwise transforming this response is the responsibility of the caller.
<p class="level1">Only digit characters (0-9) are valid in the &#39;start&#39; and &#39;stop&#39; fields of the &apos;start-stop&#39; range syntax. If a non-digit character is given in the range, the server&#39;s response will be unspecified, depending on the server&#39;s configuration.
<p class="level1">You should also be aware that many HTTP/1.1 servers do not have this feature enabled, so that when you attempt to get a range, you will instead get the whole document.
<p class="level1">FTP and SFTP range downloads only support the simple &#39;start-stop&#39; syntax (optionally with one of the numbers omitted). FTP use depends on the extended FTP command SIZE.
<p class="level1">If ##-r, --range## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --range 22-44 https://example.com
```
<p class="level1">
<p class="level1">See also ##-C, --continue-at## and ##-a, --append##.
<p class="level0"><a name="--rate"></a><span class="nroffip">--rate &lt;max request rate&gt;</span>
<p class="level1">Specify the maximum transfer frequency you allow curl to use - in number of transfer starts per time unit (sometimes called request rate). Without this option, curl will start the next transfer as fast as possible.
<p class="level1">If given several URLs and a transfer completes faster than the allowed rate, curl will wait until the next transfer is started to maintain the requested rate. This option has no effect when ##-Z, --parallel## is used.
<p class="level1">The request rate is provided as &quot;N/U&quot; where N is an integer number and U is a time unit. Supported units are &#39;s&#39; (second), &#39;m&#39; (minute), &#39;h&#39; (hour) and &#39;d&#39; /(day, as in a 24 hour unit). The default time unit, if no &quot;/U&quot; is provided, is number of transfers per hour.
<p class="level1">If curl is told to allow 10 requests per minute, it will not start the next request until 6 seconds have elapsed since the previous transfer was started.
<p class="level1">This function uses millisecond resolution. If the allowed frequency is set more than 1000 per second, it will instead run unrestricted.
<p class="level1">When retrying transfers, enabled with ##--retry##, the separate retry delay logic is used and not this setting.
<p class="level1">If ##--rate## is provided several times, the last set value will be used.
<p class="level1">Examples:
```
curl --rate 2/s https://example.com
curl --rate 3/h https://example.com
curl --rate 14/m https://example.com
```
<p class="level1">
<p class="level1">See also ##--limit-rate## and ##--retry-delay##. Added in 7.84.0.
<p class="level0"><a name="--raw"></a><span class="nroffip">--raw</span>
<p class="level1">(HTTP) When used, it disables all internal HTTP decoding of content or transfer encodings and instead makes them passed on unaltered, raw.
<p class="level1">Providing ##--raw## multiple times has no extra effect. Disable it again with --no-raw.
<p class="level1">Example:
```
curl --raw https://example.com
```
<p class="level1">
<p class="level1">See also ##--tr-encoding##.
<p class="level0"><a name="-e"></a><span class="nroffip">-e, --referer &lt;URL&gt;</span>
<p class="level1">(HTTP) Sends the &quot;Referrer Page&quot; information to the HTTP server. This can also be set with the ##-H, --header## flag of course. When used with ##-L, --location## you can append &quot;;auto&quot; to the ##-e, --referer## URL to make curl automatically set the previous URL when it follows a Location: header. The &quot;;auto&quot; string can be used alone, even if you do not set an initial ##-e, --referer##.
<p class="level1">If ##-e, --referer## is provided several times, the last set value will be used.
<p class="level1">Examples:
```
curl --referer &quot;https://fake.example&quot; https://example.com
curl --referer &quot;https://fake.example;auto&quot; -L https://example.com
curl --referer &quot;;auto&quot; -L https://example.com
```
<p class="level1">
<p class="level1">See also ##-A, --user-agent## and ##-H, --header##.
<p class="level0"><a name="-J"></a><span class="nroffip">-J, --remote-header-name</span>
<p class="level1">(HTTP) This option tells the ##-O, --remote-name## option to use the server-specified Content-Disposition filename instead of extracting a filename from the URL. If the server-provided file name contains a path, that will be stripped off before the file name is used.
<p class="level1">The file is saved in the current directory, or in the directory specified with ##--output-dir##.
<p class="level1">If the server specifies a file name and a file with that name already exists in the destination directory, it will not be overwritten and an error will occur. If the server does not specify a file name then this option has no effect.
<p class="level1">There&#39;s no attempt to decode %-sequences (yet) in the provided file name, so this option may provide you with rather unexpected file names.
<p class="level1"><span Class="bold">WARNING</span>: Exercise judicious use of this option, especially on Windows. A rogue server could send you the name of a DLL or other file that could be loaded automatically by Windows or some third party software.
<p class="level1">Providing ##-J, --remote-header-name## multiple times has no extra effect. Disable it again with --no-remote-header-name.
<p class="level1">Example:
```
curl -OJ https://example.com/file
```
<p class="level1">
<p class="level1">See also ##-O, --remote-name##.
<p class="level0"><a name="--remote-name-all"></a><span class="nroffip">--remote-name-all</span>
<p class="level1">This option changes the default action for all given URLs to be dealt with as if ##-O, --remote-name## were used for each one. So if you want to disable that for a specific URL after ##--remote-name-all## has been used, you must use &quot;-o -&quot; or --no-remote-name.
<p class="level1">Providing ##--remote-name-all## multiple times has no extra effect. Disable it again with --no-remote-name-all.
<p class="level1">Example:
```
curl --remote-name-all ftp://example.com/file1 ftp://example.com/file2
```
<p class="level1">
<p class="level1">See also ##-O, --remote-name##.
<p class="level0"><a name="-O"></a><span class="nroffip">-O, --remote-name</span>
<p class="level1">Write output to a local file named like the remote file we get. (Only the file part of the remote file is used, the path is cut off.)
<p class="level1">The file will be saved in the current working directory. If you want the file saved in a different directory, make sure you change the current working directory before invoking curl with this option or use ##--output-dir##.
<p class="level1">The remote file name to use for saving is extracted from the given URL, nothing else, and if it already exists it will be overwritten. If you want the server to be able to choose the file name refer to ##-J, --remote-header-name## which can be used in addition to this option. If the server chooses a file name and that name already exists it will not be overwritten.
<p class="level1">There is no URL decoding done on the file name. If it has %20 or other URL encoded parts of the name, they will end up as-is as file name.
<p class="level1">You may use this option as many times as the number of URLs you have.
<p class="level1">##-O, --remote-name## can be used several times in a command line
<p class="level1">Example:
```
curl -O https://example.com/filename
```
<p class="level1">
<p class="level1">See also ##--remote-name-all##, ##--output-dir## and ##-J, --remote-header-name##.
<p class="level0"><a name="-R"></a><span class="nroffip">-R, --remote-time</span>
<p class="level1">When used, this will make curl attempt to figure out the timestamp of the remote file, and if that is available make the local file get that same timestamp.
<p class="level1">Providing ##-R, --remote-time## multiple times has no extra effect. Disable it again with --no-remote-time.
<p class="level1">Example:
```
curl --remote-time -o foo https://example.com
```
<p class="level1">
<p class="level1">See also ##-O, --remote-name## and ##-z, --time-cond##.
<p class="level0"><a name="--remove-on-error"></a><span class="nroffip">--remove-on-error</span>
<p class="level1">When curl returns an error when told to save output in a local file, this option removes that saved file before exiting. This prevents curl from leaving a partial file in the case of an error during transfer.
<p class="level1">If the output is not a file, this option has no effect.
<p class="level1">Providing ##--remove-on-error## multiple times has no extra effect. Disable it again with --no-remove-on-error.
<p class="level1">Example:
```
curl --remove-on-error -o output https://example.com
```
<p class="level1">
<p class="level1">See also ##-f, --fail##. Added in 7.83.0.
<p class="level0"><a name="--request-target"></a><span class="nroffip">--request-target &lt;path&gt;</span>
<p class="level1">(HTTP) Tells curl to use an alternative &quot;target&quot; (path) instead of using the path as provided in the URL. Particularly useful when wanting to issue HTTP requests without leading slash or other data that does not follow the regular URL pattern, like &quot;OPTIONS *&quot;.
<p class="level1">If ##--request-target## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --request-target &quot;*&quot; -X OPTIONS https://example.com
```
<p class="level1">
<p class="level1">See also ##-X, --request##. Added in 7.55.0.
<p class="level0"><a name="-X"></a><span class="nroffip">-X, --request &lt;method&gt;</span>
<p class="level1">(HTTP) Specifies a custom request method to use when communicating with the HTTP server. The specified request method will be used instead of the method otherwise used (which defaults to GET). Read the HTTP 1.1 specification for details and explanations. Common additional HTTP requests include PUT and DELETE, but related technologies like WebDAV offers PROPFIND, COPY, MOVE and more.
<p class="level1">Normally you do not need this option. All sorts of GET, HEAD, POST and PUT requests are rather invoked by using dedicated command line options.
<p class="level1">This option only changes the actual word used in the HTTP request, it does not alter the way curl behaves. So for example if you want to make a proper HEAD request, using -X HEAD will not suffice. You need to use the ##-I, --head## option.
<p class="level1">The method string you set with ##-X, --request## will be used for all requests, which if you for example use ##-L, --location## may cause unintended side-effects when curl does not change request method according to the HTTP 30x response codes - and similar.
<p class="level1">(FTP) Specifies a custom FTP command to use instead of LIST when doing file lists with FTP.
<p class="level1">(POP3) Specifies a custom POP3 command to use instead of LIST or RETR.
<p class="level1">
<p class="level1">(IMAP) Specifies a custom IMAP command to use instead of LIST. (Added in 7.30.0)
<p class="level1">(SMTP) Specifies a custom SMTP command to use instead of HELP or VRFY. (Added in 7.34.0)
<p class="level1">If ##-X, --request## is provided several times, the last set value will be used.
<p class="level1">Examples:
```
curl -X &quot;DELETE&quot; https://example.com
curl -X NLST ftp://example.com/
```
<p class="level1">
<p class="level1">See also ##--request-target##.
<p class="level0"><a name="--resolve"></a><span class="nroffip">--resolve &lt;[+]host:port:addr[,addr]...&gt;</span>
<p class="level1">Provide a custom address for a specific host and port pair. Using this, you can make the curl requests(s) use a specified address and prevent the otherwise normally resolved address to be used. Consider it a sort of /etc/hosts alternative provided on the command line. The port number should be the number used for the specific protocol the host will be used for. It means you need several entries if you want to provide address for the same host but different ports.
<p class="level1">By specifying &#39;*&#39; as host you can tell curl to resolve any host and specific port pair to the specified address. Wildcard is resolved last so any ##--resolve## with a specific host and port will be used first.
<p class="level1">The provided address set by this option will be used even if ##-4, --ipv4## or ##-6, --ipv6## is set to make curl use another IP version.
<p class="level1">By prefixing the host with a &#39;+&#39; you can make the entry time out after curl&#39;s default timeout (1 minute). Note that this will only make sense for long running parallel transfers with a lot of files. In such cases, if this option is used curl will try to resolve the host as it normally would once the timeout has expired.
<p class="level1">Support for providing the IP address within [brackets] was added in 7.57.0.
<p class="level1">Support for providing multiple IP addresses per entry was added in 7.59.0.
<p class="level1">Support for resolving with wildcard was added in 7.64.0.
<p class="level1">Support for the &#39;+&#39; prefix was was added in 7.75.0.
<p class="level1">This option can be used many times to add many host names to resolve.
<p class="level1">##--resolve## can be used several times in a command line
<p class="level1">Example:
```
curl --resolve example.com:443:127.0.0.1 https://example.com
```
<p class="level1">
<p class="level1">See also ##--connect-to## and ##--alt-svc##.
<p class="level0"><a name="--retry-all-errors"></a><span class="nroffip">--retry-all-errors</span>
<p class="level1">Retry on any error. This option is used together with ##--retry##.
<p class="level1">This option is the &quot;sledgehammer&quot; of retrying. Do not use this option by default (eg in curlrc), there may be unintended consequences such as sending or receiving duplicate data. Do not use with redirected input or output. You&#39;d be much better off handling your unique problems in shell script. Please read the example below.
<p class="level1"><span Class="bold">WARNING</span>: For server compatibility curl attempts to retry failed flaky transfers as close as possible to how they were started, but this is not possible with redirected input or output. For example, before retrying it removes output data from a failed partial transfer that was written to an output file. However this is not true of data redirected to a | pipe or &gt; file, which are not reset. We strongly suggest you do not parse or record output via redirect in combination with this option, since you may receive duplicate data.
<p class="level1">By default curl will not error on an HTTP response code that indicates an HTTP error, if the transfer was successful. For example, if a server replies 404 Not Found and the reply is fully received then that is not an error. When ##--retry## is used then curl will retry on some HTTP response codes that indicate transient HTTP errors, but that does not include most 4xx response codes such as 404. If you want to retry on all response codes that indicate HTTP errors (4xx and 5xx) then combine with ##-f, --fail##.
<p class="level1">Providing ##--retry-all-errors## multiple times has no extra effect. Disable it again with --no-retry-all-errors.
<p class="level1">Example:
```
curl --retry 5 --retry-all-errors https://example.com
```
<p class="level1">
<p class="level1">See also ##--retry##. Added in 7.71.0.
<p class="level0"><a name="--retry-connrefused"></a><span class="nroffip">--retry-connrefused</span>
<p class="level1">In addition to the other conditions, consider ECONNREFUSED as a transient error too for ##--retry##. This option is used together with ##--retry##.
<p class="level1">Providing ##--retry-connrefused## multiple times has no extra effect. Disable it again with --no-retry-connrefused.
<p class="level1">Example:
```
curl --retry-connrefused --retry 7 https://example.com
```
<p class="level1">
<p class="level1">See also ##--retry## and ##--retry-all-errors##. Added in 7.52.0.
<p class="level0"><a name="--retry-delay"></a><span class="nroffip">--retry-delay &lt;seconds&gt;</span>
<p class="level1">Make curl sleep this amount of time before each retry when a transfer has failed with a transient error (it changes the default backoff time algorithm between retries). This option is only interesting if ##--retry## is also used. Setting this delay to zero will make curl use the default backoff time.
<p class="level1">If ##--retry-delay## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --retry-delay 5 --retry 7 https://example.com
```
<p class="level1">
<p class="level1">See also ##--retry##.
<p class="level0"><a name="--retry-max-time"></a><span class="nroffip">--retry-max-time &lt;seconds&gt;</span>
<p class="level1">The retry timer is reset before the first transfer attempt. Retries will be done as usual (see ##--retry##) as long as the timer has not reached this given limit. Notice that if the timer has not reached the limit, the request will be made and while performing, it may take longer than this given time period. To limit a single request&#39;s maximum time, use ##-m, --max-time##. Set this option to zero to not timeout retries.
<p class="level1">If ##--retry-max-time## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --retry-max-time 30 --retry 10 https://example.com
```
<p class="level1">
<p class="level1">See also ##--retry##.
<p class="level0"><a name="--retry"></a><span class="nroffip">--retry &lt;num&gt;</span>
<p class="level1">If a transient error is returned when curl tries to perform a transfer, it will retry this number of times before giving up. Setting the number to 0 makes curl do no retries (which is the default). Transient error means either: a timeout, an FTP 4xx response code or an HTTP 408, 429, 500, 502, 503 or 504 response code.
<p class="level1">When curl is about to retry a transfer, it will first wait one second and then for all forthcoming retries it will double the waiting time until it reaches 10 minutes which then will be the delay between the rest of the retries. By using ##--retry-delay## you disable this exponential backoff algorithm. See also ##--retry-max-time## to limit the total time allowed for retries.
<p class="level1">Since curl 7.66.0, curl will comply with the Retry-After: response header if one was present to know when to issue the next retry.
<p class="level1">If ##--retry## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --retry 7 https://example.com
```
<p class="level1">
<p class="level1">See also ##--retry-max-time##.
<p class="level0"><a name="--sasl-authzid"></a><span class="nroffip">--sasl-authzid &lt;identity&gt;</span>
<p class="level1">Use this authorization identity (authzid), during SASL PLAIN authentication, in addition to the authentication identity (authcid) as specified by ##-u, --user##.
<p class="level1">If the option is not specified, the server will derive the authzid from the authcid, but if specified, and depending on the server implementation, it may be used to access another user&#39;s inbox, that the user has been granted access to, or a shared mailbox for example.
<p class="level1">If ##--sasl-authzid## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --sasl-authzid zid imap://example.com/
```
<p class="level1">
<p class="level1">See also ##--login-options##. Added in 7.66.0.
<p class="level0"><a name="--sasl-ir"></a><span class="nroffip">--sasl-ir</span>
<p class="level1">Enable initial response in SASL authentication.
<p class="level1">Providing ##--sasl-ir## multiple times has no extra effect. Disable it again with --no-sasl-ir.
<p class="level1">Example:
```
curl --sasl-ir imap://example.com/
```
<p class="level1">
<p class="level1">See also ##--sasl-authzid##. Added in 7.31.0.
<p class="level0"><a name="--service-name"></a><span class="nroffip">--service-name &lt;name&gt;</span>
<p class="level1">This option allows you to change the service name for SPNEGO.
<p class="level1">Examples: ##--negotiate## ##--service-name## sockd would use sockd/server-name.
<p class="level1">If ##--service-name## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --service-name sockd/server https://example.com
```
<p class="level1">
<p class="level1">See also ##--negotiate## and ##--proxy-service-name##. Added in 7.43.0.
<p class="level0"><a name="-S"></a><span class="nroffip">-S, --show-error</span>
<p class="level1">When used with ##-s, --silent##, it makes curl show an error message if it fails.
<p class="level1">This option is global and does not need to be specified for each use of ##-:, --next##.
<p class="level1">Providing ##-S, --show-error## multiple times has no extra effect. Disable it again with --no-show-error.
<p class="level1">Example:
```
curl --show-error --silent https://example.com
```
<p class="level1">
<p class="level1">See also ##--no-progress-meter##.
<p class="level0"><a name="-s"></a><span class="nroffip">-s, --silent</span>
<p class="level1">Silent or quiet mode. Do not show progress meter or error messages. Makes Curl mute. It will still output the data you ask for, potentially even to the terminal/stdout unless you redirect it.
<p class="level1">Use ##-S, --show-error## in addition to this option to disable progress meter but still show error messages.
<p class="level1">Providing ##-s, --silent## multiple times has no extra effect. Disable it again with --no-silent.
<p class="level1">Example:
```
curl -s https://example.com
```
<p class="level1">
<p class="level1">See also ##-v, --verbose##, ##--stderr## and ##--no-progress-meter##.
<p class="level0"><a name="--socks4"></a><span class="nroffip">--socks4 &lt;host[:port]&gt;</span>
<p class="level1">Use the specified SOCKS4 proxy. If the port number is not specified, it is assumed at port 1080. Using this socket type make curl resolve the host name and passing the address on to the proxy.
<p class="level1">To specify proxy on a unix domain socket, use localhost for host, e.g. socks4://localhost/path/to/socket.sock
<p class="level1">This option overrides any previous use of ##-x, --proxy##, as they are mutually exclusive.
<p class="level1">This option is superfluous since you can specify a socks4 proxy with ##-x, --proxy## using a socks4:// protocol prefix.
<p class="level1">Since 7.52.0, ##--preproxy## can be used to specify a SOCKS proxy at the same time ##-x, --proxy## is used with an HTTP/HTTPS proxy. In such a case curl first connects to the SOCKS proxy and then connects (through SOCKS) to the HTTP or HTTPS proxy.
<p class="level1">If ##--socks4## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --socks4 hostname:4096 https://example.com
```
<p class="level1">
<p class="level1">See also ##--socks4a##, ##--socks5## and ##--socks5-hostname##.
<p class="level0"><a name="--socks4a"></a><span class="nroffip">--socks4a &lt;host[:port]&gt;</span>
<p class="level1">Use the specified SOCKS4a proxy. If the port number is not specified, it is assumed at port 1080. This asks the proxy to resolve the host name.
<p class="level1">To specify proxy on a unix domain socket, use localhost for host, e.g. socks4a://localhost/path/to/socket.sock
<p class="level1">This option overrides any previous use of ##-x, --proxy##, as they are mutually exclusive.
<p class="level1">This option is superfluous since you can specify a socks4a proxy with ##-x, --proxy## using a socks4a:// protocol prefix.
<p class="level1">Since 7.52.0, ##--preproxy## can be used to specify a SOCKS proxy at the same time ##-x, --proxy## is used with an HTTP/HTTPS proxy. In such a case curl first connects to the SOCKS proxy and then connects (through SOCKS) to the HTTP or HTTPS proxy.
<p class="level1">If ##--socks4a## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --socks4a hostname:4096 https://example.com
```
<p class="level1">
<p class="level1">See also ##--socks4##, ##--socks5## and ##--socks5-hostname##.
<p class="level0"><a name="--socks5-basic"></a><span class="nroffip">--socks5-basic</span>
<p class="level1">Tells curl to use username/password authentication when connecting to a SOCKS5 proxy.  The username/password authentication is enabled by default.  Use ##--socks5-gssapi## to force GSS-API authentication to SOCKS5 proxies.
<p class="level1">Providing ##--socks5-basic## multiple times has no extra effect.
<p class="level1">Example:
```
curl --socks5-basic --socks5 hostname:4096 https://example.com
```
<p class="level1">
<p class="level1">See also ##--socks5##. Added in 7.55.0.
<p class="level0"><a name="--socks5-gssapi-nec"></a><span class="nroffip">--socks5-gssapi-nec</span>
<p class="level1">As part of the GSS-API negotiation a protection mode is negotiated. <a href="http://www.ietf.org/rfc/rfc1961.txt">RFC 1961</a> says in section 4.3/4.4 it should be protected, but the NEC reference implementation does not. The option ##--socks5-gssapi-nec## allows the unprotected exchange of the protection mode negotiation.
<p class="level1">Providing ##--socks5-gssapi-nec## multiple times has no extra effect. Disable it again with --no-socks5-gssapi-nec.
<p class="level1">Example:
```
curl --socks5-gssapi-nec --socks5 hostname:4096 https://example.com
```
<p class="level1">
<p class="level1">See also ##--socks5##.
<p class="level0"><a name="--socks5-gssapi-service"></a><span class="nroffip">--socks5-gssapi-service &lt;name&gt;</span>
<p class="level1">The default service name for a socks server is rcmd/server-fqdn. This option allows you to change it.
<p class="level1">Examples: ##--socks5## proxy-name ##--socks5-gssapi-service## sockd would use sockd/proxy-name ##--socks5## proxy-name ##--socks5-gssapi-service## sockd/real-name would use sockd/real-name for cases where the proxy-name does not match the principal name.
<p class="level1">If ##--socks5-gssapi-service## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --socks5-gssapi-service sockd --socks5 hostname:4096 https://example.com
```
<p class="level1">
<p class="level1">See also ##--socks5##.
<p class="level0"><a name="--socks5-gssapi"></a><span class="nroffip">--socks5-gssapi</span>
<p class="level1">Tells curl to use GSS-API authentication when connecting to a SOCKS5 proxy. The GSS-API authentication is enabled by default (if curl is compiled with GSS-API support).  Use ##--socks5-basic## to force username/password authentication to SOCKS5 proxies.
<p class="level1">Providing ##--socks5-gssapi## multiple times has no extra effect. Disable it again with --no-socks5-gssapi.
<p class="level1">Example:
```
curl --socks5-gssapi --socks5 hostname:4096 https://example.com
```
<p class="level1">
<p class="level1">See also ##--socks5##. Added in 7.55.0.
<p class="level0"><a name="--socks5-hostname"></a><span class="nroffip">--socks5-hostname &lt;host[:port]&gt;</span>
<p class="level1">Use the specified SOCKS5 proxy (and let the proxy resolve the host name). If the port number is not specified, it is assumed at port 1080.
<p class="level1">To specify proxy on a unix domain socket, use localhost for host, e.g. socks5h://localhost/path/to/socket.sock
<p class="level1">This option overrides any previous use of ##-x, --proxy##, as they are mutually exclusive.
<p class="level1">This option is superfluous since you can specify a socks5 hostname proxy with ##-x, --proxy## using a socks5h:// protocol prefix.
<p class="level1">Since 7.52.0, ##--preproxy## can be used to specify a SOCKS proxy at the same time ##-x, --proxy## is used with an HTTP/HTTPS proxy. In such a case curl first connects to the SOCKS proxy and then connects (through SOCKS) to the HTTP or HTTPS proxy.
<p class="level1">If ##--socks5-hostname## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --socks5-hostname proxy.example:7000 https://example.com
```
<p class="level1">
<p class="level1">See also ##--socks5## and ##--socks4a##.
<p class="level0"><a name="--socks5"></a><span class="nroffip">--socks5 &lt;host[:port]&gt;</span>
<p class="level1">Use the specified SOCKS5 proxy - but resolve the host name locally. If the port number is not specified, it is assumed at port 1080.
<p class="level1">To specify proxy on a unix domain socket, use localhost for host, e.g. socks5://localhost/path/to/socket.sock
<p class="level1">This option overrides any previous use of ##-x, --proxy##, as they are mutually exclusive.
<p class="level1">This option is superfluous since you can specify a socks5 proxy with ##-x, --proxy## using a socks5:// protocol prefix.
<p class="level1">Since 7.52.0, ##--preproxy## can be used to specify a SOCKS proxy at the same time ##-x, --proxy## is used with an HTTP/HTTPS proxy. In such a case curl first connects to the SOCKS proxy and then connects (through SOCKS) to the HTTP or HTTPS proxy.
<p class="level1">This option (as well as ##--socks4##) does not work with IPV6, FTPS or LDAP.
<p class="level1">If ##--socks5## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --socks5 proxy.example:7000 https://example.com
```
<p class="level1">
<p class="level1">See also ##--socks5-hostname## and ##--socks4a##.
<p class="level0"><a name="-Y"></a><span class="nroffip">-Y, --speed-limit &lt;speed&gt;</span>
<p class="level1">If a transfer is slower than this given speed (in bytes per second) for speed-time seconds it gets aborted. speed-time is set with ##-y, --speed-time## and is 30 if not set.
<p class="level1">If ##-Y, --speed-limit## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --speed-limit 300 --speed-time 10 https://example.com
```
<p class="level1">
<p class="level1">See also ##-y, --speed-time##, ##--limit-rate## and ##-m, --max-time##.
<p class="level0"><a name="-y"></a><span class="nroffip">-y, --speed-time &lt;seconds&gt;</span>
<p class="level1">If a transfer runs slower than speed-limit bytes per second during a speed-time period, the transfer is aborted. If speed-time is used, the default speed-limit will be 1 unless set with ##-Y, --speed-limit##.
<p class="level1">This option controls transfers (in both directions) but will not affect slow connects etc. If this is a concern for you, try the ##--connect-timeout## option.
<p class="level1">If ##-y, --speed-time## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --speed-limit 300 --speed-time 10 https://example.com
```
<p class="level1">
<p class="level1">See also ##-Y, --speed-limit## and ##--limit-rate##.
<p class="level0"><a name="--ssl-allow-beast"></a><span class="nroffip">--ssl-allow-beast</span>
<p class="level1">This option tells curl to not work around a security flaw in the SSL3 and TLS1.0 protocols known as BEAST.  If this option is not used, the SSL layer may use workarounds known to cause interoperability problems with some older SSL implementations.
<p class="level1"><span Class="bold">WARNING</span>: this option loosens the SSL security, and by using this flag you ask for exactly that.
<p class="level1">Providing ##--ssl-allow-beast## multiple times has no extra effect. Disable it again with --no-ssl-allow-beast.
<p class="level1">Example:
```
curl --ssl-allow-beast https://example.com
```
<p class="level1">
<p class="level1">See also ##--proxy-ssl-allow-beast## and ##-k, --insecure##.
<p class="level0"><a name="--ssl-auto-client-cert"></a><span class="nroffip">--ssl-auto-client-cert</span>
<p class="level1">Tell libcurl to automatically locate and use a client certificate for authentication, when requested by the server. This option is only supported for Schannel (the native Windows SSL library). Prior to 7.77.0 this was the default behavior in libcurl with Schannel. Since the server can request any certificate that supports client authentication in the OS certificate store it could be a privacy violation and unexpected.
<p class="level1">Providing ##--ssl-auto-client-cert## multiple times has no extra effect. Disable it again with --no-ssl-auto-client-cert.
<p class="level1">Example:
```
curl --ssl-auto-client-cert https://example.com
```
<p class="level1">
<p class="level1">See also ##--proxy-ssl-auto-client-cert##. Added in 7.77.0.
<p class="level0"><a name="--ssl-no-revoke"></a><span class="nroffip">--ssl-no-revoke</span>
<p class="level1">(Schannel) This option tells curl to disable certificate revocation checks. WARNING: this option loosens the SSL security, and by using this flag you ask for exactly that.
<p class="level1">Providing ##--ssl-no-revoke## multiple times has no extra effect. Disable it again with --no-ssl-no-revoke.
<p class="level1">Example:
```
curl --ssl-no-revoke https://example.com
```
<p class="level1">
<p class="level1">See also ##--crlfile##. Added in 7.44.0.
<p class="level0"><a name="--ssl-reqd"></a><span class="nroffip">--ssl-reqd</span>
<p class="level1">(FTP IMAP POP3 SMTP LDAP) Require SSL/TLS for the connection. Terminates the connection if the transfer cannot be upgraded to use SSL/TLS.
<p class="level1">This option is handled in LDAP since version 7.81.0. It is fully supported by the OpenLDAP backend and rejected by the generic ldap backend if explicit TLS is required.
<p class="level1">This option is unnecessary if you use a URL scheme that in itself implies immediate and implicit use of TLS, like for FTPS, IMAPS, POP3S, SMTPS and LDAPS. Such transfers will always fail if the TLS handshake does not work.
<p class="level1">This option was formerly known as --ftp-ssl-reqd.
<p class="level1">Providing ##--ssl-reqd## multiple times has no extra effect. Disable it again with --no-ssl-reqd.
<p class="level1">Example:
```
curl --ssl-reqd ftp://example.com
```
<p class="level1">
<p class="level1">See also ##--ssl## and ##-k, --insecure##.
<p class="level0"><a name="--ssl-revoke-best-effort"></a><span class="nroffip">--ssl-revoke-best-effort</span>
<p class="level1">(Schannel) This option tells curl to ignore certificate revocation checks when they failed due to missing/offline distribution points for the revocation check lists.
<p class="level1">Providing ##--ssl-revoke-best-effort## multiple times has no extra effect. Disable it again with --no-ssl-revoke-best-effort.
<p class="level1">Example:
```
curl --ssl-revoke-best-effort https://example.com
```
<p class="level1">
<p class="level1">See also ##--crlfile## and ##-k, --insecure##. Added in 7.70.0.
<p class="level0"><a name="--ssl"></a><span class="nroffip">--ssl</span>
<p class="level1">(FTP IMAP POP3 SMTP LDAP) Warning: this is considered an insecure option. Consider using ##--ssl-reqd## instead to be sure curl upgrades to a secure connection.
<p class="level1">Try to use SSL/TLS for the connection. Reverts to a non-secure connection if the server does not support SSL/TLS. See also ##--ftp-ssl-control## and ##--ssl-reqd## for different levels of encryption required.
<p class="level1">This option is handled in LDAP since version 7.81.0. It is fully supported by the OpenLDAP backend and ignored by the generic ldap backend.
<p class="level1">Please note that a server may close the connection if the negotiation does not succeed.
<p class="level1">This option was formerly known as --ftp-ssl. That option name can still be used but will be removed in a future version.
<p class="level1">Providing ##--ssl## multiple times has no extra effect. Disable it again with --no-ssl.
<p class="level1">Example:
```
curl --ssl pop3://example.com/
```
<p class="level1">
<p class="level1">See also ##--ssl-reqd##, ##-k, --insecure## and ##--ciphers##.
<p class="level0"><a name="-2"></a><span class="nroffip">-2, --sslv2</span>
<p class="level1">(SSL) This option previously asked curl to use SSLv2, but starting in curl 7.77.0 this instruction is ignored. SSLv2 is widely considered insecure (see RFC 6176).
<p class="level1">Providing ##-2, --sslv2## multiple times has no extra effect.
<p class="level1">Example:
```
curl --sslv2 https://example.com
```
<p class="level1">
<p class="level1">See also ##--http1.1## and ##--http2##. ##-2, --sslv2## requires that the underlying libcurl was built to support TLS. This option is mutually exclusive to ##-3, --sslv3## and ##-1, --tlsv1## and ##--tlsv1.1## and ##--tlsv1.2##.
<p class="level0"><a name="-3"></a><span class="nroffip">-3, --sslv3</span>
<p class="level1">(SSL) This option previously asked curl to use SSLv3, but starting in curl 7.77.0 this instruction is ignored. SSLv3 is widely considered insecure (see RFC 7568).
<p class="level1">Providing ##-3, --sslv3## multiple times has no extra effect.
<p class="level1">Example:
```
curl --sslv3 https://example.com
```
<p class="level1">
<p class="level1">See also ##--http1.1## and ##--http2##. ##-3, --sslv3## requires that the underlying libcurl was built to support TLS. This option is mutually exclusive to ##-2, --sslv2## and ##-1, --tlsv1## and ##--tlsv1.1## and ##--tlsv1.2##.
<p class="level0"><a name="--stderr"></a><span class="nroffip">--stderr &lt;file&gt;</span>
<p class="level1">Redirect all writes to stderr to the specified file instead. If the file name is a plain &#39;-&#39;, it is instead written to stdout.
<p class="level1">This option is global and does not need to be specified for each use of ##-:, --next##.
<p class="level1">If ##--stderr## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --stderr output.txt https://example.com
```
<p class="level1">
<p class="level1">See also ##-v, --verbose## and ##-s, --silent##.
<p class="level0"><a name="--styled-output"></a><span class="nroffip">--styled-output</span>
<p class="level1">Enables the automatic use of bold font styles when writing HTTP headers to the terminal. Use --no-styled-output to switch them off.
<p class="level1">Styled output requires a terminal that supports bold fonts. This feature is not present on curl for Windows due to lack of this capability.
<p class="level1">This option is global and does not need to be specified for each use of ##-:, --next##.
<p class="level1">Providing ##--styled-output## multiple times has no extra effect. Disable it again with --no-styled-output.
<p class="level1">Example:
```
curl --styled-output -I https://example.com
```
<p class="level1">
<p class="level1">See also ##-I, --head## and ##-v, --verbose##. Added in 7.61.0.
<p class="level0"><a name="--suppress-connect-headers"></a><span class="nroffip">--suppress-connect-headers</span>
<p class="level1">When ##-p, --proxytunnel## is used and a CONNECT request is made do not output proxy CONNECT response headers. This option is meant to be used with ##-D, --dump-header## or ##-i, --include## which are used to show protocol headers in the output. It has no effect on debug options such as ##-v, --verbose## or ##--trace##, or any statistics.
<p class="level1">Providing ##--suppress-connect-headers## multiple times has no extra effect. Disable it again with --no-suppress-connect-headers.
<p class="level1">Example:
```
curl --suppress-connect-headers --include -x proxy https://example.com
```
<p class="level1">
<p class="level1">See also ##-D, --dump-header##, ##-i, --include## and ##-p, --proxytunnel##. Added in 7.54.0.
<p class="level0"><a name="--tcp-fastopen"></a><span class="nroffip">--tcp-fastopen</span>
<p class="level1">Enable use of TCP Fast Open (RFC7413).
<p class="level1">Providing ##--tcp-fastopen## multiple times has no extra effect. Disable it again with --no-tcp-fastopen.
<p class="level1">Example:
```
curl --tcp-fastopen https://example.com
```
<p class="level1">
<p class="level1">See also ##--false-start##. Added in 7.49.0.
<p class="level0"><a name="--tcp-nodelay"></a><span class="nroffip">--tcp-nodelay</span>
<p class="level1">Turn on the TCP_NODELAY option. See the <span Class="emphasis">curl_easy_setopt(3)</span> man page for details about this option.
<p class="level1">Since 7.50.2, curl sets this option by default and you need to explicitly switch it off if you do not want it on.
<p class="level1">Providing ##--tcp-nodelay## multiple times has no extra effect. Disable it again with --no-tcp-nodelay.
<p class="level1">Example:
```
curl --tcp-nodelay https://example.com
```
<p class="level1">
<p class="level1">See also ##-N, --no-buffer##.
<p class="level0"><a name="-t"></a><span class="nroffip">-t, --telnet-option &lt;opt=val&gt;</span>
<p class="level1">Pass options to the telnet protocol. Supported options are:
<p class="level1">TTYPE=&lt;term&gt; Sets the terminal type.
<p class="level1">XDISPLOC=&lt;X display&gt; Sets the X display location.
<p class="level1">NEW_ENV=&lt;var,val&gt; Sets an environment variable.
<p class="level1">##-t, --telnet-option## can be used several times in a command line
<p class="level1">Example:
```
curl -t TTYPE=vt100 telnet://example.com/
```
<p class="level1">
<p class="level1">See also ##-K, --config##.
<p class="level0"><a name="--tftp-blksize"></a><span class="nroffip">--tftp-blksize &lt;value&gt;</span>
<p class="level1">(TFTP) Set TFTP BLKSIZE option (must be &gt;512). This is the block size that curl will try to use when transferring data to or from a TFTP server. By default 512 bytes will be used.
<p class="level1">If ##--tftp-blksize## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --tftp-blksize 1024 tftp://example.com/file
```
<p class="level1">
<p class="level1">See also ##--tftp-no-options##.
<p class="level0"><a name="--tftp-no-options"></a><span class="nroffip">--tftp-no-options</span>
<p class="level1">(TFTP) Tells curl not to send TFTP options requests.
<p class="level1">This option improves interop with some legacy servers that do not acknowledge or properly implement TFTP options. When this option is used ##--tftp-blksize## is ignored.
<p class="level1">Providing ##--tftp-no-options## multiple times has no extra effect. Disable it again with --no-tftp-no-options.
<p class="level1">Example:
```
curl --tftp-no-options tftp://192.168.0.1/
```
<p class="level1">
<p class="level1">See also ##--tftp-blksize##. Added in 7.48.0.
<p class="level0"><a name="-z"></a><span class="nroffip">-z, --time-cond &lt;time&gt;</span>
<p class="level1">(HTTP FTP) Request a file that has been modified later than the given time and date, or one that has been modified before that time. The &lt;date expression&gt; can be all sorts of date strings or if it does not match any internal ones, it is taken as a filename and tries to get the modification date (mtime) from &lt;file&gt; instead. See the <span Class="emphasis">curl_getdate(3)</span> man pages for date expression details.
<p class="level1">Start the date expression with a dash (-) to make it request for a document that is older than the given date/time, default is a document that is newer than the specified date/time.
<p class="level1">If ##-z, --time-cond## is provided several times, the last set value will be used.
<p class="level1">Examples:
```
curl -z &quot;Wed 01 Sep 2021 12:18:00&quot; https://example.com
curl -z &quot;-Wed 01 Sep 2021 12:18:00&quot; https://example.com
curl -z file https://example.com
```
<p class="level1">
<p class="level1">See also ##--etag-compare## and ##-R, --remote-time##.
<p class="level0"><a name="--tls-max"></a><span class="nroffip">--tls-max &lt;VERSION&gt;</span>
<p class="level1">(SSL) VERSION defines maximum supported TLS version. The minimum acceptable version is set by tlsv1.0, tlsv1.1, tlsv1.2 or tlsv1.3.
<p class="level1">If the connection is done without TLS, this option has no effect. This includes QUIC-using (HTTP/3) transfers.
<p class="level1">
<p class="level2">
<p class="level1"><a name="default"></a><span class="nroffip">default</span>
<p class="level2">Use up to recommended TLS version.
<p class="level1"><a name="10"></a><span class="nroffip">1.0</span>
<p class="level2">Use up to TLSv1.0.
<p class="level1"><a name="11"></a><span class="nroffip">1.1</span>
<p class="level2">Use up to TLSv1.1.
<p class="level1"><a name="12"></a><span class="nroffip">1.2</span>
<p class="level2">Use up to TLSv1.2.
<p class="level1"><a name="13"></a><span class="nroffip">1.3</span>
<p class="level2">Use up to TLSv1.3.
<p class="level1">
<p class="level1">If ##--tls-max## is provided several times, the last set value will be used.
<p class="level1">Examples:
```
curl --tls-max 1.2 https://example.com
curl --tls-max 1.3 --tlsv1.2 https://example.com
```
<p class="level1">
<p class="level1">See also ##--tlsv1.0##, ##--tlsv1.1##, ##--tlsv1.2## and ##--tlsv1.3##. ##--tls-max## requires that the underlying libcurl was built to support TLS. Added in 7.54.0.
<p class="level0"><a name="--tls13-ciphers"></a><span class="nroffip">--tls13-ciphers &lt;ciphersuite list&gt;</span>
<p class="level1">(TLS) Specifies which cipher suites to use in the connection if it negotiates TLS 1.3. The list of ciphers suites must specify valid ciphers. Read up on TLS 1.3 cipher suite details on this URL:
<p class="level1">
```
https://curl.se/docs/ssl-ciphers.html
```
<p class="level1">
<p class="level1">This option is currently used only when curl is built to use OpenSSL 1.1.1 or later. If you are using a different SSL backend you can try setting TLS 1.3 cipher suites by using the ##--ciphers## option.
<p class="level1">If ##--tls13-ciphers## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --tls13-ciphers TLS_AES_128_GCM_SHA256 https://example.com
```
<p class="level1">
<p class="level1">See also ##--ciphers## and ##--curves##. Added in 7.61.0.
<p class="level0"><a name="--tlsauthtype"></a><span class="nroffip">--tlsauthtype &lt;type&gt;</span>
<p class="level1">Set TLS authentication type. Currently, the only supported option is &quot;SRP&quot;, for TLS-SRP (RFC 5054). If ##--tlsuser## and ##--tlspassword## are specified but ##--tlsauthtype## is not, then this option defaults to &quot;SRP&quot;. This option works only if the underlying libcurl is built with TLS-SRP support, which requires OpenSSL or GnuTLS with TLS-SRP support.
<p class="level1">If ##--tlsauthtype## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --tlsauthtype SRP https://example.com
```
<p class="level1">
<p class="level1">See also ##--tlsuser##.
<p class="level0"><a name="--tlspassword"></a><span class="nroffip">--tlspassword &lt;string&gt;</span>
<p class="level1">Set password for use with the TLS authentication method specified with ##--tlsauthtype##. Requires that ##--tlsuser## also be set.
<p class="level1">This option does not work with TLS 1.3.
<p class="level1">If ##--tlspassword## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --tlspassword pwd --tlsuser user https://example.com
```
<p class="level1">
<p class="level1">See also ##--tlsuser##.
<p class="level0"><a name="--tlsuser"></a><span class="nroffip">--tlsuser &lt;name&gt;</span>
<p class="level1">Set username for use with the TLS authentication method specified with ##--tlsauthtype##. Requires that ##--tlspassword## also is set.
<p class="level1">This option does not work with TLS 1.3.
<p class="level1">If ##--tlsuser## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --tlspassword pwd --tlsuser user https://example.com
```
<p class="level1">
<p class="level1">See also ##--tlspassword##.
<p class="level0"><a name="--tlsv10"></a><span class="nroffip">--tlsv1.0</span>
<p class="level1">(TLS) Forces curl to use TLS version 1.0 or later when connecting to a remote TLS server.
<p class="level1">In old versions of curl this option was documented to allow _only_ TLS 1.0. That behavior was inconsistent depending on the TLS library. Use ##--tls-max## if you want to set a maximum TLS version.
<p class="level1">Providing ##--tlsv1.0## multiple times has no extra effect.
<p class="level1">Example:
```
curl --tlsv1.0 https://example.com
```
<p class="level1">
<p class="level1">See also ##--tlsv1.3##. Added in 7.34.0.
<p class="level0"><a name="--tlsv11"></a><span class="nroffip">--tlsv1.1</span>
<p class="level1">(TLS) Forces curl to use TLS version 1.1 or later when connecting to a remote TLS server.
<p class="level1">In old versions of curl this option was documented to allow _only_ TLS 1.1. That behavior was inconsistent depending on the TLS library. Use ##--tls-max## if you want to set a maximum TLS version.
<p class="level1">Providing ##--tlsv1.1## multiple times has no extra effect.
<p class="level1">Example:
```
curl --tlsv1.1 https://example.com
```
<p class="level1">
<p class="level1">See also ##--tlsv1.3## and ##--tls-max##. Added in 7.34.0.
<p class="level0"><a name="--tlsv12"></a><span class="nroffip">--tlsv1.2</span>
<p class="level1">(TLS) Forces curl to use TLS version 1.2 or later when connecting to a remote TLS server.
<p class="level1">In old versions of curl this option was documented to allow _only_ TLS 1.2. That behavior was inconsistent depending on the TLS library. Use ##--tls-max## if you want to set a maximum TLS version.
<p class="level1">Providing ##--tlsv1.2## multiple times has no extra effect.
<p class="level1">Example:
```
curl --tlsv1.2 https://example.com
```
<p class="level1">
<p class="level1">See also ##--tlsv1.3## and ##--tls-max##. Added in 7.34.0.
<p class="level0"><a name="--tlsv13"></a><span class="nroffip">--tlsv1.3</span>
<p class="level1">(TLS) Forces curl to use TLS version 1.3 or later when connecting to a remote TLS server.
<p class="level1">If the connection is done without TLS, this option has no effect. This includes QUIC-using (HTTP/3) transfers.
<p class="level1">Note that TLS 1.3 is not supported by all TLS backends.
<p class="level1">Providing ##--tlsv1.3## multiple times has no extra effect.
<p class="level1">Example:
```
curl --tlsv1.3 https://example.com
```
<p class="level1">
<p class="level1">See also ##--tlsv1.2## and ##--tls-max##. Added in 7.52.0.
<p class="level0"><a name="-1"></a><span class="nroffip">-1, --tlsv1</span>
<p class="level1">(SSL) Tells curl to use at least TLS version 1.x when negotiating with a remote TLS server. That means TLS version 1.0 or higher
<p class="level1">Providing ##-1, --tlsv1## multiple times has no extra effect.
<p class="level1">Example:
```
curl --tlsv1 https://example.com
```
<p class="level1">
<p class="level1">See also ##--http1.1## and ##--http2##. ##-1, --tlsv1## requires that the underlying libcurl was built to support TLS. This option is mutually exclusive to ##--tlsv1.1## and ##--tlsv1.2## and ##--tlsv1.3##.
<p class="level0"><a name="--tr-encoding"></a><span class="nroffip">--tr-encoding</span>
<p class="level1">(HTTP) Request a compressed Transfer-Encoding response using one of the algorithms curl supports, and uncompress the data while receiving it.
<p class="level1">Providing ##--tr-encoding## multiple times has no extra effect. Disable it again with --no-tr-encoding.
<p class="level1">Example:
```
curl --tr-encoding https://example.com
```
<p class="level1">
<p class="level1">See also ##--compressed##.
<p class="level0"><a name="--trace-ascii"></a><span class="nroffip">--trace-ascii &lt;file&gt;</span>
<p class="level1">Enables a full trace dump of all incoming and outgoing data, including descriptive information, to the given output file. Use &quot;-&quot; as filename to have the output sent to stdout.
<p class="level1">This is similar to ##--trace##, but leaves out the hex part and only shows the ASCII part of the dump. It makes smaller output that might be easier to read for untrained humans.
<p class="level1">This option is global and does not need to be specified for each use of ##-:, --next##.
<p class="level1">If ##--trace-ascii## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --trace-ascii log.txt https://example.com
```
<p class="level1">
<p class="level1">See also ##-v, --verbose## and ##--trace##. This option is mutually exclusive to ##--trace## and ##-v, --verbose##.
<p class="level0"><a name="--trace-time"></a><span class="nroffip">--trace-time</span>
<p class="level1">Prepends a time stamp to each trace or verbose line that curl displays.
<p class="level1">This option is global and does not need to be specified for each use of ##-:, --next##.
<p class="level1">Providing ##--trace-time## multiple times has no extra effect. Disable it again with --no-trace-time.
<p class="level1">Example:
```
curl --trace-time --trace-ascii output https://example.com
```
<p class="level1">
<p class="level1">See also ##--trace## and ##-v, --verbose##.
<p class="level0"><a name="--trace"></a><span class="nroffip">--trace &lt;file&gt;</span>
<p class="level1">Enables a full trace dump of all incoming and outgoing data, including descriptive information, to the given output file. Use &quot;-&quot; as filename to have the output sent to stdout. Use &quot;%&quot; as filename to have the output sent to stderr.
<p class="level1">This option is global and does not need to be specified for each use of ##-:, --next##.
<p class="level1">If ##--trace## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --trace log.txt https://example.com
```
<p class="level1">
<p class="level1">See also ##--trace-ascii## and ##--trace-time##. This option is mutually exclusive to ##-v, --verbose## and ##--trace-ascii##.
<p class="level0"><a name="--unix-socket"></a><span class="nroffip">--unix-socket &lt;path&gt;</span>
<p class="level1">(HTTP) Connect through this Unix domain socket, instead of using the network.
<p class="level1">If ##--unix-socket## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl --unix-socket socket-path https://example.com
```
<p class="level1">
<p class="level1">See also ##--abstract-unix-socket##. Added in 7.40.0.
<p class="level0"><a name="-T"></a><span class="nroffip">-T, --upload-file &lt;file&gt;</span>
<p class="level1">This transfers the specified local file to the remote URL. If there is no file part in the specified URL, curl will append the local file name. NOTE that you must use a trailing / on the last directory to really prove to Curl that there is no file name or curl will think that your last directory name is the remote file name to use. That will most likely cause the upload operation to fail. If this is used on an HTTP(S) server, the PUT command will be used.
<p class="level1">Use the file name &quot;-&quot; (a single dash) to use stdin instead of a given file. Alternately, the file name &quot;.&quot; (a single period) may be specified instead of &quot;-&quot; to use stdin in non-blocking mode to allow reading server output while stdin is being uploaded.
<p class="level1">You can specify one ##-T, --upload-file## for each URL on the command line. Each ##-T, --upload-file## + URL pair specifies what to upload and to where. curl also supports &quot;globbing&quot; of the ##-T, --upload-file## argument, meaning that you can upload multiple files to a single URL by using the same URL globbing style supported in the URL.
<p class="level1">When uploading to an SMTP server: the uploaded data is assumed to be <a href="http://www.ietf.org/rfc/rfc5322.txt">RFC 5322</a> formatted. It has to feature the necessary set of headers and mail body formatted correctly by the user as curl will not transcode nor encode it further in any way.
<p class="level1">##-T, --upload-file## can be used several times in a command line
<p class="level1">Examples:
```
curl -T file https://example.com
curl -T &quot;img[1-1000].png&quot; ftp://ftp.example.com/
curl --upload-file &quot;{file1,file2}&quot; https://example.com
```
<p class="level1">
<p class="level1">See also ##-G, --get## and ##-I, --head##.
<p class="level0"><a name="--url-query"></a><span class="nroffip">--url-query &lt;data&gt;</span>
<p class="level1">(all) This option adds a piece of data, usually a name + value pair, to the end of the URL query part. The syntax is identical to that used for ##--data-urlencode## with one extension:
<p class="level1">If the argument starts with a &#39;+&#39; (plus), the rest of the string is provided as-is unencoded.
<p class="level1">The query part of a URL is the one following the question mark on the right end.
<p class="level1">##--url-query## can be used several times in a command line
<p class="level1">Examples:
```
curl --url-query name=val https://example.com
curl --url-query =encodethis http://example.net/foo
curl --url-query name@file https://example.com
curl --url-query @fileonly https://example.com
curl --url-query &quot;+name=%20foo&quot; https://example.com
```
<p class="level1">
<p class="level1">See also ##--data-urlencode## and ##-G, --get##. Added in 7.87.0.
<p class="level0"><a name="--url"></a><span class="nroffip">--url &lt;url&gt;</span>
<p class="level1">Specify a URL to fetch. This option is mostly handy when you want to specify URL(s) in a config file.
<p class="level1">If the given URL is missing a scheme name (such as &quot;<a href="http://&quot;">http://&quot;</a> or &quot;<a href="ftp://&quot;">ftp://&quot;</a> etc) then curl will make a guess based on the host. If the outermost sub-domain name matches DICT, FTP, IMAP, LDAP, POP3 or SMTP then that protocol will be used, otherwise HTTP will be used. Since 7.45.0 guessing can be disabled by setting a default protocol, see ##--proto-default## for details.
<p class="level1">To control where this URL is written, use the ##-o, --output## or the ##-O, --remote-name## options.
<p class="level1"><span Class="bold">WARNING</span>: On Windows, particular file:// accesses can be converted to network accesses by the operating system. Beware!
<p class="level1">##--url## can be used several times in a command line
<p class="level1">Example:
```
curl --url https://example.com
```
<p class="level1">
<p class="level1">See also ##-:, --next## and ##-K, --config##.
<p class="level0"><a name="-B"></a><span class="nroffip">-B, --use-ascii</span>
<p class="level1">(FTP LDAP) Enable ASCII transfer. For FTP, this can also be enforced by using a URL that ends with &quot;;type=A&quot;. This option causes data sent to stdout to be in text mode for win32 systems.
<p class="level1">Providing ##-B, --use-ascii## multiple times has no extra effect. Disable it again with --no-use-ascii.
<p class="level1">Example:
```
curl -B ftp://example.com/README
```
<p class="level1">
<p class="level1">See also ##--crlf## and ##--data-ascii##.
<p class="level0"><a name="-A"></a><span class="nroffip">-A, --user-agent &lt;name&gt;</span>
<p class="level1">(HTTP) Specify the User-Agent string to send to the HTTP server. To encode blanks in the string, surround the string with single quote marks. This header can also be set with the ##-H, --header## or the ##--proxy-header## options.
<p class="level1">If you give an empty argument to ##-A, --user-agent## (&quot;&quot;), it will remove the header completely from the request. If you prefer a blank header, you can set it to a single space (&quot; &quot;).
<p class="level1">If ##-A, --user-agent## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl -A &quot;Agent 007&quot; https://example.com
```
<p class="level1">
<p class="level1">See also ##-H, --header## and ##--proxy-header##.
<p class="level0"><a name="-u"></a><span class="nroffip">-u, --user &lt;user:password&gt;</span>
<p class="level1">Specify the user name and password to use for server authentication. Overrides ##-n, --netrc## and ##--netrc-optional##.
<p class="level1">If you simply specify the user name, curl will prompt for a password.
<p class="level1">The user name and passwords are split up on the first colon, which makes it impossible to use a colon in the user name with this option. The password can, still.
<p class="level1">On systems where it works, curl will hide the given option argument from process listings. This is not enough to protect credentials from possibly getting seen by other users on the same system as they will still be visible for a moment before cleared. Such sensitive data should be retrieved from a file instead or similar and never used in clear text in a command line.
<p class="level1">When using Kerberos V5 with a Windows based server you should include the Windows domain name in the user name, in order for the server to successfully obtain a Kerberos Ticket. If you do not, then the initial authentication handshake may fail.
<p class="level1">When using NTLM, the user name can be specified simply as the user name, without the domain, if there is a single domain and forest in your setup for example.
<p class="level1">To specify the domain name use either Down-Level Logon Name or UPN (User Principal Name) formats. For example, EXAMPLE&bsol;user and user@example.com respectively.
<p class="level1">If you use a Windows SSPI-enabled curl binary and perform Kerberos V5, Negotiate, NTLM or Digest authentication then you can tell curl to select the user name and password from your environment by specifying a single colon with this option: &quot;-u :&quot;.
<p class="level1">If ##-u, --user## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl -u user:secret https://example.com
```
<p class="level1">
<p class="level1">See also ##-n, --netrc## and ##-K, --config##.
<p class="level0"><a name="-v"></a><span class="nroffip">-v, --verbose</span>
<p class="level1">Makes curl verbose during the operation. Useful for debugging and seeing what&#39;s going on &quot;under the hood&quot;. A line starting with &#39;&gt;&#39; means &quot;header data&quot; sent by curl, &#39;&lt;&#39; means &quot;header data&quot; received by curl that is hidden in normal cases, and a line starting with &#39;*&#39; means additional info provided by curl.
<p class="level1">If you only want HTTP headers in the output, ##-i, --include## might be the option you are looking for.
<p class="level1">If you think this option still does not give you enough details, consider using ##--trace## or ##--trace-ascii## instead.
<p class="level1">This option is global and does not need to be specified for each use of ##-:, --next##.
<p class="level1">Use ##-s, --silent## to make curl really quiet.
<p class="level1">Providing ##-v, --verbose## multiple times has no extra effect. Disable it again with --no-verbose.
<p class="level1">Example:
```
curl --verbose https://example.com
```
<p class="level1">
<p class="level1">See also ##-i, --include##. This option is mutually exclusive to ##--trace## and ##--trace-ascii##.
<p class="level0"><a name="-V"></a><span class="nroffip">-V, --version</span>
<p class="level1">Displays information about curl and the libcurl version it uses.
<p class="level1">The first line includes the full version of curl, libcurl and other 3rd party libraries linked with the executable.
<p class="level1">The second line (starts with &quot;Protocols:&quot;) shows all protocols that libcurl reports to support.
<p class="level1">The third line (starts with &quot;Features:&quot;) shows specific features libcurl reports to offer. Available features include:
<p class="level2">
<p class="level1"><a name="alt-svc"></a><span class="nroffip">alt-svc</span>
<p class="level2">Support for the Alt-Svc: header is provided.
<p class="level1"><a name="AsynchDNS"></a><span class="nroffip">AsynchDNS</span>
<p class="level2">This curl uses asynchronous name resolves. Asynchronous name resolves can be done using either the c-ares or the threaded resolver backends.
<p class="level1"><a name="brotli"></a><span class="nroffip">brotli</span>
<p class="level2">Support for automatic brotli compression over HTTP(S).
<p class="level1"><a name="CharConv"></a><span class="nroffip">CharConv</span>
<p class="level2">curl was built with support for character set conversions (like EBCDIC)
<p class="level1"><a name="Debug"></a><span class="nroffip">Debug</span>
<p class="level2">This curl uses a libcurl built with Debug. This enables more error-tracking and memory debugging etc. For curl-developers only!
<p class="level1"><a name="gsasl"></a><span class="nroffip">gsasl</span>
<p class="level2">The built-in SASL authentication includes extensions to support SCRAM because libcurl was built with libgsasl.
<p class="level1"><a name="GSS-API"></a><span class="nroffip">GSS-API</span>
<p class="level2">GSS-API is supported.
<p class="level1"><a name="HSTS"></a><span class="nroffip">HSTS</span>
<p class="level2">HSTS support is present.
<p class="level1"><a name="HTTP2"></a><span class="nroffip">HTTP2</span>
<p class="level2">HTTP/2 support has been built-in.
<p class="level1"><a name="HTTP3"></a><span class="nroffip">HTTP3</span>
<p class="level2">HTTP/3 support has been built-in.
<p class="level1"><a name="HTTPS-proxy"></a><span class="nroffip">HTTPS-proxy</span>
<p class="level2">This curl is built to support HTTPS proxy.
<p class="level1"><a name="IDN"></a><span class="nroffip">IDN</span>
<p class="level2">This curl supports IDN - international domain names.
<p class="level1"><a name="IPv6"></a><span class="nroffip">IPv6</span>
<p class="level2">You can use IPv6 with this.
<p class="level1"><a name="Kerberos"></a><span class="nroffip">Kerberos</span>
<p class="level2">Kerberos V5 authentication is supported.
<p class="level1"><a name="Largefile"></a><span class="nroffip">Largefile</span>
<p class="level2">This curl supports transfers of large files, files larger than 2GB.
<p class="level1"><a name="libz"></a><span class="nroffip">libz</span>
<p class="level2">Automatic decompression (via gzip, deflate) of compressed files over HTTP is supported.
<p class="level1"><a name="MultiSSL"></a><span class="nroffip">MultiSSL</span>
<p class="level2">This curl supports multiple TLS backends.
<p class="level1"><a name="NTLM"></a><span class="nroffip">NTLM</span>
<p class="level2">NTLM authentication is supported.
<p class="level1"><a name="NTLMWB"></a><span class="nroffip">NTLM_WB</span>
<p class="level2">NTLM delegation to winbind helper is supported.
<p class="level1"><a name="PSL"></a><span class="nroffip">PSL</span>
<p class="level2">PSL is short for Suffix List and means that this curl has been built with knowledge about &quot;suffixes&quot;.
<p class="level1"><a name="SPNEGO"></a><span class="nroffip">SPNEGO</span>
<p class="level2">SPNEGO authentication is supported.
<p class="level1"><a name="SSL"></a><span class="nroffip">SSL</span>
<p class="level2">SSL versions of various protocols are supported, such as HTTPS, FTPS, POP3S and so on.
<p class="level1"><a name="SSPI"></a><span class="nroffip">SSPI</span>
<p class="level2">SSPI is supported.
<p class="level1"><a name="TLS-SRP"></a><span class="nroffip">TLS-SRP</span>
<p class="level2">SRP (Secure Remote Password) authentication is supported for TLS.
<p class="level1"><a name="TrackMemory"></a><span class="nroffip">TrackMemory</span>
<p class="level2">Debug memory tracking is supported.
<p class="level1"><a name="Unicode"></a><span class="nroffip">Unicode</span>
<p class="level2">Unicode support on Windows.
<p class="level1"><a name="UnixSockets"></a><span class="nroffip">UnixSockets</span>
<p class="level2">Unix sockets support is provided.
<p class="level1"><a name="zstd"></a><span class="nroffip">zstd</span>
<p class="level2">Automatic decompression (via zstd) of compressed files over HTTP is supported.
<p class="level1">
<p class="level1">Providing ##-V, --version## multiple times has no extra effect. Disable it again with --no-version.
<p class="level1">Example:
```
curl --version
```
<p class="level1">
<p class="level1">See also ##-h, --help## and ##-M, --manual##.
<p class="level0"><a name="-w"></a><span class="nroffip">-w, --write-out &lt;format&gt;</span>
<p class="level1">Make curl display information on stdout after a completed transfer. The format is a string that may contain plain text mixed with any number of variables. The format can be specified as a literal &quot;string&quot;, or you can have curl read the format from a file with &quot;@filename&quot; and to tell curl to read the format from stdin you write &quot;@-&quot;.
<p class="level1">The variables present in the output format will be substituted by the value or text that curl thinks fit, as described below. All variables are specified as %{variable_name} and to output a normal % you just write them as %%. You can output a newline by using &bsol;n, a carriage return with &bsol;r and a tab space with &bsol;t.
<p class="level1">The output will be written to standard output, but this can be switched to standard error by using %{stderr}.
<p class="level1">Output HTTP headers from the most recent request by using <span Class="bold">%header{name}</span> where <span Class="bold">name</span> is the case insensitive name of the header (without the trailing colon). The header contents are exactly as sent over the network, with leading and trailing whitespace trimmed. Added in curl 7.84.0.
<p class="level1"><span Class="bold">NOTE:</span> In Windows the %-symbol is a special symbol used to expand environment variables. In batch files all occurrences of % must be doubled when using this option to properly escape. If this option is used at the command prompt then the % cannot be escaped and unintended expansion is possible.
<p class="level1">The variables available are:
<p class="level2">
<p class="level2"><span Class="bold">certs</span> Output the certificate chain with details. Supported only by the OpenSSL, GnuTLS, Schannel, NSS, GSKit and Secure Transport backends (Added in 7.88.0)
<p class="level2"><span Class="bold">content_type</span> The Content-Type of the requested document, if there was any.
<p class="level2"><span Class="bold">errormsg</span> The error message. (Added in 7.75.0)
<p class="level2"><span Class="bold">exitcode</span> The numerical exitcode of the transfer. (Added in 7.75.0)
<p class="level2"><span Class="bold">filename_effective</span> The ultimate filename that curl writes out to. This is only meaningful if curl is told to write to a file with the ##-O, --remote-name## or ##-o, --output## option. It&#39;s most useful in combination with the ##-J, --remote-header-name## option.
<p class="level2"><span Class="bold">ftp_entry_path</span> The initial path curl ended up in when logging on to the remote FTP server.
<p class="level2"><span Class="bold">header_json</span> A JSON object with all HTTP response headers from the recent transfer. Values are provided as arrays, since in the case of multiple headers there can be multiple values.
<p class="level2">The header names provided in lowercase, listed in order of appearance over the wire. Except for duplicated headers. They are grouped on the first occurrence of that header, each value is presented in the JSON array.
<p class="level2"><span Class="bold">http_code</span> The numerical response code that was found in the last retrieved HTTP(S) or FTP(s) transfer.
<p class="level2"><span Class="bold">http_connect</span> The numerical code that was found in the last response (from a proxy) to a curl CONNECT request.
<p class="level2"><span Class="bold">http_version</span> The http version that was effectively used. (Added in 7.50.0)
<p class="level2"><span Class="bold">json</span> A JSON object with all available keys.
<p class="level2"><span Class="bold">local_ip</span> The IP address of the local end of the most recently done connection - can be either IPv4 or IPv6.
<p class="level2"><span Class="bold">local_port</span> The local port number of the most recently done connection.
<p class="level2"><span Class="bold">method</span> The http method used in the most recent HTTP request. (Added in 7.72.0)
<p class="level2"><span Class="bold">num_certs</span> Number of server certificates received in the TLS handshake. Supported only by the OpenSSL, GnuTLS, Schannel, NSS, GSKit and Secure Transport backends (Added in 7.88.0)
<p class="level2"><span Class="bold">num_connects</span> Number of new connects made in the recent transfer.
<p class="level2"><span Class="bold">num_headers</span> The number of response headers in the most recent request (restarted at each redirect). Note that the status line IS NOT a header. (Added in 7.73.0)
<p class="level2"><span Class="bold">num_redirects</span> Number of redirects that were followed in the request.
<p class="level2"><span Class="bold">onerror</span> The rest of the output is only shown if the transfer returned a non-zero error (Added in 7.75.0)
<p class="level2"><span Class="bold">proxy_ssl_verify_result</span> The result of the HTTPS proxy&#39;s SSL peer certificate verification that was requested. 0 means the verification was successful. (Added in 7.52.0)
<p class="level2"><span Class="bold">redirect_url</span> When an HTTP request was made without ##-L, --location## to follow redirects (or when ##--max-redirs## is met), this variable will show the actual URL a redirect <span Class="emphasis">would</span> have gone to.
<p class="level2"><span Class="bold">referer</span> The Referer: header, if there was any. (Added in 7.76.0)
<p class="level2"><span Class="bold">remote_ip</span> The remote IP address of the most recently done connection - can be either IPv4 or IPv6.
<p class="level2"><span Class="bold">remote_port</span> The remote port number of the most recently done connection.
<p class="level2"><span Class="bold">response_code</span> The numerical response code that was found in the last transfer (formerly known as &quot;http_code&quot;).
<p class="level2"><span Class="bold">scheme</span> The URL scheme (sometimes called protocol) that was effectively used. (Added in 7.52.0)
<p class="level2"><span Class="bold">size_download</span> The total amount of bytes that were downloaded. This is the size of the body/data that was transferred, excluding headers.
<p class="level2"><span Class="bold">size_header</span> The total amount of bytes of the downloaded headers.
<p class="level2"><span Class="bold">size_request</span> The total amount of bytes that were sent in the HTTP request.
<p class="level2"><span Class="bold">size_upload</span> The total amount of bytes that were uploaded. This is the size of the body/data that was transferred, excluding headers.
<p class="level2"><span Class="bold">speed_download</span> The average download speed that curl measured for the complete download. Bytes per second.
<p class="level2"><span Class="bold">speed_upload</span> The average upload speed that curl measured for the complete upload. Bytes per second.
<p class="level2"><span Class="bold">ssl_verify_result</span> The result of the SSL peer certificate verification that was requested. 0 means the verification was successful.
<p class="level2"><span Class="bold">stderr</span> From this point on, the ##-w, --write-out## output will be written to standard error. (Added in 7.63.0)
<p class="level2"><span Class="bold">stdout</span> From this point on, the ##-w, --write-out## output will be written to standard output. This is the default, but can be used to switch back after switching to stderr. (Added in 7.63.0)
<p class="level2"><span Class="bold">time_appconnect</span> The time, in seconds, it took from the start until the SSL/SSH/etc connect/handshake to the remote host was completed.
<p class="level2"><span Class="bold">time_connect</span> The time, in seconds, it took from the start until the TCP connect to the remote host (or proxy) was completed.
<p class="level2"><span Class="bold">time_namelookup</span> The time, in seconds, it took from the start until the name resolving was completed.
<p class="level2"><span Class="bold">time_pretransfer</span> The time, in seconds, it took from the start until the file transfer was just about to begin. This includes all pre-transfer commands and negotiations that are specific to the particular protocol(s) involved.
<p class="level2"><span Class="bold">time_redirect</span> The time, in seconds, it took for all redirection steps including name lookup, connect, pretransfer and transfer before the final transaction was started. time_redirect shows the complete execution time for multiple redirections.
<p class="level2"><span Class="bold">time_starttransfer</span> The time, in seconds, it took from the start until the first byte was just about to be transferred. This includes time_pretransfer and also the time the server needed to calculate the result.
<p class="level2"><span Class="bold">time_total</span> The total time, in seconds, that the full operation lasted.
<p class="level2"><span Class="bold">url</span> The URL that was fetched. (Added in 7.75.0)
<p class="level2"><span Class="bold">urlnum</span> The URL index number of this transfer, 0-indexed. De-globbed URLs share the same index number as the origin globbed URL. (Added in 7.75.0)
<p class="level2"><span Class="bold">url_effective</span> The URL that was fetched last. This is most meaningful if you have told curl to follow location: headers.
<p class="level1">
<p class="level0"><a name=""></a><span class="nroffip"></span>
<p class="level1">
<p class="level1">If ##-w, --write-out## is provided several times, the last set value will be used.
<p class="level1">Example:
```
curl -w &#39;%{http_code}&bsol;n&#39; https://example.com
```
<p class="level1">
<p class="level1">See also ##-v, --verbose## and ##-I, --head##.
<p class="level0"><a name="--xattr"></a><span class="nroffip">--xattr</span>
<p class="level1">When saving output to a file, this option tells curl to store certain file metadata in extended file attributes. Currently, the URL is stored in the xdg.origin.url attribute and, for HTTP, the content type is stored in the mime_type attribute. If the file system does not support extended attributes, a warning is issued.
<p class="level1">Providing ##--xattr## multiple times has no extra effect. Disable it again with --no-xattr.
<p class="level1">Example:
```
curl --xattr -o storage https://example.com
```
<p class="level1">
<p class="level1">See also ##-R, --remote-time##, ##-w, --write-out## and ##-v, --verbose##
"""
