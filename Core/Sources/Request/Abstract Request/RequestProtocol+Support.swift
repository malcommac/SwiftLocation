//
//  RequestProtocol+Support.swift
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

/// This defines how the request should threat it's cancel policy.
/// - `onError`: request is removed after the first error != .`discardedData` received.
/// - `onReceiveData`: remove request after passed count of valid data. If subscription of the parent request is `single` it will be ignored and request is removed automatically after the first result.
public enum RequestEvictionPolicy: CustomStringConvertible, Hashable {
    case onError
    case onReceiveData(count: Int)
    
    public var description: String {
        switch self {
        case .onError:              return "onError"
        case .onReceiveData(let c): return "onReceiveData[\(c)]"
        }
    }
    
    internal var isReceiveDataEviction: Bool {
        guard case .onReceiveData = self else {
            return false
        }
        
        return true
    }
    
}
