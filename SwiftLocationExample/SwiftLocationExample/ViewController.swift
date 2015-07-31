//
//  ViewController.swift
//  SwiftLocationExample
//
//  Created by daniele on 31/07/15.
//  Copyright (c) 2015 danielemargutti. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

class ViewController: UIViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		SwiftLocation.shared.significantLocation({ (location) -> Void in
			println("Posizione trovata")
		}, onFail: { (error) -> Void in
			println("Failed \(error?.localizedDescription)")
		})
		
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}


}

