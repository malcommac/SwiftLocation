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
	public var lastPlace: CLVisit?
	internal(set) var isEnabled: Bool = true
	internal var UUID: String = NSUUID().UUIDString
	
	public var onDidVisitPlace: VisitHandler?
	
	public init(onDidVisit: VisitHandler?) {
		self.onDidVisitPlace = onDidVisit
	}
	
	public func onDidVisit(handler: VisitHandler?) -> VisitRequest {
		self.onDidVisitPlace = handler
		return self
	}
	
	public func start() {
		LocationManager.shared.addVisitRequest(self)
	}
	
	public func stop() {
		LocationManager.shared.stopObservingInterestingPlaces(self)
	}
}