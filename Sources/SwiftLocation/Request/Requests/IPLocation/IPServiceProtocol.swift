//
//  File.swift
//  
//
//  Created by daniele on 26/09/2020.
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
    func execute(_ completion: @escaping ((Result<IPLocation.Data, LocatorErrors>) -> Void))
    
    /// Validate json response for specific errors.
    /// - Parameters:
    ///   - data: data received.
    ///   - httpResponse: http response received
    func validateResponse(data: IPLocation.Data, httpResponse: HTTPURLResponse) -> LocatorErrors?
    
    /// Cancel active request.
    func cancel()
    
}

// MARK: - IPService Extension

public extension IPServiceProtocol {
    
    func execute(_ completion: @escaping ((Result<IPLocation.Data, LocatorErrors>) -> Void)) {
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
                guard let response = response as? HTTPURLResponse,
                      response.statusCode == 200,
                      let data = data else {
                    completion(.failure(.internalError))
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
            completion(.failure( (error as? LocatorErrors) ?? .internalError ))
        }
    }
    
    func cancel() {
        guard isCancelled == false else {
            return
        }
        
        isCancelled = true
        task?.cancel()
    }
    
}

public enum IPLocation {
    
}