//
//  File.swift
//  
//
//  Created by daniele on 26/09/2020.
//

import Foundation

public extension IPLocation {
    
    /// This is the implementation of IPData location search by ip.
    /// https://ipinfo.io
    class IPInfo: IPServiceProtocol {
        
        /// Used to retrive data from json.
        public var jsonServiceDecoder: IPServiceDecoders = .ipinfo
        
        // MARK: - Configurable Settings
        
        /// Optional target IP to discover; `nil` to use current machine internet address.
        public var targetIP: String?
        
        /// Locale.
        /// NOTE: It's ignored for this service.
        public var locale: String?
        
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
        public var APIKey: String?
        
        public var description: String {
            JSONStringify([
                "targetIP": targetIP ?? "",
                "isCancelled": isCancelled,
                "timeout": timeout,
                "decoder": jsonServiceDecoder.rawValue
            ])
        }
        
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
            guard let targetIP = targetIP else {
                return URL(string: "https://ipinfo.io")!
            }
            
            return URL(string: "https://ipinfo.io/\(targetIP)")!
        }
        
        public func buildRequest() throws -> URLRequest {
            var urlComponents = URLComponents(string: serviceURL().absoluteString)
            urlComponents?.queryItems = [
                URLQueryItem(name: "token", value: APIKey)
            ]
            
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