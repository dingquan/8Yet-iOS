//
//  Contact.swift
//  8Yet
//
//  Created by Quan Ding on 6/9/15.
//  Copyright (c) 2015 EightYet. All rights reserved.
//

import Foundation

class Contact: PFObject, PFSubclassing {
    private static var __once: () = {
            self.registerSubclass()
        }()
    override class func initialize() {
        struct Static {
            static var onceToken : Int = 0;
        }
        _ = Contact.__once
    }
    
    class func parseClassName() -> String {
        return "Contact"
    }
    
    // the user id with lower alphabetic order
    @NSManaged var expires: NSNumber
    @NSManaged var owner: User
    @NSManaged var user: User
}
