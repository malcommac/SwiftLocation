//
//  File.swift
//  
//
//  Created by daniele on 27/09/2020.
//

import Foundation
import CoreLocation

public extension Geocoder {
    
    class Apple: GeocoderServiceProtocol {
        
        // MARK: - Public Properties
        
        public private(set) var kind: GeocoderServiceKind = .apple

        /// Is request cancelled.
        public var isCancelled = false
        
        /// Underlying service operation.
        public private(set) var operation: GeocoderOperation
        
        /// Proximity region to better contextualize received results.
        public var proximityRegion: CLCircularRegion?
        
        /// Language.
        public var locale: Locale?
        
        // MARK: - Private Properties
        
        /// Geocoder service.
        private var geocoder = CLGeocoder()
        
        public var description: String {
            JSONStringify([
                "kind": kind.rawValue,
                "operation": operation.description,
                "proximityRegion": proximityRegion?.description ?? "",
                "locale": locale?.description ?? ""
            ])
        }
        
        // MARK: - Initialize
        
        /// Initialize to reverse geocode a pair of coordinates.
        ///
        /// - Parameters:
        ///   - coordinates: coordinates.
        ///   - locale: language to use.
        public init(coordinates: CLLocationCoordinate2D, locale: Locale? = nil) {
            self.operation = .geoAddress(coordinates)
            self.locale = locale
        }
        
        /// Initialize to forward geocode a given address.
        ///
        /// - Parameters:
        ///   - address: address to geocode.
        ///   - region: region to better contextualize the address.
        ///   - locale: language to use.
        public init(address: String, region: CLCircularRegion? = nil, locale: Locale? = nil) {
            self.operation = .getCoordinates(address)
            self.proximityRegion = region
            self.locale = locale
        }
        
        // MARK: - Service Functions
        
        public func execute(_ completion: @escaping ((Result<[GeoLocation], LocatorErrors>) -> Void)) {
            let completionHandler: CoreLocation.CLGeocodeCompletionHandler = { [weak self] (placemarks, error) in
                guard let self = self, !self.isCancelled else {
                    return
                }
                
                if let error = error { // something bad occurred
                    completion(.failure(.generic(error)))
                    return
                }
                
                let locations = GeoLocation.fromAppleList(placemarks)
                completion(.success(locations))
            }
            
            
            switch operation {
            case .geoAddress(let coordinates):
                let location = CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)
                geocoder.reverseGeocodeLocation(location, preferredLocale: locale, completionHandler: completionHandler)
                
            case .getCoordinates(let address):
                geocoder.geocodeAddressString(address, in: proximityRegion, completionHandler: completionHandler)
                
            }
            
        }
        
        /// Cancel the request.
        public func cancel() {
            self.isCancelled = true
            geocoder.cancelGeocode()
        }
        
        // MARK: - Codable
        
        enum CodingKeys: String, CodingKey {
            case kind, isCancelled, locale, operation, proximityRegionCenter, proximityRegionRadius, proximityRegionUUID
        }
        
        // Encodable protocol
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            try container.encode(kind, forKey: .kind)
            try container.encode(locale, forKey: .locale)
            try container.encode(operation, forKey: .operation)
            
            try container.encodeIfPresent(proximityRegion?.center, forKey: .proximityRegionCenter)
            try container.encodeIfPresent(proximityRegion?.radius, forKey: .proximityRegionRadius)
            try container.encodeIfPresent(proximityRegion?.identifier, forKey: .proximityRegionUUID)
        }
        
        // Decodable protocol
        required public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            self.kind = try container.decode(GeocoderServiceKind.self, forKey: .kind)
            self.locale = try container.decode(Locale.self, forKey: .locale)
            self.operation = try container.decode(GeocoderOperation.self, forKey: .operation)
            
            if let center = try container.decodeIfPresent(CLLocationCoordinate2D.self, forKey: .proximityRegionCenter),
               let radius = try container.decodeIfPresent(CLLocationDegrees.self, forKey: .proximityRegionCenter),
               let identifier = try container.decodeIfPresent(String.self, forKey: .proximityRegionUUID) {
                self.proximityRegion = CLCircularRegion(center: center, radius: radius, identifier: identifier)
            }
        }
        
    }
    
}
