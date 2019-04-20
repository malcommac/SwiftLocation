//
//  LocationRequest.swift
//  SwiftLocation
//
//  Created by dan on 14/04/2019.
//  Copyright © 2019 SwiftLocation. All rights reserved.
//

import Foundation
import CoreLocation

/// LocationRequest represent the request entity which contains a reference
/// to subscriber, a list of contraints to evaluate.
/// A reference is keep on queue until its valid and you can manage the subscription
// directly from here.
public class LocationRequest: ServiceRequest, Hashable {
    
    // MARK: - Typealiases -

    public typealias Data = Result<CLLocation,LocationManager.ErrorReason>
    public typealias Callback = ((Data) -> Void)
    
    // MARK: - Private Properties -
    
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
    
    /// Type of timeout set.
    public var timeout: Timeout.Mode? {
        return timeoutManager?.mode
    }
    
    /// Unique identifier of the request.
    public var id: ServiceRequest.RequestID
    
    /// Minimum accuracy level required to receive valid locations in this request.
    /// If a timeout is set and no events are received inside the interval range the
    /// request will fails with `timeout` error and it will be removed from queue.
    public var accuracy: LocationManager.Accuracy = .any
    
    /// Callbacks called once a new location or error is received.
    public var callbacks = Observers<LocationRequest.Callback>()
    public private(set) var lastLocation: CLLocation?
    
    /// Current state of the request.
    public internal(set) var state: RequestState = .idle
    
    /// Subscription mode used to receive events.
    public internal(set) var subscription: Subscription = .oneShot
    
    // MARK: - Initialization -
    
    internal init() {
        self.id = UUID().uuidString
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
    public func complete(location: CLLocation) {
        guard state.canReceiveEvents && locationSatisfyRequest(location) else {
            return // ignore events
        }
        
        // We can stop the timeout timer, the first valid event has been received.
        timeoutManager?.reset()
        dispatch(data: .success(location)) // dispatch to callbacks
        if subscription == .oneShot { // one shot events will be removed
            LocationManager.shared.removeLocation(self)
        }
    }
    
    /// Mark the request as paused. It still remain in queue but any received event (valid or not)
    /// will be discarded and not passed to the subscribed callbacks.
    public func pause()  {
        state = .paused
    }
    
    /// Start/restart a [paused/idle/expired] request.
    public func start() {
        guard state.isRunning == false else {
            return
        }
        state = (LocationManager.state == .available ? .running : .idle) // change the state
        LocationManager.shared.startLocation(self) // add to queue
    }
    
    // MARK: - Protocols Conformances -
    
    public static func == (lhs: LocationRequest, rhs: LocationRequest) -> Bool {
        return lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // MARK: - Internal Methods -
    
    /// Stop a request with passed error reason and optionally remvoe it from queue.
    ///
    /// - Parameters:
    ///   - reason: reason of failure.
    ///   - remove: `true` to also remove it from queue.
    internal func stop(reason: LocationManager.ErrorReason = .cancelled, remove: Bool) {
        defer {
            if remove {
                LocationManager.shared.removeLocation(self)
            }
        }
        timeoutManager?.reset()
        state = .expired
        dispatch(data: .failure(reason))
    }
    
    /// Dispatch received events to all callbacks.
    ///
    /// - Parameter data: data to pass.
    internal func dispatch(data: Data) {
        callbacks.list.forEach {
            $0(data)
        }
    }
    
    /// Return `true` if received location satisfy the constraint of the request and can be dispatched to its observers.
    ///
    /// - Parameter location: location to evaluate.
    /// - Returns: `true` if valid, `false` otherwise.
    private func locationSatisfyRequest(_ location: CLLocation) -> Bool {
        guard location.timestamp > (lastLocation?.timestamp ?? Date.distantPast) else {
            return false // timestamp of the location is older than the latest we got. We can ignore it.
        }
        
        guard location.horizontalAccuracy < accuracy.value else {
            return false // accuracy is not enough
        }
        
        guard location.timestamp.timeIntervalSinceNow <= accuracy.interval else {
            return false // not too much time is passed since the event itself.
        }
        
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

public extension LocationRequest {
    
    /// Type of subscription for events.
    ///
    /// - oneShot: one shot subscription. Once fulfilled or rejected request will be removed automatically.
    /// - continous: continous subscription still produces events (error or valid locations) until it will be removed manually.
    /// - significant: significant subsription sitll produces events (error or valid significant location) until removed.
    enum Subscription {
        case oneShot
        case continous
        case significant
    }
    
    
}
