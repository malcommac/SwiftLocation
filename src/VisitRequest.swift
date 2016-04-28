//
//  VisitRequest.swift
//  SwiftLocation
//
//  Created by Daniele Margutti on 21/04/16.
//  Copyright © 2016 danielemargutti. All rights reserved.
//

import Foundation
import CoreLocation

public class VisitRequest {
		/// Last place received
	private(set) var lastPlace: CLVisit?
		/// Handler called when a new place is currently visited
	public var onDidVisitPlace: VisitHandler?

		/// Private vars
	internal(set) var isEnabled: Bool = true
	internal var UUID: String = NSUUID().UUIDString
	
	
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
		LocationManager.shared.addVisitRequest(self)
	}
	
	/**
	Stop a visit request and remove it from the queue
	*/
	public func stop() {
		LocationManager.shared.stopObservingInterestingPlaces(self)
	}
}