//
//  SwiftLocationPlayground
//
//  Copyright (c) 2020 Daniele Margutti (hello@danielemargutti.com).
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import UIKit
import SwiftLocation
import UserNotifications
import MapKit
import CoreLocation

public let NOT_SET = "not set"
public let USER_SET = "user's set"
public let NOTIFICATION_GPS_DATA = Notification.Name("NOTIFICATION_GPS_DATA")
public let NOTIFICATION_VISITS_DATA = Notification.Name("NOTIFICATION_VISITS_DATA")
public let NOTIFICATION_BEACONS_DATA = Notification.Name("NOTIFICATION_BEACONS_DATA")

public var beaconsLogItems = [Result<BeaconRequest.ProducedData, LocationError>]()

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Setup locator
        SwiftLocation.onRestoreGeofences = AppDelegate.onRestoreGeofencedRequests
        SwiftLocation.onRestoreGPS = AppDelegate.onRestoreGPSRequests
        SwiftLocation.onRestoreVisits = AppDelegate.onRestoreVisitsRequests
        SwiftLocation.restoreState()

        // Enable push notifications
        UNUserNotificationCenter.current().delegate = self
        AppDelegate.enablePushNotifications()

        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {

    }
    
    func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
                    
        AppDelegate.openResultController(response)
        completionHandler()
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .badge, .sound])
    }
    
    // MARK: - Private Helper
    
    private static func openResultController(_ response: UNNotificationResponse) {
        guard let rootController = UIApplication.shared.windows.first?.rootViewController,
              let rawData = response.notification.request.content.userInfo["result"] as? String else {
            return
        }
        
        ResultController.showWithData(rawData, in: rootController)
    }
    
    private static func enablePushNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if let error = error {
                UIAlertController.showAlert(title: "Failed to enable notifications",
                                            message: error.localizedDescription)
            }
        }
    }
    
    public static func attachSubscribersToGeofencedRegions(_ requests: [GeofencingRequest]) {
        for request in requests {
            request.cancelAllSubscriptions() // remove previous subscribers
            
            // attach new ones
            request.then(queue: .main) { result in
                switch result {
                case .success(let event):
                    sendLocalPushNotification(title: "New Geofence Event", subtitle: event.description, object: result.description)
                case .failure(let error):
                    sendLocalPushNotification(title: "Geofence Error", subtitle: error.localizedDescription, object: result.description)
                }
            }
        }
    }
    
    public static func attachSubscribersToBeacons(_ requests: [BeaconRequest]) {
        for request in requests {
            request.cancelAllSubscriptions() // remove previous subscribers
            
            // attach new ones
            request.then(queue: .main) { result in
                NotificationCenter.default.post(name: NOTIFICATION_BEACONS_DATA, object: result, userInfo: nil)
                AppDelegate.addToBeaconLog(result)
                
                if UIApplication.shared.applicationState == .background {
                    switch result {
                    case .success(let event):
                        sendLocalPushNotification(title: "New Beacon Event", subtitle: event.description, object: result.description)
                    case .failure(let error):
                        sendLocalPushNotification(title: "Beacon Error", subtitle: error.localizedDescription, object: result.description)
                    }
                }
            }
        }
    }
    
    private static func addToBeaconLog(_ item: Result<BeaconRequest.ProducedData, LocationError>) {
        beaconsLogItems.insert(item, at: 0)
        beaconsLogItems = Array(beaconsLogItems.prefix(10))
    }
    
    public static func attachSubscribersToVisitsRegions(_ requests: [VisitsRequest?]) {
        for request in requests {
            if let unwrappedRequest = request {
                unwrappedRequest.then(queue: .main) { result in
                    NotificationCenter.default.post(name: NOTIFICATION_VISITS_DATA, object: result, userInfo: nil)

                    switch result {
                    case .success(let visit):
                        VisitsController.addVisitToHistory(visit)
                        sendLocalPushNotification(title: "New Visit", subtitle: visit.description, object: result.description)
                    case .failure(let error):
                        sendLocalPushNotification(title: "Visit Error", subtitle: error.localizedDescription, object: result.description)
                    }
                }
            }
        }
    }
        
    public static func attachSubscribersToGPS(_ requests: [GPSLocationRequest]) {
        for request in requests {
            request.then(queue: .main) { result in
                NotificationCenter.default.post(name: NOTIFICATION_GPS_DATA, object: result, userInfo: nil)
                
                switch result {
                case .success(let visit):
                    sendLocalPushNotification(title: "New GPS Location", subtitle: visit.description, object: result.description)
                case .failure(let error):
                    sendLocalPushNotification(title: "GPS Error", subtitle: error.localizedDescription, object: result.description)
                }
            }
        }
    }
    
    public static func sendLocalPushNotification(title: String, subtitle: String, object: Any? = nil, afterInterval: TimeInterval = 3) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.subtitle = subtitle
        content.sound = UNNotificationSound.default
        
        if let object = object {
            content.userInfo = ["result": object]
        }
        
        // show this notification five seconds from now
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: afterInterval, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Restore
    
    public static func onRestoreGPSRequests(_ requests: [GPSLocationRequest]) {
        guard requests.isEmpty == false else {
            return
        }
        
        print("Restoring \(requests.count) gps regions...")
        AppDelegate.attachSubscribersToGPS(requests)
    }
    
    public static func onRestoreGeofencedRequests(_ requests: [GeofencingRequest]) {
        guard requests.isEmpty == false else {
            return
        }
        
        print("Restoring \(requests.count) geofenced regions...")
        AppDelegate.attachSubscribersToGeofencedRegions(requests)
    }
    
    public static func onRestoreVisitsRequests(_ requests: [VisitsRequest]) {
        guard requests.isEmpty == false else {
            return
        }
        
        print("Restoring \(requests.count) visits requests...")
        attachSubscribersToVisitsRegions(requests)
    }
    
}

