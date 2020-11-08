//
//  JSONNetworkHelper.swift
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

public class JSONNetworkHelper {
    
    /// Inner task.
    private var networkTask: URLSessionDataTask?
    
    /// Is network operation cancelled
    public var isCancelled = false
    
    /// Execute request and return data or error.
    ///
    /// - Parameters:
    ///   - request: request to execute.
    ///   - validateResponse: optional validation mechanism callback.
    ///   - completion: completion callback.
    public func executeDataRequest(request: URLRequest,
                                   validateResponse: ((Data, HTTPURLResponse) -> LocationError?)? = nil,
                                   _ completion: @escaping ((Result<Data, LocationError>) -> Void)) {
        self.networkTask = URLSession.shared.dataTask(with: request) { [weak self] (data, response, error) in
            guard let self = self, self.isCancelled == false else {
                completion(.failure(.cancelled))
                return
            }
            
            if let error = error { // a generic error has occurred
                completion(.failure(.generic(error)))
                return
            }
            
            // not expected response
            guard let response = response as? HTTPURLResponse,
                  //response.statusCode == 200,
                  let data = data else {
                completion(.failure(.internalError))
                return
            }
            
            /// External validation
            if let validationError = validateResponse?(data, response) {
                completion(.failure(validationError))
                return
            }
            
            completion(.success(data))
        }
        networkTask?.resume()
    }
    
    /// Cancel network task.
    public func cancel() {
        isCancelled = true
        networkTask?.cancel()
    }
    
}
