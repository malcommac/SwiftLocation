//
//  GeocoderRequest.swift
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

/// Monitoring:
///     * actions triggered on entering/exiting region’s range; works in the foreground, background, and even when the app is killed.
///     * Monitoring a region enables your app to know when a device enters or exits the range of beacons defined by the region.
/// Ranging:
///     * actions triggered based on proximity to a beacon; works only in the foreground.
///     * It returns a list of beacons in range, together with an estimated distance to each of them.
///
/// Links:
/// Monitoring and Ranging:
///     - https://community.estimote.com/hc/en-us/articles/203356607-What-are-region-Monitoring-and-Ranging-
/// Background vs Foreground:
///     - http://www.scriptscoop.com/t/194508ceaf47/ios-detecting-beacons-via-ibeacon-monitoring-ranging-vs-corebluetooth-scan.html
public class BeaconRequest: RequestProtocol, CustomStringConvertible {
    public typealias ProducedData = Event
    
    // MARK: - Public Properties
    
    /// Unique identifier of the request.
    public var uuid = UUID().uuidString
    
    /// Readable name.
    public var name: String?
    
    /// Eviction policy for request. You should never change this for GeocoderRequest.
    public var evictionPolicy = Set<RequestEvictionPolicy>([.onError])
    
    /// Subscriptions which receive updates.
    public var subscriptions = [RequestDataCallback<DataCallback>]()
    
    /// This is ignored for this request.
    public var isEnabled = true
    
    /// This is ignored for this request.
    public var countReceivedData = 0
    
    /// Last received response.
    public var lastReceivedValue: (Result<ProducedData, LocationError>)?
    
    /// Name that is used as the prefix for the region identifier.
    public var requestRegionIdentifier = ""
    
    /// Monitored beacon regions.
    public var monitoredRegions: [CLBeaconRegion] {
        Array(regions.values)
    }
    
    /// Define if the `rangingBeacons` event should also be called when the received list of beacons which does not match the list.
    public var reportAllBeaconsInRegions = false
    
    /// Monitored beacon instances.
    public private(set) var monitoredBeacons = [BeaconRequest.Beacon]()

    // MARK: - Private Properties
        
    /// Dictionary containing the CLBeaconRegions the locationManager is listening to.
    /// Each region is assigned to it's UUID String as the key.
    /// The String key in this dictionary is used as the unique key: This means, that each CLBeaconRegion will be unique by it's UUID.
    /// A CLBeaconRegion is unique by it's 'identifier' and not it's UUID. When using this default unique key a dictionary would not be necessary.
    private var regions = [String: CLBeaconRegion]()
    
    public var description: String {
        JSONStringify([
            "uuid": uuid,
            "name": name ?? "",
            "subscriptions": subscriptions.count,
            "enabled": isEnabled,
            "monitoredRegions": monitoredRegions.description,
            "monitoredBeacons": monitoredBeacons.description
        ])
    }
    
    // MARK: - Initialization
    
    /// Init the request and listen only to the given UUID.
    /// - Parameter UUID: NSUUID for the region the locationManager is listening to.
    public init(UUID: UUID) {
        regions[UUID.uuidString] = regionFromUUID(UUID)
    }
    
    /// Init the request and listen to multiple UUIDs.
    /// - Parameter uuids: Array of UUIDs for the regions the locationManager should listen to.
    public init(UUIDs: [UUID]) {
        for uuid in UUIDs {
            regions[uuid.uuidString] = regionFromUUID(uuid)
        }
    }
    
    /// Initialize a new request to receive updates only from a particular beacon.
    /// From the Beacon values (uuid, major and minor) a concrete `CLBeaconRegion` will be created.
    ///
    /// - Parameter beacon: Beacon instance the BeaconMonitor is listening for and it will be used to create a concrete CLBeaconRegion.
    public init(beacon: BeaconRequest.Beacon) {
        self.monitoredBeacons = [beacon]
        self.regions[beacon.uuid.uuidString] = regionFromBeacon(beacon)
    }
    
    /// Initialize a new request to receive only given beacons.
    /// The UUID(s) for the regions will be extracted from the Beacon Array.
    /// When Beacons with different UUIDs are defined multiple regions will be created.
    ///
    /// - Parameter beacons:Beacon instances to listen for.
    public init(beacons: [BeaconRequest.Beacon]) {
        self.monitoredBeacons = beacons
        
        // create a CLBeaconRegion for each different UUID
        beacons.distinctUnionOfUUIDs().forEach { UUID in
            regions[UUID.uuidString] = self.regionFromUUID(UUID)
        }
    }
    
    // MARK: - Public Functions
    
    internal func matchingRegion(_ region: CLBeaconRegion) -> Bool {
        monitoredRegions.first {
            $0 == region
        } != nil
    }
    
    internal func matchingBeacons(_ sourceList: [CLBeacon], inRegion region: CLBeaconRegion) -> [CLBeacon]? {
        guard !monitoredBeacons.isEmpty else { return nil }
        
        let matched = sourceList.filter { b in
            monitoredBeacons.contains(where: {
                $0.major == b.major && $0.minor == b.minor && $0.uuid as UUID == b.proximityUUID
            })
        }
        return (matched.isEmpty ? (reportAllBeaconsInRegions ? sourceList : nil) : matched)
    }
    
    public func validateData(_ data: ProducedData) -> DataDiscardReason? {
        nil
    }
    
    public func startTimeoutIfNeeded() {
        
    }
    
    public func didAddInQueue() {

    }
    
    public func didRemovedFromQueue() {

    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }
    
    public static func == (lhs: BeaconRequest, rhs: BeaconRequest) -> Bool {
        return lhs.uuid == rhs.uuid
    }
    
    // MARK: - Private Functions
    
    fileprivate func regionFromUUID(_ uuid: UUID) -> CLBeaconRegion {
        let region = CLBeaconRegion(proximityUUID: uuid, identifier: "\(requestRegionIdentifier)\(uuid.uuidString)")
        region.notifyEntryStateOnDisplay = true
        return region
    }
    
    private func regionFromBeacon(_ beacon: Beacon) -> CLBeaconRegion {
        let region = CLBeaconRegion(proximityUUID: beacon.uuid as UUID,
                                    major: CLBeaconMajorValue(beacon.major.int32Value),
                                    minor: CLBeaconMinorValue(beacon.minor.int32Value),
                                    identifier: "\(requestRegionIdentifier)\(beacon.uuid.uuidString)")
        region.notifyEntryStateOnDisplay = true
        return region
    }
    
}

// MARK: BeaconRequest Support Structures

public extension BeaconRequest {
    
    /// Struct to represent a Beacon the library should be listening to.
    struct Beacon {
        
        /// The UUID is a 128-bit value that uniquely identifies your app’s beacons.
        public var uuid: UUID
        
        /// The major value is a 16-bit unsigned integer that you use to differentiate groups of beacons with the same UUID.
        public var minor: NSNumber
        
        /// The minor value is a 16-bit unsigned integer that you use to differentiate groups of beacons with the same UUID and major value.
        public var major: NSNumber
        
        public init(uuid: UUID, minor: NSNumber, major: NSNumber) {
            self.uuid = uuid
            self.minor = minor
            self.major = major
        }
    }
    
    /// Events
    /// - `rangingBeacons`: one or more beacon monitor found.
    /// - `didEnterRegion`: entered in one of the monitored regions.
    /// - `didExitRegion`: exited from one of the monitored regions.
    enum Event: CustomStringConvertible {
        case rangingBeacons([CLBeacon])
        case didEnterRegion(CLBeaconRegion)
        case didExitRegion(CLBeaconRegion)
        
        public var description: String {
            switch self {
            case .rangingBeacons(let b): return "Ranging Beacons: \(b.map({ $0.description }).joined(separator: ","))"
            case .didEnterRegion(let r): return "Enter Beacon Region: \(r.description)"
            case .didExitRegion(let r):  return "Exit Beacon Region: \(r.description)"
            }
        }
        
    }
    
}

// MARK: Array Extensions (BeaconRequest.Request)

fileprivate extension Array where Element == BeaconRequest.Beacon {
    
    func distinctUnionOfUUIDs() -> [UUID] {
        var dict = [UUID : Bool]()
        let filtered = filter { (element: BeaconRequest.Beacon) -> Bool in
            if dict[element.uuid as UUID] == nil {
                dict[element.uuid as UUID] = true
                return true
            }
            return false
        }
        
        return filtered.map { ($0.uuid as UUID)}
    }
    
}

// MARK: - Result<[GeoLocation,LocatorErrors>

public extension Result where Success == BeaconRequest.Event, Failure == LocationError {
    
    var description: String {
        switch self {
        case .failure(let error):
            return "Failure \(error.localizedDescription)"
        case .success(let event):
            return "Success \(event.description)"
        }
    }
    
    var error: LocationError? {
        switch self {
        case .failure(let e): return e
        case .success: return nil
        }
    }
    
    var data: BeaconRequest.Event? {
        switch self {
        case .failure: return nil
        case .success(let e): return e
        }
    }
    
}
