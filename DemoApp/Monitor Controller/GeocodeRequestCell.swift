//
//  GeocodeRequestCell.swift
//  DemoApp
//
//  Created by dan on 23/04/2019.
//  Copyright © 2019 SwiftLocation. All rights reserved.
//

import CoreLocation
import MapKit

public class GeocodeRequestCell: UITableViewCell, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    public static let height: CGFloat = 170
    
    @IBOutlet public var titleLabel: UILabel!
    @IBOutlet public var collection: UICollectionView!
    @IBOutlet public var page: UIPageControl!
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
    
    public var request: GeocoderRequest? {
        didSet {
            stopButton.setTitle( (request?.state == .running ? "Stop" : "Remove"), for: .normal)
            
            guard let request = request else {
                titleLabel.text = "-"
                return
            }
            
            var title = (request.isReverse ? "REVERSE GEOCODER" : "GEOCODER")
            if request.value?.count ?? 0 > 0 {
                title += " (\(request.value!.count) RESULTS)"
            }
            page.numberOfPages = request.value?.count ?? 0
            titleLabel.text = title
            collection.reloadData()
            stopButton.isEnabled = true
            stopButton.alpha = 1.0
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return request?.value?.count ?? 0
    }
    
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        page.currentPage = indexPath.section
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GeocoderCollectionCell", for: indexPath) as! GeocoderCollectionCell
        cell.index = indexPath.row + 1
        cell.total = request?.value?.count ?? 0
        cell.place = request?.value?[indexPath.row]
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.frame.size
    }
}

public class GeocoderCollectionCell: UICollectionViewCell {
    
    @IBOutlet public var titleLabel: UILabel!
    @IBOutlet public var nameLabel: UILabel!
    @IBOutlet public var coordinatesLabel: UILabel!
    @IBOutlet public var cityLabel: UILabel!
    @IBOutlet public var countryLabel: UILabel!
    @IBOutlet public var addressLabel: UILabel!
    
    public var index: Int = 0
    public var total: Int = 0
    
    public var place: Place? {
        didSet {
            guard let place = place else {
                titleLabel.text = "-"
                nameLabel.text = "-"
                coordinatesLabel.text = "-"
                cityLabel.text = "-"
                countryLabel.text = "-"
                addressLabel.text = "-"
                return
            }
            
            titleLabel.text = "DATA RESULT #\(index) of \(total):"
            nameLabel.text = place.name ?? "-"
            coordinatesLabel.text = NSString(format: "%0.5f, %0.5f", place.coordinates?.latitude ?? 0, place.coordinates?.longitude ?? 0) as String
            cityLabel.text = place.city ?? "-"
            countryLabel.text = place.country ?? "-"
            addressLabel.text = place.formattedAddress ?? "-"
        }
    }
    
}
