//
//  ViewController.swift
//  SwiftLocationExample
//
//  Created by daniele on 31/07/15.
//  Copyright (c) 2015 danielemargutti. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

class ViewController: UIViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		
		SwiftLocation.shared.currentLocation(Accuracy.Neighborhood, timeout: 20, onSuccess: { (location) -> Void in
			// location is a CLPlacemark
		}) { (error) -> Void in
			// something went wrong
		}
		
		SwiftLocation.shared.reverseAddress(Service.Apple, address: "1 Infinite Loop, Cupertino (USA)", region: nil, onSuccess: { (place) -> Void in
			// our CLPlacemark is here
		}) { (error) -> Void in
			// something went wrong
		}
		
		let coordinates = CLLocationCoordinate2DMake(41.890198, 12.492204)
		SwiftLocation.shared.reverseCoordinates(Service.Apple, coordinates: coordinates, onSuccess: { (place) -> Void in
			// our placemark is here
		}) { (error) -> Void in
			// something went wrong
		}
		
		let requestID = SwiftLocation.shared.continuousLocation(Accuracy.Room, onSuccess: { (location) -> Void in
			// a new location has arrived
		}) { (error) -> Void in
			// something went wrong. request will be cancelled automatically
		}
		// Sometime in the future... you may want to interrupt it
		SwiftLocation.shared.cancelRequest(requestID)
		
		
		SwiftLocation.shared.significantLocation({ (location) -> Void in
			// a new significant location has arrived
		}, onFail: { (error) -> Void in
			// something went wrong. request will be cancelled automatically
		})
		
		let regionCoordinates = CLLocationCoordinate2DMake(41.890198, 12.492204)
		var region = CLCircularRegion(center: regionCoordinates, radius: CLLocationDistance(50), identifier: "identifier_region")
		SwiftLocation.shared.monitorRegion(region, onEnter: { (region) -> Void in
			// events called on enter
		}) { (region) -> Void in
			// event called on exit
		}
		
		let bRegion = CLBeaconRegion(proximityUUID: NSUUID(UUIDString: "ciao"), identifier: "myIdentifier")
		SwiftLocation.shared.monitorBeaconsInRegion(bRegion, onRanging: { (regions) -> Void in
			// events called on ranging
		})
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}


}

