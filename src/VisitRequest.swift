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

public class VisitRequest: Request {
		/// Last place received
	private(set) var lastPlace: CLVisit?
		/// Handler called when a new place is currently visited
	public var onDidVisitPlace: VisitHandler?

		/// Private vars
	internal(set) var isEnabled: Bool = false
	public var UUID: String = NSUUID().UUIDString
	
	
	/**
	Create a new request with an associated handler to call
	
	- parameter onDidVisit: handler to call when a new interesting place is visited
	
	- returns: the request instance you can add to the queue
	*/
	public init(onDidVisit: VisitHandler?) {
		self.onDidVisitPlace = onDidVisit
	}
	
	/**
	This method allows you set the the handler you want to be called when a new place is visited
	
	- parameter handler: handler to call
	
	- returns: self instance, used to make the function chainable
	*/
	public func onDidVisit(handler: VisitHandler?) -> VisitRequest {
		self.onDidVisitPlace = handler
		return self
	}
	
	/**
	Start a new visit request
	*/
	public func start() {
		Location.addVisitRequest(self)
	}
	
	/**
	Stop a visit request and remove it from the queue
	*/
	public func cancel() {
		Location.stopInterestingPlacesRequest(self)
	}
	
	public func pause() {
		self.isEnabled = false
	}
}