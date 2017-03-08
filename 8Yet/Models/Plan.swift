//
//  Plan.swift
//  8Yet
//
//  Created by Quan Ding on 1/27/16.
//  Copyright © 2016 EightYet. All rights reserved.
//
//  This class represents a lunch plan

import Foundation

let createPlanNotification = "createPlanNotification"
let joinPlanNotification = "joinPlanNotification"
let quitPlanNotification = "quitPlanNotificatin"
let updatePlanNotification = "updatePlanNotification"

class Plan: PFObject, PFSubclassing {
    private static var __once: () = {
            self.registerSubclass()
        }()
    override class func initialize() {
        struct Static {
            static var onceToken : Int = 0;
        }
        _ = Plan.__once
    }
    
    class func parseClassName() -> String {
        return "Plan"
    }
    
    @NSManaged var host: User
    @NSManaged var participants: [User]
    @NSManaged var startTime: Date
    @NSManaged var minParticipants: Int
    @NSManaged var maxParticipants: Int
    @NSManaged var numParticipants: Int
    @NSManaged var topic: String?
    @NSManaged var chat: Chat?
    @NSManaged var geo: PFGeoPoint? // duplicated from "location" for easier query
    @NSManaged var location: Location?
    
    class func findNearbyPlans(_ location: PFGeoPoint, completion: @escaping (_ plans: [Plan], _ error: NSError?) -> Void) {
        
        PFCloud.callFunctionInBackground("findNearbyPlans", withParameters: ["latitude": location.latitude, "longitude": location.longitude]) { (plans:AnyObject?, error: NSError?) -> Void in
            if error != nil {
                NSLog("Failed to findNearbyPlans: " + error!.localizedDescription)
                completion(plans: [], error: error)
            } else {
                print("number of nearby plans: \(plans == nil ? 0 : plans!.count)")
                if plans != nil {
                    let nearbyPlans = plans as! [Plan]
                    completion(plans: nearbyPlans, error: nil)
                }
            }
            
        }
    }
    
    class func findMyTodaysPlan(_ completion: @escaping (_ plan: Plan?, _ error: NSError?) -> Void) {
        
        PFCloud.callFunctionInBackground("findMyTodaysPlan", withParameters: nil) { (results:AnyObject?, error: NSError?) -> Void in
            if error != nil {
                NSLog("Failed to findMyTodaysPlan: " + error!.localizedDescription)
                completion(plan: nil, error: error)
            } else {
                let plans = results as! [Plan]
                if plans.count == 0 {
                    completion(plan: nil, error: nil)
                } else {
                    completion(plan: plans[0], error: nil)
                }
            }
            
        }
    }
    
    func getPlanDetails(_ completion: @escaping (_ plan: Plan?, _ error: NSError?) -> Void) {
        if let planId = objectId {
            PFCloud.callFunctionInBackground("getPlanDetails", withParameters: ["planId": planId]) { (fetchedPlan: AnyObject?, error: NSError?) -> Void in
                if error != nil {
                    NSLog("Failed to getPlanDetails: " + error!.localizedDescription)
                    completion(plan: nil, error: error)
                } else {
                    completion(plan: fetchedPlan as? Plan, error: nil)
                }
            }
        }
    }
    
    // join the current plan
    func join(_ completion: @escaping (_ plan: Plan?, _ error: NSError?) -> Void) {
        if let planId = objectId {
            PFCloud.callFunctionInBackground("joinPlan", withParameters: ["planId": planId]) { (plan: AnyObject?, error: NSError?) -> Void in
                if error != nil {
                    print("error while joining plan: \(error)")
                    completion(plan: nil, error: error)
                } else {
                    print("joinPlan succeeded: \(plan)")
                    completion(plan: plan as? Plan, error: nil)
                }
            }
        }
    }
    
    func quit(_ completion: @escaping (_ plan: Plan?, _ error: NSError?) -> Void) {
        if let planId = objectId {
            PFCloud.callFunctionInBackground("quitPlan", withParameters: ["planId": planId]) { (plan: AnyObject?, error: NSError?) -> Void in
                if error != nil {
                    print("error while quit/cancel plan: \(error)")
                    completion(plan: nil, error: error)
                } else {
                    print("quitPlan succeeded: \(plan)")
                    completion(plan: plan as? Plan, error: nil)
                }
            }
        }
    }
}
