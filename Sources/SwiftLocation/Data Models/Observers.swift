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

public class Observers<Callback> {
    public typealias ObserverID = UInt64
    
    /// Registered callbacks.
    public var callbacks = [ObserverID: Callback]()
    
    /// Next identifier of a registered callbacks.
    private var id: ObserverID = 0
    
    /// List of registered callbacks.
    public var list: [Callback] {
        return Array(callbacks.values)
    }
    
    /// Register a new callback.
    ///
    /// - Parameter callback: callback to register.
    /// - Returns: identifier of the callback (you can use it in order to remove the callback later).
    @discardableResult
    public func add(_ callback: Callback) -> ObserverID {
        let result = id.addingReportingOverflow(1)
        self.id = (result.overflow ? 0 : result.partialValue)
        callbacks[self.id] = callback
        return self.id
    }
    
    /// Remove specified callback.
    ///
    /// - Parameter id: identifier of the callback to remove.
    public func remove(_ id: ObserverID) {
        callbacks.removeValue(forKey: id)
    }
    
    /// Remove all callbacks
    public func removeAll() {
        callbacks.removeAll()
    }
        
}
