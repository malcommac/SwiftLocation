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
	//	let major = CLBeaconMajorValue(13783)
	//	let minor = CLBeaconMinorValue(51131)
	//	let proximity = "B9407F30-F5F8-466E-AFF9-25556B57FE6D"
		
//		do {
//			let beacon = Beacon(proximity: proximity, major: major, minor: minor)
//			try Beacons.monitor(beacon: beacon, events: Event.RegionBoundary, onStateDidChange: { state in
//				print("state \(state)")
//			}, onRangingBeacons: { beacons in
//				print("beacons \(beacons.count)")
//			}, onError: { error in
//				print("error \(error)")
//			})
//		} catch let err {
//			print("errrr \(err)")
//		}

		Location.getLocation(withAccuracy: .City, frequency: .Continuous, onSuccess: { (location) in
			print("new loc \(location)")
		}) { (lastValidLocation, error) in
			print("fail")
		}
	
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}


}

