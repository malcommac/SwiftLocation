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

open class GeoRegionRequest: NSObject, Request {
	
	open var UUID: String
	
	open var coordinates: CLLocationCoordinate2D {
		return region.center
	}
	
	open var radius: CLLocationDistance {
		return region.radius
	}
	fileprivate(set) var region: CLCircularRegion

	/// Authorization did change
	open var onAuthorizationDidChange: LocationHandlerAuthDidChange?

	open var onStateDidChange: RegionStateDidChange?
	open var onError: RegionMonitorError?
	
	open var rState: RequestState = .pending
	
	public init(coordinates: CLLocationCoordinate2D, radius: CLLocationDistance) {
		self.UUID = Foundation.UUID().uuidString
		self.region = CLCircularRegion(center: coordinates, radius: radius, identifier: self.UUID)
	}
	
	open func cancel(_ error: LocationError?) {
		_ = Beacons.remove(request: self, error: error)
	}
	
	open func cancel() {
		self.cancel(nil)
	}
	
	open func pause() {
		if Beacons.remove(request: self) == true {
			self.rState = .paused
		}
	}
	
	open func start() {
		_ = Beacons.add(request: self)
	}
	
}
