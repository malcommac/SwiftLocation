//
//  File.swift
//  
//
//  Created by daniele on 27/09/2020.
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
                                   validateResponse: ((Data, HTTPURLResponse) -> LocatorErrors?)? = nil,
                                   _ completion: @escaping ((Result<Data, LocatorErrors>) -> Void)) {
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
