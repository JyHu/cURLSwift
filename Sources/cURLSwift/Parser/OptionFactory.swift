//
//  File.swift
//  
//
//  Created by Jo on 2023/2/5.
//

import Foundation

public class OptionFactory {
    /// UUID 对应的option类
    private var optionClses: [OptionUUID: cURL.ArgOption.Type] = [:]
    
    private(set) static var shared = OptionFactory()
    
    private init() {
        cacheAllTypes()
    }
    
    func makeOption(with option: OptionKey, unit: Options.Unit, arg: String? = nil) throws -> cURL.Option {
        /// 如果当前参数无需入参，那么直接返回一个无参的option即可
        if !unit.hasArg {
            return try cURL.Option(option: option, unit: unit)
        }
        
        /// 如果入参为空，那么说明无效
        guard let arg = arg else { throw cURLError.noOptionArg("\(option.rawValue)需要有入参，如: \(unit.arg ?? "")") }
        
        /// 获取对应有效的uuid和参数类，并初始化
        let uuid = try Options.shared.uuid(of: option)
        
        if let cls = optionClses[uuid] {
            return try cls.init(option: option, unit: unit, arg: arg)
        }
        
        /// 创建对应的有效的参数类
        return try cURL.ArgOption(option: option, unit: unit, arg: arg)
    }
}

private extension OptionFactory {
    func cacheAllTypes() {
        cache(options: [
            ._abstractUnixSocket,
            ._altSvc,
            ._cacert,
            ._capath,
            ._certType,
            ._ciphers,
            ._config,
            ._cookieJar,
            ._cookie,
            ._createFileMode,
            ._crlfile,
            ._curves,
            ._dataAscii,
            ._dataBinary,
            ._dataRaw,
            ._dataUrlencode,
            ._data,
            ._dnsInterface,
            ._dnsIpv4Addr,
            ._dnsIpv6Addr,
            ._dohUrl,
            ._dumpHeader,
            ._egdFile,
            ._engine,
            ._etagCompare,
            ._etagSave,
            ._formString,
            ._ftpAccount,
            ._ftpAlternativeToUser,
            ._ftpPort,
            ._help,
            ._hostpubmd5,
            ._hostpubsha256,
            ._hsts,
            ._interface,
            ._key,
            ._libcurl,
            ._loginOptions,
            ._mailAuth,
            ._mailFrom,
            ._mailRcpt,
            ._netrcFile,
            ._noproxy,
            ._oauth2Bearer,
            ._outputDir,
            ._output,
            ._pass,
            ._pinnedpubkey,
            ._protoDefault,
            ._proxyCacert,
            ._proxyCapath,
            ._proxyCertType,
            ._proxyCert,
            ._proxyCiphers,
            ._proxyCrlfile,
            ._proxyKeyType,
            ._proxyKey,
            ._proxyPass,
            ._proxyPinnedpubkey,
            ._proxyServiceName,
            ._proxyTls13Ciphers,
            ._proxyTlsauthtype,
            ._proxyTlspassword,
            ._proxyTlsuser,
            ._pubkey,
            ._quote,
            ._randomFile,
            ._referer,
            ._requestTarget,
            ._saslAuthzid,
            ._serviceName,
            ._socks5GssapiService,
            ._stderr,
            ._timeCond,
            ._tls13Ciphers,
            ._tlspassword,
            ._tlsuser,
            ._traceAscii,
            ._trace,
            ._unixSocket,
            ._uploadFile,
            ._url,
            ._userAgent
        ], clsType: cURL.ArgOption.self)
        
        cache(options: [
            ._connectTimeout,
            ._expect100Timeout,
            ._happyEyeballsTimeoutMs,
            ._keepaliveTime,
            ._maxTime,
            ._retryDelay,
            ._retryMaxTime,
            ._speedTime
        ], clsType: cURL.IntervalOption.self)
        
        cache(options: [
            ._continueAt,
            ._maxRedirs,
            ._parallelMax,
            ._retry,
            ._speedLimit,
            ._tftpBlksize
        ], clsType: cURL.IntegerOption.self)
        
        cache(options: [
            ._proxy1_0,
            ._socks4,
            ._socks4a,
            ._socks5Hostname,
            ._socks5
        ], clsType: cURL.HostOption.self)
        
        cache(options: [
            ._maxFilesize,
            ._limitRate
        ], clsType: cURL.FileSizeOption.self)
        
        cache(._awsSigv4,       cURL.AwsSigv4Option.self      )
        cache(._cert,           cURL.CertOption.self          )
        cache(._connectTo,      cURL.ConnectToOption.self     )
        cache(._delegation,     cURL.DelegationOption.self    )
        cache(._dnsServers,     cURL.DNSServersOption.self    )
        cache(._form,           cURL.FormOption.self          )
        cache(._ftpMethod,      cURL.FTPMethodOption.self     )
        cache(._ftpSslCccMode,  cURL.FTPSSLCCCModeOption.self )
        cache(._header,         cURL.HeaderOption.self        )
        cache(._json,           cURL.JSONOption.self          )
        cache(._keyType,        cURL.KeyTypeOption.self       )
        cache(._krb,            cURL.KrbOption.self           )
        cache(._localPort,      cURL.LocalPortOption.self     )
        cache(._preproxy,       cURL.ProxyOption.self         )
        cache(._protoRedir,     cURL.ProtoRedirOption.self    )
        cache(._proto,          cURL.ProtoOption.self         )
        cache(._proxyHeader,    cURL.ProxyHeaderOption.self   )
        cache(._proxyUser,      cURL.ProxyUserOption.self     )
        cache(._proxy,          cURL.ProxyOption.self         )
        cache(._range,          cURL.RangeOption.self         )
        cache(._rate,           cURL.RateOption.self          )
        cache(._request,        cURL.RequestOption.self       )
        cache(._resolve,        cURL.ResolveOption.self       )
        cache(._telnetOption,   cURL.TelnetOptionOption.self  )
        cache(._tlsMax,         cURL.TLSMaxOption.self        )
        cache(._tlsauthtype,    cURL.TLSAuthTypeOption.self   )
        cache(._urlQuery,       cURL.URLQueryOption.self      )
        cache(._user,           cURL.UserOption.self          )
        cache(._writeOut,       cURL.WriteOutOption.self      )
    }
    
    func cache(options: [OptionKey], clsType: cURL.ArgOption.Type) {
        for optionKey in options {
            cache(optionKey, clsType)
        }
    }
    
    func cache(_ option: OptionKey, _ type: cURL.ArgOption.Type) {
        guard let uuid = try? Options.shared.uuid(of: option) else { return }
        optionClses[uuid] = type
    }
}
