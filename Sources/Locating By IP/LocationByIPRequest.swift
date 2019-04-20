//
//  LocationByIPRequest.swift
//  SwiftLocation
//
//  Created by dan on 19/04/2019.
//  Copyright © 2019 SwiftLocation. All rights reserved.
//

import Foundation

public class LocationByIPRequest: ServiceRequest, Hashable {
    
    // MARK: - Typealiases -
    
    public typealias Data = Result<IPPlace,LocationManager.ErrorReason>
    public typealias Callback = ((Data) -> Void)
    
    public var id: LocationManager.RequestID
    
    public var timeout: Timeout.Mode?
        
    /// Timeout manager handles timeout events.
    internal var timeoutManager: Timeout? {
        didSet {
            // Also set the callback to receive timeout event; it will remove the request.
            timeoutManager?.callback = { interval in
                self.stop(reason: .timeout(interval), remove: true)
            }
        }
    }
    
    public var state: RequestState = .idle
    
    public var callbacks = Observers<LocationByIPRequest.Callback>()

    init() {
        self.id = UUID().uuidString
    }
    
    public func stop() {

    }
    
    public func start() {
        
    }
    
    public func pause() {
        
    }
    
    internal func stop(reason: LocationManager.ErrorReason = .cancelled, remove: Bool) {
        state = .expired
        timeoutManager?.reset()
        dispatch(data: .failure(reason))
    }
    
    internal func dispatch(data: Data, andComplete complete: Bool = false) {
        callbacks.list.forEach {
            $0(data)
        }
        
        if complete {
            state = .expired
            LocationManager.shared.removeIPLocationRequest(self)
        }
    }
    
    public static func == (lhs: LocationByIPRequest, rhs: LocationByIPRequest) -> Bool {
        return lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
    
}
