//
//  File.swift
//  
//
//  Created by daniele on 27/09/2020.
//

import Foundation

public class GeocoderRequest: RequestProtocol {
    public typealias ProducedData = [GeocoderLocation]
    
    /// Unique identifier of the request.
    public var uuid = UUID().uuidString
    
    /// Eviction policy for request. You should never change this for GeocoderRequest.
    public var evictionPolicy = Set<RequestEvictionPolicy>([.onError, .onReceiveData(count: 1)])
    
    /// Subscriptions which receive updates.
    public var subscriptions = [RequestDataCallback<DataCallback>]()
    
    /// This is ignored for this request.
    public var isEnabled = true
    
    /// This is ignored for this request.
    public var countReceivedData = 0
    
    /// Last received response.
    public var lastReceivedValue: (Result<[GeocoderLocation], LocatorErrors>)?

    public static func == (lhs: GeocoderRequest, rhs: GeocoderRequest) -> Bool {
        return lhs.uuid == rhs.uuid
    }
    
    public func validateData(_ data: [GeocoderLocation]) -> DataDiscardReason? {
        return nil
    }
    
    public func startTimeoutIfNeeded() {
        
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }
    
    private var service: GeocoderServiceProtocol
    
    public init(service: GeocoderServiceProtocol) {
        self.service = service
    }
    
    public func didAddInQueue() {
        service.execute { [weak self] result in
            self?.lastReceivedValue = result
            self?.dispatchData(result)
        }
    }
    
    public func didRemovedFromQueue() {
        service.cancel()
    }
    
}

