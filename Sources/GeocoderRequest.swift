//
//  Geocoding.swift
//  SwiftLocation
//
//  Created by danielemargutti on 28/10/2017.
//  Copyright © 2017 Daniele Margutti. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit
import SwiftyJSON

public final class Geocoder_OpenStreet: GeocoderRequest {

	/// Operation of the request
	public private(set) var operation: GeocoderOperation
	
	/// Success Handler
	public var success: GeocoderRequest_Success?
	
	/// Failure Handler
	public var failure: GeocoderRequest_Failure?
	
	/// session task
	private var task: JSONOperation? = nil
	
	/// Timeout interval in seconds, `nil` means default timeout (10 seconds)
	public var timeout: TimeInterval?
	
	/// Initialize a new geocoder operation
	///
	/// - Parameter operation: operation
	public required init(operation: GeocoderOperation, timeout: TimeInterval) {
		self.operation = operation
		self.timeout = timeout
	}
	
	public func execute() {
		switch self.operation {
		case .getLocation(let a):
			self.execute_getLocation(a)
		case .getPlace(let l):
			self.execute_getPlace(l)
		}
	}
	
	/// Cancel any currently running task
	public func cancel() {
		self.task?.cancel()
	}

	private func execute_getPlace(_ coordinates: CLLocationCoordinate2D) {
		let url =  URL(string:"https://nominatim.openstreetmap.org/reverse?format=json&lat=\(coordinates.latitude)&lon=\(coordinates.longitude)&addressdetails=1&limit=1")!
		self.task = JSONOperation(url, timeout: self.timeout)
		self.task?.onFailure = { err in
			self.failure?(err)
		}
		self.task?.onSuccess = { json in
			self.success?([self.parseResultPlace(json)])
		}
		self.task?.execute()
	}
	
	private func execute_getLocation(_ address: String) {
		let fAddr = address.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
		let url =  URL(string:"https://nominatim.openstreetmap.org/search/\(fAddr)?format=json&addressdetails=1&limit=1")!
		self.task = JSONOperation(url, timeout: self.timeout)
		self.task?.onFailure = { err in
			self.failure?(err)
		}
		self.task?.onSuccess = { json in
			let places = json.arrayValue.map { self.parseResultPlace($0) }
			self.success?(places)
		}
		self.task?.execute()
	}
	
	private func parseResultPlace(_ json: JSON) -> Place {
		let place = Place()
		place.coordinates = CLLocationCoordinate2DMake(json["lat"].doubleValue, json["lon"].doubleValue)
		place.countryCode = json["address"]["country_code"].string
		place.country = json["address"]["country"].string
		place.state = json["address"]["state"].string
		place.county = json["address"]["county"].string
		place.postcode = json["address"]["postcode"].string
		place.city = json["address"]["city"].string
		place.cityDistrict = json["address"]["city_district"].string
		place.road = json["address"]["road"].string
		place.houseNumber = json["address"]["house_number"].string
		place.name = json["display_name"].string
		return place
	}
	
	public func onSuccess(_ success: @escaping GeocoderRequest_Success) -> Self {
		self.success = success
		return self
	}
	
	public func onFailure(_ failure: @escaping GeocoderRequest_Failure) -> Self {
		self.failure = failure
		return self
	}

}

public final class Geocoder_Apple: GeocoderRequest {
	
	/// Operation of the request
	public private(set) var operation: GeocoderOperation
	
	/// Success Handler
	public var success: GeocoderRequest_Success?
	
	/// Failure Handler
	public var failure: GeocoderRequest_Failure?
	
	public var timeout: TimeInterval?

	private var task: JSONOperation? = nil

	/// Initialize a new geocoder operation
	///
	/// - Parameter operation: operation
	public required init(operation: GeocoderOperation, timeout: TimeInterval) {
		self.operation = operation
		self.timeout = timeout
	}
	
	public func execute() {
		
	}
	
	public func cancel() {
		self.task?.cancel()
	}
	
	public func onSuccess(_ success: @escaping GeocoderRequest_Success) -> Self {
		self.success = success
		return self
	}
	
	public func onFailure(_ failure: @escaping GeocoderRequest_Failure) -> Self {
		self.failure = failure
		return self
	}
}


public class Place: CustomStringConvertible {
	public internal(set) var coordinates: CLLocationCoordinate2D?
	public internal(set) var countryCode: String?
	public internal(set) var country: String?
	public internal(set) var state: String?
	public internal(set) var county: String?
	public internal(set) var postcode: String?
	public internal(set) var city: String?
	public internal(set) var cityDistrict: String?
	public internal(set) var road: String?
	public internal(set) var houseNumber: String?
	public internal(set) var name: String?
	
	public var description: String {
		return self.name ?? "Unknown Place"
	}
}
