//
//  GeofencingRequest.swift
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
    
    /// Readable name.
    public var name: String?
    
    /// Eviction policy. Removed on a single error received.
    public var evictionPolicy: Set<RequestEvictionPolicy> = [.onError]
    
    /// Subscribed callbacks.
    public var subscriptions = [RequestDataCallback<DataCallback>]()
    
    /// Is the request enabled, use `cancel()` to remove it.
    public var isEnabled = true
    
    /// Last received valid value.
    public var lastReceivedValue: (Result<GeofenceEvent, LocationError>)?
    
    /// Number of events received.
    public var countReceivedData = 0
        
    // MARK: - Private Properties
    
    /// The following request is triggered and created when user choose a custom polygon to monitor
    /// and the device did entered into the outer geofenced polygon. We need this because we have
    /// no other way to monitor custom polygons.
    private var polygonLocationRequest: GPSLocationRequest?
    
    public var description: String {
        JSONStringify([
            "options": options.description,
            "uuid": uuid,
            "name": name ?? "",
            "subscriptions": subscriptions.count,
            "enabled": isEnabled,
            "lastValue": lastReceivedValue?.description ?? ""
        ])
    }
    
    // MARK: - Codable Support
    
    enum CodingKeys: String, CodingKey {
        case options, monitoredRegion, uuid, isEnabled, name
    }
    
    // Encodable protocol
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(options, forKey: .options)
        try container.encode(uuid, forKey: .uuid)
        try container.encode(isEnabled, forKey: .isEnabled)
        try container.encodeIfPresent(name, forKey: .name)
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.options = try container.decode(GeofencingOptions.self, forKey: .options)
        self.uuid = try container.decode(String.self, forKey: .uuid)
        self.isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
    }
    
    // MARK: - Initialization
    
    public init(options: GeofencingOptions) {
        self.options = options
        self.uuid = options.region.uuid // use the same id of the monitored region
    }
    
    // MARK: - Public Methods
    
    public func validateData(_ event: GeofenceEvent) -> DataDiscardReason? {
        if event.isEntered && options.region.polygon != nil {
            // if we are monitoring a custom polygon and we received the didEntered event in the outer
            // region of the polygon we need to start monitoring the inner region for continous locations.
            polygonLocationRequest = SwiftLocation.gpsLocationWith({
                $0.accuracy = .block
                $0.minTimeInterval = 5
            })
            // Listen for updates
            polygonLocationRequest?.then(queue: .global(qos: .background), monitorCustomPolygonLocationUpdates)
            
            dispatchGeofenceEvent(.didEnteredRegion(options.region.circularRegion))
            
            // discard the data because we're waiting for precise gps data to check if we are inside the polygon.
            return .internalEvaluation
        } else if event.isExited && polygonLocationRequest != nil {
            // You are exited from the region so we don't need of this request anymore.
            polygonLocationRequest?.cancelRequest()
            polygonLocationRequest = nil
            
            dispatchGeofenceEvent(.didExitedRegion(options.region.circularRegion))

            return .internalEvaluation
        }
        
        // for a simple circle it's always valid, no need to make evaluations
        return nil
    }
    
    private func monitorCustomPolygonLocationUpdates(_ result: Result<CLLocation, LocationError>) {
        // We are monitoring a custom polygon so we need to check if the current position is inside
        // this polygon to send the event
        
        switch result {
        case .failure(_):
            return
        case .success(let location):
            if options.region.polygon?.containsCoordinate(location.coordinate) ?? false {
                // we are moving inside the polygon! we can dispatch the event.
                let enterEvent = GeofenceEvent.didEnteredPolygon(options.region.polygon!, outerRegion: options.region.circularRegion)
                dispatchGeofenceEvent(enterEvent)
            } else {
                // we are moving outside the polygon, we can dispatch this event.
                let exitedEvent = GeofenceEvent.didExitedPolygon(options.region.polygon!, outerRegion: options.region.circularRegion)
                dispatchGeofenceEvent(exitedEvent)
            }
        }
    }
    
    /// Custom dispatcher for polygon monitoring.
    /// - Parameter event: event to dispatch.
    private func dispatchGeofenceEvent(_ event: GeofenceEvent) {
        let data: Result<ProducedData, LocationError> = .success(event)
        lastReceivedValue = data
        receiveData(data)
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
/// - `didEnteredPolygon`: called when device entered inside the observer polygon.
/// - `didExitedPolygon`: called when device exited from the observer polygon.
public enum GeofenceEvent: CustomStringConvertible {
    case didEnteredRegion(CLRegion)
    case didExitedRegion(CLRegion)
    case didEnteredPolygon(MKPolygon, outerRegion: CLRegion)
    case didExitedPolygon(MKPolygon, outerRegion: CLRegion)
    
    /// Description of the event.
    public var description: String {
        switch self {
        case .didEnteredRegion(let region):         return "Entered CircularRegion '\(region.description)'"
        case .didExitedRegion(let region):          return "Exited CircularRegion '\(region.description)'"
        case .didEnteredPolygon(let polygon, _):    return "Entered Polygon '\(polygon.description)'"
        case .didExitedPolygon(let polygon, _):     return "Exited Polygon '\(polygon.description)'"
        }
    }
    
    /// Region monitored.
    public var region: CLRegion {
        switch self {
        case .didEnteredRegion(let r):       return r
        case .didExitedRegion(let r):        return r
        case .didEnteredPolygon(_, let r):   return r
        case .didExitedPolygon(_, let r):    return r
        }
    }
    
    /// `true` if it's an enter event.
    public var isEntered: Bool {
        switch self {
        case .didEnteredRegion, .didEnteredPolygon:   return true
        case .didExitedRegion, .didExitedPolygon:     return false
        }
    }

    /// `true` if it's an exit event.
    public var isExited: Bool {
        switch self {
        case .didEnteredRegion, .didEnteredPolygon:   return false
        case .didExitedRegion, .didExitedPolygon:     return true
        }
    }
    
}

// MARK: - Result Extension

extension Result where Success == CLLocation, Failure == LocationError {
    
    /// Get the current location if result is success.
    public var location: CLLocation? {
        switch self {
        case .failure:          return nil
        case .success(let l):   return l
        }
    }
    
    public var data: CLLocation? {
        location
    }
    
}

extension Result where Success == GeofenceEvent, Failure == LocationError {
    
    /// Get the current location if result is success.
    public var description: String? {
        switch self {
        case .failure(let e): return e.localizedDescription
        case .success(let e): return e.description
        }
    }
    
    public var error: LocationError? {
        switch self {
        case .failure(let e): return e
        case .success: return nil
        }
    }
    
    public var data: GeofenceEvent? {
        switch self {
        case .failure: return nil
        case .success(let e): return e
        }
    }
    
}
