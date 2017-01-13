//
//  Accuracy.swift
//  SwiftLocation
//
//  Created by Daniele Margutti on 08/01/2017.
//  Copyright © 2017 Daniele Margutti. All rights reserved.
//

import Foundation
import MapKit
import CoreLocation

public struct IPService: CustomStringConvertible {
	
	public typealias IPServiceSuccessCallback = ((CLLocation) -> (Void))
	public typealias IPServiceFailureCallback = ((Error?) -> (Void))
	
	public var service: IPService.Name
	public var timeout: TimeInterval = 10
	
	public enum Name: CustomStringConvertible {
		case freeGeoIP
		case petabyet
		case smartIP
		case telize
		
		public var description: String {
			switch self {
			case .freeGeoIP:	return "FreeGeoIP"
			case .petabyet:		return "Petabyet"
			case .smartIP:		return "SmartIP"
			case .telize:		return "Telize"
			}
		}
	}
	
	public init(_ service: Name) {
		self.service = service
	}
	
	public var description: String {
		get { return self.service.description }
	}
	
	public func locationData(success: @escaping IPServiceSuccessCallback, fail: @escaping IPServiceFailureCallback)  {
		switch self.service {
		case .freeGeoIP:
			freeGeoIP(success: success, fail: fail)
		case .petabyet:
			break
		case .smartIP:
			break
		case .telize:
			break
		}
	}
	
	private func freeGeoIP(success: @escaping IPServiceSuccessCallback, fail: @escaping IPServiceFailureCallback) {
		let request = NSMutableURLRequest(url: URL(string: "http://freegeoip.net/json/")!,
		                                  cachePolicy: NSURLRequest.CachePolicy.reloadIgnoringCacheData,
		                                  timeoutInterval: self.timeout)
		let task = URLSession.shared.dataTask(with: request as URLRequest) { (data, response, error) in
			do {
				guard let data = data else {
					fail(error)
					return
				}
				let opts = JSONSerialization.ReadingOptions.init(rawValue: 0)
				guard let json = try JSONSerialization.jsonObject(with: data, options: opts) as? NSDictionary else {
					fail(LocationError.noData)
					return
				}
				guard	let latitude = json.value(forKey: "latitude") as? CLLocationDegrees,
						let longitude = json.value(forKey: "longitude") as? CLLocationDegrees else {
					fail(LocationError.noData)
					return
				}
				let loc = CLLocation(latitude: latitude, longitude: longitude)
				success(loc)
			} catch {
				fail(LocationError.invalidData)
			}
		}
		task.resume()
	}
}

public enum Accuracy: CustomStringConvertible {
	case IPScan(_: IPService)
	case any
	case country
	case city
	case neighborhood
	case block
	case house
	case room
	case navigation
	
	/// Order by accuracy
	internal var orderValue: Int {
	switch self {
	case .IPScan(_):	return 0
	case .any:			return 1
	case .country:		return 2
	case .city:			return 3
	case .neighborhood:	return 4
	case .block:		return 5
	case .house:		return 6
	case .room:			return 7
	case .navigation:	return 8
	}
	}
	
	/// Accuracy measured in meters
	public var meters: Double {
		switch self {
		case .IPScan(_):	return Double.infinity
		case .any:			return 1000000.0
		case .country:		return 100000.0
		case .city:			return kCLLocationAccuracyThreeKilometers
		case .neighborhood:	return kCLLocationAccuracyKilometer
		case .block:		return kCLLocationAccuracyHundredMeters
		case .house:		return kCLLocationAccuracyNearestTenMeters
		case .room:			return kCLLocationAccuracyBest
		case .navigation:	return kCLLocationAccuracyBestForNavigation
		}
	}
	
	/// Validate given `location` against the current accuracy.
	///
	/// - Parameter location: location to validate
	/// - Returns: `true` if valid, `false` otherwise
	public func isValid(_ location: CLLocation) -> Bool {
		switch self {
		case .room, .navigation:
			// This because kCLLocationAccuracyBest and kCLLocationAccuracyBestForNavigation
			// are not real values but only placeholder for a particular accuracy type
			// and values depended by the hardware.
			return (location.horizontalAccuracy < kCLLocationAccuracyNearestTenMeters)
		default:
			// Otherwise we can check meters
			return (location.horizontalAccuracy <= self.meters)
		}
	}
	
	
	/// CoreLocation user authorizations are required for this accuracy
	public var accuracyRequireAuthorization: Bool {
		get {
			guard case .IPScan(_) = self else { // only ip-scan does not require auth
				return true
			}
			return false
		}
	}
	
	/// Description of the accuracy
	public var description: String {
		switch self {
		case .IPScan(let service):		return "IPScan \(service)"
		case .any:						return "Any"
		case .country:					return "Country"
		case .city:						return "City"
		case .neighborhood:				return "Neighborhood (\(self.meters) meters)"
		case .block:					return "Block (\(self.meters) meters)"
		case .house:					return "House (\(self.meters) meters)"
		case .room:						return "Room"
		case .navigation:				return "Navigation"
		}
	}
}
