//
//  Location.swift
//  8Yet
//
//  Created by Quan Ding on 2/1/16.
//  Copyright © 2016 EightYet. All rights reserved.
//

import Foundation

class Location: PFObject, PFSubclassing {
    private static var __once: () = {
            self.registerSubclass()
        }()
    override class func initialize() {
        struct Static {
            static var onceToken : Int = 0;
        }
        _ = Location.__once
    }
    
    class func parseClassName() -> String {
        return "Location"
    }
    
    @NSManaged var name: String?
    @NSManaged var address: String
    @NSManaged var geo: PFGeoPoint
    @NSManaged var rating: NSNumber?
    @NSManaged var priceLevel: NSNumber?
    @NSManaged var cuisines: [String]?
    @NSManaged var googlePlaceId: String?
    
    func getPriceLevelString() -> String {
        var result = ""
        if let priceLevel = self.priceLevel {
            switch priceLevel {
            case 1:
                result = "$"
            case 2:
                result = "$$"
            case 3:
                result = "$$$"
            case 4:
                result = "$$$$"
            case 5:
                result = "$$$$$"
            default:
                result = ""
            }
        }
        return result
    }
}
