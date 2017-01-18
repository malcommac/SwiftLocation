//
//  CLLocation+Extras.swift
//  SwiftLocation
//
//  Created by Daniele Margutti on 17/01/2017.
//  Copyright © 2017 Daniele Margutti. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit

public extension CLLocation {
	
	/// Reverse location object and return found placemarks or get an error
	/// Note: Geocoding requests are rate-limited for each app, so making too many requests in a short period of
	///	time may cause some of the requests to fail.
	///
	/// - Parameters:
	///   - success:	callback to execute on success. Contains an array of `CLPlacemark` objects.
	///					For most geocoding requests, this array should contain only one entry.
	///					However, forward-geocoding requests may return multiple placemark objects in situations where
	///					the specified address could not be resolved to a single location.
	///   - fail:		callback to execute on failure. Failure may be a generic error or `LocationError.noData` if no
	///					placemark were found.
	public func reverse(timeout: TimeInterval? = nil,
	                    _ success: @escaping GeocoderCallback.onSuccess, _ failure: @escaping GeocoderCallback.onError ) {
		Location.getLocation(forLocation: self, timeout: timeout, success: success, failure: failure)
	}
	
}

public extension String {
	
	/// Reverse self object as address string and return `CLPlacemark` array if succeded.
	///
	/// - Parameters:
	///   - timeout:	timeout of the operation. If reverse task is not finished in this interval a `LocationError.timeout` is generated.
	///   - success:	callback to execute on success. For most geocoding requests, this array should contain only one entry.
	///					However, forward-geocoding requests may return multiple placemark objects in situations where
	///					the specified address could not be resolved to a single location.
	///   - failure:	callback to execute on failure
	@discardableResult
	public func reverse(timeout: TimeInterval? = nil,
	                    _ success: @escaping GeocoderCallback.onSuccess, _ failure: @escaping GeocoderCallback.onError ) -> GeocoderRequest {
		return Location.getLocation(forString: self, timeout: timeout, success: success, failure: failure)
	}
}

public extension CLLocationManager {
	
	public func stopMonitoringAllRegions() {
		self.monitoredRegions.forEach { self.stopMonitoring(for: $0) }
	}
	
	public class func getLocation(accuracy: Accuracy, frequency: Frequency, timeout: TimeInterval? = nil, success: @escaping LocationRequest.OnSuccessCallback, error: @escaping LocationRequest.OnErrorCallback) -> LocationRequest {
		return Location.getLocation(accuracy: accuracy, frequency: frequency, timeout: timeout, success: success, error: error)
	}
	
}

public extension CLCircularRegion {
	
	@discardableResult
	public func monitor(enter: RegionCallback.onEvent?,
	                    exit: RegionCallback.onEvent?,
	                    error: @escaping RegionCallback.onFailure) throws -> RegionRequest {
		return try Location.monitor(region: self, enter: enter, exit: exit, error: error)
	}

	
}
