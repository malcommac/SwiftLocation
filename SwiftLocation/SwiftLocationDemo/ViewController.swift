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
		
		Location.getLocation(withAccuracy: .City, frequency: .Continuous, timeout: nil, onSuccess: { (loc) in
			print("loc \(loc)")
			}) { (last, err) in
				print("err \(err)")
		}
		
//		// Do any additional setup after loading the view, typically from a nib.
//		let major = CLBeaconMajorValue(64224)
//		let minor = CLBeaconMinorValue(43514)
//		let proximity = "00194D5B-0A08-4697-B81C-C9BDE117412E"
//		
//		print("Beacon monitoring started \(proximity) - maj=\(major), min=\(minor)")
//		
//		do {
//			let beacon = Beacon(proximity: proximity, major: major, minor: minor)
//			try Beacons.monitor(beacon: beacon, events: Event.RegionBoundary, onStateDidChange: { state in
//				print("Region state change \(state)")
//			}, onRangingBeacons: { beacons in
//				print("Ranging beacons \(beacons.count)")
//			}, onError: { error in
//				print("Error \(error)")
//			})
//		} catch let err {
//			print("Error \(err)")
//		}
//		
//		
//		Beacons.advertise(beaconName: "name", UUID: proximity, major: major, minor: minor, powerRSSI: 4, serviceUUIDs: [])
//
//		
//		let centerPoint = CLLocationCoordinate2DMake(0, 0)
//		let radius = CLLocationDistance(100)
//		do {
//			
//			
//			
//			try Beacons.monitor(geographicRegion: centerPoint, radius: radius, onStateDidChange: { newState in
//				// newState is .Entered if user entered into the region defined by the center point and the radius or .Exited if it move away from the region.
//			}) { error in
//				// something bad has happened
//			}
//		} catch let err {
//			// Failed to initialize region (bad region, monitor is not supported by the hardware etc.)
//			print("Cannot monitor region due to an error: \(err)")
//		}

	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}


}

