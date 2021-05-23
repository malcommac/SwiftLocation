//
//  IPLocationRequest.swift
//
//  Copyright (c) 2020 Daniele Margutti (hello@danielemargutti.com).
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

public class IPLocationRequest: RequestProtocol {
    public typealias ProducedData = IPLocation.Data
    
    // MARK: - Private Functions

    /// Service used to get the ip data.
    public private(set) var service: IPServiceProtocol
    
    // MARK: - Public Properties

    /// Unique identifier of the request.
    public var uuid = UUID().uuidString
    
    /// Readable name.
    public var name: String?
    
    /// Eviction policy.
    /// NOTE: You don't need to change this value.
    public var evictionPolicy = Set<RequestEvictionPolicy>([.onError, .onReceiveData(count: 1)])
    
    /// Callbacks subscribed.
    public var subscriptions = [RequestDataCallback<DataCallback>]()
    
    /// Is the requeste enabled.
    /// NOTE: You don't need to change this value.
    public var isEnabled = true
    
    /// Last received valid value.
    public var lastReceivedValue: (Result<IPLocation.Data, LocationError>)? = nil
    
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
        service.resetState()
    }
    
    public var description: String {
        JSONStringify([
            "uuid": uuid,
            "name": name ?? "",
            "enabled": isEnabled,
            "lastValue": lastReceivedValue?.description ?? "",
            "subscriptions": subscriptions.count,
            "service": service.description
        ])
    }
    
}

// MARK: - Result<,LocatorErrors>

public extension Result where Success == IPLocation.Data, Failure == LocationError {
    
    var description: String {
        switch self {
        case .failure(let error):
            return "Failure \(error.localizedDescription)"
        case .success(let data):
            return "Success \(data.description)"
        }
    }
    
    var data: IPLocation.Data? {
        switch self {
        case .failure: return nil
        case .success(let l): return l
        }
    }
    
    var error: LocationError? {
        switch self {
        case .failure(let e): return e
        case .success: return nil
        }
    }
    
}
