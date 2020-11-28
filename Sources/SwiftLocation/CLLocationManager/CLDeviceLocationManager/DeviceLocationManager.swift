//
//  DeviceLocationManager.swift
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

public class DeviceLocationManager: NSObject, LocationManagerImpProtocol, CLLocationManagerDelegate {
    
    // MARK: - Private Properties
    
    /// Parent locator manager.
    private weak var locator: LocationManager?
    
    /// Internal device comunication object.
    private var manager: CLLocationManager
    
    /// Stored callbacks for authorizations.
    private var authorizationCallbacks = [AuthorizationCallback]()
    
    /// Delegate of events.
    public weak var delegate: LocationManagerDelegate?
    
    // MARK: - Public Properties

    /// The status of the authorization manager.
    public var authorizationStatus: CLAuthorizationStatus {
        if #available(iOS 14.0, *) {
            return manager.authorizationStatus
        } else {
            return CLLocationManager.authorizationStatus()
        }
    }
    
    public var allowsBackgroundLocationUpdates: Bool {
        set { manager.allowsBackgroundLocationUpdates = newValue }
        get { manager.allowsBackgroundLocationUpdates }
    }
    
    public var pausesLocationUpdatesAutomatically: Bool {
        set { manager.pausesLocationUpdatesAutomatically = newValue }
        get { manager.pausesLocationUpdatesAutomatically }
    }
    
    public var authorizationPrecise: GPSLocationOptions.Precise {
        if #available(iOS 14.0, *) {
            return GPSLocationOptions.Precise.fromCLAccuracyAuthorization(manager.accuracyAuthorization)
        } else {
            return .fullAccuracy // always return full accuracy for older iOS versions.
        }
    }
    
    // MARK: - Initialization
    
    required public init(locator: LocationManager) throws {
        self.locator = locator
        self.manager = CLLocationManager()
        super.init()

        self.manager.delegate = self
        // We want to activate background capabilities only if we found the key in Info.plist of the hosting app.
        self.manager.allowsBackgroundLocationUpdates = CLLocationManager.hasBackgroundCapabilities()
    }
    
    public var monitoredRegions: Set<CLRegion> {
        manager.monitoredRegions
    }
    
    public func monitorBeaconRegions(_ newRegions: [CLBeaconRegion]) {
        guard #available(macCatalyst 14.0, iOS 7.0, *) else {
            LocationManager.Logger.log("monitorBeaconRegions() is not available in this platform version")
            return
        }
        manager.stopMonitoringBeaconRegions(Array(manager.rangedRegions))
        manager.startMonitoringBeaconRegions(newRegions)
    }
    
    public func requestAuthorization(_ mode: AuthorizationMode?, _ callback: @escaping AuthorizationCallback) {
        guard let mode = mode else {
            callback(authorizationStatus)
            return
        }
        
        guard authorizationStatus.isAuthorized == false else {
            callback(authorizationStatus)
            return
        }
     
        authorizationCallbacks.append(callback)
        manager.requestAuthorization(mode)
    }
    
    /// Check for precise location authorization
    /// If user hasn't given it, ask for one time permission
    public func checkAndRequestForAccuracyAuthorizationIfNeeded(_ completion: ((Bool) -> Void)?) {
        if #available(iOS 14.0, *) {
            guard manager.accuracyAuthorization != .fullAccuracy else {
                completion?(true)
                return
            }
            manager.requestTemporaryFullAccuracyAuthorization(withPurposeKey: "OneTimeLocation") { [weak self] (error) in
                self?.manager.accuracyAuthorization == .fullAccuracy ? completion?(true) : completion?(false)
            }
        } else {
            // Ignore for any system below iOS 14+
            completion?(true)
        }
    }
    
    public func updateSettings(_ newSettings: LocationManagerSettings) {
        manager.setSettings(newSettings)
    }
    
    public func geofenceRegions(_ requests: [GeofencingRequest]) {
        // If region monitoring is not supported for this device just cancel all monitoring by dispatching `.notSupported`.
        let isMonitoringSupported = CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self)
        if !isMonitoringSupported {
            delegate?.locationManager(geofenceError: .notSupported, region: nil)
            return
        }
        
        let requestMonitorIds = Set<String>(requests.map({ $0.uuid }))
        let regionToStopMonitoring = manager.monitoredRegions.filter {
            requestMonitorIds.contains($0.identifier) == false
        }
        
        regionToStopMonitoring.forEach { [weak self] in
            LocationManager.Logger.log("Stop monitoring region: \($0)")
            self?.manager.stopMonitoring(for: $0)
        }
        
        requests.forEach { [weak self] in
            LocationManager.Logger.log("Start monitoring region: \($0.monitoredRegion)")
            self?.manager.startMonitoring(for: $0.monitoredRegion)
        }
    }
    
    // MARK: - Private Functions
    
    private func didChangeAuthorizationStatus(_ newStatus: CLAuthorizationStatus) {
        LocationManager.Logger.log("Authorization is set to = \(newStatus)")
        guard newStatus != .notDetermined else {
            return
        }
        
        let callbacks = authorizationCallbacks
        callbacks.forEach( { $0(authorizationStatus) })
        authorizationCallbacks.removeAll()
    }
    
    // MARK: - CLLocationManagerDelegate (Location GPS)
    
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if #available(iOS 14.0, *) {
            didChangeAuthorizationStatus(manager.authorizationStatus)
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        // This method is called only on iOS 13 or lower, for iOS14 we are using `locationManagerDidChangeAuthorization` below.
        didChangeAuthorizationStatus(status)
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        LocationManager.Logger.log("Failed to receive new locations: \(error.localizedDescription)")
        delegate?.locationManager(didFailWithError: error)
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        LocationManager.Logger.log("Received new locations: \(locations)")
        delegate?.locationManager(didReceiveLocations: locations)
    }
    
    // MARK: - CLLocationManagerDelegate (Geofencing)
    
    public func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if let beaconRegion = region as? CLBeaconRegion {
            locationManager(manager, didEnterBeaconRegion: beaconRegion)
            return
        }
        
        LocationManager.Logger.log("Did enter in region: \(region.identifier)")
        delegate?.locationManager(geofenceEvent: .didEnteredRegion(region))
    }
    
    public func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if let beaconRegion = region as? CLBeaconRegion {
            locationManager(manager, didExitBeaconRegion: beaconRegion)
            return
        }
        
        LocationManager.Logger.log("Did exit from region: \(region.identifier)")
        delegate?.locationManager(geofenceEvent: .didExitedRegion(region))
    }
    
    public func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        LocationManager.Logger.log("Did fail to monitoring region: \(region?.identifier ?? "all"). \(error.localizedDescription)")
        delegate?.locationManager(geofenceError: .generic(error), region: region)
    }
    
    public func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
        LocationManager.Logger.log("Did fail to monitoring visit: \(visit.description)")
        delegate?.locationManager(didVisits: visit)
    }
    
    // MARK: - CLLocationManagerDelegate (Beacons)

    public func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        manager.requestState(for: region)
    }
    
    public func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        guard let beaconRegion = region as? CLBeaconRegion else {
            return
        }
        guard #available(macCatalyst 14.0, iOS 7.0, *) else {
            return
        }
        switch state {
        case .inside:   manager.startRangingBeacons(in: beaconRegion)
        default:        manager.stopRangingBeacons(in: beaconRegion)
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        LocationManager.Logger.log("Did range beacons: \(beacons) in \(region.description)")
        let allBeacons = beacons.filter{ $0.proximity != CLProximity.unknown }
        delegate?.locationManager(didRangeBeacons: allBeacons, in: region)
    }
    
    private func locationManager(_ manager: CLLocationManager, didEnterBeaconRegion region: CLBeaconRegion) {
        LocationManager.Logger.log("Did enter in beacon region: \(region.identifier)")
        delegate?.locationManager(didEnterBeaconRegion: region)
    }
    
    private func locationManager(_ manager: CLLocationManager, didExitBeaconRegion region: CLBeaconRegion) {
        LocationManager.Logger.log("Did exit from beacon region: \(region.identifier)")
        delegate?.locationManager(didExitBeaconRegion: region)
    }
    
}

