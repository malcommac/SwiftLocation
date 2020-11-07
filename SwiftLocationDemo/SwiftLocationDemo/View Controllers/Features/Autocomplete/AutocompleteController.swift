//
//  Autocomplete.swift
//  SwiftLocationDemo
//
//  Created by daniele on 31/10/2020.
//

import UIKit
import SwiftLocation
import MapKit
import CoreLocation

fileprivate extension AutocompleteProtocol {
    
    var asGoogle: Autocomplete.Google? {
        return (self as? Autocomplete.Google)
    }
    
    var asApple: Autocomplete.Apple? {
        return (self as? Autocomplete.Apple)
    }
    
}

public class AutocompleteController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private var rows = [RowSetting]([.service])
    
    @IBOutlet public var settingsTableView: UITableView!
    @IBOutlet public var resultsTableView: UITableView!

    private var currentService: AutocompleteProtocol?
    private var requestResults: AutocompleteRequest.ProducedData?

    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Autocomplete Address"
        
        settingsTableView.tableFooterView = UIView()
        resultsTableView.tableFooterView = UIView()
    }
    
    public static func create() -> AutocompleteController {
        let s = UIStoryboard(name: "AutocompleteController", bundle: nil)
        return s.instantiateInitialViewController() as! AutocompleteController
    }
    
    @IBAction public func clearResults(_ sender: Any?) {
        requestResults?.removeAll()
        resultsTableView.reloadData()
    }
    
    // MARK: - TableView Data Source Delegates
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == settingsTableView {
            return settingsTableView(tableView, numberOfRowsInSection: section)
        } else {
            return resultsTableView(tableView, numberOfRowsInSection: section)
        }
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == settingsTableView {
            return settingsTableView(tableView, cellForRowAt: indexPath)
        } else {
            return resultsTableView(tableView, cellForRowAt: indexPath)
        }
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == settingsTableView {
            return settingsTableView(tableView, didSelectRowAt: indexPath)
        } else {
            return resultsTableView(tableView, didSelectRowAt: indexPath)
        }
    }
    
    // MARK: - Results TableView Data Source

    private func resultsTableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        requestResults?.count ?? 0
    }
    
    private func resultsTableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let result = requestResults![indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: StandardCellSetting.ID) as! StandardCellSetting
        cell.titleLabel.text = result.partialAddress?.title
        cell.subtitleLabel.text = result.partialAddress?.subtitle
        cell.valueLabel.text = result.place?.coordinates.description
        
        return cell
    }
    
    private func resultsTableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let result = requestResults?[indexPath.row],
              let detailService = createRequestToGetDetailForResult(result) else {
            return
        }
                
        let loader = UIAlertController.showLoader(message: "Getting details for place \(result.description)...")
        Locator.shared.autocompleteWith(detailService).then(queue: .main) { result in
            loader.dismiss(animated: true, completion: nil)
            ResultController.showWithResult(result, in: self)
        }
    }
    
    private func createRequestToGetDetailForResult(_ result: Autocomplete.Data?) -> AutocompleteProtocol? {
        switch currentService {
        case is Autocomplete.Apple:
            return Autocomplete.Apple(detailsFor: result)
        default:
            return nil
        }
    }
    
    // MARK: - Settings TableView Data Source
    
    private func settingsTableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rows.count
    }
    
    public func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        if tableView == settingsTableView && rows[indexPath.row] == .createRequest {
            return false
        }
        
        return true
    }

    private func settingsTableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = rows[indexPath.row]
        
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
            cell.item = rows[indexPath.row]
            cell.valueLabel.text = valueForKind(rows[indexPath.row])
            return cell
        }
    }
    
    private func settingsTableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch rows[indexPath.row] {
        case .service:
            selectService()
        case .addressValue:
            selectAutocompleteAddress()
        case .proximityRegion:
            selectProximityRegion()
        case .filterType:
            selectFilterType()
        case .APIKey:
            selectAPIKey()
        case .timeout:
            setTimeoutInterval()
        case .googlePlaceTypes:
            selectGooglePlaceTypes()
        case .location:
            selectGoogleLocation()
        case .radius:
            selectRadius()
        default:
            break
        }
    }
    
    private func createRequest() {
        guard let service = self.currentService else {
            return
        }

        let loader = UIAlertController.showLoader(message: "Getting information from IP address...")
        let request = Locator.shared.autocompleteWith(service)
        request.then(queue: .main) { result in
            loader.dismiss(animated: false, completion: nil)

            switch result {
            case .failure(let error):
                UIAlertController.showAlert(title: "Error Occurred", message: error.localizedDescription)
                break
            case .success(let data):
                self.requestResults = data
                self.resultsTableView.reloadData()
                break
            }
        }
    }
    
    private func reloadData() {
        defer {
            settingsTableView.reloadData()
        }
        
        guard let service = currentService else {
            self.rows = [.service]
            return
        }
        
        switch service {
        case is Autocomplete.Apple:
            self.rows = [.service, .addressValue, .proximityRegion, .filterType, .createRequest]
        case is Autocomplete.Google:
            self.rows = [.service, .APIKey, .addressValue, .locale, .timeout, .googlePlaceTypes, .location, .radius, .createRequest]
        default:
            break
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
    
    private func setTimeoutInterval() {
        let subscriptionTypes: [UIAlertController.ActionSheetOption] = ([
            nil, 3, 5, 10, 15
        ] as [Int?]
        ).map { [weak self] item in
            let title = (item == nil ? "Not Set" : "\(item!)s")
            return (title, { _ in
                self?.currentService?.timeout = (item != nil ? TimeInterval(item!) : nil)
                self?.reloadData()
            })
        }
        
        UIAlertController.showActionSheet(title: "Select Subscription",
                                          message: "Delayed starts only after the necessary authorization will be granted",
                                          options: subscriptionTypes)
    }
    
    private func selectAPIKey() {
        UIAlertController.showInputFieldSheet(title: "API Key",
                                              message: "See the documentation to get t") { [weak self] value in
            
            guard let APIKey = value, !APIKey.isEmpty else {
                return
            }
            
            self?.currentService?.asGoogle?.APIKey = APIKey
            self?.reloadData()
        }
    }
    
    private func valueForKind(_ kind: RowSetting) -> String {
        switch kind {
        case .service:
            return serviceName()
        case .addressValue:
            return currentService?.operation.value ?? "Not Set"
        case .proximityRegion:
            return currentService?.asApple?.proximityRegion?.description ?? "Not Set"
        case .filterType:
            return currentService?.asApple?.resultType.description ?? "Not Set"
        case .locale:
            return ""
        case .limit:
            return "Limit"
        case .APIKey:
            if let google = currentService?.asGoogle, !google.APIKey.isEmpty {
                return google.APIKey
            }
            
            return "Not Set"
        case .timeout:
            return (currentService?.timeout != nil ? "\(currentService!.timeout!)s" : "Not Set")
        case .googlePlaceTypes:
            return currentService?.asGoogle?.placeTypes?.description ?? "None"
        case .location:
            return currentService?.asGoogle?.location?.description ?? "Not Set"
        case .radius:
            return currentService?.asGoogle?.radius?.description ?? "Not Set"
        default:
            return ""
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
                self?.reloadData()
            }),
            ("Google", { [weak self] _ in
                self?.currentService = Autocomplete.Google(partialMatches: "", APIKey: "")
                self?.reloadData()
            }),
            ("Here", { [weak self] _ in
                self?.currentService = Autocomplete.Here(partialMatches: "", APIKey: "")
                self?.reloadData()
            })
        ]
        UIAlertController.showActionSheet(title: "Select a service", message: "Autocomplete services available", options: servicesList)
    }
    
    private func serviceName() -> String {
        guard let service = currentService else {
            self.rows = [.service]
            return "No Set"
        }
        
        switch service {
        case _ as Autocomplete.Apple: return "Apple"
        case _ as Autocomplete.Here: return "Nokia Here"
        case _ as Autocomplete.Google: return "Google"
        default: return ""
        }
    }
    
}

public extension AutocompleteController {
    
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
        
        public var title: String {
            switch self {
            case .service: return "Service"
            case .addressValue: return "Address"
            case .proximityRegion: return "Proximity"
            case .filterType: return "Results Type"
            case .locale: return "Locale"
            case .limit: return "Limit"
            case .APIKey: return "API Key"
            case .timeout: return "Timeout"
            case .googlePlaceTypes: return "Place Types"
            case .location: return "Location"
            case .radius: return "Radius (mts)"
            default: return "Execute Request"
            }
        }
        
        public var subtitle: String {
            switch self {
            case .service: return "[REQUIRED] Service to use to perform autocomplete"
            case .addressValue: return "[REQUIRED] Address to autocomplete"
            case .proximityRegion: return "To get better contextualized results"
            case .filterType: return "Allowed results"
            case .locale: return "Language of the results"
            case .limit: return "Limit the number of data"
            case .APIKey: return "Required"
            case .timeout: return "Network call timeout (in secs)"
            case .googlePlaceTypes: return "Get only specified place types"
            case .location: return "Proximity location to get better results"
            case .radius: return "Distance within which to return place results"
            default: return ""
            }
        }
        
        public var icon: UIImage? {
            return nil
        }
        
    }
    
}

extension MKCoordinateRegion: CustomStringConvertible {
    
    static func fromRawString(_ rawString: String?) -> MKCoordinateRegion? {
        guard let values = rawString?.components(separatedBy: ",").compactMap({ CLLocationDegrees($0) }), values.count == 4 else {
            return nil
        }
        
        let coords = CLLocationCoordinate2D(latitude: values[0], longitude: values[1])
        let region = MKCoordinateRegion(center: coords,
                                        latitudinalMeters: CLLocationDistance(values[2]),
                                        longitudinalMeters: CLLocationDistance(values[3]))
        return region
    }
    
    public var description: String {
        "\(center.formattedValue)"
    }
    
}
