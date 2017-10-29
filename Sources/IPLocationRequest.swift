//
//  IPLocationRequest.swift
//  SwiftLocation
//
//  Created by danielemargutti on 29/10/2017.
//  Copyright © 2017 Daniele Margutti. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit
import SwiftyJSON

/// Get the current location data using IP address of the device
public class IPLocationRequest: Request, Hashable, Equatable {
	
	/// Callback called on success
	internal var success: LocationRequest.Success? = nil
	
	/// Callback called on failure
	internal var failure: LocationRequest.Failure? = nil
	
	/// Hash value
	public var hashValue: Int {
		return self.id.hashValue
	}
	
	/// Timeout interval
	public private(set) var timeout: TimeInterval?
	
	/// JSON Operation to download data
	private var task: JSONOperation? = nil
	
	/// Identifier of the request
	public private(set) var id: RequestID = UUID().uuidString
	
	/// Service used to retrive the location
	public private(set) var service: IPService

	public static func ==(lhs: IPLocationRequest, rhs: IPLocationRequest) -> Bool {
		return lhs.id == rhs.id
	}
	
	/// Init a new IP service with given data
	///
	/// - Parameters:
	///   - service: service to use
	///   - timeout: timeout, `nil` means 10 seconds timeout
	public init(_ service: IPService, timeout: TimeInterval? = nil) {
		self.service = service
		self.timeout = timeout
	}
	
	/// Execute the operation
	internal func execute() {
		self.task = JSONOperation(self.service.url, timeout: self.timeout)
		self.task?.onSuccess = { json in
			var latKey = "latitude"
			var lngKey = "longitude"
			switch self.service {
			case .ipApi:
				latKey = "lat"
				lngKey = "lon"
			default:
				break
			}
			if let lat = json[latKey].double, let lng = json[lngKey].double {
				let loc = CLLocation(latitude: lat, longitude: lng)
				self.success?(loc)
				return
			}
			self.failure?(LocationError.failedToObtainData, nil)
		}
		self.task?.onFailure = { err in
			self.failure?(err,nil)
		}
		self.task?.execute()
	}
	
	public func cancel() {
		self.task?.cancel()
	}
	
}
