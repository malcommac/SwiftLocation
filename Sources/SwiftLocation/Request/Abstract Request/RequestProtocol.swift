//
//  RequestProtocol.swift
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

// Identifier of an item.
public typealias Identifier = String

// MARK: - RequestProtocol

public protocol RequestProtocol: class, Hashable, CustomStringConvertible {
    associatedtype ProducedData
    
    typealias DataCallback = ((Result<ProducedData, LocationError>) -> Void)
    
    // MARK: - Public Properties
    
    /// Unique identifier of the request.
    var uuid: Identifier { get }
    
    /// Name of the request, you can use it to identify your requests with a readable value.
    var name: String? { get set }
    
    /// Define the policy used to auto-remove a request from the pool.
    /// The default behaviour differ from request type.
    var evictionPolicy: Set<RequestEvictionPolicy> { get set }
    
    /// Registered subscriptions.
    var subscriptions: [RequestDataCallback<DataCallback>] { get set }
    
    /// If `false` the request still on queue but will not receive events. By default is `true`.
    var isEnabled: Bool { get set }
    
    /// Last value received from the server. Any new attached subscriber will receive these values.
    var lastReceivedValue: (Result<ProducedData, LocationError>)? { get set }
    
    /// Count received valid data.
    var countReceivedData: Int { get set }
    
    // MARK: - Request Managment
    
    /// Remove the entire request from the queue.
    func cancelRequest()
        
    // MARK: - Data Management
    
    /// This method is called from the underlying manager to inform the request of new data.
    /// Usually you don't need to override it.
    ///
    /// - Parameter data: data received.
    /// - Returns: `nil` if data is used `nil` is returned, otherwise a valid reason (`DataDiscardReason`).
    func receiveData(_ data: Result<ProducedData, LocationError>) -> DataDiscardReason?
    
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
    func validateData(_ data: ProducedData) -> DataDiscardReason?
    
    /// Method is called to dispatch result data to subscribers.
    /// - Parameters:
    ///   - result: data to dispatch.
    ///   - toSubscriptions: if passed a custom list of subscriptions. If `nil` is passed the internal list of subscriptions.
    func dispatchData(_ result: Result<ProducedData, LocationError>, toSubscriptions: [RequestDataCallback<DataCallback>]?)

    // MARK: - Subscription Management
    
    /// Register a new callback which receive data from request once it's available.
    /// If not specified callback is always called on main thread.
    ///
    /// - Parameters:
    ///   - queue: queue in which the callback is called, by default is `main`.
    ///   - dataCallback: data callback to subscribe.
    /// - Returns: `Identifier` you can use to remove subscription.
    func then(queue: DispatchQueue, _ callback: @escaping DataCallback) -> Identifier

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
    
    // MARK: - Requests Events
    
    /// Request was added into the queue.
    func didAddInQueue()
    
    /// Request was removed from the queue.
    /// You should use this method to reset the state of the request.
    func didRemovedFromQueue()
    
}
