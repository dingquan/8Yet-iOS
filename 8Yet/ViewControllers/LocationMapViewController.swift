//
//  LocationMapViewController.swift
//  8Yet
//
//  Created by Quan Ding on 7/22/15.
//  Copyright (c) 2015 EightYet. All rights reserved.
//

import UIKit
import MapKit

class LocationMapViewController: BaseViewController {
    let regionRadius: CLLocationDistance = 1000
    
    var message: Message!

    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        if let message = message {
            let media = message.media as! JSQLocationMediaItem
            let location = media.location
            let coordinate = media.coordinate
            centerMapOnLocation(location)
            showLocationOnMap(coordinate)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    func centerMapOnLocation(_ location: CLLocation) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate,
            regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    func showLocationOnMap(_ coordinate: CLLocationCoordinate2D) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
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
