//
//  ViewController.swift
//  SwiftLocationDemo
//
//  Created by Daniele Margutti on 15/08/16.
//  Copyright © 2016 danielemargutti. All rights reserved.
//

import UIKit
import SwiftLocation
import CoreLocation
import CoreBluetooth

class ViewController: UIViewController {

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
		let major = CLBeaconMajorValue(13017)
		let minor = CLBeaconMinorValue(22994)
		do {
			try Beacon.monitorForBeacon(proximityUUID: "B9407F30-F5F8-466E-AFF9-25556B57FE6D", major: major, minor: minor, onFound: { (beacons) in
				print("found \(beacons.count)")
			}) { (error) in
				print(error)
			}
		} catch let err {
			print(err)
		}
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}


}

