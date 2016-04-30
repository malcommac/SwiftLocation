//
//  ViewController.swift
//  SwiftLocationExample
//
//  Created by Daniele Margutti on 23/04/16.
//  Copyright © 2016 danielemargutti. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
		
		LocationManager.shared.observeLocations(.Block, frequency: .Continuous, onSuccess: { location in
			print("Location \(location)")
		}) { error in
			print("error: \(error.description)")
		}
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}


}

