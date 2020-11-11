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

public class GeocoderController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // MARK: - Private Properties

    private var settings = [RowSetting]()
    private var service: GeocoderServiceProtocol?
    
    // MARK: - IBOutlets

    @IBOutlet public var tableView: UITableView!
    
    // MARK: - Initialization

    public static func create() -> GeocoderController {
        let s = UIStoryboard(name: "GeocoderController", bundle: nil)
        return s.instantiateInitialViewController() as! GeocoderController
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.registerUINibForClass(StandardCellSetting.self)
        tableView.registerUINibForClass(StandardCellButton.self)
        navigationItem.title = "Geocoder/Reverse Geocoder"
        reloadData()
    }
    
    // MARK: - Public Functions

    public func reloadData() {
        defer {
            tableView.reloadData()
        }
        
        settings = [.service]
        guard let service = self.service else {
            return
        }
        
        settings.append((service.operation.isReverseGeocoder ? .coordinates : .addressValue))

        switch service {
        case is Geocoder.Apple:
            if !service.operation.isReverseGeocoder {
                settings.append(contentsOf: [.proximityRegion, .locale])
            }
            
        case is Geocoder.Google:
            settings.append(contentsOf: [
                .APIKey,
                .timeout,
                .countryCode,
                .boundingBox,
                .googleResultFilters,
                .resultTypes
            ])
            
        case is Geocoder.Here:
            settings.append(contentsOf: [
                .APIKey,
                .timeout,
                .locale,
                .limitResultCount,
                .countryCode,
                .proximityCoordinates
            ])
            
        case is Geocoder.MapBox:
            settings.append(contentsOf: [
                .APIKey,
                .timeout,
                .locale,
                .limitResultCount,
                .countryCode,
                .includeRoutingData,
                .mapBoxResultTypes,
                .reverseMode,
                .proximityRegion,
                .boundingBox,
                .useFuzzyMatch
            ])
            
        case is Geocoder.OpenStreet:
            settings.append(contentsOf: [
                .timeout,
                .locale,
                .includeAddressDetails,
                .includeExtraTags,
                .includeNameDetails,
                .zoomLevel,
                .polygonThreshold
            ])
            
        default:
            break
        }
        
        settings.append(.createRequest)
    }
    
    // MARK: - TableView DataSource & Delegate
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        settings.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = settings[indexPath.row]
        
        switch row {
        case .createRequest:
            let cell = tableView.dequeueReusableCell(withIdentifier: StandardCellButton.defaultReuseIdentifier) as! StandardCellButton
            cell.buttonAction.setTitle(row.title, for: .normal)
            cell.onAction = { [weak self] in
                self?.createRequest()
            }
            return cell
            
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: StandardCellSetting.defaultReuseIdentifier) as! StandardCellSetting
            cell.item = settings[indexPath.row]
            cell.valueLabel.text = valueForKind(settings[indexPath.row])
            return cell
        }
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch settings[indexPath.row] {
        case .service:                  selectService()
        case .coordinates:              selectCoordinates()
        case .addressValue:             selectAddressToReverse()
        case .locale:                   selectLocale()
        case .proximityRegion:          selectProximityRegion()
        case .APIKey:                   selectAPIKey()
        case .timeout:                  selectTimeout()
        case .countryCode:              selectCountryCodes()
        case .boundingBox:              selectBoundingBox()
        case .googleLocationTypes:      selectLocationTypes()
        case .googleResultFilters:      selectResultFilters()
        case .limitResultCount:         selectLimitResults()
        case .proximityCoordinates:     selectProximityCoordinates()
        case .includeRoutingData:       selectIncludeRoutingData()
        case .mapBoxResultTypes:        selectMapBoxResultTypes()
        case .reverseMode:              selectReverseMode()
        case .useFuzzyMatch:            selectMapBoxFuzzyMatch()
        case .includeAddressDetails:    selectIncludeAddressDetails()
        case .includeExtraTags:         selectIncludeExtraTags()
        case .includeNameDetails:       selectIncludeNameDetails()
        case .zoomLevel:                selectZoomLevel()
        case .polygonThreshold:         selectPolygonThreshold()
        default:
            break
        }
    }
    
    // MARK: - Actions
    
    private func createRequest() {
        guard let service = self.service else {
            UIAlertController.showAlert(title: "You must select a service first")
            return
        }

        let loader = UIAlertController.showLoader(message: "Geocoding in progress...")
        let request = SwiftLocation.geocodeWith(service)
        request.then(queue: .main) { result in
            loader.dismiss(animated: false, completion: {
                ResultController.showWithResult(result, in: self)
            })
        }
    }
    
    // MARK: - Get Settings
    
    private func valueForKind(_ row: RowSetting) -> String? {
        switch row {
        case .service:
            return serviceName()
        case .coordinates:
            return service?.operation.coordinates.description
        case .addressValue:
            return (service?.operation.address.isEmpty ?? true ? NOT_SET : service?.operation.address)
        case .proximityRegion:
            return service?.asApple?.proximityRegion?.description ?? NOT_SET
        case .locale:
            return service?.locale ?? NOT_SET
        case .APIKey:
            return [
                service?.asGoogle?.APIKey,
                service?.asHere?.APIKey,
                service?.asMapBox?.APIKey
            ].firstNonNilOrFallback(NOT_SET)
        case .timeout:
            return service?.timeout?.description ?? NOT_SET
        case .countryCode:
            return [
                service?.asGoogle?.countryCode,
                service?.asHere?.countryCodes?.joined(separator: ","),
                service?.asMapBox?.countryCode
            ].firstNonNilOrFallback(NOT_SET)
        case .googleResultFilters:
            return service?.asGoogle?.locationTypes?.description ?? NOT_SET
        case .limitResultCount:
            return service?.asHere?.limit?.description ?? NOT_SET
        case .proximityCoordinates:
            return service?.asHere?.proximityCoordinates?.description ?? NOT_SET
        case .includeRoutingData:
            return service?.asMapBox?.includeRoutingData?.description ?? NOT_SET
        case .reverseMode:
            return service?.asMapBox?.reverseMode?.description ?? NOT_SET
        case .boundingBox:
            return service?.asMapBox?.boundingBox?.description ?? NOT_SET
        case .useFuzzyMatch:
            return service?.asMapBox?.useFuzzyMatch?.description ?? NOT_SET
        case .mapBoxResultTypes:
            return service?.asMapBox?.resultTypes?.description ?? NOT_SET
        case .includeAddressDetails:
            return service?.asOpenStreet?.includeAddressDetails.description ?? NOT_SET
        case .includeExtraTags:
            return service?.asOpenStreet?.includeExtraTags.description ?? NOT_SET
        case .includeNameDetails:
            return service?.asOpenStreet?.includeNameDetails.description ?? NOT_SET
        case .zoomLevel:
            return service?.asOpenStreet?.zoomLevel.description ?? NOT_SET
        case .polygonThreshold:
            return service?.asOpenStreet?.polygonThreshold.description ?? NOT_SET
        default:
            return nil
        }
    }
    
    // MARK: - Select Settings
    
    private func selectZoomLevel() {
        let zoomOptions: [UIAlertController.ActionSheetOption] = [
            ("Country", { [weak self] _ in
                self?.service?.asOpenStreet?.zoomLevel = .country
                self?.reloadData()
            }),
            ("State", { [weak self] _ in
                self?.service?.asOpenStreet?.zoomLevel = .state
                self?.reloadData()
            }),
            ("County", { [weak self] _ in
                self?.service?.asOpenStreet?.zoomLevel = .county
                self?.reloadData()
            }),
            ("City", { [weak self] _ in
                self?.service?.asOpenStreet?.zoomLevel = .city
                self?.reloadData()
            }),
            ("Suburb", { [weak self] _ in
                self?.service?.asOpenStreet?.zoomLevel = .suburb
                self?.reloadData()
            }),
            ("Major Streets", { [weak self] _ in
                self?.service?.asOpenStreet?.zoomLevel = .majorStreets
                self?.reloadData()
            }),
            ("Major & Minor Streets", { [weak self] _ in
                self?.service?.asOpenStreet?.zoomLevel = .majorAndMinorStreets
                self?.reloadData()
            }),
            ("Building", { [weak self] _ in
                self?.service?.asOpenStreet?.zoomLevel = .building
                self?.reloadData()
            })
        ]
        UIAlertController.showActionSheet(title: "Zoom Level",
                                          message: "Level of detail required for the address", options: zoomOptions)
    }
    
    private func selectPolygonThreshold() {
        UIAlertController.showInputFieldSheet(title: "Polygon Threshold Level", message: "Simplify the output geometry before returning") { [weak self] value in
            guard let value = value, let threshold = Double(value) else {
                return
            }
            
            self?.service?.asOpenStreet?.polygonThreshold = threshold
            self?.reloadData()
        }
    }
    
    private func selectReverseMode() {
        let reverseOptions: [UIAlertController.ActionSheetOption] = [
            ("Not Specified", { [weak self] _ in
                self?.service?.asMapBox?.reverseMode = nil
                self?.reloadData()
            }),
            ("By Distance", { [weak self] _ in
                self?.service?.asMapBox?.reverseMode = .distance
                self?.reloadData()
            }),
            ("By Score", { [weak self] _ in
                self?.service?.asMapBox?.reverseMode = .score
                self?.reloadData()
            })
        ]
        UIAlertController.showActionSheet(title: "Reverse Mode",
                                          message: "Decides how results are sorted in a reverse geocoding query if multiple results are requested using a limit other than 1.", options: reverseOptions)
    }
    
    private func selectMapBoxFuzzyMatch() {
        UIAlertController.showBoolSheet(title: "Fuzzy Match",
                                        message: "Specify whether the Geocoding API should attempt approximate matches.") { [weak self] value in
            self?.service?.asMapBox?.useFuzzyMatch = value
            self?.reloadData()
        }
    }
    
    private func selectIncludeRoutingData() {
        UIAlertController.showBoolSheet(title: "Include Routing Data",
                                        message: "Specify whether to request additional metadata about the recommended navigation destination corresponding to the feature") { [weak self] value in
            self?.service?.asMapBox?.includeRoutingData = value
            self?.reloadData()
        }
    }
    
    private func selectProximityCoordinates() {
        UIAlertController.showInputCoordinates(title: "Proximity Coordinates") { [weak self] coords in
            self?.service?.asHere?.proximityCoordinates = coords
            self?.reloadData()
        }
    }
    
    private func selectIncludeAddressDetails() {
        UIAlertController.showBoolSheet(title: "Include Address Details",
                                        message: "Include a breakdown of the address into elements.") { [weak self] value in
            self?.service?.asOpenStreet?.includeAddressDetails = value
            self?.reloadData()
        }
    }
    
    private func selectIncludeExtraTags() {
        UIAlertController.showBoolSheet(title: "Include Extra Tags",
                                        message: "Include additional information in the result if available, e.g. wikipedia link, opening hours.") { [weak self] value in
            self?.service?.asOpenStreet?.includeAddressDetails = value
            self?.reloadData()
        }
    }
    
    private func selectIncludeNameDetails() {
        UIAlertController.showBoolSheet(title: "Include Name Details",
                                        message: "Include a list of alternative names in the results. These may include language variants, references, operator and brand.") { [weak self] value in
            self?.service?.asOpenStreet?.includeNameDetails = value
            self?.reloadData()
        }
    }
    
    private func selectMapBoxResultTypes() {
        let servicesList: [UIAlertController.ActionSheetOption] = [
            ("Not Specified", { [weak self] _ in
                self?.service?.asMapBox?.resultTypes = nil
                self?.reloadData()
            }),
            ("All", { [weak self] _ in
                self?.service?.asMapBox?.resultTypes = Geocoder.MapBox.ResultTypes.all
                self?.reloadData()
            }),
            ("Country & Region", { [weak self] _ in
                self?.service?.asMapBox?.resultTypes = [.country, .region]
                self?.reloadData()
            }),
            ("Postcode & District", { [weak self] _ in
                self?.service?.asMapBox?.resultTypes = [.postcode, .district]
                self?.reloadData()
            }),
            ("Place & Locality", { [weak self] _ in
                self?.service?.asMapBox?.resultTypes = [.place, .locality]
                self?.reloadData()
            }),
            ("Neighborhood & Address", { [weak self] _ in
                self?.service?.asMapBox?.resultTypes = [.neighborhood, .address]
                self?.reloadData()
            })
        ]
        UIAlertController.showActionSheet(title: "Filter Types", message: "A more fine graded managment is available trough the APIs", options: servicesList)
    }
    
    private func selectResultFilters() {
        let servicesList: [UIAlertController.ActionSheetOption] = [
            ("None", { [weak self] _ in
                self?.service?.asGoogle?.resultFilters = nil
                self?.reloadData()
            }),
            ("All", { [weak self] _ in
                self?.service?.asGoogle?.resultFilters = Geocoder.Google.FilterTypes.all
                self?.reloadData()
            }),
            ("Only Route", { [weak self] _ in
                self?.service?.asGoogle?.resultFilters = [.route]
                self?.reloadData()
            }),
            ("Only Locality", { [weak self] _ in
                self?.service?.asGoogle?.resultFilters = [.locality]
                self?.reloadData()
            }),
            ("Only Administrative Area", { [weak self] _ in
                self?.service?.asGoogle?.resultFilters = [.administrativeArea]
                self?.reloadData()
            })
        ]
        UIAlertController.showActionSheet(title: "Filter Types", message: "A more fine graded managment is available trough the APIs", options: servicesList)
    }
    
    private func selectLimitResults() {
        UIAlertController.showInputFieldSheet(title: "Limit result count", message: "Empty to remove limit count.") { [weak self] limit in
            guard let limit = limit, let value = Int(limit) else {
                self?.service?.asHere?.limit = nil
                self?.service?.asMapBox?.limit = nil
                return
            }
            self?.service?.asHere?.limit = value
            self?.service?.asHere?.limit = value
            self?.reloadData()
        }
    }
    
    private func selectLocationTypes() {
        let servicesList: [UIAlertController.ActionSheetOption] = [
            ("None", { [weak self] _ in
                self?.service?.asGoogle?.locationTypes = nil
                self?.reloadData()
            }),
            ("All", { [weak self] _ in
                self?.service?.asGoogle?.locationTypes = Geocoder.Google.LocationTypes.all
                self?.reloadData()
            }),
            ("Only Rooftop", { [weak self] _ in
                self?.service?.asGoogle?.locationTypes = [.rooftop]
                self?.reloadData()
            }),
            ("Only Range Interpolated", { [weak self] _ in
                self?.service?.asGoogle?.locationTypes = [.rangeInterpolated]
                self?.reloadData()
            }),
            ("Only Geometric Center", { [weak self] _ in
                self?.service?.asGoogle?.locationTypes = [.geometricCenter]
                self?.reloadData()
            }),
            ("Only Approximate", { [weak self] _ in
                self?.service?.asGoogle?.locationTypes = [.approximate]
                self?.reloadData()
            }),
        ]
        UIAlertController.showActionSheet(title: "Location Types", message: "A more fine graded managment is available trough the APIs", options: servicesList)
    }
    
    private func selectBoundingBox() {
        UIAlertController.showInputFieldSheet(title: "Bounding Box", message: "As 'swLat,swLng,neLat,neLng' string") { [weak self] value in
            guard let coords = value?.components(separatedBy: ",").compactMap({ CLLocationDegrees($0) }),
                  coords.count == 4 else {
                self?.service?.asGoogle?.boundingBox = nil
                self?.reloadData()
                return
            }
            
            let southWestCoord = CLLocationCoordinate2D(latitude: coords[0], longitude: coords[1])
            let northEastCoord = CLLocationCoordinate2D(latitude: coords[2], longitude: coords[3])
            self?.service?.asGoogle?.boundingBox = .init(southwest: southWestCoord, northeast: northEastCoord)
            self?.reloadData()
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
    
    private func selectAPIKey() {
        UIAlertController.showAPIKey { [weak self] APIKey in
            self?.service?.asHere?.APIKey = APIKey
            self?.service?.asGoogle?.APIKey = APIKey
            self?.service?.asMapBox?.APIKey = APIKey
            self?.reloadData()
        }
    }
    
    private func selectCountryCodes() {
        UIAlertController.showInputFieldSheet(title: "Select Country Code/s Filter",
                                              message: "Read the doc for each service about allowed data types.") { [weak self] value in
            self?.service?.asGoogle?.countryCode = value
            self?.service?.asMapBox?.countryCode = value
            self?.service?.asHere?.countryCodes = value?.components(separatedBy: ",")
            self?.reloadData()
        }
    }
    
    private func selectTimeout() {
        UIAlertController.showTimeout { [weak self] interval in
            self?.service?.timeout = interval
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
            ("Google Geocoder", { [weak self] _ in
                self?.service = Geocoder.Google(address: "", APIKey: "")
                self?.selectAddressToReverse()
                self?.reloadData()
            }),
            ("Google Reverse Geocoder", { [weak self] _ in
                self?.service = Geocoder.Apple(coordinates: CLLocationCoordinate2D(latitude: 0,longitude: 0))
                self?.selectCoordinates()
                self?.reloadData()
            }),
            ("Here Geocoder", { [weak self] _ in
                self?.service = Geocoder.Here(address: "", APIKey: "")
                self?.selectAddressToReverse()
                self?.reloadData()
            }),
            ("Here Reverse Geocoder", { [weak self] _ in
                self?.service = Geocoder.Here(coordinates: CLLocationCoordinate2D(latitude: 0,longitude: 0), APIKey: "")
                self?.selectCoordinates()
                self?.reloadData()
            }),
            ("MapBox Geocoder", { [weak self] _ in
                self?.service = Geocoder.MapBox(address: "", APIKey: "")
                self?.selectAddressToReverse()
                self?.reloadData()
            }),
            ("MapBox Reverse Geocoder", { [weak self] _ in
                self?.service = Geocoder.MapBox(coordinates: CLLocationCoordinate2D(latitude: 0,longitude: 0), APIKey: "")
                self?.selectCoordinates()
                self?.reloadData()
            }),
            ("OpenStreet Geocoder", { [weak self] _ in
                self?.service = Geocoder.OpenStreet(address: "")
                self?.selectAddressToReverse()
                self?.reloadData()
            }),
            ("OpenStreet Reverse Geocoder", { [weak self] _ in
                self?.service = Geocoder.OpenStreet(coordinates: CLLocationCoordinate2D(latitude: 0,longitude: 0))
                self?.selectCoordinates()
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
        case googleResultFilters
        case googleLocationTypes
        case mapBoxResultTypes

        public var title: String {
            switch self {
            case .service:                  return "Service"
            case .addressValue:             return "Address"
            case .coordinates:              return "Coordinates"
            case .timeout:                  return "Timeout (s)"
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
            case .googleResultFilters:      return "Result Filters"
            case .googleLocationTypes:      return "Location Filters"
            case .mapBoxResultTypes:        return "Result Types"
            }
        }
        
        public var subtitle: String {
            switch self {
            case .service:                  return "Service to use for geocoding/reverse"
            case .addressValue:             return "Address to geocode"
            case .coordinates:              return "Coordinates to reverse geocode"
            case .timeout:                  return "Request timeout interval (secs)"
            case .proximityRegion:          return "Better contextualize received results"
            case .locale:                   return "Language of the results"
            case .countryCode:              return "Better contextualize received results"
            case .boundingBox:              return "To bias geocode results more prominently"
            case .resultTypes:              return "Type of results to get"
            case .APIKey:                   return "API Service Key"
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
            case .googleResultFilters:      return "A filter of one or more location types"
            case .googleLocationTypes:      return "Acts as a post-search filter"
            case .mapBoxResultTypes:        return "Filter results to include only a subsets of available feature types"
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
