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

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

	@IBOutlet public var table: UITableView?
	
	private var rq_continousLoc: LocationRequest?
	private var rq_continousLoc2: LocationRequest?
	private var rq_ipscan: LocationRequest?
	private var rq_oneshot: LocationRequest?
	private var rq_background: LocationRequest?
	private var rq_backgroundTravelled: LocationRequest?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.table?.rowHeight = UITableViewAutomaticDimension
		// Do any additional setup after loading the view, typically from a nib.
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		Location.onAddNewRequest = {
			print("[+] \($0)")
		}
		Location.onRemoveRequest = {
			print("[-] \($0)")
		}
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return 7	
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		var cell = tableView.dequeueReusableCell(withIdentifier: "cell")
		if cell == nil {
			cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
			cell?.detailTextLabel?.textColor = UIColor.darkGray
		}
		
		switch indexPath.row {
		case 0:
			cell?.textLabel?.text = "IPScan Location"
			cell?.detailTextLabel?.text = "Get the approximate location using IP scan services."
		case 1:
			cell?.textLabel?.text = "Continous Location (City)"
			cell?.detailTextLabel?.text = "Continous Updating location with city accuracy"
		case 2:
			cell?.textLabel?.text = "Continous Location (Block)"
			cell?.detailTextLabel?.text = "Continous Updating location with block accuracy"
		case 3:
			cell?.textLabel?.text = "One Shot (Neighborhood)"
			cell?.detailTextLabel?.text = "Continous Updating location with neighborhood accuracy"
		case 4:
			cell?.textLabel?.text = "Background Significant"
			cell?.detailTextLabel?.text = "Background"
		case 5:
			cell?.textLabel?.text = "Background Travelled"
			cell?.detailTextLabel?.text = "Background when travelled"
		case 6:
			cell?.textLabel?.text = "Status"
			cell?.detailTextLabel?.text = "Get the status of the tracker."
		default:
			break
		}
		
		return cell!
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: false)
		switch indexPath.row {
		case 0:
			test_IPScan()
		case 1:
			test_continousLocation()
		case 2:
			test_continousLocation2()
		case 3:
			test_oneShot()
		case 4:
			test_background()
		case 5:
			test_backgroundTravelled()
		case 6:
			tracker_description()
		default:
			break
		}
	}
	
	private func tracker_description() {
		print(Location.description)
	}
	
	private func test_backgroundTravelled() {
		if rq_backgroundTravelled != nil {
			let alert = UIAlertController(title: "Action", message: "", preferredStyle: .actionSheet)
			alert.addAction(UIAlertAction(title: "Pause", style: .default, handler: { _ in
				self.rq_backgroundTravelled?.pause()
			}))
			if rq_background!.state.isPaused {
				alert.addAction(UIAlertAction(title: "Resume", style: .default, handler: { _ in
					self.rq_backgroundTravelled?.resume()
				}))
			} else {
				alert.addAction(UIAlertAction(title: "Cancel/Remove", style: .default, handler: { _ in
					self.rq_backgroundTravelled?.cancel()
				}))
			}
			self.present(alert, animated: true, completion: nil)
			return
		}
		
		rq_backgroundTravelled = LocationRequest(name: "REQ_4", accuracy: .any, frequency: .whenTravelled(meters: 5, timeout: 10), { loc in
			print("\t\t[\(self.rq_backgroundTravelled!.name)] > New location \(loc)")
			
			let notification = UILocalNotification()
			notification.alertTitle = "SIG.TRAVELLED LOCATION RECEIVED"
			notification.alertBody = "\(loc.coordinate.latitude),\(loc.coordinate.longitude)"
			notification.fireDate = Date()
			UIApplication.shared.scheduleLocalNotification(notification)
			
		}, { (last, error) in
			print("\t\t[\(self.rq_backgroundTravelled!.name)] > Error \(error)")
			
			let notification = UILocalNotification()
			notification.alertTitle = "SIG.TRAVELLED LOCATION ERROR"
			notification.alertBody = "\(error)"
			notification.fireDate = Date()
			UIApplication.shared.scheduleLocalNotification(notification)
		})
		rq_backgroundTravelled?.activity = .fitness
		rq_backgroundTravelled!.resume()
	}

	
	private func test_background() {
		if rq_background != nil {
			let alert = UIAlertController(title: "Action", message: "", preferredStyle: .actionSheet)
			alert.addAction(UIAlertAction(title: "Pause", style: .default, handler: { _ in
				self.rq_background?.pause()
			}))
			if rq_background!.state.isPaused {
				alert.addAction(UIAlertAction(title: "Resume", style: .default, handler: { _ in
					self.rq_background?.resume()
				}))
			} else {
				alert.addAction(UIAlertAction(title: "Cancel/Remove", style: .default, handler: { _ in
					self.rq_background?.cancel()
				}))
			}
			self.present(alert, animated: true, completion: nil)
			return
		}
		
		rq_background = LocationRequest(name: "REQ_3", accuracy: .any, frequency: .significant, { loc in
			print("\t\t[\(self.rq_background!.name)] > New location \(loc)")
			
			let notification = UILocalNotification()
			notification.alertTitle = "SIGNIFICANT LOCATION RECEIVED"
			notification.alertBody = "\(loc.coordinate.latitude),\(loc.coordinate.longitude)"
			notification.fireDate = Date()
			UIApplication.shared.scheduleLocalNotification(notification)

		}, { (last, error) in
			print("\t\t[\(self.rq_background!.name)] > Error \(error)")
			
			let notification = UILocalNotification()
			notification.alertTitle = "SIGNIFICANT LOCATION ERROR"
			notification.alertBody = "\(error)"
			notification.fireDate = Date()
			UIApplication.shared.scheduleLocalNotification(notification)
		})
		rq_background?.activity = .fitness
		rq_background!.resume()
	}
	
	private func test_oneShot() {
		if rq_oneshot != nil {
			let alert = UIAlertController(title: "Action", message: "", preferredStyle: .actionSheet)
			alert.addAction(UIAlertAction(title: "Pause", style: .default, handler: { _ in
				self.rq_oneshot?.pause()
			}))
			if rq_oneshot!.state.isPaused {
				alert.addAction(UIAlertAction(title: "Resume", style: .default, handler: { _ in
					self.rq_oneshot?.resume()
				}))
			} else {
				alert.addAction(UIAlertAction(title: "Cancel/Remove", style: .default, handler: { _ in
					self.rq_oneshot?.cancel()
				}))
			}
			self.present(alert, animated: true, completion: nil)
			return
		}
		
		rq_oneshot = LocationRequest(name: "REQ_1", accuracy: .neighborhood, frequency: .oneShot, { loc in
			print("\t\t[\(self.rq_oneshot!.name)] > New location \(loc)")
		}, { (last, error) in
			print("\t\t[\(self.rq_oneshot!.name)] > Error \(error)")
		})
		rq_oneshot!.resume()
	}
	
	private func test_continousLocation() {
		if rq_continousLoc != nil {
			let alert = UIAlertController(title: "Action", message: "", preferredStyle: .actionSheet)
			alert.addAction(UIAlertAction(title: "Pause", style: .default, handler: { _ in
				self.rq_continousLoc?.pause()
			}))
			if rq_continousLoc!.state.isPaused {
				alert.addAction(UIAlertAction(title: "Resume", style: .default, handler: { _ in
					self.rq_continousLoc?.resume()
				}))
			} else {
				alert.addAction(UIAlertAction(title: "Cancel/Remove", style: .default, handler: { _ in
					self.rq_continousLoc?.cancel()
				}))
			}
			self.present(alert, animated: true, completion: nil)
			return
		}
		
		rq_continousLoc = LocationRequest(name: "REQ_1", accuracy: .city, frequency: .continuous, { loc in
			print("\t\t[\(self.rq_continousLoc!.name)] > New location \(loc)")
		}, { (last, error) in
			print("\t\t[\(self.rq_continousLoc!.name)] > Error \(error)")
		})
		rq_continousLoc!.resume()
	}
	
	private func test_continousLocation2() {
		if rq_continousLoc2 != nil {
			let alert = UIAlertController(title: "Action", message: "", preferredStyle: .actionSheet)
			alert.addAction(UIAlertAction(title: "Pause", style: .default, handler: { _ in
				self.rq_continousLoc2?.pause()
			}))
			if rq_continousLoc2!.state.isPaused {
				alert.addAction(UIAlertAction(title: "Resume", style: .default, handler: { _ in
					self.rq_continousLoc2?.resume()
				}))
			} else {
				alert.addAction(UIAlertAction(title: "Cancel/Remove", style: .default, handler: { _ in
					self.rq_continousLoc2?.cancel()
				}))
			}
			self.present(alert, animated: true, completion: nil)
			return
		}
		
		rq_continousLoc2 = LocationRequest(name: "REQ_2", accuracy: .block, frequency: .continuous, { loc in
			print("\t\t[\(self.rq_continousLoc2!.name)] > New location \(loc)")
		}, { (last, error) in
			print("\t\t[\(self.rq_continousLoc2!.name)] > Error \(error)")
		})
		rq_continousLoc2!.resume()
	}
	
	private func test_IPScan() {
		let ipServices: [IPService.Name] = [.freeGeoIP, .petabyet, .smartIP, .telize]
		let randomService = ipServices[random(0, UInt32(ipServices.count - 1))]
		let sv = Accuracy.IPScan(IPService(randomService))
		let fq = Frequency.oneShot
		
		rq_ipscan = LocationRequest(name: "REQ_0", accuracy: sv, frequency: fq, { location in
			print("\t\t[\(self.rq_ipscan!.name)] > [\(randomService)]: \(location.coordinate.latitude), \(location.coordinate.longitude)")
		}, { (last, error) in
			print("\t\t[\(self.rq_ipscan!.name)] > Error: \(error)")
		})
		rq_ipscan!.resume()
	}
	
	private func random(_ from: UInt32, _ to: UInt32) -> Int {
		return Int(arc4random_uniform(to) + from)
	}

}

