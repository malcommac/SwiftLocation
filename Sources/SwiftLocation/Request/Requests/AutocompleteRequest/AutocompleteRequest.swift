//
//  File.swift
//  
//
//  Created by daniele on 28/09/2020.
//

import Foundation

public class AutocompleteRequest: RequestProtocol {
    public typealias ProducedData = [Autocomplete.AutocompleteResult]
    
    /// Service used to perform the request.
    public let service: AutocompleteProtocol
    
    /// Unique identifier of the request.
    public var uuid = UUID().uuidString
    
    /// Eviction policy of the request.
    ///
    /// NOTE: You should never change it for this kind of request.
    public var evictionPolicy: Set<RequestEvictionPolicy> = [.onError, .onReceiveData(count: 1)]
    
    /// Subscribed callbacks.
    public var subscriptions = [RequestDataCallback<DataCallback>]()
    
    /// Is request enabled, by default is `true`.
    ///
    /// NOTE: You should never change it for this kind of request.
    public var isEnabled = true
    
    /// Last received value from the request's service.
    public var lastReceivedValue: (Result<[Autocomplete.AutocompleteResult], LocatorErrors>)?
    
    /// Number of data received. For this kind of request it's always 1 once data is arrived.
    public var countReceivedData = 0
    
    // MARK: - Public Properties
    
    public func validateData(_ data: [Autocomplete.AutocompleteResult]) -> DataDiscardReason? {
        return nil // performed by the service
    }
    
    public func startTimeoutIfNeeded() {
        // managed by the service
    }
    
    // MARK: - Initialization
    
    public init(_ service: AutocompleteProtocol) {
        self.service = service
    }
    
    // MARK: - Public Functions
        
    public static func == (lhs: AutocompleteRequest, rhs: AutocompleteRequest) -> Bool {
        return lhs.uuid == rhs.uuid
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }
    
    public func didAddInQueue() {
        service.execute { [weak self] result in
            self?.dispatchData(result)
        }
    }
    
    public func didRemovedFromQueue() {
        service.cancel()
    }

}
