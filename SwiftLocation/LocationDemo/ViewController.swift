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
	@IBOutlet public var textView: UITextView?
	
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
	
	func debug(_ string: String) {
		DispatchQueue.main.async {
			self.textView?.text = self.textView!.text + "\n\n\(string)"
			
			let stringLength:Int = self.textView!.text.characters.count
			self.textView!.scrollRangeToVisible(NSMakeRange(stringLength-1, 0))
		}
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		Location.onAddNewRequest = {
			self.debug("[+] \($0)")
		}
		Location.onRemoveRequest = {
			self.debug("[-] \($0)")
		}
		
		NotificationCenter.default.addObserver(self, selector: #selector(rec), name: NSNotification.Name(rawValue: "prova"), object: nil)
	}
	
	public func rec(not: NSNotification) {
		self.debug("\(not.userInfo!["text"])")
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return 8
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
			cell?.textLabel?.text = "Monitor Region"
			cell?.detailTextLabel?.text = "Monitor a region"
		case 7:
			cell?.textLabel?.text = "Status"
			cell?.detailTextLabel?.text = "Get the status of the tracker."
		case 8:
			cell?.textLabel?.text = "Clear"
			cell?.detailTextLabel?.text = "Clear"
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
			test_monitorRegion()
		case 7:
			tracker_description()
		case 8:
			textView?.text = ""
		default:
			break
		}
	}
	
	private func tracker_description() {
		debug(Location.description)
	}
	
	private func test_monitorRegion() {
		let loc = CLLocationCoordinate2D(latitude: 41.917501, longitude: 12.543548)
		let range = CLLocationDistance(100)
		try! Location.monitor(regionAt: loc, radius: range, enter: { _ in
			self.sendLocal(title: "MONITOR REGION", text: "ENTER")
		}, exit: { _ in
			self.sendLocal(title: "MONITOR REGION", text: "EXIT")
		}) { error in
			self.sendLocal(title: "MONITOR REGION", text: "ERROR \(error)")
		}
	}
	
	private func sendLocal(title: String, text: String) {
		let notification = UILocalNotification()
		notification.alertTitle = title
		notification.alertBody = text
		notification.fireDate = Date(timeIntervalSinceNow: 10)
		UIApplication.shared.scheduleLocalNotification(notification)
	}
	
	private func test_backgroundTravelled() {
		if rq_backgroundTravelled != nil {
			let alert = UIAlertController(title: "Action", message: "", preferredStyle: .actionSheet)
			alert.addAction(UIAlertAction(title: "Pause", style: .default, handler: { _ in
				self.rq_backgroundTravelled?.pause()
			}))
			if rq_backgroundTravelled!.state.isPaused {
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
		
		rq_backgroundTravelled = LocationRequest(name: "REQ_4", accuracy: .any, frequency: .deferredUntil(distance: 20, timeout: CLTimeIntervalMax, navigation: true), { loc in
			self.debug("\t\t[\(self.rq_backgroundTravelled!.name)] > New location \(loc)")
		}, { (last, error) in
			self.debug("\t\t[\(self.rq_backgroundTravelled!.name)] > Error \(error)")
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
			self.debug("\t\t[\(self.rq_background!.name)] > New location \(loc)")
		}, { (last, error) in
			self.debug("\t\t[\(self.rq_background!.name)] > Error \(error)")
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
			self.debug("\t\t[\(self.rq_oneshot!.name)] > New location \(loc)")
		}, { (last, error) in
			self.debug("\t\t[\(self.rq_oneshot!.name)] > Error \(error)")
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
			self.debug("\t\t[\(self.rq_continousLoc!.name)] > New location \(loc)")
		}, { (last, error) in
			self.debug("\t\t[\(self.rq_continousLoc!.name)] > Error \(error)")
		})
		rq_continousLoc?.minimumDistance = 10
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
			self.debug("\t\t[\(self.rq_continousLoc2!.name)] > New location \(loc)")
		}, { (last, error) in
			self.debug("\t\t[\(self.rq_continousLoc2!.name)] > Error \(error)")
		})
		rq_continousLoc2!.resume()
	}
	
	private func test_IPScan() {
		let ipServices: [IPService.Name] = [.freeGeoIP, .petabyet, .smartIP, .telize]
		let randomService = ipServices[random(0, UInt32(ipServices.count - 1))]
		let sv = Accuracy.IPScan(IPService(randomService))
		let fq = Frequency.oneShot
		
		rq_ipscan = LocationRequest(name: "REQ_0", accuracy: sv, frequency: fq, { location in
			self.debug("\t\t[\(self.rq_ipscan!.name)] > [\(randomService)]: \(location.coordinate.latitude), \(location.coordinate.longitude)")
		}, { (last, error) in
			self.debug("\t\t[\(self.rq_ipscan!.name)] > Error: \(error)")
		})
		rq_ipscan!.resume()
	}
	
	private func random(_ from: UInt32, _ to: UInt32) -> Int {
		return Int(arc4random_uniform(to) + from)
	}

}

