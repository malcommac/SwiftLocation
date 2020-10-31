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
    class IPify: IPServiceProtocol, Codable {
        
        /// Used to retrive data from json.
        public var jsonServiceDecoder: IPServiceDecoders = .ipify
        
        // MARK: - Configurable Settings
        
        /// Optional target IP to discover; `nil` to use current machine internet address.
        public var targetIP: String?
        
        /// Locale.
        /// NOTE: It's ignored for this service.
        public var locale: String?
        
        /// API Key if used.
        public var APIKey: String?
        
        // MARK: - Protocol Specific
        
        /// Service underlying.
        public var task: URLSessionDataTask?
        
        /// Operation was cancelled.
        public var isCancelled = false
        
        /// Timeout interval to execute the call.
        public var timeout: TimeInterval = 5
        
        /// Session URL session.
        public var session = URLSession.shared
        
        public var description: String {
            JSONStringify([
                "targetIP": targetIP ?? "",
                "APIKey": APIKey?.trunc(length: 5) ?? "",
                "isCancelled": isCancelled,
                "timeout": timeout,
                "decoder": jsonServiceDecoder.rawValue
            ])
        }
        
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
        
        // MARK: - Codable
        
        enum CodingKeys: String, CodingKey {
            case jsonServiceDecoder, targetIP, APIKey, timeout
        }
        
        // Encodable protocol
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(jsonServiceDecoder, forKey: .jsonServiceDecoder)
            try container.encodeIfPresent(targetIP, forKey: .targetIP)
            try container.encode(APIKey, forKey: .APIKey)
            try container.encode(timeout, forKey: .timeout)
        }
        
        // Decodable protocol
        required public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.jsonServiceDecoder = try container.decode(IPServiceDecoders.self, forKey: .jsonServiceDecoder)
            self.targetIP = try container.decodeIfPresent(String.self, forKey: .targetIP)
            self.APIKey = try container.decode(String.self, forKey: .APIKey)
            self.timeout = try container.decode(TimeInterval.self, forKey: .timeout)
        }
        
    }
    
}
