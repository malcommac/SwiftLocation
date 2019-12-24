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

public class RegionRequest: ServiceRequest, Hashable {
    public typealias Data = Result<(Kind,CLRegion), LocationManager.ErrorReason>
    public typealias Callback = ((Data) -> Void)

    /// Callbacks called once a new location or error is received.
    public var observers = Observers<RegionRequest.Callback>()
  
    public internal(set) var state: RequestState = .idle
    
    public let id: LocationManager.RequestID
    
    public let notifyEvents: Notify
    
    /// Type of timeout set.
    public let timeout: Timeout.Mode? = nil
    
    
    public func stop() {
        stop(reason: .cancelled, remove: true)
    }
    
    internal func stop(reason: LocationManager.ErrorReason = .cancelled, remove: Bool) {
        defer {
            if remove {
                LocationManager.shared.removeRegion(self)
            }
        }
        dispatch(data: .failure(reason))
    }
    
    
    public func start() {
        LocationManager.shared.startRegion(self)
    }
    
    public func pause() {
        state = .paused
    }
    
    public static func == (lhs: RegionRequest, rhs: RegionRequest) -> Bool {
        return lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // MARK: - Internal Methods -
        
    internal init(notify: Notify) {
        self.id = UUID().uuidString
        self.notifyEvents = notify
    }
    
    /// Dispatch received events to all callbacks.
    ///
    /// - Parameter data: data to pass.
    internal func dispatch(data: Data) {
        observers.list.forEach {
            $0(data)
        }
    }
    
    internal func didReceiveEvent(kind: Kind, inRegion region: CLRegion) {
        dispatch(data: .success((kind, region)))
    }

}

public extension RegionRequest {
    
    enum Kind {
        case enter
        case exit
    }
    
    struct Notify: OptionSet {
        public let rawValue: Int
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        /// When this property is true, a device crossing from outside the region to
        /// inside the region triggers the delivery of a notification.
        /// If not set a notification is not generated.
        /// The default value of this property is true.
        ///
        /// If the app is not running when a boundary crossing occurs, the system launches
        /// the app into the background to handle it.
        public static let onEnter = Notify(rawValue: 1 << 0)
        
        /// When this property is true, a device crossing from inside the region
        /// to outside the region triggers the delivery of a notification.
        /// If the property is false, a notification is not generated.
        /// The default value of this property is true.
        ///
        /// If the app is not running when a boundary crossing occurs, the system
        /// launches the app into the background to handle it.
        public static let onExit = Notify(rawValue: 1 << 1)
        
        /// All notifications are set.
        public static let all: Notify = [.onEnter, onExit]
        
    }
    
}
