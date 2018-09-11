//
//  ViewController.swift
//  TestApplication
//
//  Created by danielemargutti on 27/10/2017.
//  Copyright © 2017 Daniele Margutti. All rights reserved.
//

import UIKit
import SwiftLocation
import MapKit
import CoreLocation

class ViewController: UIViewController {

	private var loc: IPLocationRequest?
	private var geocoder: GeocoderRequest?
	override func viewDidLoad() {
		super.viewDidLoad()
		
		Locator.api.googleAPIKey = "AIzaSyDy2wdv5jbT7BuOhmbDU2VEQobz83xNcpw"
//		Locator.autocompletePlaces(with: "Via Veneto", onSuccess: { place in
//			print("\(place.count)")
//		}) { err in
//			print("err: \(err)")
//		}

		let c = CLLocationCoordinate2DMake(41.895660, 12.493186)
		Locator.location(fromCoordinates: c, locale: nil, using: GeocoderService.google, timeout: 10, onSuccess: { places in
			print("")
		}) { err in
			print("\(err)")
		}
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}


}

