//
//  File.swift
//  
//
//  Created by daniele on 26/09/2020.
//

import Foundation
import CoreLocation

/// This is the implementation of IPData location search by ip.
/// https://ipdata.co
public class IPDataService: IPService {
    
    /// Used to retrive data from json.
    public var jsonServiceDecoder: IPServiceDecoders = .ipdata

    // MARK: - Configurable Settings
    
    /// Optional target IP to discover; `nil` to use current machine internet address.
    public let targetIP: String?
    
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
    
    /// Initialize a new service with given parameters.
    ///
    /// - Parameters:
    ///   - IP: IP to discover; ignore this parameter to get the location of the currently machine.
    ///   - APIKey: APIKey to use service (go to https://ipdata.co/registration.html for more infos).
    public init(targetIP: String? = nil, APIKey: String) {
        self.targetIP = targetIP
        self.APIKey = APIKey
    }
    
    private func serviceURL() -> URL {
        return URL(string: "https://api.ipdata.co/\(targetIP != nil ? targetIP! : "")")!
    }
    
    public func buildRequest() throws -> URLRequest {
        var urlComponents = URLComponents(string: serviceURL().absoluteString)
        urlComponents?.queryItems = [
            URLQueryItem(name: "api-key", value: APIKey)
        ]
        
        guard let fullURL = urlComponents?.url else {
            throw LocatorErrors.internalError
        }
        
        return URLRequest(url: fullURL, cachePolicy: .useProtocolCachePolicy, timeoutInterval: timeout)
    }
    
}
