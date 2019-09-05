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

/// BeaconsRequest represent the request entity which contains a reference
/// to subscriber, a list of contraints to evaluate.
/// A reference is keep on queue until its valid and you can manage the subscription
// directly from here.
public class BeaconsRequest: ServiceRequest, Hashable {
    
    // MARK: - Typealiases -

    public typealias Data = Result<[CLBeacon], LocationManager.ErrorReason>
    public typealias Callback = ((Data) -> Void)
    
    // MARK: - Private Properties -
    
    /// Timeout manager handles timeout events.
    internal var timeoutManager: Timeout? {
        didSet {
            // Also set the callback to receive timeout event; it will remove the request.
            timeoutManager?.callback = { interval in
                self.stop(reason: .requiredBeaconsNotFound(timeout: interval, last: self.lastAbsoluteBeacons), remove: true)
            }
        }
    }
    
    // MARK: - Public Properties -
    
    /// Last obtained valid value for request.
    public internal(set) var value: [CLBeacon]?

    /// Type of timeout set.
    public var timeout: Timeout.Mode? {
        return timeoutManager?.mode
    }
    
    /// Unique identifier of the request.
    public var id: ServiceRequest.RequestID
    

    /// Proximity identifier of iBeacon to monitor
    public var proximityUUID: UUID
    
    /// Minimum accuracy level required to receive valid locations in this request.
    /// If a timeout is set and no events are received inside the interval range the
    /// request will fails with `timeout` error and it will be removed from queue.
    public var accuracy: LocationManager.Accuracy = .any
    
//    /// The minimum distance (measured in meters) a device must move horizontally before an update event is generated.
//    /// If `kCLDistanceFilterNone` this constraint will be not applied when receiving events for this request.
//    public var distance: CLLocationDistance = kCLDistanceFilterNone
//
//    /// The location manager uses the information in this property as a cue to determine
//    /// when location updates may be automatically paused.
//    /// Pausing updates gives the system the opportunity to save power in situations where
//    /// the user's location is not likely to be changing.
//    public var activityType: CLActivityType = .other
    
    /// Callbacks called once a new location or error is received.
    public var observers = Observers<BeaconsRequest.Callback>()
    
    /// Last received location (even if not valid).
    public private(set) var lastAbsoluteBeacons: [CLBeacon]?
    
    /// Last valid received location (only if meet request's criteria).
    public private(set) var lastBeacons: [CLBeacon]?

    /// Current state of the request.
    public internal(set) var state: RequestState = .idle
    
    /// Subscription mode used to receive events.
    public internal(set) var subscription: Subscription = .oneShot
    
    /// You can provide a custom validation rule which overrides the default settings for
    /// accuracy and time threshold. You will receive in this callback any location retrived
    /// from the GPS system and you can decide if it's valid to be propagated or not.
    /// Inside the callback you will receive the location and the time interval between now
    /// and the time you have received the location.
    public var customValidation: (([CLBeacon]) -> Bool)? = nil
    
    // MARK: - Initialization -
    
    internal init(proximityUUID: UUID) {
        self.id = UUID().uuidString
        self.proximityUUID = proximityUUID
    }
    
    // MARK: - Public Methods -
    
    /// Stop the request and remove it from queue.
    /// Request will be marked as `expired`.
    public func stop() {
        stop(reason: .cancelled, remove: true)
    }
    
    /// Complete a request with given location.
    /// If subscription mode is continous the event will be passed to callbacks and
    /// request still alive receiving other events; in case of one shot request
    /// it fulfill the request itself and remove it from queue.
    ///
    /// - Parameter location: location to pass.
    internal func complete(beacons: [CLBeacon]) {
        lastBeacons = beacons
        guard state.canReceiveEvents && beaconsSatisfyRequest(beacons) else {
            return // ignore events
        }
        
        // We can stop the timeout timer, the first valid event has been received.
        timeoutManager?.reset()
        value = beacons
        dispatch(data: .success(beacons)) // dispatch to callbacks
        if subscription == .oneShot { // one shot events will be removed
            LocationManager.shared.removeBeaconTracking(self)
        }
    }
    
    /// Mark the request as paused. It still remain in queue but any received event (valid or not)
    /// will be discarded and not passed to the subscribed callbacks.
    public func pause()  {
        state = .paused
    }
    
    /// Start/restart a [paused/idle/expired] request.
    public func start() {
        LocationManager.shared.startBeaconTracking(self) // add to queue
    }
    
    // MARK: - Protocols Conformances -
    
    public static func == (lhs: BeaconsRequest, rhs: BeaconsRequest) -> Bool {
        return lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // MARK: - Internal Methods -
    
    /// Stop a request with passed error reason and optionally remove it from queue.
    ///
    /// - Parameters:
    ///   - reason: reason of failure.
    ///   - remove: `true` to also remove it from queue.
    internal func stop(reason: LocationManager.ErrorReason = .cancelled, remove: Bool) {
        defer {
            if remove {
                LocationManager.shared.removeBeaconTracking(self)
            }
        }
        timeoutManager?.reset()
        dispatch(data: .failure(reason))
    }
    
    /// Dispatch received events to all callbacks.
    ///
    /// - Parameter data: data to pass.
    internal func dispatch(data: Data) {
        observers.list.forEach {
            $0(data)
        }
    }
    
    /// Return `true` if received location satisfy the constraint of the request and can be dispatched to its observers.
    ///
    /// - Parameter location: location to evaluate.
    /// - Returns: `true` if valid, `false` otherwise.
    private func beaconsSatisfyRequest(_ beacons: [CLBeacon]) -> Bool {
//        guard location.timestamp > (lastBeacons?.first.timestamp ?? Date.distantPast) else {
//            return false // timestamp of the location is older than the latest we got. We can ignore it.
//        }
        
        if let customValidationRule = customValidation {
            // overridden by custom validator rule
            return customValidationRule(beacons)
        }
        
//        guard location.horizontalAccuracy < accuracy.value else {
//            return false // accuracy is not enough
//        }
        
//        guard location.timestamp.timeIntervalSinceNow <= accuracy.interval else {
//            return false // not too much time is passed since the event itself.
//        }
//
//        if let lastLoc = lastLocation, distance != kCLDistanceFilterNone {
//            let distanceWithPrevious = lastLoc.distance(from: location)
//            guard distanceWithPrevious >= distance else {
//                return false // minimum distance not found
//            }
//        }
        
        return true
    }
    
    /// Restart a request which are not paused.
    internal func switchToRunningIfNotPaused() {
        switch state {
        case .paused:
            break
        default:
            state = .running
        }
    }
    
}

// MARK: - Subscription -

public extension BeaconsRequest {
    
    /// Type of subscription for events.
    ///
    /// - oneShot: one shot subscription. Once fulfilled or rejected request will be removed automatically.
    /// - continous: continous subscription still produces events (error or valid locations) until it will be removed manually.
    /// - significant: significant subsription sitll produces events (error or valid significant location) until removed.
    enum Subscription: CustomStringConvertible {
        case oneShot
        case continous
        
        public static var all: [Subscription] {
            return [.oneShot, .continous]
        }
        
        public var description: String {
            switch self {
            case .oneShot:      return "oneShot"
            case .continous:    return "continous"
            }
        }
    }
    
}
