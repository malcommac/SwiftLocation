//
//  Geocoder+Apple.swift
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
    
    class Apple: GeocoderServiceProtocol {
        
        // MARK: - Public Properties
        
        /// NOTE: It's ignored for this service.
        public var timeout: TimeInterval?

        /// Is request cancelled.
        public var isCancelled = false
        
        /// Operation to perform.
        /// NOTE: Usually it's set via init and you should not change it.
        public var operation: GeocoderOperation
        
        /// Proximity region to better contextualize received results.
        public var proximityRegion: CLCircularRegion?
        
        /// Language as Locale identifier string.
        public var locale: String?
        
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
            self.locale = locale?.identifier
        }
        
        /// Initialize to reverse geocode a pair of coordinates.
        /// - Parameters:
        ///   - lat: latitude.
        ///   - lng: longitude.
        ///   - locale: locale.
        public convenience init(lat: CLLocationDegrees, lng: CLLocationDegrees, locale: Locale? = nil) {
            let coordinates = CLLocationCoordinate2D(latitude: lat, longitude: lng)
            self.init(coordinates: coordinates, locale: locale)
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
            self.locale = locale?.identifier
        }
        
        // MARK: - Service Functions
        
        public func execute(_ completion: @escaping ((Result<[GeoLocation], LocationError>) -> Void)) {
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
                let localeInstance = (locale != nil ? Locale(identifier: locale!) : nil)
                geocoder.reverseGeocodeLocation(location, preferredLocale: localeInstance, completionHandler: completionHandler)
                
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
