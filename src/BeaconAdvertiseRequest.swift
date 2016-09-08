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

open class BeaconAdvertiseRequest: NSObject, Request {
	
	
	open var UUID: String
	open var rState: RequestState = .pending
	fileprivate(set) var region: CLBeaconRegion
	fileprivate(set) var RSSIPower: NSNumber?
	fileprivate(set) var name: String
	/// Authorization did change
	open var onAuthorizationDidChange: LocationHandlerAuthDidChange?
	
	init?(name: String, proximityUUID: String, major: CLBeaconMajorValue? = nil, minor: CLBeaconMinorValue? = nil) {
		self.name = name
		guard let proximityUUID = Foundation.UUID(uuidString: proximityUUID) else { // invalid Proximity UUID
			return nil
		}
		self.UUID = proximityUUID.uuidString
		if major == nil && minor == nil {
			self.region = CLBeaconRegion(proximityUUID: proximityUUID, identifier: self.UUID)
		} else if major != nil && minor != nil {
			self.region = CLBeaconRegion(proximityUUID: proximityUUID, major: major!, minor: minor!, identifier: self.UUID)
		} else {
			return nil
		}
	}
	
	open func cancel(_ error: LocationError?) {
		if self.rState.isRunning == true {
			_ = Beacons.stopAdvertise(self.name, error: error)
		}
	}
	
	open func cancel() {
		self.cancel(nil)
	}
	
	open func pause() {
		if self.rState.isRunning == true {
			_ = Beacons.stopAdvertise(self.name, error: nil)
			self.rState = .paused
		}
	}
	
	open func start() {
		if self.rState.canStart == true {
			self.rState = .running
			Beacons.updateBeaconAdvertise()
		}
	}
	
	internal func dataToAdvertise() -> [String:AnyObject?] {
		let data: [String:AnyObject?] = [
			CBAdvertisementDataLocalNameKey : self.name as ImplicitlyUnwrappedOptional<AnyObject>,
			CBAdvertisementDataManufacturerDataKey : self.region.peripheralData(withMeasuredPower: self.RSSIPower),
			CBAdvertisementDataServiceUUIDsKey : self.UUID as Optional<AnyObject>]
		return data
	}

}
