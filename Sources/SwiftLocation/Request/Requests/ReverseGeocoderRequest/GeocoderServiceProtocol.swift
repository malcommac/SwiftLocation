//
//  File.swift
//  
//
//  Created by daniele on 27/09/2020.
//

import Foundation
import CoreLocation

public protocol GeocoderServiceProtocol: class {
    
    var operation: GeocoderOperation { get }
    
    func execute(_ completion: @escaping ((Result<[GeoLocation], LocatorErrors>) -> Void))
    func cancel()
    
    var isCancelled: Bool { get }
    
}

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
