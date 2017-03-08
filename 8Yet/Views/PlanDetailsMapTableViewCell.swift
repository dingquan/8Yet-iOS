//
//  PlanDetailsMapTableViewCell.swift
//  8Yet
//
//  Created by Quan Ding on 2/22/16.
//  Copyright © 2016 EightYet. All rights reserved.
//

import UIKit

class PlanDetailsMapTableViewCell: UITableViewCell, MKMapViewDelegate {
    var plan: Plan? {
        didSet {
            if let plan = plan {
                if let location = plan.location {
                    mapContainerView.isHidden = false
                    addressView.isHidden = false
                    addressLabel.text = location.address
                    addressLabel.preferredMaxLayoutWidth = addressLabel.bounds.width
                    addressLabel.sizeToFit()
                    if let userGeo = User.currentUser()?.lastKnownLocation {
                        let distance = userGeo.distanceInMilesTo(location.geo)
                        distanceLabel.text = NSString(format: "%.1f miles", distance) as String
                        distanceLabel.sizeToFit()
                        distanceLabel.isHidden = false
                    } else {
                        distanceLabel.text = nil
                        distanceLabel.sizeToFit()
                        distanceLabel.isHidden = true
                    }
                    mapContainerViewHeightConstraint.constant = origMapContainerViewHeight ?? 238
                    addressViewHeightConstraint.constant = origAddressViewHeight ?? 42
                    mapView.removeAnnotations(mapView.annotations) // clear previous annotations
                    ViewHelpers.showLocationOnMap(mapView, geo: location.geo)
                    ViewHelpers.centerMapOnLocation(mapView, geo: location.geo, regionRadius: 500)
                } else {
                    mapContainerViewHeightConstraint.constant = 0
                    mapContainerView.isHidden = true
                    addressViewHeightConstraint.constant = 0
                    addressView.isHidden = true
                }
            }
        }
    }
    
    fileprivate var origMapContainerViewHeight: CGFloat?
    fileprivate var origAddressViewHeight: CGFloat?
    
    @IBOutlet weak var mapContainerView: UIView!
    @IBOutlet weak var mapContainerViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var addressView: UIView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var addressViewHeightConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        origMapContainerViewHeight = mapContainerViewHeightConstraint.constant
        origAddressViewHeight = addressViewHeightConstraint.constant
        self.mapView.delegate = self
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    // MARK: - MKMapViewDelegate
    func mapView(_ mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        var pinView = self.mapView.dequeueReusableAnnotationViewWithIdentifier("mapPointAnnotation")
        if pinView == nil {
            pinView = MKAnnotationView(annotation: annotation, reuseIdentifier: "mapPointAnnotation")
        }
        pinView?.canShowCallout = true
        pinView?.image = UIImage(named: "mapPin")
        return pinView
    }
}
