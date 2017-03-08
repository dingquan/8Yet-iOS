//
//  ReportUser.swift
//  8Yet
//
//  Created by Quan Ding on 8/30/15.
//  Copyright (c) 2015 EightYet. All rights reserved.
//

import Foundation

class ReportUser: PFObject, PFSubclassing {
    private static var __once: () = {
            self.registerSubclass()
        }()
    override class func initialize() {
        struct Static {
            static var onceToken : Int = 0;
        }
        _ = ReportUser.__once
    }
    
    class func parseClassName() -> String {
        return "ReportUser"
    }
    
    init(fromUser: User, toUser: User, reason: String) {
        super.init()
        self.fromUser = fromUser
        self.toUser = toUser
        self.reason = reason
    }
    
    @NSManaged var fromUser: User
    @NSManaged var toUser: User
    @NSManaged var reason: String
}
