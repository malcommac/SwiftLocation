//
//  AutocompleteRequest.swift
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

public class AutocompleteRequest: RequestProtocol {
    public typealias ProducedData = [Autocomplete.Data]
    
    /// Service used to perform the request.
    public let service: AutocompleteProtocol
    
    /// Unique identifier of the request.
    public var uuid = UUID().uuidString
    
    /// Readable name.
    public var name: String?
    
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
    public var lastReceivedValue: (Result<[Autocomplete.Data], LocationError>)?
    
    /// Number of data received. For this kind of request it's always 1 once data is arrived.
    public var countReceivedData = 0
    
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
    
    // MARK: - Public Properties
    
    public func validateData(_ data: [Autocomplete.Data]) -> DataDiscardReason? {
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
        service.executeAutocompleter { [weak self] result in
            self?.receiveData(result)
        }
    }
    
    public func didRemovedFromQueue() {
        service.cancel()
    }

}

// MARK: - Result<[Autocomplete.Data],LocatorErrors>

public extension Result where Success == [Autocomplete.Data], Failure == LocationError {
    
    var description: String {
        switch self {
        case .failure(let error):
            return "Failure \(error.localizedDescription)"
        case .success(let data):
            return "Success \(data.description)"
        }
    }
    
    var data: [Autocomplete.Data]? {
        switch self {
        case .failure: return nil
        case .success(let d): return d
        }
    }
    
    var error: LocationError? {
        switch self {
        case .failure(let e): return e
        case .success: return nil
        }
    }
    
}
