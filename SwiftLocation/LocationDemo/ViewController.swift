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

public extension UITextView {
	public func scrollBottom() {
		guard self.text.characters.count > 0 else {
			return
		}
		let stringLength:Int = self.text.characters.count
		self.scrollRangeToVisible(NSMakeRange(stringLength-1, 0))
	}
}

public extension CLLocation {
	
	public var shortDesc: String {
		return "- lat,lng=\(self.coordinate.latitude),\(self.coordinate.longitude), h-acc=\(self.horizontalAccuracy) mts\n"
	}
	
}

class ViewController: UIViewController {
	
	@IBOutlet private var textView: UITextView?
	@IBOutlet private var textViewAll: UITextView?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.textView?.layoutManager.allowsNonContiguousLayout = false
		self.textViewAll?.layoutManager.allowsNonContiguousLayout = false

	}
	
	private func log(_ value: String) {
		self.textView!.insertText(value)
		self.textView!.scrollBottom()
	}
	
	private func logAll(_ value: String) {
		self.textViewAll!.insertText(value)
		self.textViewAll!.scrollBottom()
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		Location.onChangeTrackerSettings = { settings in
			self.log(String(describing: settings))
		}
		
		let x = Location.getLocation(accuracy: .room, frequency: .continuous, timeout: 60*60*5, success: { (_, location) in
			self.log(location.shortDesc)
			
		}) { (request, last, error) in
			self.log("Location monitoring failed due to an error \(error)")

			request.cancel() // stop continous location monitoring on error
		}
		x.register(observer: LocObserver.onAuthDidChange(.main, { (request, oldAuth, newAuth) in
			print("Authorization moved from '\(oldAuth)' to '\(newAuth)'")
		}))
		
		Location.onReceiveNewLocation = { location in
			self.logAll(location.shortDesc)
		}
		
		
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

