//
//  AppDelegate.swift
//  LocationDemo
//
//  Created by Daniele Margutti on 08/01/2017.
//  Copyright © 2017 Daniele Margutti. All rights reserved.
//

import UIKit
import SwiftLocation
import CoreLocation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate {

	var window: UIWindow?
	var locationManager: CLLocationManager = CLLocationManager()
	var deferringUpdates: Bool = false


	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		// Override point for customization after application launch.
		
		let n = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
		UIApplication.shared.registerUserNotificationSettings(n)

		
	//	startHikeLocationUpdates()
		return true
	}

	func applicationWillResignActive(_ application: UIApplication) {
		// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
		// Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
	}

	func applicationDidEnterBackground(_ application: UIApplication) {
		// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
		// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
		
		
	}
	
//	func startHikeLocationUpdates() {
//		// Create a location manager object
//		
//		// Set the delegate
//		self.locationManager.delegate = self
//		self.locationManager.allowsBackgroundLocationUpdates = true
//		
//		// Request location authorization
//		self.locationManager.requestAlwaysAuthorization()
//		
//		// Specify the type of activity your app is currently performing
//		self.locationManager.activityType = .fitness//CLActivityTypeFitness
//		
//		// Start location updates
//		self.locationManager.startUpdatingLocation()
//	}
//	
//	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//		// Add the new locations to the hike
//		print(locations)
//		
//		// Defer updates until the user hikes a certain distance or a period of time has passed
//		if (!deferringUpdates) {
//			var distance: CLLocationDistance = 10
//			var time: TimeInterval = CLTimeIntervalMax//nextUpdate.timeIntervalSinceNow()
//			self.locationManager.allowDeferredLocationUpdates(untilTraveled: distance, timeout:time)
//			deferringUpdates = true;
//		} else {
//			dispatchNotif("\(locations.first!.coordinate.latitude),\(locations.first!.coordinate.longitude)")
//		}
//	}
//	
//	func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
////		let v = UIAlertView(title: "ALERT", message: notification.alertBody, delegate: nil, cancelButtonTitle: "OK")
////		v.show()
//		NotificationCenter.default.post(name: NSNotification.Name(rawValue: "prova"), object: notification, userInfo: ["text" : notification.alertBody])
//	}
// 
//	func locationManager(manager: CLLocationManager, didFinishDeferredUpdatesWithError error: Error!) {
//		// Stop deferring updates
//		self.deferringUpdates = false
//		
//		// Adjust for the next goal
//	}
//	
//	
//	func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
//		print(error)
//		dispatchNotif(error.localizedDescription)
//	}
//	
//	func dispatchNotif(_ text: String) {
//		let notification = UILocalNotification()
//		notification.alertTitle = "NOTIF"
//		notification.alertBody = "\(text)"
//		notification.fireDate = Date()
//		UIApplication.shared.scheduleLocalNotification(notification)
//	}


	func applicationWillEnterForeground(_ application: UIApplication) {
		// Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
	}

	func applicationDidBecomeActive(_ application: UIApplication) {
		// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	}

	func applicationWillTerminate(_ application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
	}


}

