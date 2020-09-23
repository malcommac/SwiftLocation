//
//  Request.swift
//  SwiftLocation
//
//  Created by Daniele Margutti on 18/09/2020.
//

import Foundation

// Identifier of an item.
public typealias Identifier = String

// MARK: - RequestProtocol

public protocol RequestProtocol: class, Hashable {
    associatedtype ProducedData
    
    typealias DataCallback = ((Result<ProducedData, LocatorErrors>) -> Void)
    
    // MARK: - Public Properties

    /// Unique identifier of the request.
    var uuid: Identifier { get }
    
    /// Return `true` if you want any error can cancel the request from the locator's queue.
    /// Return `false` to continue subscription even on error.
    var autoCancelOnError: Bool { get }
    
    /// Registered subscriptions.
    var subscriptions: [RequestDataCallback<DataCallback>] { get set }
    
    /// If `false` the request still on queue but will not receive events. By default is `true`.
    var isEnabled: Bool { get set }
    
    // MARK: - Request Managment
    
    /// Remove the entire request from the queue.
    func cancelRequest()
    
    // MARK: - Data Management
    
    /// This method is called from the underlying manager to inform the request of new data.
    /// Usually you don't need to override it.
    ///
    /// - Parameter data: data received.
    func receiveData(_ data: Result<ProducedData, Error>)
    
    /// This method is called to verify received data from underlying manager is valid and can be
    /// dispatched to the register subscriptions. Usually you don't need to override it but if you want
    /// to further customize the behaviour of a request be sure you call super implementation
    /// to validate standard parameters defined in options.
    /// If you return a valid error this is threated as error and may result in request cancellation
    /// depending of settings of the request itself.
    ///
    /// You can return `.discardedData` if data did not pass your validation but it's not an error.
    ///
    /// - Parameter data: data.
    func validateData(_ data: ProducedData) -> LocatorErrors?
    
    /// Method is called to dispatch result data to subscribers.
    /// - Parameter result: data to dispatch.
    func dispatchData(_ result: Result<ProducedData, LocatorErrors>)

    // MARK: - Subscription Management
    
    /// Register a new callback which receive data from request once it's available.
    /// If not specified callback is always called on main thread.
    ///
    /// - Parameters:
    ///   - queue: queue in which the callback is called, by default is `main`.
    ///   - dataCallback: data callback to subscribe.
    /// - Returns: `Identifier` you can use to remove subscription.
    func on(queue: DispatchQueue, _ callback: @escaping DataCallback) -> Identifier

    /// Cancel specified callback subscription.
    /// - Parameter subscription: subscription identifier to remove.
    func cancel(subscription: Identifier)
    
    /// Cancel all registered subscriptions.
    func cancelAllSubscriptions()
    
    /// Return the subscription with given identifier if it's part of the subscription of the request.
    /// - Parameter identifier: identifier.
    func subscriptionWithID(_ identifier: Identifier) -> RequestDataCallback<ProducedData>?
    
    /// Start tiemout timer if set; this method should be not called outside but it's internally managed by the locator.
    func startTimeoutIfNeeded()

}

// MARK: - RequestProtocol

public extension RequestProtocol {

    @discardableResult
    func on(queue: DispatchQueue, _ callback: @escaping DataCallback) -> Identifier {
        let callbackContainer = RequestDataCallback(queue: queue, callback: callback)
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
    
    func dispatchData(_ result: Result<ProducedData, LocatorErrors>) {
        subscriptions.forEach { subscription in
            subscription.queue.async { // dispatch on passed queue.
                subscription.callback(result)
            }
        }
    }
    
    func cancelRequest() {
        Locator.shared.cancel(request: self)
    }
    
    func receiveData(_ data: Result<ProducedData, Error>) {
        switch data {
        case .failure(let error):   receiveError(.generic(error))
        case .success(let data):    receiveData(data)
        }
    }
    
    // MARK: - Private Functions
    
    private func receiveError(_ error: LocatorErrors) {
        guard error != .discardedData else {
            // discarded data do not produce any error.
            return
        }
        
        // Otherwise error is dispatched
        dispatchData(.failure(.generic(error)))
        // and eventually the request is cancelled
        if autoCancelOnError {
            cancelRequest()
        }
    }
    
    private func receiveData(_ data: ProducedData) {
        if let error = validateData(data) {
            receiveError(error)
            return
        }
        
        // no validation error occurred, we can dispatch data
        dispatchData(.success(data))
    }
    
}

// MARK: - RequestDataCallback

public class RequestDataCallback<T: Any> {
    
    /// Callback to call when new data is available.
    let callback : T
    
    /// Queue in which the callback is called.
    let queue: DispatchQueue
    
    /// Identifier of the callback used to remove it.
    let identifier: Identifier = UUID().uuidString
    
    internal init(queue: DispatchQueue, callback: T) {
        self.callback = callback
        self.queue = queue
    }
    
}
