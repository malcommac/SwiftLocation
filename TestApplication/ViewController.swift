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
		
		SwiftLocation.Locator.currentPosition(usingIP: .freeGeoIP, onSuccess: { loc in
			print("loc")
		}) { (e, b) -> (Void) in
			print("")
		}
	
		
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}


}

