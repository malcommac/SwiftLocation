//
//  HeadingRequest.swift
//  SwiftLocation
//
//  Created by dan on 20/04/2019.
//  Copyright © 2019 SwiftLocation. All rights reserved.
//

import Foundation
import CoreLocation

public class HeadingRequest: ServiceRequest, Hashable {
    
    // MARK: - Typealiases -
    
    public typealias Data = Result<CLHeading,LocationManager.ErrorReason>
    public typealias Callback = ((Data) -> Void)
    
    /// Typealias for accuracy, measured in degree
    public typealias AccuracyDegree = CLLocationDirection
    
    public var id: LocationManager.RequestID
    
    public var timeout: Timeout.Mode?
    
    public var state: RequestState = .idle
    
    public var accuracy: AccuracyDegree?
    
    public var minInterval: TimeInterval?
    
    /// Callbacks called once a new location or error is received.
    public var callbacks = Observers<HeadingRequest.Callback>()
    
    internal init(accuracy: AccuracyDegree?, minInterval: TimeInterval?) {
        self.id = UUID().uuidString
        self.accuracy = accuracy
        self.minInterval = minInterval
    }
    
    public func stop() {
        stop(reason: .cancelled, remove: true)
    }
    
    public func start() {
        self.state = .running
    }
    
    public func pause() {
        self.state = .paused
    }
    
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
}
