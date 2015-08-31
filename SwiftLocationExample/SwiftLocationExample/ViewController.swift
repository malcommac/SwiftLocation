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
		
		SwiftLocation.shared.currentLocation(Accuracy.Room, timeout: 20, onSuccess: { (location) -> Void in
			// location is a CLPlacemark
			print("1. Location found \(location?.description)")
		}) { (error) -> Void in
			print("1. Something went wrong -> \(error?.localizedDescription)")
		}

		SwiftLocation.shared.reverseAddress(Service.Apple, address: "1 Infinite Loop, Cupertino (USA)", region: nil, onSuccess: { (place) -> Void in
            print("2. place = \(place)")
		}) { (error) -> Void in
            print("2. Something went wrong -> \(error?.localizedDescription)")
		}
		
		let coordinates = CLLocationCoordinate2DMake(41.890198, 12.492204)
		SwiftLocation.shared.reverseCoordinates(Service.Apple, coordinates: coordinates, onSuccess: { (place) -> Void in
            print("3. place = \(place)")
		}) { (error) -> Void in
            print("3. Something went wrong -> \(error?.localizedDescription)")
		}
		
		let requestID = SwiftLocation.shared.continuousLocation(Accuracy.Room, onSuccess: { (location) -> Void in
            print("4. Location found \(location?.description)")
		}) { (error) -> Void in
            print("4. Something went wrong -> \(error?.localizedDescription)")
		}
		// Sometime in the future... you may want to interrupt it
		SwiftLocation.shared.cancelRequest(requestID)
		
		
		SwiftLocation.shared.significantLocation({ (location) -> Void in
            print("5. Location found \(location?.description)")
		}, onFail: { (error) -> Void in
            print("5. Something went wrong -> \(error?.localizedDescription)")
		})
		
		let regionCoordinates = CLLocationCoordinate2DMake(41.890198, 12.492204)
		let region = CLCircularRegion(center: regionCoordinates, radius: CLLocationDistance(50), identifier: "identifier_region")
		SwiftLocation.shared.monitorRegion(region, onEnter: { (region) -> Void in
            print("region enter = \(region)")
        }) { (region) -> Void in
            print("region exit = \(region)")
		}
		
        return // Still goes wrong:
		let bRegion = CLBeaconRegion(proximityUUID: NSUUID(UUIDString: "ciao")!, identifier: "myIdentifier")
		SwiftLocation.shared.monitorBeaconsInRegion(bRegion, onRanging: { (regions) -> Void in
			// events called on ranging
		})
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}


}

