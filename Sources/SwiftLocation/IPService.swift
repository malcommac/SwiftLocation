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

public struct IPService: CustomStringConvertible {
	
	public typealias IPServiceSuccessCallback = ((CLLocation) -> (Void))
	public typealias IPServiceFailureCallback = ((Error?) -> (Void))
	
	/// Service used for IP Scan
	public var service: IPService.Name
	
	/// Timeout of the operation
	public var timeout: TimeInterval
	
	/// Name of the service
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
	
	/// Initialize a new `IPService` with given service
	///
	/// - Parameter service: service
	/// - Parameter timeout: timeout of the operation
	public init(_ service: Name, timeout: TimeInterval = 15) {
		self.service = service
		self.timeout = timeout
	}
	
	
	/// Description of the IP Service
	public var description: String {
		get { return self.service.description }
	}
	
	
	/// Create a request for given service query
	private var request: NSURLRequest {
		var url: String = ""
		switch self.service {
		case .freeGeoIP:	url = "http://freegeoip.net/json/"
		case .petabyet:		url = "http://api.petabyet.com/geoip/"
		case .smartIP:		url = "http://smart-ip.net/geoip-json/"
		case .telize:		url = "http://www.telize.com/geoip/"
		}
		let request = NSMutableURLRequest(url: URL(string: url)!,
		                                  cachePolicy: NSURLRequest.CachePolicy.reloadIgnoringCacheData,
		                                  timeoutInterval: self.timeout)
		return request
	}
	
	
	/// Get location from current IP address
	///
	/// - Parameters:
	///   - success: callback for success
	///   - fail: callback for fails
	public func getLocationFromIP(success: @escaping IPServiceSuccessCallback, fail: @escaping IPServiceFailureCallback)  {
		self.execute(request: self.request, success, fail)
	}
	
	
	/// All these queries share the same output so we can group them in a single call
	///
	/// - Parameters:
	///   - request: request to url
	///   - success: success callback
	///   - fail: fail callback
	private func execute(request: NSURLRequest,
	                     _ success: @escaping IPServiceSuccessCallback, _ fail: @escaping IPServiceFailureCallback) {
		let task = URLSession.shared.dataTask(with: request as URLRequest) { (data, response, error) in
			do {
				guard let data = data else { // something went wrong
					fail(error)
					return
				}
				// fail to deserialize JSON output
				let opts = JSONSerialization.ReadingOptions.init(rawValue: 0)
				guard let json = try JSONSerialization.jsonObject(with: data, options: opts) as? NSDictionary else {
					fail(LocationError.noData)
					return
				}
				// failed to get latitude and longitude keys
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

