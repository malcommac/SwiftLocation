//
//  GeofencingOptions.swift
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
import MapKit
import CoreLocation

public struct GeofencingOptions: Codable, CustomStringConvertible {
    
    // MARK: - Public Properties
    
    /// Region monitored.
    public let region: Region
    
    /// Set `true` to be notified on enter in region events (by default is `true`).
    public var notifyOnEnter: Bool {
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
    
    public var description: String {
        JSONStringify([
            "region": region.description,
            "notifyOnEntry": notifyOnEnter,
            "notifyOnExit": notifyOnExit
        ])
    }
    
    // MARK: - Initialization
    
    /// Initialize to monitor a specific polygon.
    ///
    /// - Parameter polygon: polygon to monitor.
    public init(polygon: MKPolygon) throws {
        // TODO: inner circle!
        guard let outerCircle = polygon.outerCircle() else {
            // failed to create the outer circle from polygon
            throw LocationError.invalidPolygon
        }
        
        let outerCircleRegion = CLCircularRegion(center: outerCircle.coordinate, radius: outerCircle.radius, identifier: UUID().uuidString)
        self.region = .polygon(polygon, outerCircleRegion)
        
        defer {
            self.notifyOnEnter = true
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
            self.notifyOnEnter = true
            self.notifyOnExit = true
        }
    }
    
    /// Initialize a new region monitoring with circle passed.
    /// 
    /// - Parameter circle: circle.
    public init(circle: MKCircle) {
        self.init(circleWithCenter: circle.coordinate, radius: circle.radius)
    }
    
}

// MARK: - GeofencingOptions Options

public extension GeofencingOptions {
    
    /// Region monitored.
    /// - `circle`: monitoring a circle region.
    /// - `polygon`: monitoring a polygon region.
    ///             (it's always a circle but it's evaluated by request and it's inside the circular region identified by the second parameter, generated internally)
    enum Region: Codable, CustomStringConvertible {
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
        
        internal var kind: Int {
            switch self {
            case .circle: return 0
            case .polygon: return 1
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
        
        public var description: String {
            JSONStringify([
                "kind": (kind == 0 ? "circle": "polygon"),
                "polygon": polygon?.description ?? "",
                "circularRegion": circularRegion.description
            ])
        }
        
        // MARK: - Codable Support
        
        enum CodingKeys: String, CodingKey {
            case kind, cRegionCenter, clRegionRadius, polygonCoordinates, identifier
        }
        
        // Encodable protocol
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(kind, forKey: .kind)
            switch self {
            case .circle(let circularRegion):
                try container.encode(circularRegion.center, forKey: .cRegionCenter)
                try container.encode(circularRegion.radius, forKey: .clRegionRadius)
                try container.encode(circularRegion.identifier, forKey: .identifier)

            case .polygon(let polygon, let circularRegion):
                try container.encode(circularRegion.center, forKey: .cRegionCenter)
                try container.encode(circularRegion.radius, forKey: .clRegionRadius)
                try container.encode(circularRegion.identifier, forKey: .identifier)

                try container.encode(polygon.coordinates, forKey: .polygonCoordinates)
            }
        }
        
        // Decodable protocol
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            switch try container.decode(Int.self, forKey: .kind) {
            case 0:
                let center = try container.decode(CLLocationCoordinate2D.self, forKey: .cRegionCenter)
                let radius = try container.decode(CLLocationDegrees.self, forKey: .clRegionRadius)
                let identifier = try container.decode(String.self, forKey: .identifier)
                let cRegion = CLCircularRegion(center: center, radius: radius, identifier: identifier)
                
                self = .circle(cRegion)
                
            case 1:
                let center = try container.decode(CLLocationCoordinate2D.self, forKey: .cRegionCenter)
                let radius = try container.decode(CLLocationDegrees.self, forKey: .clRegionRadius)
                let identifier = try container.decode(String.self, forKey: .identifier)
                let cRegion = CLCircularRegion(center: center, radius: radius, identifier: identifier)
                
                let coordinates = try container.decode([CLLocationCoordinate2D].self, forKey: .polygonCoordinates)
                let polygon = MKPolygon(coordinates: coordinates, count: coordinates.count)
                
                self = .polygon(polygon, cRegion)
                
            default:
                fatalError()
            }
        }
        
    }
    
}
