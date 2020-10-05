//
//  File.swift
//  
//
//  Created by daniele on 27/09/2020.
//

import Foundation

public extension IPLocation {
    
    /// This is the implementation of IPGeolocation location search by ip.
    /// https://ipgeolocation.io
    class IPGeolocation: IPServiceProtocol, Codable {
        
        /// Used to retrive data from json.
        public var jsonServiceDecoder: IPServiceDecoders = .ipgeolocation
        
        // MARK: - Configurable Settings
        
        /// Optional target IP to discover; `nil` to use current machine internet address.
        public let targetIP: String?
        
        /// API key. See https://app.ipgeolocation.io.
        public let APIKey: String?
        
        /// Locale identifier.
        /// Not all languages are supported (https://ip-api.com/docs/api:json).
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
        
        /// Initialize a new https://ip-api.com service with given parameters.
        ///
        /// - Parameters:
        ///   - targetIP: IP to discover; ignore this parameter to get the location of the currently machine.
        ///   - APIKey: API Key for service. Signup at https://app.ipgeolocation.io.
        public init(targetIP: String? = nil, APIKey: String) {
            self.targetIP = targetIP
            self.APIKey = APIKey
        }
        
        public func buildRequest() throws -> URLRequest {
            let serviceURL = URL(string: "https://api.ipgeolocation.io/ipgeo")!
            var urlComponents = URLComponents(string: serviceURL.absoluteString)
            
            urlComponents?.queryItems = [
                URLQueryItem(name: "apiKey", value: APIKey),
                URLQueryItem(name: "lang", value: locale ?? Locale.current.collatorIdentifier?.lowercased() ?? "en"),
                (targetIP != nil ? URLQueryItem(name: "ip", value: targetIP) : nil)
            ].compactMap({ $0 })
            
            guard let fullURL = urlComponents?.url else {
                throw LocatorErrors.internalError
            }
            
            return URLRequest(url: fullURL, cachePolicy: .useProtocolCachePolicy, timeoutInterval: timeout)
        }
        
        public func validateResponse(data: IPLocation.Data, httpResponse: HTTPURLResponse) -> LocatorErrors? {
            guard httpResponse.statusCode != 200 else {
                return nil
            }
            
            switch httpResponse.statusCode {
            // If your subscription is paused from use.
            // (1) If the provided API key is not valid.
            // (2) If your account has been disabled or locked by admin because of any illegal activity.
            // (3) If you’re making requests after your subscription trial has been expired.
            // (4) If you’ve exceeded your requests limit.
            // (5) If your subscription is not active.
            //(6) If you’re accessing a paid feature on free subscription.
            // (7) If you’re making a request without authorization with our IP Geolocation API.
            case 400, 401: return .usageLimitReached
            case 404: return .notFound // If the queried IP address or domain name is not found in our database.
            case 423: return .reserved // If the queried IP address is a bogon (reserved) IP address like private, multicast, etc.
            default:
                return .other(String(httpResponse.statusCode))
            }
            
        }
        
        // MARK: - Codable
        
        enum CodingKeys: String, CodingKey {
            case jsonServiceDecoder, targetIP, APIKey, timeout, locale
        }
        
        // Encodable protocol
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(jsonServiceDecoder, forKey: .jsonServiceDecoder)
            try container.encodeIfPresent(targetIP, forKey: .targetIP)
            try container.encodeIfPresent(locale, forKey: .locale)
            try container.encode(APIKey, forKey: .APIKey)
            try container.encode(timeout, forKey: .timeout)
        }
        
        // Decodable protocol
        required public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.jsonServiceDecoder = try container.decode(IPServiceDecoders.self, forKey: .jsonServiceDecoder)
            self.targetIP = try container.decodeIfPresent(String.self, forKey: .targetIP)
            self.locale = try container.decodeIfPresent(String.self, forKey: .locale)
            self.APIKey = try container.decode(String.self, forKey: .APIKey)
            self.timeout = try container.decode(TimeInterval.self, forKey: .timeout)
        }
        
    }
    
}
