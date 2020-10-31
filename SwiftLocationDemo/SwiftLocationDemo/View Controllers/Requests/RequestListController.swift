//
//  RequestListController.swift
//  SwiftLocationDemo
//
//  Created by daniele margutti on 15/10/2020.
//

import UIKit
import SwiftLocation
import CoreLocation
import MapKit

public class ListData {
    var visits = [VisitsRequest]()
    var gps = [GPSLocationRequest]()
    var ip = [IPLocationRequest]()
    var geofencing = [GeofencingRequest]()
    var geocode = [GeocoderRequest]()
    var autocomplete = [AutocompleteRequest]()

    public init() {
        visits = Array(Locator.shared.visitsRequest.list)
        gps = Array(Locator.shared.gpsRequests.list)
        ip = Array(Locator.shared.ipRequests.list)
        geofencing = Array(Locator.shared.geofenceRequests.list)
        geocode = Array(Locator.shared.geocoderRequests.list)
        autocomplete = Array(Locator.shared.autocompleteRequests.list)
    }
    
}

class RequestListController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet public var tableView: UITableView?
    @IBOutlet public var statusText: UITextView?

    private var timer: Timer?
    private var listData = ListData()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Requests List"
        
        tableView?.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView?.delegate = self
        tableView?.dataSource = self
        tableView?.tableFooterView = UIView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.timer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(reloadTable), userInfo: nil, repeats: true)
        reloadTable()
    }
    
    @objc private func reloadTable() {
        listData = ListData()
        
        tableView?.rowHeight = UITableView.automaticDimension
        tableView?.estimatedRowHeight = 80
        tableView?.reloadData()
        
        statusText?.text = Locator.shared.description
    }
    
    @IBAction public func reloadData(_ sender: Any?) {
        reloadTable()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        6
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return listData.visits.count
        case 1: return listData.gps.count
        case 2: return listData.ip.count
        case 3: return listData.geocode.count
        case 4: return listData.autocomplete.count
        case 5: return listData.geofencing.count
        default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.lineBreakMode = .byWordWrapping
        cell.textLabel?.font = UIFont.systemFont(ofSize: 13, weight: .bold)

        cell.detailTextLabel?.numberOfLines = 0
        cell.detailTextLabel?.lineBreakMode = .byWordWrapping
        cell.detailTextLabel?.font = UIFont.monospacedSystemFont(ofSize: 10, weight: .regular)

        switch indexPath.section {
        case 0:
            cell.textLabel?.text = listData.visits[indexPath.row].uuid
            cell.detailTextLabel?.text = listData.visits[indexPath.row].description
        case 1:
            cell.textLabel?.text = listData.gps[indexPath.row].uuid
            cell.detailTextLabel?.text = listData.gps[indexPath.row].description
        case 2:
            cell.textLabel?.text = listData.ip[indexPath.row].uuid
            cell.detailTextLabel?.text = listData.ip[indexPath.row].description
        case 3:
            cell.textLabel?.text = listData.geocode[indexPath.row].uuid
            cell.detailTextLabel?.text = listData.geocode[indexPath.row].description
        case 4:
            cell.textLabel?.text = listData.autocomplete[indexPath.row].uuid
            cell.detailTextLabel?.text = listData.autocomplete[indexPath.row].description
        case 5:
            cell.textLabel?.text = listData.geofencing[indexPath.row].uuid
            cell.detailTextLabel?.text = listData.geofencing[indexPath.row].description
        default:
            cell.textLabel?.text = ""
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
        case 0: return "VISITS"
        case 1: return "GPS"
        case 2: return "IP"
        case 3: return "GEOCODE"
        case 4: return "AUTOCOMPLETE"
        case 5: return "GEOFENCING"
        default: return ""
        }
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        [
            UITableViewRowAction(style: .destructive, title: "Stop Monitor", handler: { [weak self] (_, indexPath) in
                self?.cancelRequestAtIndexPath(indexPath)
            })
        ]
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        false
    }
    
    func cancelRequestAtIndexPath(_ indexPath: IndexPath) {
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
