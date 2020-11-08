//
//  File.swift
//  
//
//  Created by daniele on 28/09/2020.
//

import Foundation
import CoreLocation

public extension Geocoder {
    
    /// Geocoding using Here
    /// https://developer.here.com/projects
    /// See https://developer.here.com/documentation/geocoding-search-api/api-reference-swagger.html for more infos.
    class Here: JSONNetworkHelper, GeocoderServiceProtocol {
        
        /// Operation to perform.
        /// NOTE: Usually it's set via init and you should not change it.
        public var operation: GeocoderOperation
        
        /// API Key for service.
        /// https://account.mapbox.com
        public var APIKey: String
        
        /// Request timeout.
        public var timeout: TimeInterval = 5
        
        /// Maximum number of results to be returned. If not specified 20 is used.
        public var limit: Int?
        
        /// Select the language to be used for result rendering from a list of BCP47 compliant Language Codes.
        public var locale: String?
        
        /// Search within a geographic area. This is a hard filter. Results will be returned if they are located within the specified area.
        /// See https://en.wikipedia.org/wiki/ISO_3166-1_alpha-3 for values.
        ///
        /// NOTE: This does not apply to reverse geocoder.
        public var countryCodes: [String]?
        
        /// Specify the center of the search context expressed as coordinates.
        public var proximityCoordinates: CLLocationCoordinate2D?
        
        public var description: String {
            JSONStringify([
                "APIKey": APIKey.trunc(length: 5),
                "timeout": timeout,
                "locale": locale ?? "",
                "limit": limit ?? "",
                "locale": locale ?? "",
                "limitToCountries": countryCodes ?? "",
                "proximityCoordinates": proximityCoordinates?.description  ?? ""
            ])
        }
        
        // MARK: - Initialize
        
        /// Initialize to reverse geocode coordinates to return estimated address.
        ///
        /// - Parameters:
        ///   - coordinates: coordinates.
        ///   - APIKey: API key
        public init(coordinates: CLLocationCoordinate2D, APIKey: String) {
            self.operation = .geoAddress(coordinates)
            self.APIKey = APIKey
        }
        
        /// Initialize to geocode given address and obtain coordinates.
        ///
        /// - Parameters:
        ///   - address: address to geocode.
        ///   - APIKey: API Key
        public init(address: String, APIKey: String) {
            self.operation = .getCoordinates(address)
            self.APIKey = APIKey
        }
        
        // MARK: - Public Functions
        
        public func execute(_ completion: @escaping ((Result<[GeoLocation], LocatorErrors>) -> Void)) {
            do {
                let request = try buildRequest()
                executeDataRequest(request: request) { result in
                    switch result {
                    case .failure(let error):
                        completion(.failure(error))
                    case .success(let rawData):
                        do {
                            let rawJSON = try JSONSerialization.jsonObject(with: rawData, options: .allowFragments)
                            guard let json = rawJSON as? [String: Any] else {
                                completion(.failure(.parsingError))
                                return
                            }
                            
                            let message: String? = json.valueForKeyPath(keyPath: "message") ?? json.valueForKeyPath(keyPath: "error_description")
                            if (message?.isEmpty ?? true) == false {
                                completion(.failure(.other(message!)))
                                return
                            }
                            
                            let locations = GeoLocation.fromHereList(json.valueForKeyPath(keyPath: "items"))
                            completion(.success(locations))
                        } catch {
                            completion(.failure(.parsingError))
                        }
                    }
                }
            } catch {
                completion(.failure(.generic(error)))
            }
        }
        
        private func buildRequest() throws -> URLRequest {
            var url: URL!
            var queryItems = [URLQueryItem]()
            
            // Options
            queryItems.append(URLQueryItem(name: "apiKey", value: APIKey))
            queryItems.appendIfNotNil(URLQueryItem(name: "limit", optional: (limit != nil ? String(limit!) : nil)))
            queryItems.appendIfNotNil(URLQueryItem(name: "lang", optional: locale))
            
            if let limitToCountries = self.countryCodes {
                let limitToCountriesValue = "countryCode:\(limitToCountries.joined(separator: ","))"
                queryItems.appendIfNotNil(URLQueryItem(name: "in", value: limitToCountriesValue))
            }
            
            switch operation {
            case .getCoordinates(let address):
                queryItems.append(URLQueryItem(name: "q", value: address))
                queryItems.appendIfNotNil(URLQueryItem(name: "at", optional: proximityCoordinates?.hereWSParameter))
                
                url = URL(string: "https://geocode.search.hereapi.com/v1/geocode/")!
                
            case .geoAddress(let coordinates):
                url = URL(string: "https://revgeocode.search.hereapi.com/v1/revgeocode")!
                queryItems.appendIfNotNil(URLQueryItem(name: "at", optional: coordinates.hereWSParameter))
                
            }
            
            // Create
            var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
            urlComponents?.queryItems = queryItems
            
            guard let fullURL = urlComponents?.url else {
                throw LocatorErrors.internalError
            }
            
            let request = URLRequest(url: fullURL, cachePolicy: .useProtocolCachePolicy, timeoutInterval: timeout)
            return request
        }
        
        private static func parseRawData(_ data: Data) throws -> [GeoLocation] {
            return try GeoLocation.fromOpenStreetList(data)
        }
        
    }
    
}

fileprivate extension CLLocationCoordinate2D {
    
    var hereWSParameter: String {
        return "\(latitude),\(longitude)"
    }
    
}
