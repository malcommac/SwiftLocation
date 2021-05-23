//
//  GeocoderRequest.swift
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
    public var lastReceivedValue: (Result<[GeoLocation], LocationError>)?
    
    /// Service used.
    public var service: GeocoderServiceProtocol
    
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

public extension Result where Success == [GeoLocation], Failure == LocationError {
    
    var description: String {
        switch self {
        case .failure(let error):
            return "Failure \(error.localizedDescription)"
        case .success(let values):
            return "Success \(values.count) locations"
        }
    }
    
    var data: [GeoLocation]? {
        switch self {
        case .success(let locations): return locations
        case .failure: return nil
        }
    }
    
    var error: LocationError? {
        switch self {
        case .failure(let e): return e
        case .success: return nil
        }
    }
    
}
