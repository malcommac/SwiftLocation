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

public class LocationByIPRequest: ServiceRequest, Hashable {
    
    // MARK: - Typealiases -
    
    public typealias Data = Result<IPPlace,LocationManager.ErrorReason>
    public typealias Callback = ((Data) -> Void)
    
    // MARK: - Public Properties -
    
    /// Unique identifier of the request.
    public var id: LocationManager.RequestID
    
    /// Timeout of the request.
    public var timeout: Timeout.Mode?
    
    /// Last obtained valid value for request.
    public internal(set) var value: IPPlace?
    
    /// Service used
    public var service: LocationByIPRequest.Service {
        fatalError("Missing service property")
    }
        
    /// Timeout manager handles timeout events.
    internal var timeoutManager: Timeout? {
        didSet {
            // Also set the callback to receive timeout event; it will remove the request.
            timeoutManager?.callback = { interval in
                self.stop(reason: .timeout(interval), remove: true)
            }
        }
    }
    
    /// State of the request.
    public var state: RequestState = .idle
    
    /// Registered callbacks.
    public var observers = Observers<LocationByIPRequest.Callback>()

    // MARK: - Initialization -
    
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
        timeoutManager?.reset()
        dispatch(data: .failure(reason))
    }
    
    internal func dispatch(data: Data, andComplete complete: Bool = false) {
        DispatchQueue.main.async {
            self.observers.list.forEach {
                $0(data)
            }
            
            if complete {
                LocationManager.shared.removeIPLocationRequest(self)
            }
        }
    }
    
    public static func == (lhs: LocationByIPRequest, rhs: LocationByIPRequest) -> Bool {
        return lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
    
}
