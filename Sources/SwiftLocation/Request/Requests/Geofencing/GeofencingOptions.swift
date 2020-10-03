//
//  File.swift
//  
//
//  Created by daniele on 30/09/2020.
//

import Foundation
import MapKit
import CoreLocation

public struct GeofencingOptions {
    
    // MARK: - Public Properties
    
    /// Region monitored.
    public let region: Region
    
    /// Set `true` to be notified on enter in region events (by default is `true`).
    public var notifyOnEntry: Bool {
        set {
            region.circularRegion.notifyOnEntry = newValue
        }
        get {
            region.circularRegion.notifyOnEntry
        }
    }
    
    /// Set `true` to be notified on exit from region events (by default is `true`).
    public var notifyOnExit: Bool {
        set {
            region.circularRegion.notifyOnExit = newValue
        }
        get {
            region.circularRegion.notifyOnExit
        }
    }
    
    // MARK: - Initialization
    
    /// Initialize to monitor a specific polygon.
    ///
    /// - Parameter polygon: polygon to monitor.
    public init(polygon: MKPolygon) {
        // TODO: inner circle!
        let innerCircle = CLCircularRegion(center: CLLocationCoordinate2D(), radius: 0, identifier: UUID().uuidString)
        self.region = .polygon(polygon, innerCircle)
        
        defer {
            self.notifyOnEntry = true
            self.notifyOnExit = true
        }
    }
    
    /// Initialize a new region monitoring to geofence passed circular region.
    ///
    /// - Parameters:
    ///   - center: center of the circle.
    ///   - radius: radius of the circle in meters.
    public init(circleWithCenter center: CLLocationCoordinate2D, radius: CLLocationDegrees) {
        let circle = CLCircularRegion(center: center, radius: radius, identifier: UUID().uuidString)
        self.region = .circle(circle)
        
        defer {
            self.notifyOnEntry = true
            self.notifyOnExit = true
        }
    }
    
}

// MARK: - GeofencingOptions Options

public extension GeofencingOptions {
    
    /// Region monitored.
    /// - `circle`: monitoring a circle region.
    /// - `polygon`: monitoring a polygon region.
    ///             (it's always a circle but it's evaluated by request and it's inside the circular region identified by the second parameter, generated internally)
    enum Region {
        case circle(CLCircularRegion)
        case polygon(MKPolygon, CLCircularRegion)
        
        /// Unique identifier of the region monitored.
        internal var uuid: String {
            switch self {
            case .circle(let circle):
                return circle.identifier
            case .polygon(_, let boundCircle):
                return boundCircle.identifier
            }
        }
        
        /// Return the observed circle (outer circle which inscribes the polygon for polygon monitoring)
        var circularRegion: CLCircularRegion {
            switch self {
            case .circle(let c): return c
            case .polygon(_, let c): return c
            }
        }
        
        /// Return monitored polygon if monitoring is about a polygon.
        var polygon: MKPolygon? {
            switch self {
            case .circle: return nil
            case .polygon(let p, _): return p
            }
        }
        
    }
    
}
