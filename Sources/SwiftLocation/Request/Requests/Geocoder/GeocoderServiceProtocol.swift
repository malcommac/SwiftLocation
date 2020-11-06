//
//  File.swift
//  
//
//  Created by daniele on 27/09/2020.
//

import Foundation
import CoreLocation

// MARK: - GeocoderServiceProtocol

public protocol GeocoderServiceProtocol: class, CustomStringConvertible {
    
    /// Operastion.
    var operation: GeocoderOperation { get }
    
    /// Execute service operation.
    /// - Parameter completion: completion callback.
    func execute(_ completion: @escaping ((Result<[GeoLocation], LocatorErrors>) -> Void))
    
    /// Cancel running operation.
    func cancel()
    
    /// Is operation cancelled.
    var isCancelled: Bool { get }
    
}

// MARK: - GeocoderOperation

public enum GeocoderOperation: CustomStringConvertible, Codable {
    case getCoordinates(String)
    case geoAddress(CLLocationCoordinate2D)
    
    internal var coordinates: CLLocationCoordinate2D {
        switch self {
        case .getCoordinates:       return CLLocationCoordinate2D()
        case .geoAddress(let c):    return c
        }
    }
    
    internal var address: String {
        switch self {
        case .getCoordinates(let a):    return a
        case .geoAddress:               return ""
        }
    }
    
    public var description: String {
        switch self {
        case .geoAddress(let c): return "Address from coordinates: \(c)"
        case .getCoordinates(let a): return "Coordinates from address: \(a)"
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
