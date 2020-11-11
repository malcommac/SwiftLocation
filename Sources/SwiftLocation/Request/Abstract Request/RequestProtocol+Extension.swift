//
//  RequestProtocol+Extension.swift
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
import CoreLocation

// MARK: - RequestProtocol

public extension RequestProtocol {

    @discardableResult
    func then(queue: DispatchQueue = .main, _ callback: @escaping DataCallback) -> Identifier {
        let callbackContainer = RequestDataCallback(queue: queue, callback: callback)
        
        if let unwrappedLastValue = lastReceivedValue {
            dispatchData(unwrappedLastValue, toSubscriptions: [callbackContainer])
        }
        
        subscriptions.append(callbackContainer)
        return callbackContainer.identifier
    }
    
    func cancel(subscription identifier: Identifier) {
        if let index = subscriptions.firstIndex(where: { $0.identifier == identifier }) {
            subscriptions.remove(at: index)
        }
    }
    
    func cancelAllSubscriptions() {
        subscriptions.removeAll()
    }
    
    func subscriptionWithID(_ identifier: Identifier) -> RequestDataCallback<ProducedData>? {
        return subscriptions.first(where: { $0.identifier == identifier }) as? RequestDataCallback<ProducedData>
    }
    
    func dispatchData(_ result: Result<ProducedData, LocationError>, toSubscriptions: [RequestDataCallback<DataCallback>]? = nil) {
        (toSubscriptions ?? subscriptions).forEach { subscription in
            subscription.queue.async { // dispatch on passed queue.
                subscription.callback(result)
            }
        }
    }
    
    func cancelRequest() {
        SwiftLocation.cancel(request: self)
    }
    
    @discardableResult
    func receiveData(_ data: Result<ProducedData, LocationError>) -> DataDiscardReason? {
        lastReceivedValue = data
        
        switch data {
        case .failure(let error):
            receiveError(error)
            return .generic(error)
        case .success(let data):
            return receiveData(data)
        }
    }
    
    // MARK: - Private Functions
    
    private func receiveError(_ error: LocationError) {
        guard !error.isDataDiscarded else {
            // discarded data do not produce any error.
            return
        }
        
        // Otherwise error is dispatched
        dispatchData(.failure(error))
        if evictionPolicy.contains(.onError) { // if in case of error we should cancel the request.
            cancelRequest()
        }
    }
    
    private func receiveData(_ data: ProducedData) -> DataDiscardReason? {
        if let error = validateData(data) {
            receiveError(.discardedData(error))
            return error
        }
        
        // no validation error occurred, we can dispatch data
        countReceivedData += 1
        dispatchData(.success(data))
        
        if shouldRemoveRequest() { // if first data invalidate the request
            LocationManager.Logger.log("Request '\(uuid)' will be removed due to eviction policy \(evictionPolicy)")
            cancelRequest()
        }
        
        return nil
    }
    
    /// Should remove request due to auto-eviction policy.
    /// - Returns: Bool
    private func shouldRemoveRequest() -> Bool {
        for policy in evictionPolicy {
            if case .onReceiveData(let expireCount) = policy {
                return expireCount == countReceivedData
            }
        }
        
        return false
    }
    
    /// Request was added into the queue.
    func didAddInQueue() { }
    
    /// Request was removed from the queue.
    func didRemovedFromQueue() { }
    
}
