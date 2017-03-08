//
//  LocationViewController.swift
//  8Yet
//
//  Created by Quan Ding on 5/18/15.
//  Copyright (c) 2015 EightYet. All rights reserved.
//

import UIKit
import CoreLocation

class LocationViewController: BaseViewController, CLLocationManagerDelegate {
    var locationManager = CLLocationManager()
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var yesBtn: UIButton!
    @IBOutlet weak var noBtn: UIButton!
    @IBOutlet weak var yesBtnWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var yesBtnHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var noBtnWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var noBtnHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var noBtnBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var iconWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var iconHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var bodyText: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        
        ViewHelpers.roundedCorner(yesBtn, radius: 5)
        ViewHelpers.roundedCorner(noBtn, radius: 5)
        
        titleLabel.font = UIFont(name: serifBoldFontName, size: 24 * screenSizeMultiplier)
        titleLabel.sizeToFit()
        
        bodyText.font = UIFont(name: sansSerifFontName, size: 21 * screenSizeMultiplier)
        bodyText.sizeToFit()
        
        iconWidthConstraint.constant *= screenSizeMultiplier
        iconHeightConstraint.constant *= screenSizeMultiplier
        
        yesBtnWidthConstraint.constant *= screenSizeMultiplier
        yesBtnHeightConstraint.constant *= screenSizeMultiplier
        noBtnWidthConstraint.constant *= screenSizeMultiplier
        noBtnHeightConstraint.constant *= screenSizeMultiplier
        
        yesBtn.titleLabel?.font = UIFont(name: serifMediumFontName, size: 30 * screenSizeMultiplier)
        noBtn.titleLabel?.font = UIFont(name: serifMediumFontName, size: 24 * screenSizeMultiplier)
        
        // adjust layout of buttons
        let screenBounds = UIScreen.main.bounds
        if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad || screenBounds.width * 480 == screenBounds.height * 320 {
            noBtnBottomConstraint.constant = 16
        } else {
            noBtnBottomConstraint.constant *= screenSizeMultiplier
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onYes(_ sender: UIButton) {
        Analytics.sharedInstance.event(Analytics.Event.LocationPermission.rawValue, properties: ["permissionGranted": "yes"])
        // iOS 8
        if #available(iOS 8.0, *) {
            locationManager.requestWhenInUseAuthorization()
        } else {
            // Fallback on earlier versions
            // no need to request permission, just ask for location
            if CLLocationManager.locationServicesEnabled() {
                locationManager.startUpdatingLocation()
            }
        }
    }

    @IBAction func onNo(_ sender: UIButton) {
        Analytics.sharedInstance.event(Analytics.Event.LocationPermission.rawValue, properties: ["permissionGranted": "no"])
        let alert:UIAlertView = UIAlertView(title: "Bummer!", message: "We respect your privacy. Unfortunately our app won't function without knowing your location.", delegate: self, cancelButtonTitle: "OK")
        alert.show()
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        var statusString = ""
        switch status {
        case CLAuthorizationStatus.notDetermined:
            statusString = "NotDetermined"
            // if it's not determined, we haven't ask for the permission yet, don't dismiss the controller
        case CLAuthorizationStatus.denied:
            statusString = "Denied"
            fallthrough
        case CLAuthorizationStatus.restricted:
            statusString = "Restricted"
            fallthrough
        default:
            statusString = "Granted"
            self.dismiss(animated: true, completion: nil)
        }
        NSLog("location service authorization status changed to: \(statusString)")
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
