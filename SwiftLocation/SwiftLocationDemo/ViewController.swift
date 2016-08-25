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
		let proximity = "B9407F30-F5F8-466E-AFF9-25556B57FE6D"
		
		do {
//			try Beacons.monitor(beaconRegion: proximity, major: major, minor: minor, onStateDidChange: { (state) in
//				print("state \(state)")
//			}) { (error) in
//				print("\(error)")
//			}
			
			let beacon = Beacon(proximity: proximity, major: major, minor: minor)
			try Beacons.monitor(beacon: beacon, events: Event.All, onStateDidChange: { state in
				print("state \(state)")
			}, onRangingBeacons: { beacons in
				print("beacons \(beacons.count)")
			}, onError: { error in
				print("error \(error)")
			})
		} catch let err {
			print("errrr \(err)")
		}
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}


}

