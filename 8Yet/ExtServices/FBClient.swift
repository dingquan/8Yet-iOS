//
//  FBClient.swift
//  8Yet
//
//  Created by Ding, Quan on 3/3/15.
//  Copyright (c) 2015 EightYet. All rights reserved.
//

import Foundation

class FBClient {
    static let sharedInstance = FBClient()
    
    init(){
        print("initialize FBClient singleton")
    }
    
    func loginWithCompletion(_ completion: @escaping (_ user:User?, _ error: NSError?) -> Void) {
        let permissions = ["public_profile", "email", "user_friends"]
        
        PFFacebookUtils.logInInBackgroundWithReadPermissions(permissions) {
            (user: PFUser?, error: NSError?) -> Void in
            completion(user: user as? User, error: error)
        }
    }
    
    func getLoginUserProfile(_ user: User, completion: @escaping (_ user:User?, _ error: NSError?) -> Void) {
        var params = [String:String]()
        params["fields"] = "id,name,about,email,last_name,first_name,birthday,age_range,gender,locale,timezone,bio,hometown,location,meeting_for,relationship_status,verified"
        let fbRequest = FBSDKGraphRequest(graphPath: "me", parameters: params)
        fbRequest.startWithCompletionHandler { (connection: FBSDKGraphRequestConnection!, result: AnyObject!, error: NSError!) -> Void in
            if error != nil {
                NSLog("error in getting FB user profile: " + error.localizedDescription)
                completion(user: nil, error: error)
            } else {
                if (result != nil){
                    print("logged in user profile: \(result)")
                    let result = result as! NSDictionary
                    user.email = (result["email"] as? String) ?? user.email //keep old value if new value is nil
                    user.lastName = (result["last_name"] as? String) ?? user.lastName
                    user.firstName = (result["first_name"] as? String) ?? user.firstName
                    user.facebookId = (result["id"] as? String) ?? user.facebookId
                    let birthdayStr = result["birthday"] as? String
                    if birthdayStr != nil {
                        user.birthday = mmDdYyyyDateFormatter.dateFromString(birthdayStr!)
                    }
                    user.gender = (result["gender"] as? String) ?? user.gender
                    user.locale = (result["locale"] as? String) ?? user.locale
                    user.timezone = (result["timezone"] as? Int) ?? user.timezone
                    user.about = (result["about"] as? String) ?? user.about
                    user.name = (result["name"] as? String) ?? user.name
                    let ageRange = result["age_range"] as? NSDictionary
                    if let ageRange = ageRange {
                        if ageRange["min"] != nil {
                            user.ageMin = ageRange["min"] as? NSNumber
                        }
                        if ageRange["max"] != nil {
                            user.ageMax = ageRange["max"] as? NSNumber
                        }
                    }
                    // don't overwrite existing bio user entered
                    if user.bio == nil || user.bio == "" {
                        user.bio = (result["bio"] as? String) ?? user.bio
                    }
                    user.hometown = (result["hometown"] as? String) ?? user.hometown
                    user.meeting_for = (result["meeting_for"] as? String) ?? user.meeting_for
                    user.relationship_status = (result["relationship_status"] as? String) ?? user.relationship_status
                    user.verified = (result["verified"] as? NSNumber) ?? user.verified
                    
                    completion(user: user, error: nil)
                }
            }
        }
    }
    
    // get the list of facebook friends of the current user
    func updateFriendList(_ completion: @escaping (_ friends: [String]?, _ error: NSError?) -> Void) {
        var params = [String:String]()
        params["fields"] = "id"
        params["limit"] = "500" //assuming there are no more than 500 friends who are also using the app as I haven't got around to do pagination with async fb requests
        
        var friendIds: [String] = []
        
        let fbRequest = FBSDKGraphRequest(graphPath: "me/friends", parameters: params)
        fbRequest.startWithCompletionHandler { (connection: FBSDKGraphRequestConnection!, result: AnyObject!, error: NSError!) -> Void in
            if error != nil {
                NSLog("error in get facebook friends: " + error.localizedDescription)
                completion(friends: nil, error: error)
            } else {
                if (result != nil){
//                    print("facebook friends: \(result)")
                    let result = result as! NSDictionary
                    let data = result["data"] as? [NSDictionary]
                    if let data = data {
                        friendIds = data.map({ (friend) -> String in
                            return friend["id"] as! String
                        })
//                        print("Friend list: \(friendIds)")
                    }
                    completion(friends: friendIds, error: nil)
                }
            }
        }
    }
}
