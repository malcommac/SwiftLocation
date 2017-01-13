//
//  IPLocationRequest.swift
//  SwiftLocation
//
//  Created by Daniele Margutti on 13/01/2017.
//  Copyright © 2017 Daniele Margutti. All rights reserved.
//

import Foundation

internal extension LocationRequest {
	

	internal func executeIPLocationRequest() {
		guard case .IPScan(let service) = self.accuracy else {
			return
		}
		service.locationData(success: {
			self.dispatchLocation($0)
			self.cancel()
		}) {
			self.dispatchError($0)
			self.cancel()
		}
	}
	
}
