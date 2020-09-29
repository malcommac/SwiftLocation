//
//  File.swift
//  
//
//  Created by daniele on 28/09/2020.
//

import Foundation

public class AutocompleteRequest: RequestProtocol {
    public typealias ProducedData = [AutocompleteResult]

    public let service: AutocompleteProtocol
    
    public var uuid = UUID().uuidString
    
    public var evictionPolicy: Set<RequestEvictionPolicy> = [.onError, .onReceiveData(count: 1)]
    
    public var subscriptions = [RequestDataCallback<DataCallback>]()
    
    public var isEnabled = true
    
    public var lastReceivedValue: (Result<[AutocompleteResult], LocatorErrors>)?
    
    public var countReceivedData = 0
    
    public func validateData(_ data: [AutocompleteResult]) -> DataDiscardReason? {
        return nil
    }
    
    public func startTimeoutIfNeeded() {
        
    }
    
    public init(_ service: AutocompleteProtocol) {
        self.service = service
    }
        
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
