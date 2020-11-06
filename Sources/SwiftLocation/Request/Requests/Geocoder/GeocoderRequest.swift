//
//  File.swift
//  
//
//  Created by daniele on 27/09/2020.
//

import Foundation

public class GeocoderRequest: RequestProtocol {
    public typealias ProducedData = [GeoLocation]
    
    // MARK: - Public Properties
    
    /// Unique identifier of the request.
    public var uuid = UUID().uuidString
    
    /// Readable name.
    public var name: String?
    
    /// Eviction policy for request. You should never change this for GeocoderRequest.
    public var evictionPolicy = Set<RequestEvictionPolicy>([.onError, .onReceiveData(count: 1)])
    
    /// Subscriptions which receive updates.
    public var subscriptions = [RequestDataCallback<DataCallback>]()
    
    /// This is ignored for this request.
    public var isEnabled = true
    
    /// This is ignored for this request.
    public var countReceivedData = 0
    
    /// Last received response.
    public var lastReceivedValue: (Result<[GeoLocation], LocatorErrors>)?

    // MARK: - Private Properties

    private var service: GeocoderServiceProtocol
    
    // MARK: - Public Functions
    
    public var description: String {
        JSONStringify([
            "uuid": uuid,
            "name": name ?? "",
            "subscriptions": subscriptions.count,
            "enabled": isEnabled,
            "lastValue": lastReceivedValue?.description ?? "",
            "service": service.description
        ])
    }
    
    public func validateData(_ data: [GeoLocation]) -> DataDiscardReason? {
        return nil
    }
    
    public func startTimeoutIfNeeded() {
        
    }
        
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
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }
    
    public static func == (lhs: GeocoderRequest, rhs: GeocoderRequest) -> Bool {
        return lhs.uuid == rhs.uuid
    }
    
}

// MARK: - Result<[GeoLocation,LocatorErrors>

public extension Result where Success == [GeoLocation], Failure == LocatorErrors {
    
    var description: String {
        switch self {
        case .failure(let error):
            return "Failure \(error.localizedDescription)"
        case .success(let values):
            return "Success \(values.count) locations"
        }
    }
    
}
