//
//  Beacon.swift
//  SwiftLocation
//
//  Created by Daniele Margutti on 19/04/16.
//  Copyright © 2016 danielemargutti. All rights reserved.
//

import Foundation
import CoreLocation
import CoreBluetooth

public enum BeaconState {
	case Unknown
	case Advertising
	case Monitoring
}

public class BeaconRequest: Equatable {
	private(set) var identifier: String
	public var UUID: String {
		get {
			return beaconRegion!.proximityUUID.UUIDString
		}
	}
	public var majorID: CLBeaconMajorValue? {
		get {
			return (beaconRegion!.major != nil ? CLBeaconMajorValue(beaconRegion!.major!.intValue) : nil)
		}
	}
	public var minorID: CLBeaconMajorValue? {
		get {
			return (beaconRegion!.major != nil ? CLBeaconMajorValue(beaconRegion!.major!.intValue) : nil)
		}
	}
	private(set) var beaconRegion: CLBeaconRegion?
	internal(set) var state: BeaconState = .Unknown
	
	public var onRangeDidFoundBeacons: DidRangeBeaconsHandler?
	public var onRangeDidFail: RangeBeaconsDidFailHandler?
	
	public init(beaconFamilyWithUUID uuid: String, identifier: String? = nil) {
		self.identifier = (identifier ?? NSUUID().UUIDString)
		self.beaconRegion = CLBeaconRegion(proximityUUID: NSUUID(UUIDString: self.UUID)!, identifier: self.identifier)
	}
	
	public init(beaconWithUUID uuid: String, major: CLBeaconMajorValue, minor: CLBeaconMajorValue, identifier: String? = nil) {
		self.identifier = (identifier ?? NSUUID().UUIDString)
		self.beaconRegion = CLBeaconRegion(proximityUUID: NSUUID(UUIDString: self.UUID)!, major: self.majorID!, minor: self.minorID!, identifier: self.identifier)
	}

	public func startAdversiting() {
		BeaconManager.main.advertise(self)
	}
	
	public func stopAdversiting() {
		BeaconManager.main.stopAdvertise(self)
	}
	
	internal func dataToAdvertise() -> [String:AnyObject!] {
		let data: [String:AnyObject!] = [
			CBAdvertisementDataLocalNameKey : self.identifier,
			CBAdvertisementDataManufacturerDataKey : self.beaconRegion!.peripheralDataWithMeasuredPower(nil),
			CBAdvertisementDataServiceUUIDsKey : [self.UUID]]
		return data
	}
	
}

public func == (lhs: BeaconRequest, rhs: BeaconRequest) -> Bool {
	return (lhs.UUID == rhs.UUID && lhs.majorID == rhs.majorID && lhs.minorID == rhs.minorID && lhs.identifier == rhs.identifier)
}