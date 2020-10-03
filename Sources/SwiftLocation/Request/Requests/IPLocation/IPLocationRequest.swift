//
//  File.swift
//  
//
//  Created by daniele on 25/09/2020.
//

import Foundation

public class IPLocationRequest: RequestProtocol {
    public typealias ProducedData = IPLocation.Data
    
    // MARK: - Private Functions

    /// Service used to get the ip data.
    private var service: IPServiceProtocol
    
    // MARK: - Public Properties

    /// Unique identifier of the request.
    public var uuid = UUID().uuidString
    
    /// Eviction policy.
    /// NOTE: You don't need to change this value.
    public var evictionPolicy = Set<RequestEvictionPolicy>([.onError, .onReceiveData(count: 1)])
    
    /// Callbacks subscribed.
    public var subscriptions = [RequestDataCallback<DataCallback>]()
    
    /// Is the requeste enabled.
    /// NOTE: You don't need to change this value.
    public var isEnabled = true
    
    /// Last received valid value.
    public var lastReceivedValue: (Result<IPLocation.Data, LocatorErrors>)? = nil
    
    /// Number of received data.
    /// NOTE: You don't need to change this value.
    public var countReceivedData = 0
    
    // MARK: - Public Functions
    
    public func validateData(_ data: IPLocation.Data) -> DataDiscardReason? {
        return nil // validation inside the service
    }
    
    public func startTimeoutIfNeeded() {
        // don't need for this request
    }
    
    public static func == (lhs: IPLocationRequest, rhs: IPLocationRequest) -> Bool {
        return lhs.uuid == rhs.uuid
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }
    
    public init(_ service: IPServiceProtocol) {
        self.service = service
    }
    
    public func didAddInQueue() {
        // this kind of request starts once added to the queue pool.
        service.execute { [weak self] result in
            self?.receiveData(result)
        }
    }
    
    public func didRemovedFromQueue() {
        service.cancel()
    }
    
}
