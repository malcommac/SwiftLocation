//
//  File.swift
//  
//
//  Created by daniele on 26/09/2020.
//

import Foundation

public extension IPLocation {
    
    /// This is the implementation of IPStack location search by ip.
    /// https://ip-api.com (documentation: https://ip-api.com/docs/api:jsonfor)
    class IPApi: IPServiceProtocol {
        
        public enum ReturnedFields: String {
            case continent, // Continent name ('North America')
                 continentCode, // Two-letter continent code ('NA')
                 country, // Country name ('United States')
                 countryCode, // Two-letter country code ISO 3166-1 alpha-2 ('US')
                 region, // Region/state short code (FIPS or ISO) ('CA or 10')
                 regionName, // Region/state ('California')
                 city, // City ('Mountain View')
                 district, // District (subdivision of city) ('Old Farm District')
                 zip, // Zip code ('94043')
                 timezone, // Timezone (tz) ('America/Los_Angeles')
                 isp, // Internet Service Provider ('Google'),
                 query, // IP (always fetched)
                 lat, // latitude (always fetched)
                 lon // longitude (always fetched)
        }
        
        /// Used to retrive data from json.
        public var jsonServiceDecoder: IPServiceDecoders = .ipapi
        
        // MARK: - Configurable Settings
        
        /// Optional target IP to discover; `nil` to use current machine internet address.
        public var targetIP: String?
        
        /// The API can return the following fields and values.
        /// By default `[.city, .region, .regionName, .continent, .continentCode]` are used.
        public var returnedFields = Set<ReturnedFields>([.city, .region, .regionName, .continent, .continentCode])
        
        /// Locale identifier as ISO 639.
        /// Not all languages are supported (https://ip-api.com/docs/api:json).
        public var locale: String?
        
        /// Hostname lookup.
        /// By default, the ipstack API does not return information about the hostname the given IP address resolves to.
        public var hostnameLookup = false
        
        /// NOTE: This service don't need of API Key.
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
                "fields": Array(returnedFields),
                "locale": locale ?? "",
                "hostnameLookup": hostnameLookup,
                "isCancelled": isCancelled,
                "timeout": timeout,
                "decoder": jsonServiceDecoder.rawValue
            ])
        }
        
        /// Initialize a new https://ip-api.com service with given parameters.
        ///
        /// - Parameters:
        ///   - IP: IP to discover; ignore this parameter to get the location of the currently machine.
        public init(targetIP: String? = nil) {
            self.targetIP = targetIP
        }
        
        private func serviceURL() -> URL {
            guard let targetIP = targetIP else {
                return URL(string: "http://ip-api.com/json")!
            }
            
            return URL(string: "http://ip-api.com/json/\(targetIP)")!
        }
        
        public func buildRequest() throws -> URLRequest {
            var urlComponents = URLComponents(string: serviceURL().absoluteString)
            
            let allReturnedFields = returnedFields.union([.query, .lat, .lon])
            urlComponents?.queryItems = [
                URLQueryItem(name: "fields", value: Array(allReturnedFields).map({ $0.rawValue }).joined(separator: ",")),
                URLQueryItem(name: "lang", value: locale ?? Locale.current.collatorIdentifier?.lowercased() ?? "en")
            ]
            
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
            
            return .other(String(httpResponse.statusCode))
        }
        
    }
    
}
