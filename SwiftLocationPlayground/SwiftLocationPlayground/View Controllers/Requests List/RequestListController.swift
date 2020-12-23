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
import CoreLocation
import MapKit

class RequestListController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    // MARK: - IBOutlets
    
    @IBOutlet public var tableView: UITableView?

    // MARK: - Private Properties

    private var timer: Timer?
    private var listData = ListData()
    
    // MARK: - Initialiation

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Requests List"
        
        tableView?.rowHeight = UITableView.automaticDimension
        tableView?.estimatedRowHeight = 80
        tableView?.registerUINibForClass(StandardCellSetting.self)
        tableView?.delegate = self
        tableView?.dataSource = self
        tableView?.tableFooterView = UIView()
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadTable), name: NOTIFICATION_GPS_DATA, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadTable), name: NOTIFICATION_VISITS_DATA, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: NOTIFICATION_GPS_DATA, object: nil)
        NotificationCenter.default.removeObserver(self, name: NOTIFICATION_VISITS_DATA, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.timer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(reloadTable), userInfo: nil, repeats: true)
        reloadTable()
    }
    
    // MARK: - Table View DataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        8
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return listData.managerSettings.count
        case 1: return listData.visits.count
        case 2: return listData.gps.count
        case 3: return listData.ip.count
        case 4: return listData.geocode.count
        case 5: return listData.autocomplete.count
        case 6: return listData.geofencing.count
        case 7: return listData.beacons.count
        default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: StandardCellSetting.defaultReuseIdentifier, for: indexPath) as! StandardCellSetting
        cell.titleLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)

        if indexPath.section == 0 {
            cell.accessoryType = .none
            cell.titleLabel?.text = listData.managerSettings[indexPath.row].key.title
            cell.subtitleLabel.text = ""
            cell.valueLabel?.text = listData.managerSettings[indexPath.row].value
            return cell
        }
            
        cell.valueLabel?.text = ""
        cell.accessoryType = .none
        switch indexPath.section {
        case 1:
            let req = listData.visits[indexPath.row]
            cell.titleLabel?.text = req.name ?? req.uuid
            cell.subtitleLabel?.text = req.shortDescription
        case 2:
            let req = listData.gps[indexPath.row]
            cell.titleLabel?.text = req.name ?? req.uuid
            cell.subtitleLabel?.text = req.shortDescription
        case 3:
            let req = listData.ip[indexPath.row]
            cell.titleLabel?.text = req.name ?? req.uuid
            cell.subtitleLabel?.text = req.shortDescription
        case 4:
            let req = listData.geocode[indexPath.row]
            cell.titleLabel?.text = req.name ?? req.uuid
            cell.subtitleLabel?.text = req.shortDescription
        case 5:
            let req = listData.autocomplete[indexPath.row]
            cell.titleLabel?.text = req.name ?? req.uuid
            cell.subtitleLabel?.text = req.shortDescription
        case 6:
            let req = listData.geofencing[indexPath.row]
            cell.titleLabel?.text = req.name ?? req.uuid
            cell.subtitleLabel?.text = req.shortDescription
        case 7:
            let req = listData.beacons[indexPath.row]
            cell.titleLabel?.text = req.name ?? req.uuid
            cell.subtitleLabel?.text = req.shortDescription
        default:
            cell.titleLabel?.text = ""
            cell.subtitleLabel?.text = ""
        }
                
        return cell
    }
    
    public func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.tintColor = UIColor.lightGray.withAlphaComponent(0.1)

        // swiftlint:disable force_cast
        let header : UITableViewHeaderFooterView = view as! UITableViewHeaderFooterView
        header.textLabel?.textColor = UIColor.darkGray
        header.textLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Location Manager Settings"
        case 1: return "Visits"
        case 2: return "GPS"
        case 3: return "IP"
        case 4: return "Geocode"
        case 5: return "Autocomplete"
        case 6: return "Geofence"
        case 7: return "Beacons"
        default: return ""
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard indexPath.section > 0 else {
            return nil
        }
        
        let action = UIContextualAction(style: .destructive, title: "Stop Monitor") { [weak self] (action, view, completionHandler) in
            self?.cancelRequestAtIndexPath(indexPath)

            completionHandler(true)
        }
        
        return UISwipeActionsConfiguration(actions: [action])
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        UIAlertController.showInputFieldSheet(title: "Assign a name") { [weak self] value in
            guard let self = self else { return }
            
            switch indexPath.section {
            case 1: self.listData.visits[indexPath.row].name = value
            case 2: self.listData.gps[indexPath.row].name = value
            case 3: self.listData.ip[indexPath.row].name = value
            case 4: self.listData.geocode[indexPath.row].name = value
            case 5: self.listData.autocomplete[indexPath.row].name = value
            case 6: self.listData.geofencing[indexPath.row].name = value
            case 7: self.listData.beacons[indexPath.row].name = value
            default: break
            }
            
            self.reloadTable()
        }
    }
    
    // MARK: - Private Functions
    
    @objc private func reloadTable() {
        listData = ListData()
        tableView?.reloadData()
    }
    
    @IBAction public func reloadData(_ sender: Any?) {
        reloadTable()
    }
    
    private func cancelRequestAtIndexPath(_ indexPath: IndexPath) {
        switch indexPath.section {
        case 1: listData.visits[indexPath.row].cancelRequest()
        case 2: listData.gps[indexPath.row].cancelRequest()
        case 3: listData.ip[indexPath.row].cancelRequest()
        case 4: listData.geocode[indexPath.row].cancelRequest()
        case 5: listData.autocomplete[indexPath.row].cancelRequest()
        case 6: listData.geofencing[indexPath.row].cancelRequest()
        case 7: listData.beacons[indexPath.row].cancelRequest()
        default: break
        }
        
        reloadTable()
    }
        
}

// MARK: - ListData

fileprivate class ListData {
    var visits = [VisitsRequest]()
    var gps = [GPSLocationRequest]()
    var ip = [IPLocationRequest]()
    var geofencing = [GeofencingRequest]()
    var geocode = [GeocoderRequest]()
    var autocomplete = [AutocompleteRequest]()
    var beacons = [BeaconRequest]()
    var managerSettings: [(key: RequestListController.ManagerSettingsKey, value: String)]

    public init() {
        visits = Array(SwiftLocation.visitsRequest.list)
        gps = Array(SwiftLocation.gpsRequests.list)
        ip = Array(SwiftLocation.ipRequests.list)
        geofencing = Array(SwiftLocation.geofenceRequests.list)
        geocode = Array(SwiftLocation.geocoderRequests.list)
        autocomplete = Array(SwiftLocation.autocompleteRequests.list)
        beacons = Array(SwiftLocation.beaconsRequests.list)

        let settings = SwiftLocation.currentSettings
        managerSettings = [
            (.activeServices, settings.activeServices.isEmpty ? NOT_SET : settings.activeServices.description),
            (.accuracy, settings.accuracy.description),
            (.minDistance, settings.minDistance.formattedValue),
            (.activityType, settings.activityType.description)
        ]
    }
    
}

// MARK: - RequestListController (ManagerSettingsKey)

extension RequestListController {
    
    enum ManagerSettingsKey: CellRepresentableItem {
        case activeServices
        case accuracy
        case minDistance
        case activityType
        
        var title: String {
            switch self {
            case .activeServices: return "Running Services"
            case .accuracy: return "Accuracy Level"
            case .minDistance: return "Min Distance"
            case .activityType: return "Activity Type"
            }
        }
        
        var subtitle: String {
            ""
        }
        
        var icon: UIImage? {
            nil
        }
        
    }
    
}

// MARK: - RequestProtocol (Short Description)

fileprivate extension RequestProtocol {
    
    var shortDescription: String {
        switch self {
        case let gps as GPSLocationRequest:
            return [
                "› last: \(gps.lastReceivedValue?.description ?? "-")",
                "› type: \(gps.options.subscription.description)",
                "› accuracy: \(gps.options.accuracy.description)",
                "› activity: \(gps.options.activityType.description)",
                "› minDist: \(gps.options.minDistance.description)",
                "› minInterval: \(gps.options.minTimeInterval?.description ?? NOT_SET)"
            ].joined(separator: "\n")
            
        case let ip as IPLocationRequest:
            return [
                "› type: \(ip.service.jsonServiceDecoder.rawValue)",
                "› ip: \(ip.service.targetIP ?? "current")"
            ].joined(separator: "\n")
            
        case let geofence as GeofencingRequest:
            return [
                "› last: \(geofence.lastReceivedValue?.description ?? "-")",
                "› region: \(geofence.options.region.shortDecription)",
                "› onEnter: \(geofence.options.notifyOnEnter.description)",
                "› onExit: \(geofence.options.notifyOnExit.description)"
            ].joined(separator: "\n")
            
        case let visit as VisitsRequest:
            return [
                "› last: \(visit.lastReceivedValue?.description ?? "-")"
            ].joined(separator: "\n")
            
        case let autocomplete as AutocompleteRequest:
            return [
                "› value: \(autocomplete.service.operation.description)"
            ].joined(separator: "\n")
            
        case let geocoder as GeocoderRequest:
            return [
                "› value: \(geocoder.service.operation.description)"
            ].joined(separator: "\n")
            
        case let beacon as BeaconRequest:
            return [
                "› \(beacon.description)"
            ].joined(separator: "\n")
            
        default:
            return description
        }
    }
    
}

// MARK: - GeofencingOptions.Region (Description)

fileprivate extension GeofencingOptions.Region {
    
    var shortDecription: String {
        switch self {
        case .circle(let cRegion):
            return "circle: \(cRegion.description)"
        case .polygon(let polygon, let cRegion):
            return "polygon: \(polygon.description)\nouter: \(cRegion.description)"
        }
    }
    
}

// MARK: - BeaconRequest (Description)

public extension BeaconRequest {
    
    var shortDescription: String {
        if !monitoredBeacons.isEmpty {
            return "\(monitoredBeacons.count) Beacons\n\(monitoredBeacons.description)"
        } else {
            return "\(monitoredRegions.count) Regions\n\(monitoredRegions.description)"
        }
    }
    
}
