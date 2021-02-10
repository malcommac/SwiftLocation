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
import CoreBluetooth

#if canImport(SwiftLocation)
import SwiftLocation
#endif

internal class BeaconBroadcaster: NSObject, CBPeripheralManagerDelegate {
    
    // MARK: - Internal Properties
    
    /// Shared instance.
    internal static let shared = BeaconBroadcaster()
    
    /// Receive callback about the advetisting.
    internal var onStatusDidChange: ((Error?) -> Void)?
    
    /// Check if the broadcasting is active or not.
    internal var isBroadcastingActive: Bool {
        peripheralManager?.isAdvertising ?? false
    }
    
    /// Monitored identifier.
    internal var beacon: BroadcastedBeacon?
    
    // MARK: - Private Properties
    
    /// Manager.
    private var peripheralManager: CBPeripheralManager?
    
    // MARK: - Internal Functions
    
    /// Start broadcasting.
    internal func startBroadcastingAs(_ beacon: BroadcastedBeacon, onStatusDidChange: ((Error?) -> Void)? = nil) {
        self.beacon = beacon
        self.onStatusDidChange = onStatusDidChange
        
        stopBroadcasting()

        self.peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    /// Stop active broadcasting.
    internal func stopBroadcasting() {
        peripheralManager?.stopAdvertising()
        peripheralManager = nil
    }
    
    // MARK: - CBPeripheralManagerDelegate
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            guard let region = beacon?.region else {
                LocationManager.Logger.log("Failed to get region from broadcast beacon passed.")
                return
            }
            
            let data = ((region.peripheralData(withMeasuredPower: nil)) as NSDictionary) as! Dictionary<String, Any>
            peripheral.startAdvertising(data)
            LocationManager.Logger.log("Bluetooth peripheral on, start adveristing")
            
        case .poweredOff:
            peripheral.stopAdvertising()
            LocationManager.Logger.log("Bluetooth peripheral off, stop adveristing")
        default:
            LocationManager.Logger.log("Bluetooth peripheral \(peripheral.description)")
            break
        }
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        onStatusDidChange?(nil)

        if let error = error {
            LocationManager.Logger.log("Error bluetooth advertising \(error.localizedDescription)")
        } else {
            LocationManager.Logger.log("Bluetooth advertising started successfully")
        }
    }
    
}

// MARK: - BroadcastedBeacon

public struct BroadcastedBeacon {
    
    /// Monitored UUID.
    public let uuid: String
    
    /// Monitored identifier.
    public let identifier: String
    
    /// Monitored regions.
    public let region: CLBeaconRegion?
    
    /// Initialzie a new beacon to broadcast.
    public init?(UUID uuidIdentifier: String,
                majorID: CLBeaconMajorValue, minorID: CLBeaconMinorValue,
                identifier: String) {
        
        guard let uuidInstance = UUID(uuidString: uuidIdentifier) else {
            return nil
        }
        
        self.uuid = uuidIdentifier
        self.identifier = identifier
        
        // create the region that will be used to send
        self.region = CLBeaconRegion(
            proximityUUID: uuidInstance,
            major: majorID,
            minor: minorID,
            identifier: identifier
        )
    }
    
}
