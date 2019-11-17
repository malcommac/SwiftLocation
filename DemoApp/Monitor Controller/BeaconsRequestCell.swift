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

public class BeaconsRequestCell: UITableViewCell {
    public static let height: CGFloat = 70
    
    @IBOutlet public var titleLabel: UILabel!
    @IBOutlet public var descriptionLabel: UILabel!
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
    
    public var request: BeaconsRequest? {
        didSet {
            stopButton.setTitle( (request?.state == .running ? "Stop" : "Remove"), for: .normal)
            titleLabel.text = "BEACONS MONITORING"
            
            guard let beacons = request?.value else {
                descriptionLabel.text = "(not received)"
                return
            }
            
            let descritpion = beacons.compactMap { "\($0.major) \($0.minor)" }.joined(separator: " | ")
            descriptionLabel.text = descritpion
            stopButton.isEnabled = true
            stopButton.alpha = 1.0
        }
    }
}
