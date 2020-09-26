//
//  CLDeviceLocationManager.swift
//  SwiftLocation
//
//  Created by Daniele Margutti on 17/09/2020.
//

import Foundation
import CoreLocation

public class DeviceLocationManager: NSObject, LocationManagerProtocol, CLLocationManagerDelegate {
    
    // MARK: - Private Properties
    
    /// Parent locator manager.
    private weak var locator: Locator?
    
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
    
    // MARK: - Initialization
    
    required public init(locator: Locator) throws {
        self.locator = locator
        self.manager = CLLocationManager()
        super.init()

        self.manager.delegate = self
        // We want to activate background capabilities only if we found the key in Info.plist of the hosting app.
        self.manager.allowsBackgroundLocationUpdates = CLLocationManager.hasBackgroundCapabilities()
    }
    
    public func requestAuthorization(_ mode: AuthorizationMode, _ callback: @escaping AuthorizationCallback) {
        guard authorizationStatus.isAuthorized == false else {
            callback(authorizationStatus)
            return
        }
     
        authorizationCallbacks.append(callback)
        manager.requestAuthorization(mode)
    }
    
    public func updateSettings(_ newSettings: LocationManagerSettings) {
        manager.setSettings(newSettings)
    }
    
    // MARK: - Private Functions
    
    private func didChangeAuthorizationStatus(_ newStatus: CLAuthorizationStatus) {
        guard newStatus != .notDetermined else {
            return
        }
        
        let callbacks = authorizationCallbacks
        callbacks.forEach( { $0(authorizationStatus) })
        authorizationCallbacks.removeAll()
    }
    
    // MARK: - CLLocationManagerDelegate
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        // This method is called only on iOS 13 or lower, for iOS14 we are using `locationManagerDidChangeAuthorization` below.
        didChangeAuthorizationStatus(status)
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        delegate?.locationManager(didFailWithError: error)
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        delegate?.locationManager(didReceiveLocations: locations)
    }
    
}

