//
//  File.swift
//  
//
//  Created by daniele on 27/09/2020.
//

import Foundation
import CoreLocation

public class AppleGeocoderService: GeocoderServiceProtocol {
    public var isCancelled = false
    
    public private(set) var operation: GeocoderOperation
    public var proximityRegion: CLRegion?
    public var locale: Locale?
    
    private var geocoder = CLGeocoder()
    
    public init(coordinates: CLLocationCoordinate2D, locale: Locale? = nil) {
        self.operation = .geoAddress(coordinates)
        self.locale = locale
    }
    
    public init(address: String, region: CLRegion? = nil, locale: Locale? = nil) {
        self.operation = .getCoordinates(address)
        self.proximityRegion = region
        self.locale = locale
    }
    
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
    
    public func cancel() {
        self.isCancelled = true
        geocoder.cancelGeocode()
    }
    
}
