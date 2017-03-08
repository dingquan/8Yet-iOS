//
//  UserLocation.swift
//  8Yet
//
//  Record user location history
//
//  Created by Quan Ding on 2/10/16.
//  Copyright © 2016 EightYet. All rights reserved.
//

import Foundation

class UserLocation: PFObject, PFSubclassing {
    private static var __once: () = {
            self.registerSubclass()
        }()
    @NSManaged var user: User
    @NSManaged var geo: PFGeoPoint
    
    override class func initialize() {
        struct Static {
            static var onceToken : Int = 0;
        }
        _ = UserLocation.__once
    }
    
    class func parseClassName() -> String {
        return "UserLocation"
    }
    
    init (user: User, geo: PFGeoPoint) {
        super.init()
        self.user = user
        self.geo = geo
    }
    
    override init(){
        super.init()
    }
}
