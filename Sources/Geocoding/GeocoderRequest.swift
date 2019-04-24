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

public class GeocoderRequest: ServiceRequest, Hashable {
    
    // MARK: - Typealiases -
    
    public typealias Data = Result<[Place],LocationManager.ErrorReason>
    public typealias Callback = ((Data) -> Void)
    
    // MARK: - Private Properties -
    
    /// Type of geocoding.
    internal let operationType: GeocoderRequest.OperationType
    
    /// Service related options.
    internal var options: Options?
    
    /// Last obtained valid value for request.
    public internal(set) var value: [Place]?

    /// Timeout manager handles timeout events.
    internal var timeoutManager: Timeout? {
        didSet {
            // Also set the callback to receive timeout event; it will remove the request.
            timeoutManager?.callback = { interval in
                self.stop(reason: .timeout(interval), remove: true)
            }
        }
    }
    
    // MARK: - Public Properties -
    
    public private(set) var observers = Observers<Callback>()

    /// Identifier of the request.
    public var id: LocationManager.RequestID
    
    /// State of the request.
    public internal(set) var state: RequestState = .idle
    
    /// Timeout set for request.
    public var timeout: Timeout.Mode?
    
    // MARK: - Private Geocoder Related Properties -

    internal let address: String?
    internal let region: CLRegion?
    internal let coordinates: CLLocationCoordinate2D?
    
    /// Is reverse geocoding operation?
    public var isReverse: Bool {
        return coordinates != nil
    }

    // MARK: - Initialization -

    internal init(address: String, region: CLRegion?) {
        self.operationType = .geocoder
        self.id = UUID().uuidString
        self.address = address
        self.region = region
        self.coordinates = nil
    }
    
    internal init(coordinates: CLLocationCoordinate2D) {
        self.operationType = .reverseGeocoder
        self.id = UUID().uuidString
        self.coordinates = coordinates
        self.address = nil
        self.region = nil
    }
    
    // MARK: - Public Functions -
    
    public func stop() {
        stop(reason: .cancelled, remove: true)
    }
    
    public func start() {
        timeoutManager?.startIfNeeded()
    }
    
    public func pause() { }
    
    // MARK: - Protocols Conformances -
    
    public static func == (lhs: GeocoderRequest, rhs: GeocoderRequest) -> Bool {
        return lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // MARK: - Internal Functions -
    
    internal func stop(reason: LocationManager.ErrorReason = .cancelled, remove: Bool) {
        timeoutManager?.reset()
        dispatch(data: .failure(reason))
    }
    
    internal func dispatch(data: Data, andComplete complete: Bool = false) {
        observers.list.forEach {
            $0(data)
        }
        
        if complete {
            LocationManager.shared.removeGeocoder(self)
        }
    }
    
}
