//
//  File.swift
//  
//
//  Created by daniele on 25/09/2020.
//

import Foundation

// MARK: - RequestDataCallback

public class RequestDataCallback<T: Any> {
    
    /// Callback to call when new data is available.
    let callback : T
    
    /// Queue in which the callback is called.
    let queue: DispatchQueue
    
    /// Identifier of the callback used to remove it.
    let identifier: Identifier = UUID().uuidString
    
    internal init(queue: DispatchQueue, callback: T) {
        self.callback = callback
        self.queue = queue
    }
    
}

/// This defines how the request should threat it's cancel policy.
/// - `onError`: request is removed after the first error != .`discardedData` received.
/// - `onReceiveData`: remove request after passed count of valid data. If subscription of the parent request is `single` it will be ignored and request is removed automatically after the first result.
public enum RequestEvictionPolicy: CustomStringConvertible, Hashable {
    case onError
    case onReceiveData(count: Int)
    
    public var description: String {
        switch self {
        case .onError:              return "onError"
        case .onReceiveData(let c): return "onReceiveData[\(c)]"
        }
    }
    
    internal var isReceiveDataEviction: Bool {
        guard case .onReceiveData = self else {
            return false
        }
        
        return true
    }
    
}
