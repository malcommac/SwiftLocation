//
//  File.swift
//  
//
//  Created by daniele on 29/09/2020.
//

import Foundation
import CoreLocation
import MapKit

public extension Autocomplete {
    
    class Here: JSONNetworkHelper, AutocompleteProtocol {
        
        public private(set) var kind: AutocompleteKind = .here

        // MARK: - Public Properties
        
        /// Timeout interval for request.
        public var timeout: TimeInterval = 5
        
        /// API Key
        /// See https://developers.google.com/places/web-service/get-api-key.
        public var APIKey: String
        
        /// Search within a geographic area. This is a hard filter. Results will be returned if they are located within the specified area.
        ///
        /// NOTE: Value is not applicable for `.addressDetail`
        public var limitResults: Limit?
        
        /// Maximum number of results to be returned.
        ///
        /// NOTE: Value is not applicable for `.addressDetail`
        public var limit: Int?
        
        /// Select the language to be used for result rendering from a list of BCP47 compliant Language Codes.
        public var locale: String?
        
        /// Callback to call at the end of the operation.
        private var callback: ((Result<[Autocomplete.Data], LocatorErrors>) -> Void)?
        
        // MARK: - Private Properties
        
        /// Type of autocomplete operation
        private let operation: AutocompleteOp
        
        // MARK: - Initialization
        
        /// Search for matches of a partial search address.
        /// Returned values is an array of `Autocomplete.AutocompleteResult.partial`.
        ///
        /// - Parameters:
        ///   - partialMatch: partial match of the address.
        ///   - region: Use this property to limit search results to the specified geographic area.
        public init(partialMatches partialAddress: String, limit: Limit, APIKey: String) {
            self.operation = .partialMatch(partialAddress)
            self.limitResults = limit
            self.APIKey = APIKey
            
            super.init()
        }
        
        /// If you want to get details of a full address, typically returned from partial match search.
        ///
        /// - Parameters:
        ///   - fullAddress: full address.
        ///   - region: Use this property to limit search results to the specified geographic area.
        public init(detailsFor fullAddress: String, APIKey: String) {
            self.operation = .addressDetail(fullAddress)
            self.APIKey = APIKey
            
            super.init()
        }
        
        /// If you want to get details of a place identified by an HERE id.
        ///
        /// - Parameters:
        ///   - lookupByID: identifier of the place.
        ///   - region: Use this property to limit search results to the specified geographic area.
        public init(lookupByID hereID: String, APIKey: String) {
            self.operation = .addressDetail(":ID:\(hereID)")
            self.APIKey = APIKey
            
            super.init()
        }
        
        // MARK: - Public Functions
        
        public func execute(_ completion: @escaping ((Result<[Autocomplete.Data], LocatorErrors>) -> Void)) {
            do {
                
                self.callback = completion
                let request = try buildRequest()
                
                switch operation {
                case .partialMatch:     executePartialAddressSearch(request)
                case .addressDetail:    executeAddressDetails(request)
                }
            } catch {
                completion(.failure(LocatorErrors.internalError))
            }
        }
        
        // MARK: - Private Function
        
        private func executePartialAddressSearch(_ request: URLRequest) {
            executeDataRequest(request: request, validateResponse: nil) { [weak self] result in
                guard let self = self else { return }
                
                do {
                    switch result {
                    case .failure(let error):
                        self.callback?(.failure(error))
                    case .success(let data):
                        guard let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
                            self.callback?(.failure(.parsingError))
                            return
                        }
                        
                        let message: String? = json.valueForKeyPath(keyPath: "message") ?? json.valueForKeyPath(keyPath: "error_description")
                        if (message?.isEmpty ?? true) == false {
                            self.callback?(.failure(.other(message!)))
                            return
                        }
                        
                        let places = PartialAddressMatch.fromHereList( json.valueForKeyPath(keyPath: "items") )
                        self.callback?(.success(places))
                    }
                } catch {
                    self.callback?(.failure(.other(error.localizedDescription)))
                }
            }
        }
        
        private func executeAddressDetails(_ request: URLRequest) {
            executeDataRequest(request: request, validateResponse: nil) { result in
                switch result {
                case .failure(let error):
                    self.callback?(.failure(error))
                case .success(let data):
                    do {
                        let rawJSON = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
                        guard let json = rawJSON as? [String: Any] else {
                            self.callback?(.failure(.parsingError))
                            return
                        }
                        
                        // Error catching
                        let message: String? = json.valueForKeyPath(keyPath: "message") ?? json.valueForKeyPath(keyPath: "error_description")
                        if (message?.isEmpty ?? true) == false {
                            self.callback?(.failure(.other(message!)))
                            return
                        }
                        
                        if let list: [[String: Any]] = json.valueForKeyPath(keyPath: "items") {
                            // multiple results (coming from geocode)
                            let places = GeoLocation.fromHereList(list).map({ Autocomplete.Data.place($0) })
                            self.callback?(.success(places))
                            
                        } else if let place = GeoLocation(hereJSON: json).map({ Autocomplete.Data.place($0) }) { // single result
                            self.callback?(.success([place]))
                        }
                    } catch {
                        self.callback?(.failure(.other(error.localizedDescription)))
                    }
                }
            }
        }
        
        private func requestURL() -> URL {
            switch operation {
            case .partialMatch:
                return URL(string: "https://autosuggest.search.hereapi.com/v1/autosuggest")!
                
            case .addressDetail(let address):
                if address.starts(with: ":ID:") {
                    return URL(string: "https://lookup.search.hereapi.com/v1/lookup")!
                } else {
                    return URL(string: "https://geocode.search.hereapi.com/v1/geocode")!
                }
            }
        }
        
        private func buildRequest() throws -> URLRequest {
            // Options
            var queryItems = [URLQueryItem]()
            queryItems.append(URLQueryItem(name: "apiKey", value: APIKey))
            
            if let limit = limitResults { // at/in are mutually exclusive
                if case .proximity = limit {
                    queryItems.appendIfNotNil(URLQueryItem(name: "at", optional: limitResults?.serverValue))
                } else {
                    queryItems.appendIfNotNil(URLQueryItem(name: "in", optional: limitResults?.serverValue))
                }
            }
            queryItems.appendIfNotNil(URLQueryItem(name: "limit", optional: (limit != nil ? String(limit!) : nil)))
            queryItems.appendIfNotNil(URLQueryItem(name: "lang", optional: locale))
            
            switch operation {
            case .partialMatch(let partialAddress):
                queryItems.append(URLQueryItem(name: "q", value: partialAddress))
            case .addressDetail(let address):
                if address.starts(with: ":ID:") {
                    queryItems.append(URLQueryItem(name: "id", value: address.replacingOccurrences(of: ":ID:", with: "")))
                } else {
                    queryItems.append(URLQueryItem(name: "q", value: address))
                }
            }
            
            // Generate url
            var urlComponents = URLComponents(url: requestURL(), resolvingAgainstBaseURL: false)
            urlComponents?.queryItems = queryItems
            guard let fullURL = urlComponents?.url else {
                throw LocatorErrors.internalError
            }
            
            let request = URLRequest(url: fullURL, cachePolicy: .useProtocolCachePolicy, timeoutInterval: timeout)
            print(request)
            return request
        }
        
        // MARK: - Codable
        
        enum CodingKeys: String, CodingKey {
            case operation, timeout, APIKey, limitResults, limit, locale
        }
        
        // Encodable protocol
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(operation, forKey: .operation)
            try container.encode(timeout, forKey: .timeout)
            try container.encode(APIKey, forKey: .APIKey)
            try container.encodeIfPresent(limitResults, forKey: .limitResults)
            try container.encodeIfPresent(limit, forKey: .limit)
            try container.encodeIfPresent(locale, forKey: .locale)
        }
        
        // Decodable protocol
        required public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            self.operation = try container.decode(AutocompleteOp.self, forKey: .operation)
            self.timeout = try container.decode(TimeInterval.self, forKey: .timeout)
            self.APIKey = try container.decode(String.self, forKey: .APIKey)
            self.limitResults = try container.decodeIfPresent(Limit.self, forKey: .limitResults)
            self.limit = try container.decodeIfPresent(Int.self, forKey: .limit)
            self.locale = try container.decodeIfPresent(String.self, forKey: .locale)
        }
        
    }
    
}

// MARK: - Autocomplete.Here Structures

public extension Autocomplete.Here {
    
    /// Search within a geographic area. This is a hard filter. Results will be returned if they are located within the specified area.
    /// - `countryCodes`: a country (or multiple countries), provided as comma-separated ISO 3166-1 alpha-3 country codes.
    /// - `circle`: a circular area, provided as latitude, longitude, and radius (in meters).
    /// - `boundingBox`: a bounding box, provided as west longitude, south latitude, east longitude, north latitude.
    enum Limit: Codable {
        case countryCodes([String])
        case circle(CLCircularRegion)
        case boundingBox(HereBoundingBox)
        case proximity(CLLocationCoordinate2D)
        
        internal var serverValue: String {
            switch self {
            case .countryCodes(let codes): // countryCode:CAN,MEX,USA
                return "countryCode:\(codes.map({ $0.uppercased() }).joined(separator:","))"
                
            case .circle(let circle): // circle:52.53,13.38;r=10000
                return "circle:\(circle.center.latitude),\(circle.center.longitude);r=\(circle.radius)"
                
            case .boundingBox(let bbox):
                return bbox.serverValue
                
            case .proximity(let coordinates):
                return coordinates.serverValue
                
            }
        }
        
        // MARK: - Private Properties
        
        private var kind: Int {
            switch self {
            case .countryCodes: return 0
            case .circle:       return 1
            case .boundingBox:  return 2
            case .proximity:    return 3
            }
        }
        
        // MARK: - Codable
        
        enum CodingKeys: String, CodingKey {
            case kind, countryCodes, circularRegionCenter, circularRegionRadius, circularRegionID, boundingBox, proximityCoordinates
        }
        
        // Encodable protocol
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(kind, forKey: .kind)

            switch self {
            case .countryCodes(let cCodes):
                try container.encode(cCodes, forKey: .countryCodes)
            case .circle(let region):
                try container.encode(region.center, forKey: .circularRegionCenter)
                try container.encode(region.radius, forKey: .circularRegionRadius)
                try container.encode(region.identifier, forKey: .circularRegionID)
            case .boundingBox(let bbox):
                try container.encode(bbox, forKey: .boundingBox)
            case .proximity(let coordinates):
                try container.encode(coordinates, forKey: .proximityCoordinates)
            }
            
        }
        
        // Decodable protocol
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
         
            switch try container.decode(Int.self, forKey: .kind) {
            case 0:
                let cCodes = try container.decode([String].self, forKey: .countryCodes)
                self = .countryCodes(cCodes)
                
            case 1:
                let cCenter = try container.decode(CLLocationCoordinate2D.self, forKey: .circularRegionCenter)
                let cRadius = try container.decode(CLLocationDegrees.self, forKey: .circularRegionRadius)
                let cIdentifier = try container.decode(String.self, forKey: .circularRegionID)
                self = .circle(CLCircularRegion(center: cCenter, radius: cRadius, identifier: cIdentifier))
            
            case 2:
                let bBox = try container.decode(HereBoundingBox.self, forKey: .boundingBox)
                self = .boundingBox(bBox)
                
            case 3:
                let coordinates = try container.decode(CLLocationCoordinate2D.self, forKey: .proximityCoordinates)
                self = .proximity(coordinates)
                
            default:
                fatalError("Failed to decode Here Limit")
            }
        }
        
    }
    
    struct HereBoundingBox: Codable {
        let westLong: CLLocationDegrees
        let southLat: CLLocationDegrees
        let eastLong: CLLocationDegrees
        let northLat: CLLocationDegrees
        
        internal var serverValue: String {
            // format: bbox:{west longitude},{south latitude},{east longitude},{north latitude}
            // Example: bbox:13.08836,52.33812,13.761,52.6755
            return "bbox:\(westLong),\(southLat),\(eastLong),\(northLat)"
        }
        
    }
    
}

// MARK: - CLLocationCoordinate2D

fileprivate extension CLLocationCoordinate2D {
    
    var hereWSParameter: String {
        return "\(latitude),\(longitude)"
    }
    
}
