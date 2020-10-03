//
//  File.swift
//  
//
//  Created by daniele on 27/09/2020.
//

import Foundation

public extension IPLocation {
    
    /// This is the implementation of IPify location search by ip.
    /// https://www.ipify.org
    class IPify: IPServiceProtocol {
        
        /// Used to retrive data from json.
        public var jsonServiceDecoder: IPServiceDecoders = .ipify
        
        // MARK: - Configurable Settings
        
        /// Optional target IP to discover; `nil` to use current machine internet address.
        public let targetIP: String?
        
        /// API Key if used.
        public let APIKey: String
        
        // MARK: - Protocol Specific
        
        /// Service underlying.
        public var task: URLSessionDataTask?
        
        /// Operation was cancelled.
        public var isCancelled = false
        
        /// Timeout interval to execute the call.
        public var timeout: TimeInterval = 5
        
        /// Session URL session.
        public var session = URLSession.shared
        
        /// Initialize a new https://www.ipify.org service with given parameters.
        ///
        /// - Parameters:
        ///   - IP: IP to discover; ignore this parameter to get the location of the currently machine.
        ///   - APIKey: API key (see https://geo.ipify.org/subscriptions)
        public init(targetIP: String? = nil, APIKey: String) {
            self.targetIP = targetIP
            self.APIKey = APIKey
        }
        
        public func buildRequest() throws -> URLRequest {
            let serviceURL = URL(string: "https://geo.ipify.org/api/v1")!
            var urlComponents = URLComponents(string: serviceURL.absoluteString)
            
            let queryItems: [URLQueryItem] = [
                URLQueryItem(name: "apiKey", value: APIKey),
                (targetIP != nil ? URLQueryItem(name: "ipAddress", value: targetIP!) : nil),
            ].compactMap({ $0 })
            
            if !queryItems.isEmpty {
                urlComponents?.queryItems = queryItems
            }
            
            guard let fullURL = urlComponents?.url else {
                throw LocatorErrors.internalError
            }
            
            return URLRequest(url: fullURL, cachePolicy: .useProtocolCachePolicy, timeoutInterval: timeout)
        }
        
        public func validateResponse(data: IPLocation.Data, httpResponse: HTTPURLResponse) -> LocatorErrors? {
            guard httpResponse.statusCode != 200 else {
                return nil
            }
            
            return .other(String(httpResponse.statusCode))
        }
        
    }
    
}
