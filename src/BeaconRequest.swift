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
		/// Identifier of the request
	private(set) var identifier: String
	
		/// This property contains the identifier that you use to identify your company’s beacons. You typically generate only one UUID for your company’s beacons but can generate more as needed
	public var UUID: String {
		get {
			return beaconRegion!.proximityUUID.UUIDString
		}
	}
	
	/// The major property contains a value that can be used to group related sets of beacons. For example, a department store might assign the same major value for all of the beacons on the same floor.
	public var majorID: CLBeaconMajorValue? {
		get {
			return (beaconRegion!.major != nil ? CLBeaconMajorValue(beaconRegion!.major!.intValue) : nil)
		}
	}
	
	/// The minor property specifies the individual beacon within a group. For example, for a group of beacons on the same floor of a department store, this value might be assigned to a beacon in a particular section.
	public var minorID: CLBeaconMajorValue? {
		get {
			return (beaconRegion!.major != nil ? CLBeaconMajorValue(beaconRegion!.major!.intValue) : nil)
		}
	}
	
		/// Beacon region monitored by this request
	private(set) var beaconRegion: CLBeaconRegion?
	
		/// State of the monitor
	internal(set) var state: BeaconState = .Unknown
	
		/// Handler called when beacon were found into the region
	public var onRangeDidFoundBeacons: DidRangeBeaconsHandler?
		/// Handler called when an error has occurred. Request will be stopped and removed from the queue.
	public var onRangeDidFail: RangeBeaconsDidFailHandler?
	
	/**
	Create a new request to monitor a beacon family identified by passed proximity uuid
	
	- parameter uuid:       identifier that you use to identify your company’s beacons. You typically generate only one UUID for your company’s beacons but can generate more as needed
	- parameter identifier: identifier of the region. If you pass nil a new identifier is generated automatically for you
	
	- returns: request you can add into the main queue
	*/
	public init(beaconFamilyWithUUID uuid: String, identifier: String? = nil) {
		self.identifier = (identifier ?? NSUUID().UUIDString)
		self.beaconRegion = CLBeaconRegion(proximityUUID: NSUUID(UUIDString: self.UUID)!, identifier: self.identifier)
	}
	
	/**
	Create a new request to monitor a beacon
	
	- parameter uuid:       identifier that you use to identify your company’s beacons. You typically generate only one UUID for your company’s beacons but can generate more as needed
	- parameter major:      The major property contains a value that can be used to group related sets of beacons. For example, a department store might assign the same major value for all of the beacons on the same floor.
	- parameter minor:      The minor property specifies the individual beacon within a group. For example, for a group of beacons on the same floor of a department store, this value might be assigned to a beacon in a particular section.
	- parameter identifier: identifier of the region. If you pass nil a new identifier is generated automatically for you
	
	- returns: request you can add into the main queue
	*/
	public init(beaconWithUUID uuid: String, major: CLBeaconMajorValue, minor: CLBeaconMajorValue, identifier: String? = nil) {
		self.identifier = (identifier ?? NSUUID().UUIDString)
		self.beaconRegion = CLBeaconRegion(proximityUUID: NSUUID(UUIDString: self.UUID)!, major: self.majorID!, minor: self.minorID!, identifier: self.identifier)
	}

	//MARK: Private
	
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