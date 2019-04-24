//
//  IPRequestCell.swift
//  DemoApp
//
//  Created by dan on 23/04/2019.
//  Copyright © 2019 SwiftLocation. All rights reserved.
//

import CoreLocation
import MapKit

public class IPRequestCell: UITableViewCell {
    public static let height: CGFloat = 180
    
    @IBOutlet public var titleLabel: UILabel!
    @IBOutlet public var coordinatesLabel: UILabel!
    @IBOutlet public var cityLabel: UILabel!
    @IBOutlet public var regionLabel: UILabel!
    @IBOutlet public var ipLabel: UILabel!
    @IBOutlet public var ISPLabel: UILabel!
    @IBOutlet public var CountryLabel: UILabel!
    @IBOutlet public var stopButton: UIButton!

    internal weak var monitorController: RequestsMonitorController?
    
    @IBAction public func didPressStop() {
        if let request = request {
            switch request.state {
            case .expired:
                monitorController?.completedRequests.removeAll(where: { $0.id == request.id })
                monitorController?.reload()
            default:
                request.stop()
            }
        }
    }
    
    public var request: LocationByIPRequest? {
        didSet {
            stopButton.setTitle( (request?.state == .running ? "Stop" : "Remove"), for: .normal)
            titleLabel.text = "LOCATION BY IP (SERVICE: \(request?.service.description ?? "-"))"
            
            guard let place = request?.value else {
                coordinatesLabel.text = "(not received)"
                cityLabel.text = "-"
                regionLabel.text = "-"
                ipLabel.text = "-"
                ISPLabel.text = "-"
                CountryLabel.text = "-"
                return
            }
            
            coordinatesLabel.text = NSString(format: "%0.5f, %0.5f", place.coordinates!.latitude, place.coordinates!.longitude) as String
            cityLabel.text = "\((place.city ?? "-")), \((place.zipCode ?? "-"))"
            regionLabel.text = "\((place.regionName ?? "-")), \((place.regionCode ?? "-"))"
            ipLabel.text = place.ip ?? "-"
            ISPLabel.text = place.isp ?? "-"
            CountryLabel.text = "\((place.countryName ?? "-")), \((place.countryCode ?? "-"))"
            
            stopButton.isEnabled = true
            stopButton.alpha = 1.0
        }
    }
    
}
