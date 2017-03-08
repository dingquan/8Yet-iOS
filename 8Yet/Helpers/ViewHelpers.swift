//
//  ViewHelper.swift
//  8Yet
//
//  Created by Ding, Quan on 3/5/15.
//  Copyright (c) 2015 EightYet. All rights reserved.
//

import Foundation

class ViewHelpers {
    class func fadeInImage(_ imageView: UIImageView, imgUrl: String?) -> Void {
        if let imgUrl = imgUrl {
            imageView.image = nil
            let urlReq = URLRequest(url: URL(string: imgUrl)!)
            imageView.setImageWithURLRequest(urlReq, placeholderImage: nil, success: { (request: URLRequest, response: HTTPURLResponse?, image:UIImage) -> Void in
                imageView.alpha = 0.0
                imageView.image = image
                //            imageView.sizeToFit()
                UIView.animateWithDuration(0.25, animations: { imageView.alpha = 1.0})
                }, failure: { (request:URLRequest, response:HTTPURLResponse?, error:NSError) -> Void in
                    print(error)
            })
        }
    }
    
    class func fadeInImageWithCompletion(_ imageView: UIImageView, imgUrl: String?, completion: @escaping (()) -> ()) {
        imageView.image = nil
        let urlReq = URLRequest(url: URL(string: imgUrl!)!)
        imageView.setImageWithURLRequest(urlReq, placeholderImage: nil, success: { (request: URLRequest, response: HTTPURLResponse?, image:UIImage) -> Void in
            imageView.alpha = 0.0
            imageView.image = image
            //            imageView.sizeToFit()
            UIView.animateWithDuration(0.25, animations: { imageView.alpha = 1.0}, completion: { (finished) -> Void in
                if (finished){
                    completion()
                }})
            }, failure: { (request:URLRequest, response:HTTPURLResponse?, error:NSError) -> Void in
                print(error)
            }
        )
    }
    
    class func setImageWithCompletion(_ imageView: UIImageView, imgUrl: String?, completion: @escaping (()) -> ()) {
        imageView.image = nil
        let urlReq = URLRequest(url: URL(string: imgUrl!)!)
        imageView.setImageWithURLRequest(urlReq, placeholderImage: nil, success: { (request: URLRequest, response: HTTPURLResponse?, image:UIImage) -> Void in
            imageView.image = image
            completion()
            }, failure: { (request:URLRequest, response:HTTPURLResponse?, error:NSError) -> Void in
                print(error)
            }
        )
    }
    
    class func roundedCorner(_ view: UIView, radius: CGFloat) -> Void {
        view.layer.cornerRadius = radius
        view.clipsToBounds = true
    }
    
    class func roundedCornerWithBoarder(_ view: UIView, radius: CGFloat, borderWidth: CGFloat, color: UIColor) -> Void {
        view.layer.cornerRadius = radius
        view.layer.borderColor = color.CGColor;
        view.layer.borderWidth = borderWidth;
        view.clipsToBounds = true
    }
    
    class func roundedCorners(_ view: UIView, corners: UIRectCorner, radius: CGFloat) {
        let rounded = UIBezierPath(roundedRect: view.bounds, byRoundingCorners: corners, cornerRadii: CGSizeMake(radius, radius))
        let shape = CAShapeLayer()
        shape.path = rounded.CGPath
        view.layer.mask = shape
    }
    
    class func addTransparentForground(_ view: UIView, colors:[CGColor], locations: [NSNumber], isVertical: Bool) {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = view.bounds;
        gradientLayer.colors = colors
        gradientLayer.locations = locations
        if isVertical {
            gradientLayer.startPoint = CGPointMake(0, 0)
            gradientLayer.endPoint = CGPointMake(0, 1)
        } else {
            gradientLayer.startPoint = CGPointMake(0, 0)
            gradientLayer.endPoint = CGPointMake(1, 0)
        }
        view.layer.mask = gradientLayer
    }
    
    class func rotateLayerInfinite(_ layer: CALayer) {
        let rotation = CABasicAnimation(keyPath: "transform.rotation")
        rotation.fromValue = 0
        rotation.toValue = 2 * M_PI
        rotation.duration = 0.7 // speed
        rotation.repeatCount = FLT_MAX
        layer.removeAllAnimations()
        layer.addAnimation(rotation, forKey: "Spin")
    }
    
    class func stopRotateLayer(_ layer: CALayer) {
        layer.removeAllAnimations()
    }

    class func addDropShadow(_ view: UIView, color: CGColor, offset: CGSize, shadowRadius: CGFloat, opacity: Float, cornerRadius: CGFloat) {
        let layer = view.layer
        layer.masksToBounds = false
        layer.cornerRadius = cornerRadius
        layer.shadowOffset = offset
        layer.shadowRadius = shadowRadius
        layer.shadowOpacity = opacity
        layer.shadowColor = color
        
        // explicitly set the shadow path to improve the drawing performance. without it, the frame rate dropped to 10s on ipod touch
        layer.shadowPath = UIBezierPath(roundedRect: view.layer.bounds, cornerRadius: cornerRadius).CGPath
    }
    
    class func centerMapOnLocation(_ mapView: MKMapView, geo: PFGeoPoint, regionRadius: CLLocationDistance) {
        let location = CLLocation(latitude: geo.latitude, longitude: geo.longitude)
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate,
            regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    class func showLocationOnMap(_ mapView: MKMapView, geo: PFGeoPoint) {
        let annotation = MKPointAnnotation()
        let coordinate = CLLocationCoordinate2D(latitude: geo.latitude, longitude: geo.longitude)
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
    }
    
    class func showLocationOnMap(_ mapView: MKMapView, location: Location) {
        let annotation = MKPointAnnotation()
        annotation.title = location.name
        let geo = location.geo
        let coordinate = CLLocationCoordinate2D(latitude: geo.latitude, longitude: geo.longitude)
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
    }
    
    class func presentErrorMessage(_ error: NSError?, vc: UIViewController) {
        if let error = error {
            NSLog("Presenting error: \(error)")
            let alert = UIAlertController(title: "It's not your fault", message: "Something went wrong. A group of highly trained code monkeys are working on it.\n\nFor techies:\n\(error.userInfo)", preferredStyle: UIAlertControllerStyle.Alert)
            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil)
            alert.addAction(okAction)
            vc.presentViewController(alert, animated: true, completion: nil)
        }
    }
}
