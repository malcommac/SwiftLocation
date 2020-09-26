//
//  File.swift
//  
//
//  Created by daniele on 25/09/2020.
//

import Foundation
import CoreLocation

/// This is the implementation of IPStack location search by ip.
/// https://ipstack.com
public class IPStackService: IPService {
    
    /// Used to retrive data from json.
    public var jsonServiceDecoder: IPServiceDecoders = .ipstack

    // MARK: - Configurable Settings
    
    /// Optional target IP to discover; `nil` to use current machine internet address.
    public let targetIP: String?
    
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
    public init(targetIP: String? = nil, APIKey: String) {
        self.targetIP = targetIP
        self.APIKey = APIKey
    }
    
    private func serviceURL() -> URL {
        guard let targetIP = targetIP else {
            return URL(string: "http://api.ipstack.com/check")!
        }
        
        return URL(string: "http://api.ipstack.com/\(targetIP)")!
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
    
}
