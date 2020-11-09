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

public class PlaygroundController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - IBOutlets

    @IBOutlet public var featuresTableView: UITableView!
    
    // MARK: - Private Properties

    private let featuresList: [Feature] = [
        .gpsLocation,
        .ipLocation,
        .geofenceMonitoring,
        .visitsMonitoring,
        .geocoder,
        .autocompleAddress,
        .beaconBroadcast,
        .beaconRanging
    ]
    
    // MARK: - Initialization
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        featuresTableView.rowHeight = UITableView.automaticDimension
        featuresTableView.estimatedRowHeight = 45
        featuresTableView.dataSource = self
        featuresTableView.delegate = self
        featuresTableView.tableFooterView = UIView()

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
            }
        }
    }
    
}
