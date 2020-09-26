//
//  File.swift
//  
//
//  Created by daniele on 25/09/2020.
//

import Foundation

/// This is the implementation of IPStack location search by ip.
/// https://ipstack.com
public class IPStackService: IPService {
    
    /// Used to retrive data from json.
    public var jsonServiceDecoder: IPServiceDecoders = .ipstack

    // MARK: - Configurable Settings
    
    /// Optional target IP to discover; `nil` to use current machine internet address.
    /// At the time of this documentation 50 is the limit of target IPs you can lookup.
    public let targetIPs: [String]?
    
    /// Locale identifier.
    /// Not all languages are supported (https://ipstack.com/documentation#language).
    public var locale = Locale(identifier: "en")
    
    /// Hostname lookup.
    /// By default, the ipstack API does not return information about the hostname the given IP address resolves to.
    public var hostnameLookup = false
    
    // MARK: - Protocol Specific
    
    /// Service underlying.
    public var task: URLSessionDataTask?
    
    /// Operation was cancelled.
    public var isCancelled = false
    
    /// Timeout interval to execute the call.
    public var timeout: TimeInterval = 5
    
    /// Session URL session.
    public var session = URLSession.shared
    
    /// API key to use the service.
    public let APIKey: String
    
    /// Initialize a new https://ipstack.com/ service with given parameters.
    ///
    /// - Parameters:
    ///   - IP: IP to discover; ignore this parameter to get the location of the currently machine.
    ///   - APIKey: APIKey to use service (go to https://ipstack.com/product for more infos).
    public init(targetIPs: [String]? = nil, APIKey: String) {
        self.targetIPs = targetIPs
        self.APIKey = APIKey
    }
    
    private func serviceURL() -> URL {
        guard let targetIPs = targetIPs else {
            return URL(string: "http://api.ipstack.com/check")!
        }
        
        return URL(string: "http://api.ipstack.com/\(targetIPs.joined(separator: ","))")!
    }
    
    public func buildRequest() throws -> URLRequest {
        var urlComponents = URLComponents(string: serviceURL().absoluteString)
        urlComponents?.queryItems = [
            URLQueryItem(name: "access_key", value: APIKey),
            URLQueryItem(name: "language", value: locale.identifier.lowercased()),
            URLQueryItem(name: "hostname", value: (hostnameLookup ? "1": "0")),
            URLQueryItem(name: "output", value: "json")
        ]
        
        guard let fullURL = urlComponents?.url else {
            throw LocatorErrors.internalError
        }
        
        let request = URLRequest(url: fullURL, cachePolicy: .useProtocolCachePolicy, timeoutInterval: timeout)
        return request
    }
    
    public func validateResponse(data: Data, httpResponse: HTTPURLResponse) -> LocatorErrors? {
        guard httpResponse.statusCode != 200 else {
            return nil
        }
        
        // see https://ipstack.com/documentation#errors
        switch httpResponse.statusCode {
        case 404:           return .notFound
        case 101, 102, 103: return .invalidAPIKey
        case 104:           return .usageLimitReached
        default:            return .other(String(httpResponse.statusCode))
        }
    }
    
}
