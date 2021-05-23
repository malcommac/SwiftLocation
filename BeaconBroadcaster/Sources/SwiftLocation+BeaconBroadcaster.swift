//
//  SwiftLocation.swift
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

#if canImport(SwiftLocation)
import SwiftLocation
#endif

#if os(OSX)
import AppKit
#else
import UIKit
#endif

public extension LocationManager {

    /// Return true if beacon foreground broadcasting is active or not.
    var isBeaconBroadcastActive: Bool {
        BeaconBroadcaster.shared.isBroadcastingActive
    }
    
    /// Return non `nil` values when broadcasting is active.
    var broadcastingBeacon: BroadcastedBeacon? {
        BeaconBroadcaster.shared.beacon
    }
    
    /// Start broadcasting beacon. This works only in foreground.
    /// NOTE: Broadcaster does not work when app is killed or is in background.
    ///
    /// - Parameters:
    ///   - UUID: UUID.
    ///   - majorID: major ID.
    ///   - minorID: minor ID.
    ///   - identifier: identifier of the beacon.
    ///   - onStatusDidChange: callback to receive the advertising result process.
    func broadcastAsBeacon(_ beacon: BroadcastedBeacon, onStatusDidChange: ((Error?) -> Void)? = nil) {
        BeaconBroadcaster.shared.startBroadcastingAs(beacon, onStatusDidChange: onStatusDidChange)
    }
    
    /// Stop running broadcast.
    func stopBroadcasting() {
        BeaconBroadcaster.shared.stopBroadcasting()
    }
    
}
