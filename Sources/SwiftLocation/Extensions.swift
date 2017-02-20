/*
* SwiftLocation
* Easy and Efficent Location Tracker for Swift
*
* Created by:	Daniele Margutti
* Email:		hello@danielemargutti.com
* Web:			http://www.danielemargutti.com
* Twitter:		@danielemargutti
*
* Copyright © 2017 Daniele Margutti
*
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
*
*/


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
	                    _ success: @escaping GeocoderObserver.onSuccess, _ failure: @escaping GeocoderObserver.onError ) {
		Location.getPlacemark(forLocation: self, timeout: timeout, success: success, failure: failure)
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
	                    _ success: @escaping GeocoderObserver.onSuccess, _ failure: @escaping GeocoderObserver.onError ) -> GeocoderRequest {
		return Location.getLocation(forAddress: self, timeout: timeout, success: success, failure: failure)
	}
}

public extension CLLocationManager {

	/// Stop monitoring all regions
	public func stopMonitoringAllRegions() {
		self.monitoredRegions.forEach { self.stopMonitoring(for: $0) }
	}
	
	public class func getLocation(accuracy: Accuracy, frequency: Frequency, timeout: TimeInterval? = nil, success: @escaping LocObserver.onSuccess, error: @escaping LocObserver.onError) -> LocationRequest {
		return Location.getLocation(accuracy: accuracy, frequency: frequency, timeout: timeout, success: success, error: error)
	}
	
	public func stopAllLocationServices() {
		self.stopUpdatingLocation()
		self.stopMonitoringSignificantLocationChanges()
		self.disallowDeferredLocationUpdates()
	}
	
}

public extension CLCircularRegion {
	
	@discardableResult
	public func monitor(enter: RegionObserver.onEvent?,
	                    exit: RegionObserver.onEvent?,
	                    error: @escaping RegionObserver.onFailure) throws -> RegionRequest {
		return try Location.monitor(region: self, enter: enter, exit: exit, error: error)
	}

	
}
