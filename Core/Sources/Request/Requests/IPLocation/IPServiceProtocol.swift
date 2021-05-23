//
//  IPServiceProtocol.swift
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

internal let IPServiceDecoder = CodingUserInfoKey(rawValue: "decoder")!

public enum IPServiceDecoders: String, CaseIterable {
    case ipstack // IPStackService
    case ipdata // IPDataService
    case ipinfo // IPInfoService
    case ipapi // IPApiService
    case ipgeolocation // IPGeolocationService
    case ipify // IPIpifyService
}

public protocol IPServiceProtocol: class, CustomStringConvertible {
    
    /// Decoder userd to read data from service.
    var jsonServiceDecoder: IPServiceDecoders { get }
    
    /// Timeout interval for request.
    var timeout: TimeInterval { get set }
    
    /// URLSession used to perform network call.
    var session: URLSession { get set }
    
    /// Active network call data task.
    var task: URLSessionDataTask? { get set }
    
    /// If you want to lookup for other IP address rather than machine's one.
    var targetIP: String? { get set }
    
    /// Some services may need of API Key value.
    /// In case of required key value is requested on init of the service.
    var APIKey: String? { get set }
    
    /// Locale of the results. See each service for its own formast.
    var locale: String? { get set }
    
    /// `true` if task received cancel command  when removed from request.
    var isCancelled: Bool { get set }
    
    /// Create the request.
    func buildRequest() throws -> URLRequest
    
    /// Execute network request and produce result.
    /// - Parameter completion: completion block.
    func execute(_ completion: @escaping ((Result<IPLocation.Data, LocationError>) -> Void))
    
    /// Validate json response for specific errors.
    /// - Parameters:
    ///   - data: data received.
    ///   - httpResponse: http response received
    func validateResponse(data: IPLocation.Data, httpResponse: HTTPURLResponse) -> LocationError?
    
    /// Cancel active request.
    func cancel()
    
    /// Reset the initial setate of the service.
    func resetState()
    
}

// MARK: - IPService Extension

public extension IPServiceProtocol {
    
    func execute(_ completion: @escaping ((Result<IPLocation.Data, LocationError>) -> Void)) {
        do {
            let request = try buildRequest()
            self.task = session.dataTask(with: request) { [weak self] (data, response, error) in
                guard let self = self, self.isCancelled == false else {
                    completion(.failure(.cancelled))
                    return
                }
                
                if let error = error { // a generic error has occurred
                    completion(.failure(.generic(error)))
                    return
                }
                
                // not expected response
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200,
                      let data = data else {
                    completion(.failure(.networkError(response as? HTTPURLResponse)))
                    return
                }
                
                do {
                    let decoder = JSONDecoder()
                    decoder.userInfo = [IPServiceDecoder : self.jsonServiceDecoder]
                    let location = try decoder.decode(IPLocation.Data.self, from: data)
                    completion(.success(location))
                } catch {
                    completion(.failure(.parsingError))
                }
                
            }
            task?.resume()
        } catch {
            completion(.failure( (error as? LocationError) ?? .internalError ))
        }
    }
    
    func cancel() {
        guard isCancelled == false else {
            return
        }
        
        isCancelled = true
        task?.cancel()
        task = nil
    }
    
    func resetState() {
        cancel()
        isCancelled = false
    }
    
}

// MARK: - IPLocation Umbrella

public enum IPLocation { }
