//
//  UserMatch.swift
//  8Yet
//
//  Created by Quan Ding on 6/22/15.
//  Copyright (c) 2015 EightYet. All rights reserved.
//

import Foundation

enum BailOutReason:String {
    case didNotArrange = "didNotArrange"
    case didNotGo = "didNotGo"
    case otherUserNoShow = "otherUserNoShow"
}

enum MeetAgain:String {
    case yes = "yes"
    case maybe = "maybe"
    case no = "no"
}

class UserMatch: PFObject, PFSubclassing {
    private static var __once: () = {
            self.registerSubclass()
        }()
    override class func initialize() {
        struct Static {
            static var onceToken : Int = 0;
        }
        _ = UserMatch.__once
    }
    
    class func parseClassName() -> String {
        return "UserMatch"
    }
    
    @NSManaged var fromUser: User
    @NSManaged var toUser: User
    @NSManaged var matchCount: Int
    @NSManaged var didMeet: NSNumber?
    @NSManaged var bailOutReason: String?
    @NSManaged var willMeetAgain: String?
    @NSManaged var ratingsOfToUser: NSNumber?
    @NSManaged var chat:Chat?
    @NSManaged var comments: String?

    class func findUnreviewedMatches(_ completion: @escaping ([UserMatch]?, NSError?) -> Void){
        
        PFCloud.callFunctionInBackground("findUnreviewedMatches", withParameters: nil) { (userMatches:AnyObject?, error: NSError?) -> Void in
            if error == nil {
                completion(userMatches as! [UserMatch]?, nil)
            } else {
                NSLog("error in findUnreviewedMatches: " + error!.localizedDescription)
                completion([], error)
            }
        }
    }
    
    class func getUserMatchById(_ id: String?, completion: @escaping (_ userMatch: UserMatch?, _ error: NSError?) -> Void) {
        if let id = id {
            let query = PFQuery(className: "UserMatch")
            query.includeKey("fromUser")
            query.includeKey("toUser")
            query.includeKey("chat")
            query.includeKey("chat.users")
            query.getObjectInBackgroundWithId(id) { (userMatch: PFObject?, error: NSError?) -> Void in
                completion(userMatch: userMatch as? UserMatch, error: error)
            }
        }
    }
}
