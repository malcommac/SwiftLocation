//
//  File.swift
//  
//
//  Created by daniele on 25/09/2020.
//

import Foundation

public class IPLocationRequest: RequestProtocol {
    public typealias ProducedData = IPLocation

    private var service: IPService
    
    public var uuid = UUID().uuidString
    
    public var evictionPolicy = Set<RequestEvictionPolicy>([.onError, .onReceiveData(count: 1)])
    
    public var subscriptions = [RequestDataCallback<DataCallback>]()
    
    public var isEnabled = true
    
    public var lastReceivedValue: (Result<IPLocation, LocatorErrors>)? = nil
    
    public var countReceivedData = 0
    
    public func validateData(_ data: IPLocation) -> DataDiscardReason? {
        return nil
    }
    
    public func startTimeoutIfNeeded() {
        
    }
    
    public static func == (lhs: IPLocationRequest, rhs: IPLocationRequest) -> Bool {
        return lhs.uuid == rhs.uuid
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }
    
    public init(_ service: IPService) {
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
