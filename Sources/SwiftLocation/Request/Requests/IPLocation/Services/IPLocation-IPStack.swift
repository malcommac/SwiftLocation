//
//  File.swift
//  
//
//  Created by daniele on 25/09/2020.
//

import Foundation

public extension IPLocation {
    
    /// This is the implementation of IPStack location search by ip.
    /// https://ipstack.com
    class IPStack: IPServiceProtocol, Codable {
        
        /// Used to retrive data from json.
        public var jsonServiceDecoder: IPServiceDecoders = .ipstack
        
        // MARK: - Configurable Settings
        
        /// Optional target IP to discover; `nil` to use current machine internet address.
        public var targetIP: String?
        
        /// Locale identifier.
        /// Not all languages are supported (https://ipstack.com/documentation#language).
        public var locale: String?
        
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
        public var APIKey: String?
        
        public var description: String {
            JSONStringify([
                "targetIP": targetIP ?? "",
                "APIKey": APIKey?.trunc(length: 5) ?? "",
                "locale": locale ?? "",
                "isCancelled": isCancelled,
                "timeout": timeout,
                "decoder": jsonServiceDecoder.rawValue
            ])
        }
        
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
                URLQueryItem(name: "language", optional: locale?.lowercased()),
                URLQueryItem(name: "hostname", value: (hostnameLookup ? "1": "0")),
                URLQueryItem(name: "output", value: "json")
            ].compactMap({ $0 })
            
            guard let fullURL = urlComponents?.url else {
                throw LocatorErrors.internalError
            }
            
            let request = URLRequest(url: fullURL, cachePolicy: .useProtocolCachePolicy, timeoutInterval: timeout)
            return request
        }
        
        public func validateResponse(data: IPLocation.Data, httpResponse: HTTPURLResponse) -> LocatorErrors? {
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
     
        // MARK: - Codable
        
        enum CodingKeys: String, CodingKey {
            case jsonServiceDecoder, targetIP, APIKey, timeout, locale, hostnameLookup
        }
        
        // Encodable protocol
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(jsonServiceDecoder, forKey: .jsonServiceDecoder)
            try container.encodeIfPresent(targetIP, forKey: .targetIP)
            try container.encode(APIKey, forKey: .APIKey)
            try container.encode(hostnameLookup, forKey: .hostnameLookup)
            try container.encode(timeout, forKey: .timeout)
        }
        
        // Decodable protocol
        required public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.jsonServiceDecoder = try container.decode(IPServiceDecoders.self, forKey: .jsonServiceDecoder)
            self.targetIP = try container.decodeIfPresent(String.self, forKey: .targetIP)
            self.APIKey = try container.decode(String.self, forKey: .APIKey)
            self.hostnameLookup = try container.decode(Bool.self, forKey: .hostnameLookup)
            self.timeout = try container.decode(TimeInterval.self, forKey: .timeout)
        }
        
    }
    
}
