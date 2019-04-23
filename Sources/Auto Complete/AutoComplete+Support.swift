//
//  SwiftLocation - Efficient Location Tracking for iOS
//
//  Created by Daniele Margutti
//   - Web: https://www.danielemargutti.com
//   - Twitter: https://twitter.com/danielemargutti
//   - Mail: hello@danielemargutti.com
//
//  Copyright © 2019 Daniele Margutti. Licensed under MIT License.

import Foundation
import MapKit
import CoreLocation

public extension AutoCompleteRequest {
    
    /// Service to use.
    ///
    /// - apple: apple service.
    /// - google: google service.
    /// - openStreet: open streep map service.
    enum Service: CustomStringConvertible {
        case apple(Options?)
        case google(GoogleOptions)
        
        public static var all: [Service] {
            return [.apple(nil), .google(GoogleOptions(APIKey: ""))]
        }
        
        public var description: String {
            switch self {
            case .apple: return "Apple"
            case .google: return "Google"
            }
        }
    }
    
    /// Type of autocomplete operation.
    ///
    /// - partialSearch: it's a partial search operation. Usually it's used when you need to provide a search
    ///                  inside search boxes of the map. Once you have the full query or the address you can
    ///                  use a placeDetail search to retrive more info about the place.
    /// - placeDetail: when you have a full search query (from services like apple) or the place id (from service like google)
    ///                you can use this operation to retrive more info about the place.
    enum Operation: CustomStringConvertible {
        case partialSearch(String)
        case placeDetail(String)
        
        public static var all: [Operation] {
            return [.partialSearch(""),.placeDetail("")]
        }
        
        public var value: String {
            switch self {
            case .partialSearch(let v): return v
            case .placeDetail(let v): return v
            }
        }
        
        public var description: String {
            switch self {
            case .partialSearch: return "Partial Search"
            case .placeDetail: return "Place Detail"
            }
        }
    }
    
    class Options {
        
        // MARK: - Public Properties -
        
        /// Type of autocomplete operation
        /// By default is `.partialSearch`.
        internal var operation: Operation = .partialSearch("")
        
        /// The region that defines the geographic scope of the search.
        /// Use this property to limit search results to the specified geographic area.
        /// The default value is nil which for `AppleOptions` means a region that spans the entire world.
        /// For other services when nil the entire parameter will be ignored.
        public var region: MKCoordinateRegion?
        
        // Use this property to determine whether you want completions that represent points-of-interest
        // or whether completions might yield additional relevant query strings.
        // The default value is set to `.locationAndQueries`:
        // Points of interest and query suggestions.
        /// Specify this value when you want both map-based points of interest and common
        /// query terms used to find locations. For example, the search string “cof” yields a completion for “coffee”.
        public var filter: MKLocalSearchCompleter.FilterType = .locationsAndQueries
        
        // MARK: - Private Methods -
        
        /// Return server parameters to compose the url.
        ///
        /// - Returns: URL
        internal func serverParams() -> [URLQueryItem] {
            return []
        }
        
    }

    class GoogleOptions: Options {
        
        /// API Key for searvice.
        public var APIKey: String?
        
        /// Restrict results from a Place Autocomplete request to be of a certain type.
        /// See: https://developers.google.com/places/web-service/autocomplete#place_types
        ///
        /// - geocode: return only geocoding results, rather than business results.
        /// - address: return only geocoding results with a precise address.
        /// - establishment: return only business results.
        /// - regions: return any result matching the following types: `locality, sublocality, postal_code, country, administrative_area_level_1, administrative_area_level_2`
        /// - cities: return results that match `locality` or `administrative_area_level_3`.
        public enum PlaceTypes: String {
            case geocode
            case address
            case establishment
            case regions
            case cities
        }
        
        /// Restrict results to be of certain type, `nil` to ignore this filter.
        public var placeTypes: Set<PlaceTypes>? = nil
        
        /// The distance (in meters) within which to return place results.
        /// Note that setting a radius biases results to the indicated area,
        /// but may not fully restrict results to the specified area.
        /// More info: https://developers.google.com/places/web-service/autocomplete#location_biasing
        /// and https://developers.google.com/places/web-service/autocomplete#location_restrict.
        public var radius: Float? = nil
        
        /// Returns only those places that are strictly within the region defined by location and radius.
        /// This is a restriction, rather than a bias, meaning that results outside this region will
        /// not be returned even if they match the user input.
        public var strictBounds: Bool = false
        
        /// The language code, indicating in which language the results should be returned, if possible.
        public var locale: String?
        
        /// A grouping of places to which you would like to restrict your results up to 5 countries.
        /// Countries must be added in ISO3166-1_alpha-2 version you can found:
        /// https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2.
        public var countries: Set<String>?
        
        public init(APIKey: String?) {
            self.APIKey = APIKey
        }
        
        // MARK: - Private Functions -
        
        internal override func serverParams() -> [URLQueryItem] {
            var list = [URLQueryItem]()
            
            if let placeTypes = self.placeTypes {
                list.append(URLQueryItem(name: "types", value: placeTypes.map { $0.rawValue }.joined(separator: ",")))
            }
            
            if let radius = self.radius {
                list.append(URLQueryItem(name: "radius", value: String(radius)))
            }
            
            if self.strictBounds == true {
                list.append(URLQueryItem(name: "strictbounds", value: nil))
            }
            
            if let locale = self.locale {
                list.append(URLQueryItem(name: "language", value: locale.lowercased()))
            }
            
            if let countries = self.countries {
                list.append(URLQueryItem(name: "components", value: countries.map {
                    return "country:\($0)"
                    }.joined(separator: "|")))
            }
            
            return list
        }
        
    }
    
}
