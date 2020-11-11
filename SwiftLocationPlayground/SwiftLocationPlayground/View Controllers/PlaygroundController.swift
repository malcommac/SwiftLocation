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

public class PlaygroundController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - IBOutlets

    @IBOutlet public var featuresTableView: UITableView!
    
    // MARK: - Private Properties

    private static let UserDefaultsCredentialsKey = "swiftlocation.playground.credentials"

    private let featuresList: [Feature] = [
        .authRequest,
        .gpsLocation,
        .ipLocation,
        .geofenceMonitoring,
        .visitsMonitoring,
        .geocoder,
        .autocompleAddress,
        .beaconBroadcast,
        .beaconRanging,
        .credentailsStore
    ]
    
    // MARK: - Initialization
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        featuresTableView.rowHeight = UITableView.automaticDimension
        featuresTableView.estimatedRowHeight = 45
        featuresTableView.dataSource = self
        featuresTableView.delegate = self
        featuresTableView.tableFooterView = UIView()

        restoreCredentialsFromUserDefaults()
        
        self.navigationItem.title = "SwiftLocation Playground"
    }
    
    // MARK: - TableView DataSource & Delegates
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        featuresList.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ActionCell.RIdentifier) as! ActionCell
        cell.item = featuresList[indexPath.row]
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        openFeatureScreen(featuresList[indexPath.row])
    }
    
    // MARK: - Private Functions

    private func openFeatureScreen(_ feature: Feature) {
        switch feature {
        case .ipLocation:
            navigationController?.pushViewController(IPLocationController.create(), animated: true)
        case .gpsLocation:
            navigationController?.pushViewController(GPSController.create(), animated: true)
        case .visitsMonitoring:
            navigationController?.pushViewController(VisitsController.create(), animated: true)
        case .geofenceMonitoring:
            navigationController?.pushViewController(GeofenceController.create(), animated: true)
        case .autocompleAddress:
            navigationController?.pushViewController(AutocompleteController.create(), animated: true)
        case .geocoder:
            navigationController?.pushViewController(GeocoderController.create(), animated: true)
        case .beaconBroadcast:
            navigationController?.pushViewController(BroadcastBeaconController.create(), animated: true)
        case .beaconRanging:
            navigationController?.pushViewController(BeaconsMonitorController.create(), animated: true)
        case .authRequest:
            requestAuthorizations()
        case .credentailsStore:
            setCredentialsStoreValue()
        }
    }
    
    private func requestAuthorizations() {
        
        func requestAuthWithMode(_ mode: AuthorizationMode) {
            SwiftLocation.requestAuthorization(mode) { [weak self] newStatus in
                UIAlertController.showAlert(title: "Current Status is\n\(newStatus.description)")
                self?.featuresTableView.reloadData()
            }
        }
        
        UIAlertController.showActionSheet(title: "Request Authorization",
                                          message: "Select the method to use to request auth",
                                          options: [
                                            ("Via plist", { _ in
                                                requestAuthWithMode(.plist)
                                            }),
                                            ("Always", { _ in
                                                requestAuthWithMode(.always)
                                            }),
                                            ("Only In Use", { _ in
                                                requestAuthWithMode(.onlyInUse)
                                            }),
                                          ])
    }
    
    private func setCredentialsStoreValue() {
        
        func askForKey(_ service: LocationManager.Credentials.ServiceName) {
            let currentValue = SwiftLocation.credentials[service]
            UIAlertController.showInputFieldSheet(title: "API Key \(service.description)", message: nil, placeholder: nil, fieldValue: currentValue, cancelAction: {
                // nothing
            }, confirmAction: { [weak self] apiKey in
                SwiftLocation.credentials[service] = apiKey ?? ""
                self?.saveCredentialsInUserDefaults()
            })
        }
        
        let values: [UIAlertController.ActionSheetOption] = LocationManager.Credentials.ServiceName.allCases.map { serviceKind in
            (serviceKind.description, { _ in
                askForKey(serviceKind)
            })
        }
        UIAlertController.showActionSheet(title: "Select Service", message: "Select a service you want to set the API key. It will be saved in your user defaults", options: values, cancelAction: nil)
    }
    
    private func saveCredentialsInUserDefaults() {
        do {
            let value = try JSONEncoder().encode(SwiftLocation.credentials)
            UserDefaults.standard.setValue(value, forKey: PlaygroundController.UserDefaultsCredentialsKey)
        } catch {
            UIAlertController.showAlert(title: "Failed to store credentials", message: error.localizedDescription)
        }
    }
    
    private func restoreCredentialsFromUserDefaults() {
        do {
            guard let data = UserDefaults.standard.object(forKey: PlaygroundController.UserDefaultsCredentialsKey) as? Data else {
                return
            }
            
            let credentials = try JSONDecoder().decode(LocationManager.Credentials.self, from: data)
            SwiftLocation.credentials.loadCredential(credentials)
        } catch {
            UIAlertController.showAlert(title: "Failed to restore credentials saved", message: error.localizedDescription)
        }
    }
        
}

// MARK: - PlaygroundController Feature

fileprivate extension PlaygroundController {
    
    enum Feature: CellRepresentableItem {
        case ipLocation
        case gpsLocation
        case visitsMonitoring
        case geofenceMonitoring
        case autocompleAddress
        case geocoder
        case beaconBroadcast
        case beaconRanging
        case authRequest
        case credentailsStore

        var title: String {
            switch self {
            case .ipLocation: return "Location by IP"
            case .gpsLocation: return "Location by GPS"
            case .visitsMonitoring: return "Visits"
            case .geofenceMonitoring: return "Geofence Regions"
            case .autocompleAddress: return "Autocomplete Address"
            case .geocoder: return "Geocoder & Reverse Geocoder"
            case .beaconBroadcast: return "Beacon Broadcaster"
            case .beaconRanging: return "Beacons Monitor"
            case .authRequest: return "Request Authorizations"
            case .credentailsStore: return "Credentials Store"
            }
        }
        
        var subtitle: String {
            switch self {
            case .ipLocation: return "Get coordinates from IP Address"
            case .gpsLocation: return "Get coordinates from GPS"
            case .visitsMonitoring: return "Relevant visited locations"
            case .geofenceMonitoring: return "Enter/exit notifications from regions"
            case .autocompleAddress: return "Suggest addresses, POI, activites..."
            case .geocoder: return "Get coordinates from address/address from coordinates"
            case .beaconBroadcast: return "Act as beacon (only foreground)"
            case .beaconRanging: return "Monitor beacons ranging"
            case .authRequest: return "Current: \(SwiftLocation.authorizationStatus.description)"
            case .credentailsStore:
                if SwiftLocation.credentials.keysStore.isEmpty {
                    return "Save API Key for services"
                } else {
                    return "Keys stored: \(SwiftLocation.credentials.keysStore.keys.map({ $0.description }).joined(separator: ","))"
                }
            }
        }
        
        var icon: UIImage? {
            switch self {
            case .ipLocation: return UIImage(named: "tabbar_ip")
            case .gpsLocation: return UIImage(named: "tabbar_gps")
            case .visitsMonitoring: return UIImage(named: "tabbar_visits")
            case .geofenceMonitoring: return UIImage(named: "tabbar_geofence")
            case .autocompleAddress: return UIImage(named: "tabbar_autocomplete")
            case .geocoder: return UIImage(named: "tabbar_geocoder")
            case .beaconBroadcast: return UIImage(named: "tabbar_broadcaster")
            case .beaconRanging: return UIImage(named: "tabbar_beacon")
            case .authRequest: return UIImage(named: "tabbar_auths")
            case .credentailsStore: return UIImage(named: "tabbar_credentials")
            }
        }
    }
    
}
