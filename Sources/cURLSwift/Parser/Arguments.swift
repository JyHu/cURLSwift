//
//  File.swift
//  
//
//  Created by Jo on 2023/2/5.
//

import Foundation


/// curl参数的取值方式
enum ArgType {
    /// 唯一的，没有入参的，设置多个也只会响应一个
    case unique
    /// 只会响应最后一个参数
    case lastOnly
    /// 允许多次使用添加多个参数
    case multiple
}


struct ArgTypes {
    /// curl参数对应的uuid所对应的取值类型
    private var types: [OptionUUID: ArgType] = [:]
    
    static var shared = ArgTypes()
    
    func argType(of option: OptionKey) throws -> ArgType {
        let uuid = try Options.shared.uuid(of: option)
        guard let type = types[uuid] else {
            throw cURLError.noValidArgType(option: option.rawValue)
        }
        return type
    }
    
    private init() {
        func t(_ option: OptionKey, _ argType: ArgType) {
            guard let uuid = try? Options.shared.uuid(of: option) else { return }
            types[uuid] = argType
        }
        
        t(._abstractUnixSocket,     .lastOnly)
        t(._altSvc,                 .lastOnly)
        t(._anyauth,                .unique  )
        t(._append,                 .unique  )
        t(._awsSigv4,               .lastOnly)
        t(._basic,                  .unique  )
        t(._cacert,                 .lastOnly)
        t(._capath,                 .lastOnly)
        t(._certStatus,             .unique  )
        t(._certType,               .lastOnly)
        t(._cert,                   .lastOnly)
        t(._ciphers,                .lastOnly)
        t(._compressedSsh,          .unique  )
        t(._compressed,             .unique  )
        t(._config,                 .multiple)
        t(._connectTimeout,         .lastOnly)
        t(._connectTo,              .multiple)
        t(._continueAt,             .lastOnly)
        t(._cookieJar,              .lastOnly)
        t(._cookie,                 .multiple)
        t(._createDirs,             .unique  )
        t(._createFileMode,         .lastOnly)
        t(._crlf,                   .unique  )
        t(._crlfile,                .lastOnly)
        t(._curves,                 .lastOnly)
        t(._dataAscii,              .multiple)
        t(._dataBinary,             .multiple)
        t(._dataRaw,                .multiple)
        t(._dataUrlencode,          .multiple)
        t(._data,                   .multiple)
        t(._delegation,             .lastOnly)
        t(._digest,                 .unique  )
        t(._disableEprt,            .unique  )
        t(._disableEpsv,            .unique  )
        t(._disable,                .unique  )
        t(._disallowUsernameInUrl,  .unique  )
        t(._dnsInterface,           .lastOnly)
        t(._dnsIpv4Addr,            .lastOnly)
        t(._dnsIpv6Addr,            .lastOnly)
        t(._dnsServers,             .lastOnly)
        t(._dohCertStatus,          .unique  )
        t(._dohInsecure,            .unique  )
        t(._dohUrl,                 .lastOnly)
        t(._dumpHeader,             .lastOnly)
        t(._egdFile,                .lastOnly)
        t(._engine,                 .lastOnly)
        t(._etagCompare,            .lastOnly)
        t(._etagSave,               .lastOnly)
        t(._expect100Timeout,       .lastOnly)
        t(._failEarly,              .unique  )
        t(._failWithBody,           .unique  )
        t(._fail,                   .unique  )
        t(._falseStart,             .unique  )
        t(._formEscape,             .lastOnly)
        t(._formString,             .multiple)
        t(._form,                   .multiple)
        t(._ftpAccount,             .lastOnly)
        t(._ftpAlternativeToUser,   .lastOnly)
        t(._ftpCreateDirs,          .unique  )
        t(._ftpMethod,              .lastOnly)
        t(._ftpPasv,                .unique  )
        t(._ftpPort,                .lastOnly)
        t(._ftpPret,                .unique  )
        t(._ftpSkipPasvIp,          .unique  )
        t(._ftpSslCccMode,          .unique  )
        t(._ftpSslCcc,              .unique  )
        t(._ftpSslControl,          .unique  )
        t(._get,                    .unique  )
        t(._globoff,                .unique  )
        t(._happyEyeballsTimeoutMs, .lastOnly)
        t(._haproxyProtocol,        .unique  )
        t(._head,                   .unique  )
        t(._header,                 .multiple)
        t(._help,                   .unique  )
        t(._hostpubmd5,             .lastOnly)
        t(._hostpubsha256,          .lastOnly)
        t(._hsts,                   .multiple)
        t(._http0_9,                .unique  )
        t(._http1_0,                .unique  )
        t(._http1_1,                .unique  )
        t(._http2PriorKnowledge,    .unique  )
        t(._http2,                  .unique  )
        t(._http3Only,              .unique  )
        t(._http3,                  .unique  )
        t(._ignoreContentLength,    .unique  )
        t(._include,                .unique  )
        t(._insecure,               .unique  )
        t(._interface,              .lastOnly)
        t(._ipv4,                   .unique  )
        t(._ipv6,                   .unique  )
        t(._json,                   .multiple)
        t(._junkSessionCookies,     .unique  )
        t(._keepaliveTime,          .lastOnly)
        t(._keyType,                .lastOnly)
        t(._key,                    .lastOnly)
        t(._krb,                    .lastOnly)
        t(._libcurl,                .lastOnly)
        t(._limitRate,              .lastOnly)
        t(._listOnly,               .unique  )
        t(._localPort,              .lastOnly)
        t(._locationTrusted,        .unique  )
        t(._location,               .unique  )
        t(._loginOptions,           .lastOnly)
        t(._mailAuth,               .lastOnly)
        t(._mailFrom,               .lastOnly)
        t(._mailRcptAllowfails,     .unique  )
        t(._mailRcpt,               .multiple)
        t(._manual,                 .unique  )
        t(._maxFilesize,            .lastOnly)
        t(._maxRedirs,              .lastOnly)
        t(._maxTime,                .lastOnly)
        t(._metalink,               .lastOnly)
        t(._negotiate,              .unique  )
        t(._netrcFile,              .lastOnly)
        t(._netrcOptional,          .unique  )
        t(._netrc,                  .unique  )
        t(._next,                   .multiple)
        t(._noAlpn,                 .unique  )
        t(._noBuffer,               .unique  )
        t(._noClobber,              .unique  )
        t(._noKeepalive,            .unique  )
        t(._noNpn,                  .unique  )
        t(._noProgressMeter,        .unique  )
        t(._noSessionid,            .unique  )
        t(._noproxy,                .lastOnly)
        t(._ntlmWb,                 .unique  )
        t(._ntlm,                   .unique  )
        t(._oauth2Bearer,           .lastOnly)
        t(._outputDir,              .lastOnly)
        t(._output,                 .multiple)
        t(._parallelImmediate,      .unique  )
        t(._parallelMax,            .lastOnly)
        t(._parallel,               .unique  )
        t(._pass,                   .lastOnly)
        t(._pathAsIs,               .unique  )
        t(._pinnedpubkey,           .lastOnly)
        t(._post301,                .unique  )
        t(._post302,                .unique  )
        t(._post303,                .unique  )
        t(._preproxy,               .lastOnly)
        t(._progressBar,            .unique  )
        t(._protoDefault,           .lastOnly)
        t(._protoRedir,             .lastOnly)
        t(._proto,                  .lastOnly)
        t(._proxyAnyauth,           .unique  )
        t(._proxyBasic,             .unique  )
        t(._proxyCacert,            .lastOnly)
        t(._proxyCapath,            .lastOnly)
        t(._proxyCertType,          .lastOnly)
        t(._proxyCert,              .lastOnly)
        t(._proxyCiphers,           .lastOnly)
        t(._proxyCrlfile,           .lastOnly)
        t(._proxyDigest,            .unique  )
        t(._proxyHeader,            .multiple)
        t(._proxyInsecure,          .unique  )
        t(._proxyKeyType,           .lastOnly)
        t(._proxyKey,               .lastOnly)
        t(._proxyNegotiate,         .unique  )
        t(._proxyNtlm,              .unique  )
        t(._proxyPass,              .lastOnly)
        t(._proxyPinnedpubkey,      .lastOnly)
        t(._proxyServiceName,       .lastOnly)
        t(._proxySslAllowBeast,     .unique  )
        t(._proxySslAutoClientCert, .unique  )
        t(._proxyTls13Ciphers,      .lastOnly)
        t(._proxyTlsauthtype,       .lastOnly)
        t(._proxyTlspassword,       .lastOnly)
        t(._proxyTlsuser,           .lastOnly)
        t(._proxyTlsv1,             .unique  )
        t(._proxyUser,              .lastOnly)
        t(._proxy,                  .lastOnly)
        t(._proxy1_0,               .unique  )
        t(._proxytunnel,            .unique  )
        t(._pubkey,                 .lastOnly)
        t(._quote,                  .multiple)
        t(._randomFile,             .lastOnly)
        t(._range,                  .lastOnly)
        t(._rate,                   .lastOnly)
        t(._raw,                    .unique  )
        t(._referer,                .lastOnly)
        t(._remoteHeaderName,       .unique  )
        t(._remoteNameAll,          .unique  )
        t(._remoteName,             .multiple)
        t(._remoteTime,             .unique  )
        t(._removeOnError,          .unique  )
        t(._requestTarget,          .lastOnly)
        t(._request,                .lastOnly)
        t(._resolve,                .multiple)
        t(._retryAllErrors,         .unique  )
        t(._retryConnrefused,       .unique  )
        t(._retryDelay,             .lastOnly)
        t(._retryMaxTime,           .lastOnly)
        t(._retry,                  .lastOnly)
        t(._saslAuthzid,            .lastOnly)
        t(._saslIr,                 .unique  )
        t(._serviceName,            .lastOnly)
        t(._showError,              .unique  )
        t(._silent,                 .unique  )
        t(._socks4,                 .lastOnly)
        t(._socks4a,                .lastOnly)
        t(._socks5Basic,            .unique  )
        t(._socks5GssapiNec,        .unique  )
        t(._socks5GssapiService,    .lastOnly)
        t(._socks5Gssapi,           .unique  )
        t(._socks5Hostname,         .lastOnly)
        t(._socks5,                 .lastOnly)
        t(._speedLimit,             .lastOnly)
        t(._speedTime,              .lastOnly)
        t(._sslAllowBeast,          .unique  )
        t(._sslAutoClientCert,      .unique  )
        t(._sslNoRevoke,            .unique  )
        t(._sslReqd,                .unique  )
        t(._sslRevokeBestEffort,    .unique  )
        t(._ssl,                    .unique  )
        t(._sslv2,                  .unique  )
        t(._sslv3,                  .unique  )
        t(._stderr,                 .lastOnly)
        t(._styledOutput,           .unique  )
        t(._suppressConnectHeaders, .unique  )
        t(._tcpFastopen,            .unique  )
        t(._tcpNodelay,             .unique  )
        t(._telnetOption,           .multiple)
        t(._tftpBlksize,            .lastOnly)
        t(._tftpNoOptions,          .unique  )
        t(._timeCond,               .lastOnly)
        t(._tlsMax,                 .lastOnly)
        t(._tls13Ciphers,           .lastOnly)
        t(._tlsauthtype,            .lastOnly)
        t(._tlspassword,            .lastOnly)
        t(._tlsuser,                .lastOnly)
        t(._tlsv1_0,                .unique  )
        t(._tlsv1_1,                .unique  )
        t(._tlsv1_2,                .unique  )
        t(._tlsv1_3,                .unique  )
        t(._tlsv1,                  .unique  )
        t(._trEncoding,             .unique  )
        t(._traceAscii,             .lastOnly)
        t(._traceTime,              .unique  )
        t(._trace,                  .lastOnly)
        t(._unixSocket,             .lastOnly)
        t(._uploadFile,             .multiple)
        t(._urlQuery,               .multiple)
        t(._url,                    .multiple)
        t(._useAscii,               .unique  )
        t(._userAgent,              .lastOnly)
        t(._user,                   .lastOnly)
        t(._verbose,                .unique  )
        t(._version,                .unique  )
        t(._writeOut,               .lastOnly)
        t(._xattr,                  .unique  )
    }
}
