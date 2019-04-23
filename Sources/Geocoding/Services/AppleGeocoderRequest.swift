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
import CoreLocation

public class AppleGeocoderRequest: GeocoderRequest {

    // MARK: - Private Properties -
    
    /// Geocoder operation.
    private var operation: CLGeocoder?
    
    // MARK: - Overriden Functions -

    internal override func stop(reason: LocationManager.ErrorReason = .cancelled, remove: Bool) {
        self.operation?.cancelGeocode()
        super.stop(reason: reason, remove: true)
    }
    
    public override func start() {
        guard state.isRunning == false else {
            return
        }
        state = .running
        
        self.operation = CLGeocoder()
        startGeocoder()
    }
    
    // MARK: - Private Functions -
    
    private func startGeocoder() {
        let completionHandler: CoreLocation.CLGeocodeCompletionHandler = { [weak self] (placemarks, error) in
            guard let self = self else { return }
            if let error = error {
                self.stop(reason: .generic(error.localizedDescription), remove: true)
                return
            }
            let places = placemarks?.compactMap { Place(placemark: $0) } ?? []
            self.value = places
            self.dispatch(data: .success(places), andComplete: true)
        }
        
        switch operationType {
        case .geocoder:
            self.operation!.geocodeAddressString(address!, in: region, completionHandler: completionHandler)

        case .reverseGeocoder:
            // “Reverse Geocoding” allows one to find the name and details of a
            // point of interest using only the geographic coordinates.
            
            let location = CLLocation(latitude: coordinates!.latitude, longitude: coordinates!.longitude)
            if #available(iOS 11.0, *) {
                let locale = (options?.locale != nil ? Locale(identifier: options!.locale!) : nil)
                self.operation!.reverseGeocodeLocation(location, preferredLocale: locale, completionHandler: completionHandler)
            } else {
                self.operation!.reverseGeocodeLocation(location, completionHandler: completionHandler)
            }
        }
    }
    
}
