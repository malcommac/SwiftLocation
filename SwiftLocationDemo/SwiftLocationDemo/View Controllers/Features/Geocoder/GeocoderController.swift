//
//  GeocoderController.swift
//  SwiftLocationDemo
//
//  Created by daniele on 08/11/2020.
//

import UIKit
import SwiftLocation
import CoreLocation
import MapKit

public class GeocoderController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private var settings = [RowSetting]()
    private var service: GeocoderServiceProtocol?
    
    @IBOutlet public var tableView: UITableView!
    
    public static func create() -> GeocoderController {
        let s = UIStoryboard(name: "GeocoderController", bundle: nil)
        return s.instantiateInitialViewController() as! GeocoderController
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Geocoder/Reverse Geocoder"
        reloadData()
    }
    
    private func reloadData() {
        defer {
            tableView.reloadData()
        }
        
        guard let service = self.service else {
            settings = [.service]
            return
        }
        
        switch service {
        case is Geocoder.Apple:
            if service.operation.isReverseGeocoder {
                settings = [.service, .coordinates, .createRequest]
            } else {
                settings = [.service, .addressValue, .proximityRegion, .locale, .createRequest]
            }
            
        default:
            settings = [.service]
        }
        
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        settings.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = settings[indexPath.row]
        
        switch row {
        case .createRequest:
            let cell = tableView.dequeueReusableCell(withIdentifier: StandardCellButton.ID) as! StandardCellButton
            cell.buttonAction.setTitle(row.title, for: .normal)
            cell.onAction = { [weak self] in
                self?.createRequest()
            }
            return cell
            
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: StandardCellSetting.ID) as! StandardCellSetting
            cell.item = settings[indexPath.row]
            cell.valueLabel.text = valueForKind(settings[indexPath.row])
            return cell
        }
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch settings[indexPath.row] {
        case .service:
            selectService()
        case .coordinates:
            selectCoordinates()
        case .addressValue:
            selectAddressToReverse()
        case .locale:
            selectLocale()
        case .proximityRegion:
            selectProximityRegion()
        default:
            break
        }
    }
    
    private func createRequest() {
        guard let service = self.service else {
            return
        }

        let loader = UIAlertController.showLoader(message: "Geocoding in progress...")
        let request = Locator.shared.geocodeWith(service)
        request.then(queue: .main) { result in
            loader.dismiss(animated: false, completion: {
                switch result {
                case .failure(let error):
                    UIAlertController.showAlert(title: "Error Occurred", message: error.localizedDescription)
                    break
                case .success(let data):
                        print(data)
                //ResultController.showWithResult(data, in: self)
                }
            })
        }
    }
    
    private func valueForKind(_ row: RowSetting) -> String? {
        switch row {
        case .service:
            return serviceName()
        case .coordinates:
            return service?.operation.coordinates.description
        case .addressValue:
            return (service?.operation.address.isEmpty ?? true ? "Not Set" : service?.operation.address)
        case .proximityRegion:
            return service?.asApple?.proximityRegion?.description ?? "Not Set"
        case .locale:
            return service?.locale ?? "Not Set"
        default:
            return nil
        }
    }
    
    private func selectLocale() {
        UIAlertController.showInputFieldSheet(title: "Language identifier for results", message: "See the doc for allowed values") { [weak self] locale in
            self?.service?.locale = locale
            self?.reloadData()
        }
    }
    
    private func selectCoordinates() {
        UIAlertController.showInputCoordinates(title: "Coordinates to geocode") { [weak self] coords in
            guard let coords = coords else { return }
            self?.service?.operation = .geoAddress(coords)
            self?.reloadData()
        }
    }
    
    private func selectAddressToReverse() {
        UIAlertController.showInputFieldSheet(title: "Address to reverse geocoder") { [weak self] value in
            guard let address = value else { return }
            self?.service?.operation = .getCoordinates(address)
            self?.reloadData()
        }
    }
    
    private func selectProximityRegion() {
        UIAlertController.showCircularRegion(title: "Circular Region Proximity") { [weak self] region in
            self?.service?.asApple?.proximityRegion = region
            self?.reloadData()
        }
    }
    
    private func selectService() {
        let servicesList: [UIAlertController.ActionSheetOption] = [
            ("Apple Geocoder", { [weak self] _ in
                self?.service = Geocoder.Apple(address: "")
                self?.selectAddressToReverse()
                self?.reloadData()
            }),
            ("Apple Reverse Geocoder", { [weak self] _ in
                self?.service = Geocoder.Apple(coordinates: CLLocationCoordinate2D(latitude: 0,longitude: 0))
                self?.selectCoordinates()
                self?.reloadData()
            }),
            ("Here", { [weak self] _ in

                self?.reloadData()
            }),
            ("MapBox", { [weak self] _ in

                self?.reloadData()
            }),
            ("OpenStreet", { [weak self] _ in

                self?.reloadData()
            })
        ]
        UIAlertController.showActionSheet(title: "Select a service", message: "Geocoder/Reverse Geocoder services available", options: servicesList)
    }
    
    private func serviceName() -> String {
        guard let service = self.service else {
            self.settings = [.service]
            return "No Set"
        }
        
        var serviceName = ""
        switch service {
        case _ as Geocoder.Apple:       serviceName = "Apple"
        case _ as Geocoder.Here:        serviceName = "Nokia Here"
        case _ as Geocoder.Google:      serviceName = "Google"
        case _ as Geocoder.MapBox:      serviceName = "MapBox"
        case _ as Geocoder.OpenStreet:  serviceName = "OpenStreet"
        default: break
        }
        
        return "\(serviceName) (\(service.operation.isReverseGeocoder ? "Reverse" : "Forward"))"
    }
}

public extension GeocoderController {
    
    enum RowSetting: CellRepresentableItem {
        case service
        case addressValue
        case timeout
        case coordinates
        case proximityRegion
        case locale
        case countryCode
        case boundingBox
        case resultTypes
        case APIKey
        case limitResultCount
        case proximityCoordinates
        case includeRoutingData
        case reverseMode
        case useFuzzyMatch
        case includeAddressDetails
        case includeExtraTags
        case includeNameDetails
        case zoomLevel
        case polygonThreshold
        case createRequest
        
        public var title: String {
            switch self {
            case .service:                  return "Service"
            case .addressValue:             return "Address"
            case .coordinates:              return "Coordinates"
            case .timeout:                  return "Timeout"
            case .proximityRegion:          return "Proximity Region"
            case .locale:                   return "Locale"
            case .countryCode:              return "Country/es Code/s"
            case .boundingBox:              return "Bounding Box"
            case .resultTypes:              return "Result Types"
            case .APIKey:                   return "API Key"
            case .limitResultCount:         return "Limit"
            case .proximityCoordinates:     return "Proximity Coordinates"
            case .includeRoutingData:       return "Include Routing"
            case .reverseMode:              return "Reverse Mode"
            case .useFuzzyMatch:            return "Fuzzy Match"
            case .includeAddressDetails:    return "Address Details"
            case .includeExtraTags:         return "Extra Tags"
            case .includeNameDetails:       return "Name Details"
            case .zoomLevel:                return "Zoom Level"
            case .polygonThreshold:         return "Polygon Threshold"
            case .createRequest:            return "Create Request"
            }
        }
        
        public var subtitle: String {
            switch self {
            case .service:                  return "Select service to use for geocoding/reverse"
            case .addressValue:             return "Address to geocode"
            case .coordinates:              return "Coordinates to reverse geocode"
            case .timeout:                  return "Request timeout interval (secs)"
            case .proximityRegion:          return "Better contextualize received results"
            case .locale:                   return "Language of the results"
            case .countryCode:              return "Better contextualize received results"
            case .boundingBox:              return "To bias geocode results more prominently"
            case .resultTypes:              return "Type of results to get"
            case .APIKey:                   return "[REQUIRED] API Key"
            case .limitResultCount:         return "Limit number of results"
            case .proximityCoordinates:     return "Center of the search context expressed as coordinates"
            case .includeRoutingData:       return "Additional metadata about the recommended navigation"
            case .reverseMode:              return "Decides how results are sorted in a reverse geocoding query"
            case .useFuzzyMatch:            return "How to match results"
            case .includeAddressDetails:    return "Include a breakdown of the address into elements"
            case .includeExtraTags:         return "Include additional information in the result if available"
            case .includeNameDetails:       return "Include a list of alternative names in the results"
            case .zoomLevel:                return "Level of detail required for the address"
            case .polygonThreshold:         return "Simplify the output geometry before returning"
            default:                        return ""
            }
        }
        
        public var icon: UIImage? {
            nil
        }
        
    }
    
}

// MARK: - AutocompleteProtocol Extensions

public extension GeocoderServiceProtocol {
    
    var asGoogle: Geocoder.Google? {
        (self as? Geocoder.Google)
    }
    
    var asApple: Geocoder.Apple? {
        (self as? Geocoder.Apple)
    }
    
    var asHere: Geocoder.Here? {
        (self as? Geocoder.Here)
    }
    
    var asMapBox: Geocoder.MapBox? {
        (self as? Geocoder.MapBox)
    }
    
    var asOpenStreet: Geocoder.OpenStreet? {
        (self as? Geocoder.OpenStreet)
    }
    
}
