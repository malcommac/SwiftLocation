//
//  GeofencedRegionsListController.swift
//  SwiftLocationDemo
//
//  Created by daniele margutti on 15/10/2020.
//

import UIKit
import SwiftLocation
import CoreLocation
import MapKit

class GeofencedRegionsListController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet private var tableView: UITableView!
    
    public static func create() -> GeofencedRegionsListController {
        let s = UIStoryboard(name: "GeofenceController", bundle: nil)
        let vc = s.instantiateViewController(identifier: "GeofencedRegionsListController") as! GeofencedRegionsListController
        return vc
    }
    
    private var regions = [GeofencingRequest]()
 
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44
        tableView.delegate = self
        tableView.dataSource = self
        
        self.title = "Geofenced Regions"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        reloadData()
    }
    
    private func reloadData() {
        regions = Array(Locator.shared.geofenceRequests.list)
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        regions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: GeofencedRegionCell.identifier, for: indexPath) as! GeofencedRegionCell
        cell.request = regions[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        return [
            UITableViewRowAction(style: .destructive, title: "Stop Monitor", handler: { [weak self] (_, indexPath) in
                guard let self = self else { return }
                let request = self.regions[indexPath.row]
                request.cancelRequest()
                self.reloadData()
            })
        ]
    }
    
}

public class GeofencedRegionCell: UITableViewCell {
    public static let identifier = "GeofencedRegionCell"
    
    @IBOutlet public var iconView: UIImageView!
    @IBOutlet public var titleLabel: UILabel!
    @IBOutlet public var subtitleLabel: UILabel!
    
    public weak var request: GeofencingRequest? {
        didSet {
            iconView.image = request?.icon
            titleLabel.text = request?.formattedTitle ?? ""
            subtitleLabel.text = request?.formattedSubTitle ?? ""
        }
    }

}

fileprivate extension GeofencingRequest {
    
    var icon: UIImage {
        switch self.options.region {
        case .circle:
            return UIImage(named: "circle")!
        case .polygon:
            return UIImage(named: "polygon")!
        }
    }
    
    var formattedTitle: String {
        switch self.options.region {
        case .circle:
            return "Circle Monitor"
        case .polygon:
            return "Polygon Monitor"
        }
    }
    
    var formattedSubTitle: String {
        let numberFormatter = NumberFormatter()
        numberFormatter.maximumFractionDigits = 3
        
        switch self.options.region {
        case .circle(let circle):
            return "center = \(circle.center.formattedValue)\nradius = \(circle.radius.formattedValue)"
        case .polygon(let polygon, let cRegion):
            return "points = \(polygon.coordinates.count)\ncenter = \(cRegion.center.formattedValue)"
        }
    }
    
}

public extension CLLocationCoordinate2D {

    var formattedValue: String {
        let numberFormatter = NumberFormatter()
        numberFormatter.maximumFractionDigits = 3
        return "{lat=\(numberFormatter.string(from: NSNumber(value: latitude)) ?? ""),lng=\(numberFormatter.string(from: NSNumber(value: longitude)) ?? "")}"
    }
    
}

public extension CLLocationDistance {
    
    var formattedValue: String {
        let numberFormatter = MKDistanceFormatter()
        numberFormatter.unitStyle = .abbreviated
        numberFormatter.locale = Locale(identifier: "IT-it")
        return numberFormatter.string(for: self) ?? ""
    }
    
}
