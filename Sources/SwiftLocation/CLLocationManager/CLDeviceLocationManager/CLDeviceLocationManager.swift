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
    
    private weak var locator: Locator?
    private var manager: CLLocationManager
    private var authorizationCallbacks = [AuthorizationCallback]()
    
    public var authorizationStatus: CLAuthorizationStatus {
        manager.authorizationStatus
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
    
    public func updateSettings() {
        
        
    }
    
    // MARK: - Private Functions
    
    private func didChangeAuthorizationStatus() {
        let callbacks = authorizationCallbacks
        callbacks.forEach( { $0(authorizationStatus) })
        authorizationCallbacks.removeAll()
    }
    

    // MARK: - CLLocationManagerDelegate
    
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        didChangeAuthorizationStatus()
    }
    
}

