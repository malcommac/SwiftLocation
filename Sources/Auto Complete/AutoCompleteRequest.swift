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

public class AutoCompleteRequest: NSObject, ServiceRequest {
    
    // MARK: - Typealiases -
    
    public typealias Data = Result<[PlaceMatch],LocationManager.ErrorReason>
    public typealias Callback = ((Data) -> Void)
    
    public var isPartialSearch: Bool {
        guard case .partialSearch(_) = options!.operation else {
            return false
        }
        return true
    }
    // MARK: - Public Properties -
    
    public var id: LocationManager.RequestID
    
    /// Timeout.
    public var timeout: Timeout.Mode?
    
    /// State of the request.
    public var state: RequestState = .idle
    
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
    
    /// Search options.
    internal var options: AutoCompleteRequest.Options?

    /// Registered callbacks.
    public private(set) var observers = Observers<Callback>()

    /// Last obtained valid value for request.
    public internal(set) var value: [PlaceMatch]?
    
    // MARK: - Initialization -
    
    internal override init() {
        self.id = UUID().uuidString
        super.init()
    }
    
    // MARK: - Protocol Conformances -
    
    public static func == (lhs: AutoCompleteRequest, rhs: AutoCompleteRequest) -> Bool {
        return lhs.id == rhs.id
    }
    
    // MARK: - Public Functions -
    
    public func stop() {
        
    }
    
    public func start() {
        
    }
    
    public func pause() {
        
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
            LocationManager.shared.removeAutoComplete(self)
        }
    }
    
    
}
