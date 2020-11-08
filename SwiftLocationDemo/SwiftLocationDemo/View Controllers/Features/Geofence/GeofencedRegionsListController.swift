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
        regions = Array(LocationManager.shared.geofenceRequests.list)
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
