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
import MapKit
import CoreLocation

public class AutocompleteController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // MARK: - IBOutlets
    
    @IBOutlet public var settingsTableView: UITableView!

    // MARK: - Private Properties
    
    private var settings = [RowSetting]([.service])
    private var currentService: AutocompleteProtocol?

    // MARK: - Initialization
    
    public static func create() -> AutocompleteController {
        let s = UIStoryboard(name: "AutocompleteController", bundle: nil)
        return s.instantiateInitialViewController() as! AutocompleteController
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Autocomplete Address"
        settingsTableView.registerUINibForClass(StandardCellSetting.self)
        settingsTableView.registerUINibForClass(StandardCellButton.self)
        settingsTableView.tableFooterView = UIView()
    }
    
    // MARK: - TableView Data Source Delegates
    
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
        case .service:              selectService()
        case .addressValue:         selectAutocompleteAddress()
        case .proximityRegion:      selectProximityRegion()
        case .filterType:           selectFilterType()
        case .APIKey:               selectAPIKey()
        case .timeout:              selectTimeoutInterval()
        case .googlePlaceTypes:     selectGooglePlaceTypes()
        case .location:             selectGoogleLocation()
        case .radius:               selectRadius()
        case .locale:               selectLocale()
        case .proximityArea:        selectHereProximityArea()
        case .limitResultsCount:    selectLimitResultsCount()
        default:                break
        }
    }
    
    public func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        if settings[indexPath.row] == .createRequest {
            return false
        }
        
        return true
    }
    
    // MARK: - Private Functions
    
    private func createRequest() {
        guard let service = self.currentService else {
            UIAlertController.showAlert(title: "You must select a service first")
            return
        }

        let loader = UIAlertController.showLoader(message: "Getting information from IP address...")
        let request = SwiftLocation.autocompleteWith(service)
        request.then(queue: .main) { result in
            loader.dismiss(animated: false, completion: {
                switch result {
                case .failure(let error):
                    UIAlertController.showAlert(title: "Error Occurred", message: error.localizedDescription)
                    break
                case .success(let data):
                    let vc = AutocompleteResultsController.create(list: data, forService: self.currentService)
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            })
        }
    }
    
    private func reloadData() {
        defer {
            settingsTableView.reloadData()
        }
        
        guard let service = currentService else {
            self.settings = [.service]
            return
        }
        
        switch service {
        case is Autocomplete.Apple:
            self.settings = [.service, .addressValue, .proximityRegion, .filterType, .createRequest]
        case is Autocomplete.Google:
            self.settings = [.service, .APIKey, .addressValue, .locale, .timeout, .googlePlaceTypes, .location, .radius, .createRequest]
        case is Autocomplete.Here:
            self.settings = [.service, .APIKey, .addressValue, .locale, .timeout, .limitResultsCount, .proximityArea, .createRequest]
        default:
            break
        }
    }
    
    // MARK: - Settings Action
    
    private func selectHereProximityArea() {
        
        func selectCountryCodes() {
            UIAlertController.showInputFieldSheet(title: "Country Codes Proximity",
                                                  message: "Country/ies codes provided as comma-separated ISO 3166-1 alpha-3.") { [weak self] value in
                guard let value = value else {
                    self?.currentService?.asHere?.proximityArea = nil
                    self?.reloadData()
                    return
                }
                
                let cCodes = value.components(separatedBy: ",")
                self?.currentService?.asHere?.proximityArea = .countryCodes(cCodes)
                self?.reloadData()
            }
            reloadData()
        }
        
        func selectCircle() {
            UIAlertController.showCircularRegion(title: "Circular Region Proximity") { [weak self] region in
                self?.currentService?.asHere?.proximityArea = nil
                self?.reloadData()
            }
        }
        
        func selectCoordinates() {
            UIAlertController.showInputCoordinates(title: "Coordinates Proximity") { [weak self] coords in
                self?.currentService?.asHere?.proximityArea = nil
                self?.reloadData()
            }
        }
        
        func selectBoundingBox() {
            UIAlertController.showInputFieldSheet(title: "Bounding Box Proximity",
                                                  message: "Provided as 'west longitude, south latitude, east longitude, north latitude'") { [weak self] value in
                
                guard let values = value?.components(separatedBy: ",").compactMap({ CLLocationDegrees($0 )}), values.count == 2 else {
                    self?.currentService?.asHere?.proximityArea = nil
                    self?.reloadData()
                    return
                }
                
                let coords = CLLocationCoordinate2D(latitude: CLLocationDegrees(values[0]), longitude: CLLocationDegrees(values[1]))
                self?.currentService?.asHere?.proximityArea = .coordinates(coords)
                self?.reloadData()
            }
            reloadData()
        }
        
        let proximityOptions: [UIAlertController.ActionSheetOption] = [
            ("Country Codes", { _ in selectCountryCodes() }),
            ("Circle", {  _ in selectCircle() }),
            ("Bounding Box", { _ in selectBoundingBox() }),
            ("Coordinates", { _ in selectCoordinates() })
        ]
        UIAlertController.showActionSheet(title: "Select proximity area options", message: "", options: proximityOptions)
    }
    
    private func selectLocale() {
        UIAlertController.showInputFieldSheet(title: "Locale", message: "See documentation about the format to use here.") { [weak self] value in
            self?.currentService?.asHere?.locale = value
            self?.currentService?.asGoogle?.locale = value
            self?.reloadData()
        }
    }
    
    private func selectLimitResultsCount() {
        UIAlertController.showInputFieldSheet(title: "Number of results", message: "Limit the results to get") { [weak self] value in
            self?.currentService?.asHere?.limit = (value != nil ? Int(value!) : nil)
            self?.reloadData()
        }
    }
    
    private func selectRadius() {
        UIAlertController.showInputFieldSheet(title: "Radius", message: "The distance (in meters) within which to return place results.") { [weak self] value in
            self?.currentService?.asGoogle?.radius = (value != nil ? Float(value!) : nil)
            self?.reloadData()
        }
    }
    
    private func selectGoogleLocation() {
        UIAlertController.showInputFieldSheet(title: "Proximity Location",
                                              message: "as 'latitude,longitude'") { [weak self] value in
            
            guard let rawCoordinates = value?.components(separatedBy: ",").compactMap({ CLLocationDegrees($0) }),
                  rawCoordinates.count == 2 else {
                self?.currentService?.asGoogle?.location = nil
                self?.reloadData()
                return
            }
            
            let coordinates = CLLocationCoordinate2D(latitude: rawCoordinates[0], longitude: rawCoordinates[1])
            self?.currentService?.asGoogle?.location = coordinates
            self?.reloadData()
        }
    }
    
    private func selectGooglePlaceTypes() {
        let filterTypes: [UIAlertController.ActionSheetOption] = [
            ("None (Ignore)", { [weak self] _ in
                self?.currentService?.asGoogle?.placeTypes = nil
                self?.reloadData()
            }),
            ("All", { [weak self] _ in
                self?.currentService?.asGoogle?.placeTypes = [.geocode, .address, .establishment, .cities]
                self?.reloadData()
            }),
            ("Address", { [weak self] _ in
                (self?.currentService?.asGoogle)?.placeTypes = [.address]
                self?.reloadData()
            }),
            ("Establishment", { [weak self] _ in
                (self?.currentService?.asGoogle)?.placeTypes = [.establishment]
                self?.reloadData()
            }),
            ("Regions", { [weak self] _ in
                (self?.currentService?.asGoogle)?.placeTypes = [.cities]
                self?.reloadData()
            })
        ]
        UIAlertController.showActionSheet(title: "Select type of result", message: "(A more fine tuned configuration is available via code)", options: filterTypes)
    }
    
    private func selectTimeoutInterval() {
        UIAlertController.showTimeout { [weak self] interval in
            self?.currentService?.timeout = interval
            self?.reloadData()
        }
    }
    
    private func selectAPIKey() {
        UIAlertController.showAPIKey { [weak self] APIKey in
            self?.currentService?.asGoogle?.APIKey = APIKey
            self?.reloadData()
        }
    }
    
    private func selectProximityRegion() {
        UIAlertController.showInputFieldSheet(title: "Insert proximity region using the forma below",
                                              message: "{LAT},{LNG},{LAT. METERS},{LONG. METERS}") { [weak self] value in
            self?.currentService?.asApple?.proximityRegion = MKCoordinateRegion.fromRawString(value)
            self?.reloadData()
        }
    }
    
    private func selectAutocompleteAddress() {
        UIAlertController.showInputFieldSheet(title: "Insert address to autocomplete", message: nil) { [weak self] value in
            guard let value = value, !value.isEmpty else { return }
            self?.currentService?.operation = AutocompleteOp.partialMatch(value)
            self?.reloadData()
        }
    }
    
    private func selectFilterType() {
        let filterTypes: [UIAlertController.ActionSheetOption] = [
            ("All", { [weak self] _ in
                self?.currentService?.asApple?.resultType = .all
                self?.reloadData()
            }),
            ("Address", { [weak self] _ in
                self?.currentService?.asApple?.resultType = .address
                self?.reloadData()
            }),
            ("Point of Interest", { [weak self] _ in
                self?.currentService?.asApple?.resultType = .pointOfInterest
                self?.reloadData()
            }),
            ("Query", { [weak self] _ in
                self?.currentService?.asApple?.resultType = .query
                self?.reloadData()
            })
        ]
        UIAlertController.showActionSheet(title: "Select type of result", message: "(A more fine tuned configuration is available via code)", options: filterTypes)
    }
    
    private func selectService() {
        let servicesList: [UIAlertController.ActionSheetOption] = [
            ("Apple", { [weak self] _ in
                self?.currentService = Autocomplete.Apple(partialMatches: "")
                self?.selectAutocompleteAddress()
                self?.reloadData()
            }),
            ("Google", { [weak self] _ in
                self?.currentService = Autocomplete.Google(partialMatches: "", APIKey: "")
                self?.selectAutocompleteAddress()
                self?.reloadData()
            }),
            ("Here", { [weak self] _ in
                self?.currentService = Autocomplete.Here(partialMatches: "", APIKey: "")
                self?.selectAutocompleteAddress()
                self?.reloadData()
            })
        ]
        UIAlertController.showActionSheet(title: "Select a service", message: "Autocomplete services available", options: servicesList)
    }
    
    // MARK: - Helper
    
    private func valueForKind(_ kind: RowSetting) -> String {
        switch kind {
        case .service:
            return serviceName()
        case .addressValue:
            return currentService?.operation.value ?? NOT_SET
        case .proximityRegion:
            return currentService?.asApple?.proximityRegion?.description ?? NOT_SET
        case .filterType:
            return currentService?.asApple?.resultType.description ?? NOT_SET
        case .locale:
            return currentService?.asGoogle?.locale ?? currentService?.asHere?.locale ?? NOT_SET
        case .limit:
            return "Limit"
        case .APIKey:
            if let google = currentService?.asGoogle, !google.APIKey.isEmpty {
                return google.APIKey
            }
            
            return NOT_SET
        case .timeout:
            return (currentService?.timeout != nil ? "\(currentService!.timeout!)s" : NOT_SET)
        case .googlePlaceTypes:
            return currentService?.asGoogle?.placeTypes?.description ?? NOT_SET
        case .location:
            return currentService?.asGoogle?.location?.description ?? NOT_SET
        case .radius:
            return currentService?.asGoogle?.radius?.description ?? NOT_SET
        case .limitResultsCount:
            return currentService?.asHere?.limit?.description ?? NOT_SET
        case .proximityArea:
            return currentService?.asHere?.proximityArea?.description ?? NOT_SET
        default:
            return ""
        }
    }
    
    
    private func serviceName() -> String {
        guard let service = currentService else {
            self.settings = [.service]
            return NOT_SET
        }
        
        switch service {
        case _ as Autocomplete.Apple: return "Apple"
        case _ as Autocomplete.Here: return "Nokia Here"
        case _ as Autocomplete.Google: return "Google"
        default: return ""
        }
    }
    
}

// MARK: - AutocompleteController Rows

fileprivate extension AutocompleteController {
    
    enum RowSetting: CellRepresentableItem {
        case service
        case addressValue
        case proximityRegion
        case filterType
        case locale
        case limit
        case APIKey
        case createRequest
        case timeout
        case googlePlaceTypes
        case location
        case radius
        case limitResultsCount
        case proximityArea
        
        public var title: String {
            switch self {
            case .service:              return "Service"
            case .addressValue:         return "Address"
            case .proximityRegion:      return "Proximity"
            case .filterType:           return "Results Type"
            case .locale:               return "Locale"
            case .limit:                return "Limit"
            case .APIKey:               return "API Key"
            case .timeout:              return "Timeout (s)"
            case .googlePlaceTypes:     return "Place Types"
            case .location:             return "Location"
            case .radius:               return "Radius (mt)"
            case .limitResultsCount:    return "Limit Results"
            case .proximityArea:        return "Proximity Area"
            default:                    return "Execute Request"
            }
        }
        
        public var subtitle: String {
            switch self {
            case .service:              return "Service to use to perform autocomplete"
            case .addressValue:         return "Address to autocomplete"
            case .proximityRegion:      return "To get better contextualized results"
            case .filterType:           return "Allowed results"
            case .locale:               return "Language of the results (see api doc)"
            case .limit:                return "Limit the number of data"
            case .APIKey:               return "API Service key"
            case .timeout:              return "Network call timeout (in secs)"
            case .googlePlaceTypes:     return "Get only specified place types"
            case .location:             return "Proximity location to get better results"
            case .radius:               return "Distance within which to return place results"
            case .limitResultsCount:    return "Total number of results to get"
            case .proximityArea:        return "To get better contextualized results"
            default:                    return ""
            }
        }
        
        public var icon: UIImage? {
            return nil
        }
        
    }
    
}

// MARK: - AutocompleteProtocol Extensions

public extension AutocompleteProtocol {
    
    var asGoogle: Autocomplete.Google? {
        (self as? Autocomplete.Google)
    }
    
    var asApple: Autocomplete.Apple? {
        (self as? Autocomplete.Apple)
    }
    
    var asHere: Autocomplete.Here? {
        (self as? Autocomplete.Here)
    }
    
}
