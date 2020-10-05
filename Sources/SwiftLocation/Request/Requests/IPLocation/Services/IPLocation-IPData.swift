//
//  File.swift
//  
//
//  Created by daniele on 26/09/2020.
//

import Foundation

public extension IPLocation {
    
    /// This is the implementation of IPData location search by ip.
    /// https://ipdata.co
    class IPData: IPServiceProtocol, Codable {
        
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
        
        public func validateResponse(data: IPLocation.Data, httpResponse: HTTPURLResponse) -> LocatorErrors? {
            guard httpResponse.statusCode != 200 else {
                return nil
            }
            
            // see https://docs.ipdata.co/api-reference/status-codes
            switch httpResponse.statusCode {
            case 401: return .invalidAPIKey
            case 403: return .usageLimitReached
            default:  return .other(String(httpResponse.statusCode))
            }
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
