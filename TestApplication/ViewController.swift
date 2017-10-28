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

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
		
	/*	Locator.currentPosition(accuracy: .city).onSuccess { location in
			print("Find location \(location)")
		}.onFailure { err, last in
			print("Failed: \(err)")
		}
	*/
		
		/*Locator.subscribePosition(accuracy: .city).onSuccess { loc in
			print("New: \(loc)")
		}.onFailure { err, last in
			print("Failed: \(err)")
		}*/
		
		/*Locator.location(fromAddress: "Via Veneto 12, Rieti", using: .openStreetMap).onSuccess { places in
			print(places)
		}.onFailure { err in
			print("err")
		}*/
		
		let c = CLLocationCoordinate2DMake(41.890395, 12.493083)
		Locator.location(fromCoordinates: c, onSuccess: { places in
			print(places)
		}) { err in
			print(err)
		}
		
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}


}

