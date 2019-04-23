//
//  GPSRequestCell.swift
//  DemoApp
//
//  Created by dan on 23/04/2019.
//  Copyright © 2019 SwiftLocation. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit

public class GPSRequestCell: UITableViewCell {
    public static let height: CGFloat = 105
    
    @IBOutlet public var titleLabel: UILabel!
    @IBOutlet public var coordinatesLabel: UILabel!
    @IBOutlet public var accuracyLabel: UILabel!
    @IBOutlet public var updateLabel: UILabel!
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
    
    public var request: LocationRequest? {
        didSet {
            stopButton.setTitle( (request?.state == .running ? "Stop" : "Remove"), for: .normal)
            titleLabel.text = "GPS LOCATION (MIN ACCEPTED: \(request?.accuracy.description ?? "-"))"
            
            guard let loc = request?.value else {
                coordinatesLabel.text = "(not received)"
                accuracyLabel.text = "-"
                updateLabel.text = "-"
                return
            }
            
            guard let request = request else {
                return
            }
            
            coordinatesLabel.text = NSString(format: "%0.5f, %0.5f", loc.coordinate.latitude, loc.coordinate.longitude) as String
            accuracyLabel.text = NSString(format: "%0.3f mt",loc.horizontalAccuracy) as String
            
            if request.state == .running {
                updateLabel.text = NSString(format: "%0.0f secs ago", abs(loc.timestamp.timeIntervalSinceNow)) as String
            } else {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:SS"
                updateLabel.text = dateFormatter.string(from: loc.timestamp)
            }
            
            stopButton.isEnabled = true
            stopButton.alpha = 1.0
        }
    }
}
