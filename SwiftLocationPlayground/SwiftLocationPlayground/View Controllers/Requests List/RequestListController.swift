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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.timer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(reloadTable), userInfo: nil, repeats: true)
        reloadTable()
    }
    
    // MARK: - Table View DataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        6
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
        default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: StandardCellSetting.defaultReuseIdentifier, for: indexPath) as! StandardCellSetting
        
        if indexPath.section == 0 {
            cell.accessoryType = .none
            cell.titleLabel?.text = listData.managerSettings[indexPath.row].key.title
            cell.subtitleLabel.text = ""
            cell.valueLabel?.text = listData.managerSettings[indexPath.row].value
            return cell
        }
            
        cell.valueLabel?.text = ""
        switch indexPath.section {
        case 1:
            cell.titleLabel?.text = listData.visits[indexPath.row].uuid
            cell.subtitleLabel?.text = listData.visits[indexPath.row].shortDescription
        case 2:
            cell.titleLabel?.text = listData.gps[indexPath.row].uuid
            cell.subtitleLabel?.text = listData.gps[indexPath.row].shortDescription
        case 3:
            cell.titleLabel?.text = listData.ip[indexPath.row].uuid
            cell.subtitleLabel?.text = listData.ip[indexPath.row].shortDescription
        case 4:
            cell.titleLabel?.text = listData.geocode[indexPath.row].uuid
            cell.subtitleLabel?.text = listData.geocode[indexPath.row].shortDescription
        case 5:
            cell.titleLabel?.text = listData.autocomplete[indexPath.row].uuid
            cell.subtitleLabel?.text = listData.autocomplete[indexPath.row].shortDescription
        case 6:
            cell.titleLabel?.text = listData.geofencing[indexPath.row].uuid
            cell.subtitleLabel?.text = listData.geofencing[indexPath.row].shortDescription
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
        case 0: return "Settings"
        case 1: return "Visits Requests"
        case 2: return "GPS Requests"
        case 3: return "IP Requests"
        case 4: return "Geocode Request"
        case 5: return "Autocomplete Requests"
        case 6: return "Geofence Requests"
        default: return ""
        }
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        guard indexPath.section > 0 else {
            return nil
        }
        
        return [
            UITableViewRowAction(style: .destructive, title: "Stop Monitor", handler: { [weak self] (_, indexPath) in
                self?.cancelRequestAtIndexPath(indexPath)
            })
        ]
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        false
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
        case 0: return listData.visits[indexPath.row].cancelRequest()
        case 1: return listData.gps[indexPath.row].cancelRequest()
        case 2: return listData.ip[indexPath.row].cancelRequest()
        case 3: return listData.geocode[indexPath.row].cancelRequest()
        case 4: return listData.autocomplete[indexPath.row].cancelRequest()
        case 5: return listData.geofencing[indexPath.row].cancelRequest()
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
    var managerSettings: [(key: RequestListController.ManagerSettingsKey, value: String)]

    public init() {
        visits = Array(LocationManager.shared.visitsRequest.list)
        gps = Array(LocationManager.shared.gpsRequests.list)
        ip = Array(LocationManager.shared.ipRequests.list)
        geofencing = Array(LocationManager.shared.geofenceRequests.list)
        geocode = Array(LocationManager.shared.geocoderRequests.list)
        autocomplete = Array(LocationManager.shared.autocompleteRequests.list)
        
        let settings = LocationManager.shared.currentSettings
        managerSettings = [
            (.activeServices, settings.activeServices.isEmpty ? "inactive" : settings.activeServices.description),
            (.accuracy, settings.accuracy.description),
            (.minDistance, settings.minDistance?.description ?? "any"),
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
            case .activeServices: return "Active Services"
            case .accuracy: return "Accuracy"
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
                "type: \(gps.options.subscription.description)",
                "accuracy: \(gps.options.accuracy.description)",
                "activity: \(gps.options.activityType.description)",
                "minDist: \(gps.options.minDistance?.description ?? NOT_SET)",
                "minInterval: \(gps.options.minTimeInterval?.description ?? NOT_SET)"
            ].joined(separator: "\n")
            
        case let ip as IPLocationRequest:
            return [
                "type: \(ip.service.jsonServiceDecoder.rawValue)",
                "ip: \(ip.service.targetIP ?? "current")"
            ].joined(separator: "\n")
            
        case let geofence as GeofencingRequest:
            return [
                "region: \(geofence.options.region.shortDecription)",
                "onEnter: \(geofence.options.notifyOnEnter.description)",
                "onExit: \(geofence.options.notifyOnExit.description)"
            ].joined(separator: "\n")
            
        case let visit as VisitsRequest:
            return [
                "last: \(visit.lastReceivedValue?.description ?? "-")"
            ].joined(separator: "\n")
            
        case let autocomplete as AutocompleteRequest:
            return [
                "value: \(autocomplete.service.operation.description)"
            ].joined(separator: "\n")
            
        case let geocoder as GeocoderRequest:
            return [
                "value: \(geocoder.service.operation.description)"
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
