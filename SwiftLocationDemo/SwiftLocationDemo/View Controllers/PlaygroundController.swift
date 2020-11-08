//
//  PlaygroundController.swift
//  SwiftLocationDemo
//
//  Created by daniele on 06/11/2020.
//

import UIKit

public class PlaygroundController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet public var featuresTableView: UITableView!
    
    private let featuresList: [Feature] = [
        .ipLocation,
        .gpsLocation,
        .visitsMonitoring,
        .geofenceMonitoring,
        .autocompleAddress,
        .geocoder
    ]
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        featuresTableView.rowHeight = UITableView.automaticDimension
        featuresTableView.estimatedRowHeight = 45
        featuresTableView.dataSource = self
        featuresTableView.delegate = self
        
        self.navigationItem.title = "SwiftLocation Playground"
    }
    
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
        }
    }
    
}

fileprivate extension PlaygroundController {
    
    enum Feature: CellRepresentableItem {
        case ipLocation
        case gpsLocation
        case visitsMonitoring
        case geofenceMonitoring
        case autocompleAddress
        case geocoder

        var title: String {
            switch self {
            case .ipLocation: return "IP Location"
            case .gpsLocation: return "GPS Location"
            case .visitsMonitoring: return "Visits"
            case .geofenceMonitoring: return "Geofence"
            case .autocompleAddress: return "Autocomplete Address"
            case .geocoder: return "Geocoder/Reverse Geocoder"
            }
        }
        
        var subtitle: String {
            switch self {
            case .ipLocation: return "Get coordinates from IP Address"
            case .gpsLocation: return "Get coordinates from GPS"
            case .visitsMonitoring: return "Relevant visited locations"
            case .geofenceMonitoring: return "Enter/Exit notifications from regions"
            case .autocompleAddress: return "Suggest addresses, poi etc."
            case .geocoder: return "Get coordinates from address/address from coordinates"
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
            }
        }
    }
    
}
