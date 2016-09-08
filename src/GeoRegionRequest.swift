//
//  SwiftLocation.swift
//  SwiftLocations
//
// Copyright (c) 2016 Daniele Margutti
// Web:			http://www.danielemargutti.com
// Mail:		me@danielemargutti.com
// Twitter:		@danielemargutti
//
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation
import CoreLocation

public class GeoRegionRequest: NSObject, Request {
	
	public var UUID: String
	
	public var coordinates: CLLocationCoordinate2D {
		return region.center
	}
	
	public var radius: CLLocationDistance {
		return region.radius
	}
	private(set) var region: CLCircularRegion

	/// Authorization did change
	public var onAuthorizationDidChange: LocationHandlerAuthDidChange?

	public var onStateDidChange: RegionStateDidChange?
	public var onError: RegionMonitorError?
	
	public var rState: RequestState = .Pending
	
	public init(coordinates: CLLocationCoordinate2D, radius: CLLocationDistance) {
		self.UUID = NSUUID().UUIDString
		self.region = CLCircularRegion(center: coordinates, radius: radius, identifier: self.UUID)
	}
	
	public func cancel(error: LocationError?) {
		Beacons.remove(request: self, error: error)
	}
	
	/**
	Terminate request without errors
	*/
	public func cancel() {
		self.cancel(nil)
	}
	
	public func pause() {
		if Beacons.remove(request: self) == true {
			self.rState = .Paused
		}
	}
	
	public func start() {
		Beacons.add(request: self)
	}
	
}