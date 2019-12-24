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

public class HeadingRequest: ServiceRequest, Hashable {
    
    // MARK: - Typealiases -
    
    public typealias Data = Result<CLHeading,LocationManager.ErrorReason>
    public typealias Callback = ((Data) -> Void)
    
    /// Typealias for accuracy, measured in degree
    public typealias AccuracyDegree = CLLocationDirection
    
    // MARK: - Public Properties -
    
    /// Unique identifier of the request.
    public var id: LocationManager.RequestID
    
    /// Timeout of the request. Not applicable for heading request.
    public var timeout: Timeout.Mode? = nil
    
    /// State of the request.
    public var state: RequestState = .idle
    
    /// Accuracy degree interval for the request. If `nil` no filter is applied.
    public var accuracy: AccuracyDegree?
    
    /// Minimum interval between each dispatched heading. If `nil` no filter is applied.
    public var minInterval: TimeInterval?
    
    /// Callbacks called once a new location or error is received.
    public var observers = Observers<HeadingRequest.Callback>()
    
    /// Last obtained valid value for request.
    public internal(set) var value: CLHeading?
    
    // MARK: - Initialization -
    
    internal init(accuracy: AccuracyDegree?, minInterval: TimeInterval?) {
        self.id = UUID().uuidString
        self.accuracy = accuracy
        self.minInterval = minInterval
    }
    
    // MARK: - Public Functions -
    
    public func stop() {
        stop(reason: .cancelled, remove: true)
    }
    
    public func start() {
        self.state = .running
    }
    
    public func pause() {
        self.state = .paused
    }
    
    // MARK: - Protocol Conformances -
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
    
    public static func == (lhs: HeadingRequest, rhs: HeadingRequest) -> Bool {
        return lhs.id == rhs.id
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
                LocationManager.shared.removeHeadingRequest(self)
            }
        }
        dispatch(data: .failure(reason))
    }
    
    internal func complete(heading: CLHeading) {
        guard state.canReceiveEvents && headingSatisfyRequest(heading) else {
            return // ignore events
        }
        
        value = heading
        dispatch(data: .success(heading)) // dispatch to callbacks
    }
    
    private func headingSatisfyRequest(_ heading: CLHeading) -> Bool {
        
        if let minInterval = minInterval {
            if heading.timestamp.timeIntervalSince1970 -
                (value?.timestamp ?? Date.distantPast).timeIntervalSince1970 < minInterval {
                return false // minimum timestamp interval not respected
            }
        }
        
        if let minAccuracy = accuracy {
            if heading.headingAccuracy < minAccuracy {
                return false // minimum accuracy not respected
            }
        }
        
        return true
    }
    
    /// Dispatch received events to all callbacks.
    ///
    /// - Parameter data: data to pass.
    internal func dispatch(data: Data) {
        observers.list.forEach {
            $0(data)
        }
    }
}
