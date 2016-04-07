//
//  ReverseGeocodeVC.swift
//  SwiftLocationExample
//
//  Created by aybek can kaya on 07/04/16.
//  Copyright © 2016 danielemargutti. All rights reserved.
//

import UIKit
import MapKit

class ReverseGeocodeVC: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var twAddress: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
       
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


extension ReverseGeocodeVC
{
    func guiInit()
    {
        // pin 
        let imPin:UIImage = UIImage(named: "green_pin")!
        let imViewMarker:UIImageView = UIImageView()
        imViewMarker.frame = CGRectMake(0, 0, 51, 41)
        imViewMarker.image = imPin
        
        let bounds = UIScreen.mainScreen().bounds
        imViewMarker.center = CGPointMake(bounds.size.width/2, bounds.size.height/2 - imViewMarker.frame.size.height/2)
        
        
        
        
        
        
        
        
    }
    
}