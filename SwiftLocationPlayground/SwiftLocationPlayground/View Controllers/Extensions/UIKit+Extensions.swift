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

import Foundation
import MapKit
import SwiftLocation

extension MKMapView {
    
    public func zoomToUserLocation(_ accuracy: GPSLocationOptions.Accuracy = .block,
                                   distance: CLLocationDistance = 3000,
                                   onError: ((Error) -> Void)? = nil) {
        SwiftLocation.gpsLocationWith {
            $0.accuracy = accuracy
        }.then(queue: .main) { [weak self] result in
            switch result {
            case .success(let location):
                self?.zoomToLocation(location, distance: distance)
            case .failure(let error):
                onError?(error)
            }
        }
    }
    
    private func zoomToLocation(_ location: CLLocation, distance: CLLocationDistance) {
        let mapRegion = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: distance, longitudinalMeters: distance)
        setRegion(mapRegion, animated: true)
        showsUserLocation = true
    }
    
    func zoom(for overlay: MKOverlay, insets: UIEdgeInsets = UIEdgeInsets(top: 100, left: 100, bottom: 100, right: 100), animated: Bool = true) {
        setVisibleMapRect(overlay.boundingMapRect, edgePadding: insets, animated: animated)
    }
    
    func addOverlay(_ overlay: MKOverlay, andZoom: Bool, animated: Bool = true) {
        addOverlay(overlay)
        zoom(for: overlay, animated: animated)
    }
    
    func zoomForAllOverlays(insets: UIEdgeInsets = UIEdgeInsets(top: 100, left: 100, bottom: 100, right: 100), animated: Bool = true) {
        guard let initial = overlays.first?.boundingMapRect else { return }
        
        let mapRect = overlays
            .dropFirst()
            .reduce(initial) { $0.union($1.boundingMapRect) }
        
        setVisibleMapRect(mapRect, edgePadding: insets, animated: true)
    }
    
}

// MARK: - UIAlertController

extension UIAlertController {
    
    @discardableResult
    public static func showAlert(title: String, message: String? = nil,
                                 defaultTitle: String = "OK",
                                 defaultAction: ((UIAlertAction) -> Void)? = nil,
                                 alternateTitle: String? = nil, alternateAction: ((UIAlertAction) -> Void)? = nil,
                                 controller: UIViewController? = nil) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let defaultButton = UIAlertAction(title: defaultTitle, style: .default, handler: defaultAction)
        alert.addAction(defaultButton)
        
        if let altTitle = alternateTitle, let altAction = alternateAction {
            let altButton = UIAlertAction(title: altTitle, style: .default, handler: altAction)
            alert.addAction(altButton)
        }
        
        guard let topMost = controller ?? UIViewController.topMostController() else {
            print("Failed to retrive topmost controller to show alert")
            return alert
        }
        
        topMost.present(alert, animated: true, completion: nil)
        return alert
    }
    
    public typealias ActionSheetOption = (title: String, action: ((UIAlertAction) -> Void))
    
    @discardableResult
    public static func showActionSheet(title: String, message: String?,
                                       options: [ActionSheetOption],
                                       cancelAction: ((UIAlertAction) -> Void)? = nil) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        
        options.forEach { item in
            let option = UIAlertAction(title: item.title, style: .default, handler: item.action)
            alert.addAction(option)
        }
        
        let cancelButton = UIAlertAction(title: "Cancel", style: .cancel, handler: cancelAction)
        alert.addAction(cancelButton)
        
        guard let topMost = UIViewController.topMostController() else {
            print("Failed to retrive topmost controller to show alert")
            return alert
        }
        
        topMost.present(alert, animated: true, completion: nil)
        return alert
    }
    
    @discardableResult
    public static func showInputFieldSheet(title: String, message: String? = nil,
                                           placeholder: String? = nil,
                                           fieldValue: String? = nil,
                                           cancelAction: (() -> Void)? = nil,
                                           confirmAction: ((String?) -> Void)?) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addTextField { field in
            field.placeholder = placeholder ?? ""
            field.text = fieldValue ?? ""
        }
        
        let confirmButton = UIAlertAction(title: "OK", style: .default, handler: { _ in
            if let value = alert.textFields?.first?.text, value.isEmpty == false {
                confirmAction?(value)
            } else {
                confirmAction?(nil)
            }
        })
        alert.addAction(confirmButton)
        
        let cancelButton = UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            if let cancelAction = cancelAction {
                cancelAction()
            } else {
                confirmAction?(nil)
            }
        })
        alert.addAction(cancelButton)
        
        guard let topMost = UIViewController.topMostController() else {
            print("Failed to retrive topmost controller to show alert")
            return alert
        }
        
        topMost.present(alert, animated: true, completion: nil)
        return alert
    }
    
    @discardableResult
    public static func showBoolSheet(title: String, message: String?,
                                     cancelAction: (() -> Void)? = nil,
                                     confirmAction: ((Bool) -> Void)?) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { _ in
            confirmAction?(true)
        }))
        
        alert.addAction(UIAlertAction(title: "No", style: .default, handler: { _ in
            confirmAction?(false)
        }))
        
        if let cancelAction = cancelAction {
            let cancelButton = UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
                cancelAction()
            })
            alert.addAction(cancelButton)
        }
        
        guard let topMost = UIViewController.topMostController() else {
            print("Failed to retrive topmost controller to show alert")
            return alert
        }
        
        topMost.present(alert, animated: true, completion: nil)
        return alert
    }
    
    public static func showLoader(title: String = "Executing Request", message: String?) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        guard let topMost = UIViewController.topMostController() else {
            print("Failed to retrive topmost controller to show alert")
            return alert
        }
        
        topMost.present(alert, animated: true, completion: nil)
        return alert
    }
    
    public static func showInputCoordinates(title: String, message: String? = nil, _ handler: @escaping ((CLLocationCoordinate2D?) -> Void)) {
        UIAlertController.showInputFieldSheet(title: title, message: message ?? "Use 'lat, long' format") {  value in
            guard let values = value?.components(separatedBy: ",").compactMap({ CLLocationDegrees($0.trimmingCharacters(in: .whitespaces) )}), values.count == 2 else {
                handler(nil)
                return
            }
            
            let coords = CLLocationCoordinate2D(latitude: values[0], longitude: values[1])
            handler(coords)
        }
    }
    
    public static func showCircularRegion(title: String, message: String? = nil, _ handler: @escaping ((CLCircularRegion?) -> Void)) {
        UIAlertController.showInputFieldSheet(title: title,
                                              message: message ?? "Provided as 'lat, long, radius' (in meters)") { value in
            
            guard let values = value?.components(separatedBy: ",").compactMap({ Float($0 )}), values.count == 3 else {
                handler(nil)
                return
            }
            
            let coords = CLLocationCoordinate2D(latitude: CLLocationDegrees(values[0]), longitude: CLLocationDegrees(values[1]))
            let cRegion = CLCircularRegion(center: coords, radius: CLLocationDistance(values[1]), identifier: "cRegion")
            handler(cRegion)
        }
    }
    
    public static func showAPIKey(_ handler: @escaping ((String) -> Void)) {
        UIAlertController.showInputFieldSheet(title: "API Key", message: "See the documentation to get it") { value in
            guard let APIKey = value, !APIKey.isEmpty else {
                handler("")
                return
            }
            
            handler(APIKey)
        }
    }
    
    public static func showTimeout(title: String? = nil, message: String? = nil, _ handler: @escaping ((TimeInterval?) -> Void)) {
        let subscriptionTypes: [UIAlertController.ActionSheetOption] = ([
            nil, 3, 5, 10, 15
        ] as [Int?]
        ).map { item in
            let title = (item == nil ? NOT_SET : "\(item!)s")
            return (title, { _ in
                handler((item != nil ? TimeInterval(item!) : nil))
            })
        }
        
        UIAlertController.showActionSheet(title: title ?? "Select Timeout",
                                          message: message ?? "It's used to cancel the request automatically when expired",
                                          options: subscriptionTypes)
    }
    
    public static func showDoubleInput(title: String, message: String = "", _ handler: @escaping ((Double?) -> Void)) {
        UIAlertController.showInputFieldSheet(title: title,  message: message) { value in
            guard let value = value, let doubleValue = Double(value) else {
                handler(nil)
                return
            }
            
            handler(doubleValue)
        }
    }
    
}



// MARK: - UIViewController

extension UIViewController {
    
    public static func topMostController() -> UIViewController? {
        let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first

        if var topController = keyWindow?.rootViewController {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }

            return topController
        }
        
        return nil
    }
    
}

// MARK: - UIStackView

extension UIStackView {
    
    public func setViews(_ views: [UIView], hidden: Bool, animated: Bool) {
        views.forEach {
            setView($0, hidden: hidden, animated: animated)
        }
    }
    
    public func setView(_ view: UIView, hidden: Bool, animated: Bool) {
        guard view.superview == self else { return }
        
        guard animated else {
            view.isHidden = hidden
            return
        }
        
        UIView.animate(withDuration: 0.25,
                       delay: 0.0,
                       usingSpringWithDamping: 0.9,
                       initialSpringVelocity: 1,
                       options: [],
                       animations: {
                        view.isHidden = hidden
                        self.layoutIfNeeded()
        }, completion: nil)
    }
    
}

// MARK: - UIView

extension UIView {
    
    func addIntoParent(_ parentView: UIView, autoLayout: Bool = true, safeArea: Bool = false, insets: UIEdgeInsets = .zero) {
        guard autoLayout else {
            parentView.addSubview(self)
            self.frame = parentView.bounds
            return
        }
        
        self.translatesAutoresizingMaskIntoConstraints = false
        parentView.addSubview(self)
        
        if safeArea == false {
            self.constraintToSuperview(insets: insets)
        } else {
            let guide = parentView.safeAreaLayoutGuide
            NSLayoutConstraint.activate([
                self.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: insets.right),
                self.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: insets.left),
                self.topAnchor.constraint(equalTo: guide.topAnchor, constant: insets.top),
                self.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: insets.bottom)
            ])
        }
    }
    
    func constraintToSuperview(insets: UIEdgeInsets = .zero) {
        guard let superview = self.superview else {
            assert(false, "Error! `superview` was nil – call `addSubview(_ view: UIView)` before calling `\(#function)` to fix this.")
            return
        }
        self.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: superview.topAnchor, constant: insets.top),
            bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: insets.bottom),
            leadingAnchor.constraint(equalTo: superview.leadingAnchor, constant: insets.left),
            trailingAnchor.constraint(equalTo: superview.trailingAnchor, constant: insets.right)
        ])
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

public extension Array where Element == Optional<String> {
    
    func firstNonNilOrFallback(_ fallback: String) -> String {
        guard let valueIdx = firstIndex(where: { $0 != nil && !($0?.isEmpty ?? true) }) else {
            return fallback
        }
        return self[valueIdx]!
    }
    
}

public extension UITableView {
    
    func registerUINibForClass(_ cell: UITableViewCell.Type) {
        let name = cell.defaultReuseIdentifier
        register(UINib(nibName: name, bundle: .main), forCellReuseIdentifier: name)
    }
    
}

public extension UITableViewCell {
    
    static var defaultReuseIdentifier: String {
        String(describing: self)
    }
    
    static var nibSource: UINib {
       UINib(nibName: defaultReuseIdentifier, bundle: .main)
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
        let numberFormatter = NumberFormatter()
        numberFormatter.maximumFractionDigits = 0
        return "\(numberFormatter.string(for: self) ?? "-") m"
    }
    
}

extension TimeInterval {

    func format() -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.second]
        formatter.unitsStyle = .abbreviated
        formatter.maximumUnitCount = 1

        return formatter.string(from: self)!
    }
    
}

extension UITextView {
    
    public func addOnTop(_ text: String) {
        if let position = textRange(from: beginningOfDocument, to: beginningOfDocument) {
            replace(position, withText: text)
        }
    }
}
