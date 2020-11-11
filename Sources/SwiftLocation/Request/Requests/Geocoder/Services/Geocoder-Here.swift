//
//  Geocoder+Here.swift
//
//  Copyright (c) 2020 Daniele Margutti (hello@danielemargutti.com).
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
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
        public var timeout: TimeInterval?
        
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
        
        /// Description.
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
        public init(coordinates: CLLocationCoordinate2D, APIKey: String = SharedCredentials[.here]) {
            self.operation = .geoAddress(coordinates)
            self.APIKey = APIKey
        }
        
        /// Initialize to reverse geocode a pair of coordinates.
        /// - Parameters:
        ///   - lat: latitude.
        ///   - lng: longitude.
        ///   - APIKey: API Key.
        public convenience init(lat: CLLocationDegrees, lng: CLLocationDegrees, APIKey: String = SharedCredentials[.here]) {
            let coordinates = CLLocationCoordinate2D(latitude: lat, longitude: lng)
            self.init(coordinates: coordinates, APIKey: APIKey)
        }
        
        /// Initialize to geocode given address and obtain coordinates.
        ///
        /// - Parameters:
        ///   - address: address to geocode.
        ///   - APIKey: API Key
        public init(address: String, APIKey: String = SharedCredentials[.here]) {
            self.operation = .getCoordinates(address)
            self.APIKey = APIKey
        }
        
        // MARK: - Public Functions
        
        public func execute(_ completion: @escaping ((Result<[GeoLocation], LocationError>) -> Void)) {
            do {
                guard !APIKey.isEmpty else {
                    throw LocationError.invalidAPIKey
                }
                
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
                completion(.failure(error as? LocationError ?? .generic(error)))
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
                throw LocationError.internalError
            }
            
            let request = URLRequest(url: fullURL, cachePolicy: .useProtocolCachePolicy, timeoutInterval: timeout ?? TimeInterval.highInterval)
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
