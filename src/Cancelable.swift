//
//  Cancelable.swift
//  SwiftLocation
//
//  Created by Hernan G. Gonzalez on 14/5/16.
//  Copyright © 2016 danielemargutti. All rights reserved.
//

import Foundation
import CoreLocation

public protocol Cancelable {
	func cancel()
}

extension CLGeocoder: Cancelable {

	public func cancel() {
		cancelGeocode()
	}
}

extension NSURLSessionDataTask: Cancelable {
}


