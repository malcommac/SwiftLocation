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
	
	/// session task
	private var task: JSONOperation? = nil
	
	public override func execute() {
		guard self.isFinished == false else { return }
		switch self.operation {
		case .getLocation(let a,_):
			self.execute_getLocation(a)
		case .getPlace(let l,_):
			self.execute_getPlace(l)
		}
	}
	
	/// Cancel any currently running task
	public override func cancel() {
		self.task?.cancel()
		super.cancel()
	}
	
	private func execute_getPlace(_ c: CLLocationCoordinate2D) {
		guard let APIKey = Locator.api.googleAPIKey else {
			self.failure?(LocationError.missingAPIKey(forService: "google"))
			return
		}
		let url = URL(string: "https://maps.googleapis.com/maps/api/geocode/json?latlng=\(c.latitude),\(c.longitude)&key=\(APIKey)")!
		self.task = JSONOperation(url, timeout: self.timeout)
		self.task?.onFailure = { [weak self] err in
            guard let `self` = self else { return }
			self.failure?(err)
			self.isFinished = true
		}
		self.task?.onSuccess = { [weak self] json in
            guard let `self` = self else { return }
			let places = json["results"].arrayValue.map { Place(googleJSON: $0) }
			self.success?(places)
			self.isFinished = true
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
		self.task?.onFailure = { [weak self] err in
            guard let `self` = self else { return }
			self.failure?(err)
			self.isFinished = true
		}
		self.task?.onSuccess = { [weak self] json in
            guard let `self` = self else { return }
			let places = json["results"].arrayValue.map { Place(googleJSON: $0) }
			self.success?(places)
			self.isFinished = true
		}
		self.task?.execute()
	}

}

//MARK: Geocoder OpenStreetMap

public final class Geocoder_OpenStreet: GeocoderRequest {
	
	/// session task
	private var task: JSONOperation? = nil
	
	public override func execute() {
		guard self.isFinished == false else { return }
		switch self.operation {
		case .getLocation(let a,_):
			self.execute_getLocation(a)
		case .getPlace(let l,_):
			self.execute_getPlace(l)
		}
	}
	
	/// Cancel any currently running task
	public override func cancel() {
		self.task?.cancel()
		super.cancel()
	}

	private func execute_getPlace(_ coordinates: CLLocationCoordinate2D) {
		let url =  URL(string:"https://nominatim.openstreetmap.org/reverse?format=json&lat=\(coordinates.latitude)&lon=\(coordinates.longitude)&addressdetails=1&limit=1")!
		self.task = JSONOperation(url, timeout: self.timeout)
		self.task?.onFailure = { [weak self] err in
            guard let `self` = self else { return }
			self.failure?(err)
			self.isFinished = true
		}
		self.task?.onSuccess = { [weak self] json in
            guard let `self` = self else { return }
			self.success?([self.parseResultPlace(json)])
			self.isFinished = true
		}
		self.task?.execute()
	}
	
	private func execute_getLocation(_ address: String) {
		let fAddr = address.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
		let url =  URL(string:"https://nominatim.openstreetmap.org/search/\(fAddr)?format=json&addressdetails=1&limit=1")!
		self.task = JSONOperation(url, timeout: self.timeout)
		self.task?.onFailure = { [weak self] err in
            guard let `self` = self else { return }
			self.failure?(err)
			self.isFinished = true
		}
		self.task?.onSuccess = { [weak self] json in
            guard let `self` = self else { return }
			let places = json.arrayValue.map { self.parseResultPlace($0) }
			self.success?(places)
			self.isFinished = true
		}
		self.task?.execute()
	}
	
	private func parseResultPlace(_ json: JSON) -> Place {
		let place = Place()
		place.coordinates = CLLocationCoordinate2DMake(json["lat"].doubleValue, json["lon"].doubleValue)
		place.countryCode = json["address"]["country_code"].string
		place.country = json["address"]["country"].string
		place.administrativeArea = json["address"]["state"].string
		place.subAdministrativeArea = json["address"]["county"].string
		place.postalCode = json["address"]["postcode"].string
		place.city = json["address"]["city"].string
		place.locality = json["address"]["city_district"].string
		place.thoroughfare = json["address"]["road"].string
		place.subThoroughfare = json["address"]["house_number"].string
		place.name = json["display_name"].string
		place.rawDictionary = json.dictionaryObject
		return place
	}

}

//MARK: Geocoder Apple

public final class Geocoder_Apple: GeocoderRequest {

	/// Task
	private var task: CLGeocoder?

	public override func execute() {
		guard self.isFinished == false else { return }
	
		let geocoder = CLGeocoder()
		self.task = geocoder

        let geocodeCompletionHandler: CoreLocation.CLGeocodeCompletionHandler = { [weak self] (placemarks, error) in
            if let err = error {
                self?.failure?(LocationError.other(err.localizedDescription))
				self?.isFinished = true
                return
            }

			let place = Place.load(placemarks: placemarks ?? [])
            self?.success?(place)
			self?.isFinished = true
        }

		switch self.operation {
		case .getLocation(let address, let region):
			geocoder.geocodeAddressString(address, in: region, completionHandler: geocodeCompletionHandler)
		case .getPlace(let coordinates, let locale):
			let loc = CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)

			if #available(iOS 11, *) {
				geocoder.reverseGeocodeLocation(loc, preferredLocale: locale, completionHandler: geocodeCompletionHandler)
			} else {
				// Fallback on earlier versions
				geocoder.reverseGeocodeLocation(loc, completionHandler: geocodeCompletionHandler)
			}
		}
	}
	
	public override func cancel() {
		self.task?.cancelGeocode()
		super.cancel()
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
