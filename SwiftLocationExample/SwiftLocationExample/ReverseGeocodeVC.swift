//
//  ReverseGeocodeVC.swift
//  SwiftLocationExample
//
//  Created by aybek can kaya on 07/04/16.
//  Copyright © 2016 danielemargutti. All rights reserved.
//

import UIKit
import MapKit

class ReverseGeocodeVC: UIViewController , MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var twAddress: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
       
        guiInit()
       
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}


// MARK: - GUI
extension ReverseGeocodeVC
{
    func guiInit()
    {
        self.mapView.delegate = self
        
        // pin 
        let imPin:UIImage = UIImage(named: "green_pin")!
        let imViewMarker:UIImageView = UIImageView()
        imViewMarker.frame = CGRectMake(0, 0, 41, 51)
        imViewMarker.image = imPin
        
        let bounds = UIScreen.mainScreen().bounds
        imViewMarker.center = CGPointMake(bounds.size.width/2, bounds.size.height/2 - imViewMarker.frame.size.height/2)
        
        self.view.addSubview(imViewMarker)
        
        
        self.twAddress.text = ""
        
    }

    
}


// MARK: - MapViewDelegate
extension ReverseGeocodeVC
{
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
        let centerCoordinate:CLLocationCoordinate2D = mapView.convertPoint(mapView.center, toCoordinateFromView: mapView)
       setAddressFromCoordinate(centerCoordinate)
        
    }
}


// MARK: - Location
extension ReverseGeocodeVC
{
    func zoomToLocation(coordinate:CLLocationCoordinate2D , zoomDegree:CGFloat)
    {
        let region:MKCoordinateRegion = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpanMake(CLLocationDegrees(zoomDegree) , CLLocationDegrees(zoomDegree)))
        
        self.mapView.setRegion(region, animated: true)
        
    }
    
    /**
        puts marker for given location
     */
    func setAddressFromCoordinate(coordinates:CLLocationCoordinate2D)
    {
        
        SwiftLocation.shared.reverseCoordinates(Service.Apple, coordinates: coordinates, onSuccess: { (place) -> Void in
            
                 self.twAddress.text = place?.country
            
            }) { (error) -> Void in
               
                print("Error : \(error)")
                
        }
        
      
    }
    
    
}



