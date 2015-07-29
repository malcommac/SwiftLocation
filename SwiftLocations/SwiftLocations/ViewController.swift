//
//  ViewController.swift
//  SwiftLocations
//
//  Created by daniele on 28/07/15.
//  Copyright (c) 2015 danielemargutti. All rights reserved.
//

import UIKit
import CoreLocation

class ViewController: UIViewController {

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
	
//		let request = SwiftLocation.shared.currentLocation(Accuracy.Neighborhood, timeout: 0.01, onSuccess: { (location) -> Void in
//			println("Posizione trovata")
//			location!.placemark({ (place) -> Void in
//				println("Placemark trovato")
//				}, onFail: { (error) -> Void in
//					println("Placemark error")
//			})
//		}) { (error) -> Void in
//			println("Failed \(error?.localizedDescription)")
//		}
//		
//		request.onTimeOut = { (Void) -> NSTimeInterval? in
//			return nil
//		}

		
		SwiftLocation.shared.significantLocation(Accuracy.None, onSuccess: { (location) -> Void in
			println("Posizione trovata")
		}) { (error) -> Void in
			println("Failed \(error?.localizedDescription)")
		}
		

		
//		SwiftLocation.shared.subscribeLocation(Accuracy.None, onSuccess: { (location) -> Void in
//			println("new position \(location)")
//		}) { (error) -> Void in
//			println("failed subscription")
//		}
	
		
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
		
	}



}

