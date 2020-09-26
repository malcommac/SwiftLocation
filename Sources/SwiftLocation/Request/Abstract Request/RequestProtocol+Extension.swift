//
//  File.swift
//  
//
//  Created by daniele on 25/09/2020.
//

import Foundation
import CoreLocation

// MARK: - RequestProtocol

public extension RequestProtocol {

    @discardableResult
    func then(queue: DispatchQueue, _ callback: @escaping DataCallback) -> Identifier {
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
    
    func dispatchData(_ result: Result<ProducedData, LocatorErrors>, toSubscriptions: [RequestDataCallback<DataCallback>]? = nil) {
        (toSubscriptions ?? subscriptions).forEach { subscription in
            subscription.queue.async { // dispatch on passed queue.
                subscription.callback(result)
            }
        }
    }
    
    func cancelRequest() {
        Locator.shared.cancel(request: self)
    }
    
    @discardableResult
    func receiveData(_ data: Result<ProducedData, LocatorErrors>) -> DataDiscardReason? {
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
    
    private func receiveError(_ error: LocatorErrors) {
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
            LocatorLogger.log("Request '\(uuid)' will be removed due to eviction policy \(evictionPolicy)")
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
