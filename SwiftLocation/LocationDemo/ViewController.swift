//
//  ViewController.swift
//  LocationDemo
//
//  Created by Daniele Margutti on 08/01/2017.
//  Copyright © 2017 Daniele Margutti. All rights reserved.
//

import UIKit
import SwiftLocation

class ViewController: UIViewController {

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		/*
		let req1 = LocationRequest(accuracy: .country, frequency: .whenTravelled(meters: 50, timeout: 100), { loc in
			print("loc \(loc)")
		}) { lastLoc, error in
			print("error \(error)")
		}
		
		let req2 = LocationRequest(accuracy: .country, frequency: .whenTravelled(meters: 50, timeout: 100), { loc in
			print("loc \(loc)")
		}) { lastLoc, error in
			print("error \(error)")
		}
		
		let req3 = LocationRequest(accuracy: .country, frequency: .whenTravelled(meters: 450, timeout: 100), { loc in
			print("loc \(loc)")
		}) { lastLoc, error in
			print("error \(error)")
		}
		
		let req4 = LocationRequest(accuracy: .country, frequency: .continuous, { loc in
			print("loc \(loc)")
		}) { lastLoc, error in
			print("error \(error)")
		}

		Location.start(req1)
		Location.start(req2)
		Location.start(req3)
*/
				
		let req1 = LocationRequest(accuracy: .IPScan(IPService(.freeGeoIP)), frequency: .continuous, { location in
			print("loc \(location)")
		}) { (lastLoc, error) in
			print("error")
		}
		Location.start(req1)
		
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}


}

