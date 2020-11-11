//
//  GeocoderServiceProtocol.swift
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

// MARK: - GeocoderServiceProtocol

public protocol GeocoderServiceProtocol: class, CustomStringConvertible {
    
    /// Timeout interval for request. `nil` to ignore it.
    var timeout: TimeInterval? { get set }
    
    /// Operastion.
    var operation: GeocoderOperation { get set }
    
    /// Locale of the results.
    var locale: String? { get set }
    
    /// Execute service operation.
    /// - Parameter completion: completion callback.
    func execute(_ completion: @escaping ((Result<[GeoLocation], LocationError>) -> Void))
    
    /// Cancel running operation.
    func cancel()
    
    /// Is operation cancelled.
    var isCancelled: Bool { get }
    
}

// MARK: - GeocoderOperation

public enum GeocoderOperation: CustomStringConvertible, Codable {
    case getCoordinates(String)
    case geoAddress(CLLocationCoordinate2D)
    
    public var coordinates: CLLocationCoordinate2D {
        switch self {
        case .getCoordinates:       return CLLocationCoordinate2D()
        case .geoAddress(let c):    return c
        }
    }
    
    public var address: String {
        switch self {
        case .getCoordinates(let a):    return a
        case .geoAddress:               return ""
        }
    }
    
    public var description: String {
        switch self {
        case .geoAddress(let c):        return "geocode: \(c)"
        case .getCoordinates(let a):    return "r.geocode: \(a)"
        }
    }
    
    /// Return `true` if operation is a reverse geocoding.
    public var isReverseGeocoder: Bool {
        switch self {
        case .geoAddress:       return true
        case .getCoordinates:   return false
        }
    }
    
    private var kind: Int {
        switch self {
        case .geoAddress:       return 0
        case .getCoordinates:   return 1
        }
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case kind, coordinates, address
    }
    
    // Encodable protocol
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(kind, forKey: .kind)
        
        switch self {
        case.geoAddress(let coordinates):
            try container.encode(coordinates, forKey: .coordinates)
            
        case .getCoordinates(let address):
            try container.encode(address, forKey: .address)
        }
    }
    
    // Decodable protocol
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Int.self, forKey: .kind)
        
        switch kind {
        case 0:
            let coordinates = try container.decode(CLLocationCoordinate2D.self, forKey: .coordinates)
            self = .geoAddress(coordinates)
            
        case 1:
            let address = try container.decode(String.self, forKey: .address)
            self = .getCoordinates(address)
            
        default:
            fatalError("Failed decode GeocoderOperation")
        }
    }
    
}

public enum Geocoder { }
