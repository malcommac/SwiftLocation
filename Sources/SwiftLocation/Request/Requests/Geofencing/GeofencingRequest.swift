//
//  File.swift
//  
//
//  Created by daniele on 30/09/2020.
//

import Foundation
import MapKit
import CoreLocation

public class GeofencingRequest: RequestProtocol, Codable {
    public typealias ProducedData = GeofenceEvent
    
    // MARK: - Public Properties
    
    /// Settings.
    public let options: GeofencingOptions
    
    /// Monitored region
    public var monitoredRegion: CLRegion {
        options.region.circularRegion
    }
    
    /// Unique identifier of the request.
    public var uuid = UUID().uuidString
    
    /// Eviction policy. Removed on a single error received.
    public var evictionPolicy: Set<RequestEvictionPolicy> = [.onError]
    
    /// Subscribed callbacks.
    public var subscriptions = [RequestDataCallback<DataCallback>]()
    
    /// Is the request enabled, use `cancel()` to remove it.
    public var isEnabled = true
    
    /// Last received valid value.
    public var lastReceivedValue: (Result<GeofenceEvent, LocatorErrors>)?
    
    /// Number of events received.
    public var countReceivedData = 0
    
    // MARK: - Codable Support
    
    enum CodingKeys: String, CodingKey {
        case options, monitoredRegion, uuid, isEnabled
    }
    
    // Encodable protocol
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(options, forKey: .options)
        try container.encode(uuid, forKey: .uuid)
        try container.encode(isEnabled, forKey: .isEnabled)
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.options = try container.decode(GeofencingOptions.self, forKey: .options)
        self.uuid = try container.decode(String.self, forKey: .uuid)
        self.isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
    }
    
    // MARK: - Initialization
    
    public init(options: GeofencingOptions) {
        self.options = options
        self.uuid = options.region.uuid // use the same id of the monitored region
    }
    
    // MARK: - Public Methods
    
    public func validateData(_ data: GeofenceEvent) -> DataDiscardReason? {
        switch options.region {
        case .circle:
            return nil // it's always valid, no need to make evaluations
        case .polygon(let polygon, let cRegion):
            // for polygon we can check if the point received is inside the polygon
            // this because the normal geofencing of iOS does not support polygon monitoring.
            return nil
            //return polygon.containsCoordinate()
        }
    }
        
    public func startTimeoutIfNeeded() {
        // not used for this request.
    }
    
    public static func == (lhs: GeofencingRequest, rhs: GeofencingRequest) -> Bool {
        return lhs.uuid == rhs.uuid
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }
    
}

// MARK: - GeofenceEvent

/// The event produced by the request.
/// - `didEntered`: called when device entered into observed region.
/// - `didExited`: called when device exited from observed region.
public enum GeofenceEvent: CustomStringConvertible {
    case didEntered(CLRegion)
    case didExited(CLRegion)
    
    /// Description of the event.
    public var description: String {
        switch self {
        case .didEntered(let region):   return "didEntered \(region.identifier)"
        case .didExited(let region):    return "didExited \(region.identifier)"
        }
    }
    
    /// Region monitored.
    public var region: CLRegion {
        switch self {
        case .didEntered(let r):    return r
        case .didExited(let r):     return r
        }
    }
    
}
