//
//  Installation.swift
//  8Yet
//
//  Created by Quan Ding on 10/25/15.
//  Copyright © 2015 EightYet. All rights reserved.
//

import Foundation

class Installation: PFInstallation {
    private static var __once: () = {
            self.registerSubclass()
        }()
    @NSManaged var owner:User?
    @NSManaged var notificationEnabled:NSNumber?
    @NSManaged var onboardingShown:NSNumber?
    @NSManaged var noFbEmail:String?
    @NSManaged var demoMode:NSNumber?
    
    override class func initialize() {
        struct Static {
            static var onceToken : Int = 0;
        }
        _ = Installation.__once
    }
    
    func clearOnboardingFlags() {
        onboardingShown = false
        saveInBackground()
    }
    
    func updateInstallationWithUser() {
        let user = User.currentUser()
        if let user = user {
            let oldOwner = owner
            if (oldOwner == nil || oldOwner!.objectId! != user.objectId) {
                owner = user
                saveInBackgroundWithBlock(nil)
            }
        }
    }
    
}
