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

class GeofenceController: UIViewController {
    
    private static let OuterMKCircleTitle = "OuterMKCircleTitle"
    
    public enum State {
        case browse
        case drawPolygon
        case drawCircularRegion
    }
    
    private var state: State = .browse
    
    @IBOutlet public var stackView: UIStackView!
    @IBOutlet public var mapView: MKMapView!
    @IBOutlet public var mapHolderView: UIView!
    @IBOutlet public var sliderHolderView: UIView!
    @IBOutlet public var confirmButtonHolderView: UIView!
    @IBOutlet public var confirmButton: UIButton!
    @IBOutlet public var cancelButton: UIButton!
    @IBOutlet public var sliderCurrentValue: UILabel!
    @IBOutlet public var sliderMinValue: UILabel!
    @IBOutlet public var sliderMaxValue: UILabel!
    @IBOutlet public var radiusSlider: UISlider!
    @IBOutlet public var suggestLabel: UILabel!
    @IBOutlet public var suggestHolderView: UIView!

    private var currentOverlay: MKOverlay?
    private var currentRequest: GeofencingRequest?

    private lazy var drawMap: MapDrawView = {
        let view = MapDrawView()
        view.delegate = self
        return view
    }()
    
    var points = [CLLocationCoordinate2D]() {
        didSet {
            print(points)
        }
    }
    
    public static func create() -> GeofenceController {
        let s = UIStoryboard(name: "GeofenceController", bundle: nil)
        return s.instantiateInitialViewController() as! GeofenceController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        drawMap.addIntoParent(mapHolderView)
        
        drawMap.mapView = mapView
        
        radiusSlider.addTarget(self, action: #selector(didChangeCircleRadiusValue), for: .valueChanged)
        
        radiusSlider.value = 100 // mts
        didChangeCircleRadiusValue(slider: radiusSlider, event: nil)
 
        setState(.browse, animated: false)
        self.navigationItem.title = "Geofence"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        reloadGeofencedRegions(reattachSubscribers: false)
    }
    
    // MARK: - IBActions
    
    @IBAction public func didTapCancelButton(_ sender: Any?) {
        currentRequest?.cancelRequest()
        currentOverlay = nil
        
        reloadGeofencedRegions()
        
        self.setState(.browse)
    }
    
    @IBAction public func didTapSaveButton(_ sender: Any?) {
        setState(.browse)
    }
    
    @IBAction public func didTapCurrentLocation(_ sender: Any?) {
        mapView.zoomToUserLocation { error in
            UIAlertController.showAlert(title: "Failed to retrive current location", message: error.localizedDescription)
        }
    }
    
        
    @IBAction public func didTapCreateNewGeofence(_ sender: Any?) {
        let polygonRegion: UIAlertController.ActionSheetOption = ("New Polygon", { [weak self] _ in
            self?.setState(.drawPolygon)
        })
        
        let circularRegion: UIAlertController.ActionSheetOption = ("New Circular Region", { [weak self] _ in
            self?.setState(.drawCircularRegion)
        })
        
        UIAlertController.showActionSheet(title: "Create a new geofence zone",
                                          message: "Select the zone you want to create",
                                          options: [circularRegion, polygonRegion])
        
    }
    
    // MARK: - Private Functions
    
    @objc private func didChangeCircleRadiusValue(slider: UISlider, event: UIEvent?) {
        let distance = CLLocationDistance(radiusSlider.value)
        
        let formatter = MKDistanceFormatter()
        formatter.unitStyle = .abbreviated
        formatter.locale = Locale(identifier: "IT-it")
        sliderCurrentValue.text = formatter.string(for: distance)
        sliderMinValue.text = formatter.string(for: radiusSlider.minimumValue)
        sliderMaxValue.text = formatter.string(for: radiusSlider.maximumValue)

        if let touchEvent = event?.allTouches?.first {
            switch touchEvent.phase {
            case .ended:
                if let circle = currentOverlay as? MKCircle {
                    let newCircle = MKCircle(center: circle.coordinate, radius: distance)
                    setCurrentOverlays([newCircle])
                }
            default:
                break
            }
        }
    }
    
    private func setState(_ newState: State, animated: Bool = true) {        
        switch newState {
        case .browse:
            drawMap.mode = .disabled
            
            stackView.setViews([suggestHolderView, sliderHolderView, confirmButtonHolderView],
                               hidden: true, animated: animated)
            
        case .drawCircularRegion:
            setEnableButton(confirmButton, enabled: false)
            drawMap.mode = .drawCircle
            setSuggestTitle("Tap a point to make a circle")

            stackView.setViews([sliderHolderView, confirmButtonHolderView],
                               hidden: false, animated: animated)

        case .drawPolygon:
            setEnableButton(confirmButton, enabled: false)
            confirmButton.isEnabled = false
            drawMap.mode = .drawPolygon
            setSuggestTitle("Draw your polygon")

            stackView.setView(confirmButtonHolderView,
                              hidden: false, animated: animated)
            stackView.setView(sliderHolderView, hidden: true, animated: animated)
            
        }
        
        state = newState
    }
    
    private func setEnableButton(_ button: UIButton, enabled: Bool) {
        button.isEnabled = enabled
        button.alpha = (enabled ? 1.0 : 0.3)
    }
    
    private func setSuggestTitle(_ title: String?) {
        suggestLabel.text = title ?? ""
        stackView.setView(suggestHolderView, hidden: (title == nil), animated: true)
    }
    
    private func addNewGeofencedRegionFromShape(_ shape: MKShape) {
        do {
            if let circle = shape as? MKCircle {
                let options = GeofencingOptions(circle: circle)
                currentRequest = SwiftLocation.geofenceWith(options)
                
            } else if let polygon = shape as? MKPolygon {
                let options = try GeofencingOptions(polygon: polygon)
                currentRequest = SwiftLocation.geofenceWith(options)
                
            } else {
                throw LocationError.other("Shape is not supported and cannot be monitored: \(shape.description)")
            }
            
            reloadGeofencedRegions()
        } catch {
            UIAlertController.showAlert(title: "Failed to monitor region", message: error.localizedDescription)
        }
    }
    
    private func reloadGeofencedRegions(reattachSubscribers: Bool = true) {
        // Draw polygons
        mapView.removeOverlays(mapView.overlays)
        
        for request in SwiftLocation.geofenceRequests.list {
            switch request.options.region {
            case .circle(let circularRegion):
                let circle = MKCircle(center: circularRegion.center, radius: circularRegion.radius)
                setCurrentOverlays([circle])
                
            case .polygon(let polygon, let outerCircularRegion):
                let outerCircle = MKCircle(center: outerCircularRegion.center, radius: outerCircularRegion.radius)
                outerCircle.title = GeofenceController.OuterMKCircleTitle
                setCurrentOverlays([polygon, outerCircle])
                
            }
        }
        
        setEnableButton(confirmButton, enabled: (currentRequest != nil) )
        
        if reattachSubscribers {
            // Attach event subscribers
            AppDelegate.attachSubscribersToGeofencedRegions(Array(SwiftLocation.geofenceRequests.list))
        }
    }
    
}

// MARK: - GeofenceController (MKMapViewDelegate)

extension GeofenceController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKCircle {
            if overlay.title == GeofenceController.OuterMKCircleTitle {
                let renderer = MKCircleRenderer(overlay: overlay)
                renderer.fillColor = UIColor.black.withAlphaComponent(0.2)
                renderer.strokeColor = UIColor.lightGray
                renderer.lineWidth = 2
                renderer.lineDashPhase = 10
                renderer.lineDashPattern = [0, 5, 3, 2]
                return renderer
            } else {
                let renderer = MKCircleRenderer(overlay: overlay)
                renderer.fillColor = UIColor.black.withAlphaComponent(0.2)
                renderer.strokeColor = UIColor.blue
                renderer.lineWidth = 2
                return renderer
            }
            
        } else if overlay is MKPolyline {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = UIColor.orange
            renderer.lineWidth = 3
            return renderer
        } else if let polygon = overlay as? MKPolygon {
            let renderer = MKPolygonRenderer(polygon: polygon)
            renderer.fillColor = UIColor.blue.withAlphaComponent(0.3)
            renderer.strokeColor = UIColor.blue
            renderer.lineWidth = 1
            return renderer
        } else {
            return MKPolygonRenderer()
        }
    }
    
    func setCurrentOverlays(_ overlays: [MKOverlay]?) {
        currentOverlay = overlays?.first
        
        mapView.removeOverlays(mapView.overlays)
        
        overlays?.reversed().forEach {
            mapView.addOverlay($0, andZoom: true)
        }
    }
    
}

// MARK: - GeofenceController (MapDrawViewDelegate)

extension GeofenceController: MapDrawViewDelegate {
    
    func drawView(view: MapDrawView, didCompleteTap center: CGPoint) {
        let center = mapView.convert(center, toCoordinateFrom: mapView)
        let circle = MKCircle(center: center, radius: CLLocationDistance(radiusSlider.value))
        addNewGeofencedRegionFromShape(circle)
    }
    
    func drawView(view: MapDrawView, didCompletedPolygon points: [CGPoint]) {
        guard points.count > 2 else {
            return
        }
        
        var locations = points.map { mapView.convert($0, toCoordinateFrom: mapView) }
        let polygon = MKPolygon(coordinates: &locations, count: locations.count)
        addNewGeofencedRegionFromShape(polygon)
    }

}
