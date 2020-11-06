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
        
    }
    
}