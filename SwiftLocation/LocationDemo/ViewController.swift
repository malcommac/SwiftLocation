//
//  ViewController.swift
//  LocationDemo
//
//  Created by Daniele Margutti on 08/01/2017.
//  Copyright © 2017 Daniele Margutti. All rights reserved.
//

import UIKit
import SwiftLocation
import CoreLocation

class ViewController: UIViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		Location.onAddNewRequest = { req in
			print("A new request is added to the queue \(req)")
		}
		Location.onRemoveRequest = { req in
			print("An existing request was removed from the queue \(req)")
		}
		
		/*
		let x = Location.getLocation(accuracy: .city, frequency: .continuous, success: { (_, location) in
			print("A new update of location is available: \(location)")
		}) { (request, last, error) in
			request.cancel() // stop continous location monitoring on error
			print("Location monitoring failed due to an error \(error)")
		}
		x.register(observer: LocObserver.onAuthDidChange(.main, { (request, oldAuth, newAuth) in
			print("Authorization moved from \(oldAuth) to \(newAuth)")
		}))
	*/
		
		/*
		Location.getLocation(accuracy: .IPScan(IPService(.freeGeoIP)), frequency: .oneShot, success: { _,location in
			print("Found location \(location)")
		}) { (_, last, error) in
			print("Something bad has occurred \(error)")
		}
		*/
		
		/*
		Location.getLocation(accuracy: .city, frequency: .continuous, success: { (_, location) in
			print("A new update of location is available: \(location)")
		}) { (request, last, error) in
			request.cancel() // stop continous location monitoring on error
			print("Location monitoring failed due to an error \(error)")
		}
		*/
		
		/*
		Location.getLocation(forAddress: "1 Infinite Loop, Cupertino", success: { placemark in
			print("Placemark found: \(placemark)")
		}) { error in
			print("Cannot reverse geocoding due to an error \(error)")
		}
		*/
		
		/*
		let loc = CLLocation(latitude: 42.972474, longitude: 13.757332)
		Location.getPlacemark(forLocation: loc, success: { placemarks in
			// Found Contrada San Rustico, Contrada San Rustico, 63065 Ripatransone, Ascoli Piceno, Italia
			// @ <+42.97264130,+13.75787860> +/- 100.00m, region CLCircularRegion
			print("Found \(placemarks.first!)")
		}) { error in
			print("Cannot retrive placemark due to an error \(error)")
		}
		*/
		
		/*
		do {
			try Location.getContinousHeading(filter: 0.2, success: { heading in
				print("New heading value \(heading)")
			}) { error in
				print("Failed to update heading \(error)")
			}
		} catch {
			print("Cannot start heading updates: \(error)")
		}
		*/
		
		/*
		do {
			let loc = CLLocationCoordinate2DMake( 42.972474, 13.757332)
			let radius = 100.0
			try Location.monitor(regionAt: loc, radius: radius, enter: { _ in
				print("Entered in region!")
			}, exit: { _ in
				print("Exited from the region")
			}, error: { req, error in
				print("An error has occurred \(error)")
				req.cancel() // abort the request (you can also use `cancelOnError=true` to perform it automatically
			})
		} catch {
			print("Cannot start heading updates: \(error)")
		}
		*/
		
		/*
		do {
			try Location.monitorVisit(event: { visit in
				print("A new visit to \(visit)")
			}, error: { error in
				print("Error occurred \(error)")
			})
		} catch {
			print("Cannot start visit updates: \(error)")
		}
*/
	}
	
}

