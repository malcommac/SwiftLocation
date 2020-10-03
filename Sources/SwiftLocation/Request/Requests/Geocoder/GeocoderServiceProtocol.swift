//
//  File.swift
//  
//
//  Created by daniele on 27/09/2020.
//

import Foundation
import CoreLocation

// MARK: - GeocoderServiceProtocol

public protocol GeocoderServiceProtocol: class {
    
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

public enum GeocoderOperation: CustomStringConvertible {
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
    
}

public enum Geocoder { }
