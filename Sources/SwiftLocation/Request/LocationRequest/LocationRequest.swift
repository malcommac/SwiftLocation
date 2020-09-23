//
//  LocationRequest.swift
//  SwiftLocation
//
//  Created by Daniele Margutti on 17/09/2020.
//

import Foundation
import CoreLocation

/// The following class define a single location request.
public class LocationRequest: RequestProtocol {    
    public typealias ProducedData = CLLocation
    
    /// Unique identifier of the request.
    public var uuid: Identifier = UUID().uuidString
    
    /// `true` if request is enabled.
    public var isEnabled: Bool = true

    /// Options for location
    public var options: LocationOptions

    /// Registered callbacks which receive events.
    public var subscriptions = [RequestDataCallback<DataCallback>]()
    
    /// Last valid received location from underlying service.
    /// NOTE: Until the first valid result value is `nil.`
    public private(set) var lastLocation: CLLocation?
    
    /// Return `true` if you want any error can cancel the request from the locator's queue.
    /// Return `false` to continue subscription even on error.
    ///
    /// The default implementation return `true` when subscription's mode is `single` and `false` for `continous` and `significant`.
    public var autoCancelOnError: Bool {
        switch options.subscription {
        case .continous, .significant:
            return false
        case .single:
            return true
        }
    }
    
    // MARK: - Private Properties
    
    /// Timeout timer.
    private var timeoutTimer: Timer?
     
    // MARK: - Initialization
    
    internal init() {
        self.options = LocationOptions()
    }
    
    public static func == (lhs: LocationRequest, rhs: LocationRequest) -> Bool {
        return lhs.uuid == rhs.uuid
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }
    
    // MARK: - Public Functions

    public func validateData(_ data: ProducedData) -> LocatorErrors? {
        guard isEnabled else {
            return .discardedData // request is not enabled so we'll discard data.
        }
        
        guard data.accuracy <= options.accuracy else {
            return .discardedData // accuracy level is below the minimum set
        }
        
        if let previousLocation = lastLocation {
            if let minDistance = options.minDistance,
               previousLocation.distance(from: data) > minDistance {
                return .discardedData // minimum distance since last location is not respected.
            }
            
            if let minInterval = options.minTimeInterval,
               previousLocation.timestamp.timeIntervalSince(Date()) >= minInterval {
                return .discardedData // minimum time interval since last location is not respected.
            }
        }
        
        return nil
    }

    public func startTimeoutIfNeeded() {
        guard let timeout = options.timeout, // has valid timeout settings
              timeout.canFireTimer, // can fire the timer (timeout is immediate or delayed with auth ok)
              timeoutTimer == nil else { // timer never started yet for this request
            return
        }
        
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: timeout.interval, repeats: false, block: { [weak self] timer in
            self?.dispatchData(.failure(.timeout))
            timer.invalidate()
        })
    }
    
    // MARK: - Private Data Validation Functions

}
