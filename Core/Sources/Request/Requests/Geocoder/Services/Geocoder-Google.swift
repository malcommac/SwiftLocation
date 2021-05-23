//
//  Geocoder+Google.swift
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
    
    class Google: JSONNetworkHelper, GeocoderServiceProtocol {

        /// Operation to perform.
        /// NOTE: Usually it's set via init and you should not change it.
        public var operation: GeocoderOperation
        
        /// Service API Key (https://console.cloud.google.com/google/maps-apis/credentials)
        public var APIKey: String
        
        /// This will send `X-Ios-Bundle-Identifier` header to the request.
        /// You can set it directly from the credentials store as `.googleBundleRestrictionID`.
        /// NOTE: If you enable app-restrictions in the api-console, these headers must be sent.
        public var bundleRestrictionID: String? = SwiftLocation.credentials[.googleBundleRestrictionID]
        
        /// Request timeout.
        public var timeout: TimeInterval?
        
        /// The language in which to return results.
        /// See https://developers.google.com/maps/faq#languagesupport for more informations.
        /// NOTE: If language is not supplied, the geocoder attempts to use the preferred language as specified in the Accept-Language header, or the native language of the domain from which the request is sent.
        /// More info: https://developers.google.com/maps/documentation/geocoding/overview
        public var locale: String?
        
        /// The region code, specified as a ccTLD ("top-level domain") two-character value.
        /// This parameter will only influence, not fully restrict, results from the geocoder.
        /// For more informations see https://developers.google.com/maps/documentation/geocoding/overview#RegionCodes.
        public var countryCode: String?
        
        /// The bounding box of the viewport within which to bias geocode results more prominently.
        /// This parameter will only influence, not fully restrict, results from the geocoder.
        /// See https://developers.google.com/maps/documentation/geocoding/overview#Viewports for more infos.
        public var boundingBox: BoundingBox?
        
        /// Type of results.
        /// See https://developers.google.com/maps/documentation/geocoding/overview#component-filtering for more infos.
        public var resultFilters: [FilterTypes]?
        
        /// It does not restrict the search to the specified location type(s). Rather, the location type acts as a post-search filter: the API fetches all results for the specified latlng,
        /// then discards those results that do not match the specified location type(s). Note:
        /// This parameter is available only for requests that include an API key or a client ID. The following values are supported:
        public var locationTypes: [LocationTypes]?
        
        /// Description.
        public var description: String {
            JSONStringify([
                "APIKey": APIKey.trunc(length: 5),
                "timeout": timeout,
                "language": locale ?? "",
                "region": countryCode ?? "",
                "bounds": boundingBox?.description ?? "",
                "components": resultFilters ?? "",
                "locationTypes": locationTypes?.description ?? "",
                "resultFilters": resultFilters?.description ?? ""
            ])
        }
        
        // MARK: - Initialize
        
        /// Initialize to reverse geocode coordinates to return estimated address.
        ///
        /// - Parameters:
        ///   - coordinates: coordinates.
        ///   - APIKey: API key
        public init(coordinates: CLLocationCoordinate2D, APIKey: String = SharedCredentials[.google]) {
            self.operation = .geoAddress(coordinates)
            self.APIKey = APIKey
        }
        
        /// Initialize to reverse geocode a pair of coordinates.
        /// - Parameters:
        ///   - lat: latitude.
        ///   - lng: longitude.
        ///   - APIKey: API Key.
        public convenience init(lat: CLLocationDegrees, lng: CLLocationDegrees, APIKey: String = SharedCredentials[.google]) {
            let coordinates = CLLocationCoordinate2D(latitude: lat, longitude: lng)
            self.init(coordinates: coordinates, APIKey: APIKey)
        }
        
        /// Initialize to geocode given address and obtain coordinates.
        ///
        /// - Parameters:
        ///   - address: address to geocode.
        ///   - APIKey: API Key
        public init(address: String, APIKey: String = SharedCredentials[.google]) {
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
                            let locations = try Geocoder.Google.parseRawData(rawData)
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
        
        // MARK: - Private Functions
        
        private func buildRequest() throws -> URLRequest {
            var url: URL!
            var queryItems = [ URLQueryItem(name: "key", value: APIKey), ]
            
            switch operation {
            case .getCoordinates(let address):
                url = URL(string: "https://maps.googleapis.com/maps/api/geocode/json")!
                queryItems.append(URLQueryItem(name: "address", value: address))
                
            case .geoAddress(let coordinates):
                url = URL(string: "https://maps.googleapis.com/maps/api/geocode/json")!
                queryItems.append(URLQueryItem(name: "latlng", value: "\(coordinates.latitude),\(coordinates.longitude)"))
            }
            
            // Options
            queryItems.appendIfNotNil(URLQueryItem(name: "language", optional: locale))
            queryItems.appendIfNotNil(URLQueryItem(name: "bounds", optional: boundingBox?.rawValue))
            queryItems.appendIfNotNil(URLQueryItem(name: "region", optional: countryCode))
            queryItems.appendIfNotNil(URLQueryItem(name: "components", optional: resultFilters?.map({ $0.rawValue }).joined(separator: "|")))
            queryItems.appendIfNotNil(URLQueryItem(name: "location_type", optional: locationTypes?.map({ $0.rawValue }).joined(separator: "|")))
            
            // Create
            var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
            urlComponents?.queryItems = queryItems
            
            guard let fullURL = urlComponents?.url else {
                throw LocationError.internalError
            }
            
            var request = URLRequest(url: fullURL, cachePolicy: .useProtocolCachePolicy, timeoutInterval: timeout ?? TimeInterval.highInterval)
            request.addValue(bundleRestrictionID ?? "", forHTTPHeaderField: HTTPHeaders.googleBundleRestriction)
            return request
        }
        
        internal static func parseRawData(_ data: Data) throws -> [GeoLocation] {
            return try GeoLocation.fromGoogleList(data)
        }
        
    }
    
}

// MARK: - GoogleGeocoderService Extension

public extension Geocoder.Google {
    
    /// The bounds parameter defines the latitude/longitude coordinates of the southwest and northeast corners.
    struct BoundingBox: Codable, CustomStringConvertible {
        var southwest: CLLocationCoordinate2D
        var northeast: CLLocationCoordinate2D
        
        public init(southwest: CLLocationCoordinate2D, northeast: CLLocationCoordinate2D) {
            self.southwest = southwest
            self.northeast = northeast
        }
        
        fileprivate var rawValue: String {
            "\(southwest.latitude),\(southwest.longitude)|\(northeast.latitude),\(northeast.longitude)"
        }
        
        public var description: String {
            rawValue
        }
        
    }
    
    /// A filter of one or more location types, separated by a pipe (|). If the parameter contains multiple location types, the API returns all addresses that match any of the types
    /// - `rooftop`: returns only the addresses for which Google has location information accurate down to street address precision.
    /// - `rangeInterpolated`: returns only the addresses that reflect an approximation (usually on a road) interpolated between two precise points (such as intersections).
    ///                       An interpolated range generally indicates that rooftop geocodes are unavailable for a street address.
    /// - `geometricCenter`: returns only geometric centers of a location such as a polyline (for example, a street) or polygon (region).
    /// - `approximate`: returns only the addresses that are characterized as approximate.
    enum LocationTypes: String, Codable, CustomStringConvertible {
        case rooftop = "ROOFTOP"
        case rangeInterpolated = "RANGE_INTERPOLATED"
        case geometricCenter = "GEOMETRIC_CENTER"
        case approximate = "APPROXIMATE"
        
        public static let all: [LocationTypes] = [.rooftop, .rangeInterpolated, .geometricCenter, approximate]

        public var description: String {
            rawValue.lowercased().replacingOccurrences(of: "_", with: "")
        }
    }
    
    /// In a Geocoding response, the Geocoding API can return address results restricted to a specific area.
    /// You can specify the restriction using the components filter.
    /// The following components may be used to influence results, but will not be enforced:
    /// - `route`: matches the long or short name of a route.
    /// - `locality`: matches against locality and sublocality types.
    /// - `administrativeArea` matches all the administrative_area levels.
    enum FilterTypes: String, CustomStringConvertible {
        case route = "route"
        case locality = "locality"
        case administrativeArea = "administrative_area"
        
        public static let all: [FilterTypes] = [.route, .locality, .administrativeArea]
        
        public var description: String {
            rawValue
        }
    }
    
}
