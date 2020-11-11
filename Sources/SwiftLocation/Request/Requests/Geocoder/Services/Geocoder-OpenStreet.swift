//
//  Geocoder+OpenStreet.swift
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
    
    /// Geocoding using OpenStreet APIs
    /// https://nominatim.org/release-docs/develop/api/Overview/)
    class OpenStreet: JSONNetworkHelper, GeocoderServiceProtocol {
        
        /// Operation to perform.
        /// NOTE: Usually it's set via init and you should not change it.
        public var operation: GeocoderOperation
        
        /// Request timeout.
        public var timeout: TimeInterval?
        
        /// Include a breakdown of the address into elements.
        /// By default is set `true`
        public var includeAddressDetails = true
        
        /// Include additional information in the result if available, e.g. wikipedia link, opening hours.
        /// By default is set to `false`.
        public var includeExtraTags = false
        
        /// Include a list of alternative names in the results. These may include language variants, references, operator and brand.
        /// By default is set to `false`.
        public var includeNameDetails = false
        
        /// Level of detail required for the address. Default is `building`
        /// This is a number that corresponds roughly to the zoom level used in map frameworks like Leaflet.js, Openlayers etc.
        public var zoomLevel: ZoomLevel = .building
        
        /// Preferred language order for showing search results, overrides the value specified in the "Accept-Language" HTTP header.
        /// Either use a standard RFC2616 accept-language string or a simple comma-separated list of language codes.
        public var locale: String?
        
        /// Simplify the output geometry before returning. The parameter is the tolerance in degrees with which the geometry may differ from the original geometry. Topology is preserved in the result.
        /// Default is 0.
        public var polygonThreshold = 0.0
        
        public var description: String {
            JSONStringify([
                "timeout": timeout,
                "includeAddressDetails": includeAddressDetails,
                "includeExtraTags": includeExtraTags,
                "includeNameDetails": includeNameDetails,
                "zoomLevel": zoomLevel.description,
                "locale": locale ?? "",
                "polygonThreshold": polygonThreshold
            ])
        }
        
        // MARK: - Initialize
        
        /// Initialize to reverse geocode coordinates to return estimated address.
        ///
        /// - Parameters:
        ///   - coordinates: coordinates.
        ///   - APIKey: API key
        public init(coordinates: CLLocationCoordinate2D) {
            self.operation = .geoAddress(coordinates)
        }
        
        /// Initialize to reverse geocode a pair of coordinates.
        /// - Parameters:
        ///   - lat: latitude.
        ///   - lng: longitude.
        ///   - APIKey: API Key.
        public convenience init(lat: CLLocationDegrees, lng: CLLocationDegrees) {
            let coordinates = CLLocationCoordinate2D(latitude: lat, longitude: lng)
            self.init(coordinates: coordinates)
        }
        
        /// Initialize to geocode given address and obtain coordinates.
        ///
        /// - Parameters:
        ///   - address: address to geocode.
        ///   - APIKey: API Key
        public init(address: String) {
            self.operation = .getCoordinates(address)
        }
        
        // MARK: - Public Functions
        
        public func execute(_ completion: @escaping ((Result<[GeoLocation], LocationError>) -> Void)) {
            do {
                let request = try buildRequest()
                executeDataRequest(request: request) { result in
                    switch result {
                    case .failure(let error):
                        completion(.failure(error))
                    case .success(let rawData):
                        do {
                            let locations = try Geocoder.OpenStreet.parseRawData(rawData)
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
        
        // MARK: - Private Functions
        
        private func buildRequest() throws -> URLRequest {
            var url: URL!
            var queryItems = [
                URLQueryItem(name: "format", value: "jsonv2"),
                URLQueryItem(name: "language", optional: locale)
            ].compactMap({ $0 })
            
            // Options
            queryItems.append(URLQueryItem(name: "addressdetails", value: String(includeAddressDetails)))
            queryItems.append(URLQueryItem(name: "extratags", value: String(includeExtraTags)))
            queryItems.append(URLQueryItem(name: "namedetails", value: String(includeNameDetails)))
            queryItems.append(URLQueryItem(name: "zoom", value: String(zoomLevel.rawValue)))
            queryItems.append(URLQueryItem(name: "polygon_threshold", value: String(polygonThreshold)))
            
            switch operation {
            case .getCoordinates(let address):
                url = URL(string: "https://nominatim.openstreetmap.org/search/\(address.urlEncoded)")!
                
            case .geoAddress(let coordinates):
                url = URL(string: "https://nominatim.openstreetmap.org/reverse")!
                queryItems.append(contentsOf: [
                    URLQueryItem(name: "lat", value: String(coordinates.latitude)),
                    URLQueryItem(name: "lon", value: String(coordinates.latitude)),
                ])
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

// MARK: - OpenStreetGeocoderService

public extension Geocoder.OpenStreet {
    
    /// Level of detail required for the address.
    enum ZoomLevel: Int, CustomStringConvertible {
        case country = 3
        case state = 5
        case county = 8
        case city = 10
        case suburb = 14
        case majorStreets = 16
        case majorAndMinorStreets = 17
        case building = 18
        
        public var description: String {
            switch self {
            case .country: return "country"
            case .state: return "state"
            case .county: return "county"
            case .city: return "city"
            case .suburb: return "suburb"
            case .majorStreets: return "majorStreets"
            case .majorAndMinorStreets: return "majorAndMinorStreets"
            case .building: return "building"
            }
        }
    }
    
}
