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
		let major = CLBeaconMajorValue(64224)
		let minor = CLBeaconMinorValue(43514)
		let proximity = "00194D5B-0A08-4697-B81C-C9BDE117412E"
		
		print("Beacon monitoring started \(proximity) - maj=\(major), min=\(minor)")
		
		do {
			let beacon = Beacon(proximity: proximity, major: major, minor: minor)
			try Beacons.monitor(beacon: beacon, events: Event.RegionBoundary, onStateDidChange: { state in
				print("Region state change \(state)")
			}, onRangingBeacons: { beacons in
				print("Ranging beacons \(beacons.count)")
			}, onError: { error in
				print("Error \(error)")
			})
		} catch let err {
			print("Error \(err)")
		}


	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}


}

