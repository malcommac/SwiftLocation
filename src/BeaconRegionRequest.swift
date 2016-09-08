//
//  SwiftLocation.swift
//  SwiftLocations
//
// Copyright (c) 2016 Daniele Margutti
// Web:			http://www.danielemargutti.com
// Mail:		me@danielemargutti.com
// Twitter:		@danielemargutti
//
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation
import CoreBluetooth
import CoreLocation

public class BeaconRegionRequest: NSObject, Request {
	
	public var UUID: String
	public var rState: RequestState = .Pending
	private(set) var region: CLBeaconRegion
	private(set) var type: Event
	/// Authorization did change
	public var onAuthorizationDidChange: LocationHandlerAuthDidChange?

	public var onStateDidChange: RegionStateDidChange?
	public var onRangingBeacons: RegionBeaconsRanging?
	public var onError: RegionMonitorError?
	
	init?(beacon: Beacon, monitor: Event) {
		self.type = monitor
		guard let proximityUUID = NSUUID(UUIDString: beacon.proximityUUID) else { // invalid Proximity UUID
			return nil
		}
		self.UUID = proximityUUID.UUIDString
		if beacon.major == nil && beacon.minor == nil {
			self.region = CLBeaconRegion(proximityUUID: proximityUUID, identifier: self.UUID)
		} else if beacon.major != nil && beacon.minor != nil {
			self.region = CLBeaconRegion(proximityUUID: proximityUUID, major: beacon.major!, minor: beacon.minor!, identifier: self.UUID)
		} else {
			return nil
		}
	}
	
	public func cancel(error: LocationError?) {
		Beacons.remove(request: self, error: error)
	}
	
	/**
	Terminate request without errors
	*/
	public func cancel() {
		self.cancel(nil)
	}
	
	public func pause() {
		if Beacons.remove(request: self) == true {
			self.rState = .Paused
		}
	}
	
	public func start() {
		if self.rState.isRunning == false {
			if Beacons.add(request: self) == true {
				self.rState = .Running
			}
		}
	}

}