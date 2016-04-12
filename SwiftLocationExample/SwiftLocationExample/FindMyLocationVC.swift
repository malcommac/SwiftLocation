//
//  FindMyLocationVC.swift
//  SwiftLocationExample
//
//  Created by aybek can kaya on 07/04/16.
//  Copyright © 2016 danielemargutti. All rights reserved.
//

import UIKit
import MapKit


class FindMyLocationVC: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
         self.navigationController?.hidesBarsOnTap = true
        findMyLocation()
    }
    
    func findMyLocation()
    {
        do
        {
            try SwiftLocation.shared.currentLocation(Accuracy.House, timeout: 20, onSuccess: { (location) -> Void in
                // location is a CLPlacemark
                
                if let theLocation  = location{
                    self.putAnnotation(theLocation.coordinate)
                }
                
                }) { (error) -> Void in
                    // something went wrong
                    print("error : \(error)")
            }
        }
        catch(let exc)
        {
            print("exception : \(exc)")
        }
        
       
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


// MARK: - MapView
extension FindMyLocationVC
{
    func putAnnotation(coordinate:CLLocationCoordinate2D)
    {
        let pinAnn:MKPointAnnotation = MKPointAnnotation()
        pinAnn.coordinate = coordinate
        self.mapView.addAnnotation(pinAnn)
        
        self.zoomToLocation(coordinate, zoomDegree: 0.1)
        
    }
    
    func zoomToLocation(coordinate:CLLocationCoordinate2D , zoomDegree:CGFloat)
    {
        let region:MKCoordinateRegion = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpanMake(CLLocationDegrees(zoomDegree) , CLLocationDegrees(zoomDegree)))
        
        self.mapView.setRegion(region, animated: true)
        
    }
   
    
    
}
