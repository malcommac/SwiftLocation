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
import Contacts
import SwiftyJSON

//MARK: Geocoder Google

public final class Geocoder_Google: GeocoderRequest {
	
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
		case .getLocation(let a,_):
			self.execute_getLocation(a)
		case .getPlace(let l,_):
			self.execute_getPlace(l)
		}
	}
	
	/// Cancel any currently running task
	public func cancel() {
		self.task?.cancel()
	}
	
	private func execute_getPlace(_ c: CLLocationCoordinate2D) {
		guard let APIKey = Locator.api.googleAPIKey else {
			self.failure?(LocationError.missingAPIKey(forService: "google"))
			return
		}
		let url = URL(string: "https://maps.googleapis.com/maps/api/geocode/json?latlng=\(c.latitude),\(c.longitude)&key=\(APIKey)")!
		self.task = JSONOperation(url, timeout: self.timeout)
		self.task?.onFailure = { err in
			self.failure?(err)
		}
		self.task?.onSuccess = { json in
			let places = json["results"].arrayValue.map { Place(googleJSON: $0) }
			self.success?(places)
		}
		self.task?.execute()
	}
	
	private func execute_getLocation(_ address: String) {
		guard let APIKey = Locator.api.googleAPIKey else {
			self.failure?(LocationError.missingAPIKey(forService: "google"))
			return
		}
		let url = URL(string: "https://maps.googleapis.com/maps/api/geocode/json?address=\(address.urlEncoded)&key=\(APIKey)")!
		self.task = JSONOperation(url, timeout: self.timeout)
		self.task?.onFailure = { err in
			self.failure?(err)
		}
		self.task?.onSuccess = { json in
			let places = json["results"].arrayValue.map { Place(googleJSON: $0) }
			self.success?(places)
		}
		self.task?.execute()
	}

}

//MARK: Geocoder OpenStreetMap

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
		case .getLocation(let a,_):
			self.execute_getLocation(a)
		case .getPlace(let l,_):
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
		place.rawDictionary = json.dictionaryObject
		return place
	}

}

//MARK: Geocoder Apple

public final class Geocoder_Apple: GeocoderRequest {
	
	/// Operation of the request
	public private(set) var operation: GeocoderOperation
	
	/// Success Handler
	public var success: GeocoderRequest_Success?
	
	/// Failure Handler
	public var failure: GeocoderRequest_Failure?
	
	/// Timeout interval
	public var timeout: TimeInterval?

	/// Task
	private var task: CLGeocoder?
	
	private var isFinished: Bool = false
	
	/// Initialize a new geocoder operation
	///
	/// - Parameter operation: operation
	public required init(operation: GeocoderOperation, timeout: TimeInterval) {
		self.operation = operation
		self.timeout = timeout
	}
	
	public func execute() {
		guard self.isFinished == false else { return }
	
		let geocoder = CLGeocoder()
		self.task = geocoder
		switch self.operation {
		case .getLocation(let address, let region):
			geocoder.geocodeAddressString(address, in: region, completionHandler: { (placemarks, error) in
				self.isFinished = true
			})
		case .getPlace(let coordinates, let locale):
			let loc = CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)
			if #available(iOS 11, *) {
				geocoder.reverseGeocodeLocation(loc, preferredLocale: locale, completionHandler: { (placemarks, error) in
					self.isFinished = true
					if let err = error {
						self.failure?(LocationError.other(err.localizedDescription))
						return
					}
					self.success?(Place.load(placemarks: placemarks ?? []))
				})
			} else {
				// Fallback on earlier versions
				geocoder.reverseGeocodeLocation(loc, completionHandler: { (placemarks, error) in
					self.isFinished = true
					if let err = error {
						self.failure?(LocationError.other(err.localizedDescription))
						return
					}
					self.success?(Place.load(placemarks: placemarks ?? []))
				})
			}
		}
	}
	
	public func cancel() {
		self.task?.cancelGeocode()
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
