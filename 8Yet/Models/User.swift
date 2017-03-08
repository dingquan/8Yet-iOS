//
//  User.swift
//  8Yet
//
//  Created by Ding, Quan on 3/3/15.
//  Copyright (c) 2015 EightYet. All rights reserved.
//

import Foundation
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


private let FB_PROFILE_URL = "https://graph.facebook.com/%@/picture?width=200&height=200"

class User: PFUser {
    private static var __once: () = {
            self.registerSubclass()
        }()
    fileprivate static let testUserEmails = ["chloe_ywjcbyl_test@tfbnw.net", "jason_plynrfh_lee@tfbnw.net", "lisa_lgeglyp_leob@tfbnw.net", "alessandra_srpohud_ambrosio@tfbnw.net"]
    
    fileprivate enum Gender {case male, female, other}
    
    override class func initialize() {
        struct Static {
            static var onceToken : Int = 0;
        }
        _ = User.__once
    }
    
    @NSManaged var facebookId:String?
    @NSManaged var birthday:Date?
    @NSManaged var firstName:String?
    @NSManaged var lastName:String?
    @NSManaged var gender:String?
    @NSManaged var locale:String?
    @NSManaged var timezone:NSNumber?
    @NSManaged var about:String?
    @NSManaged var name:String?
    @NSManaged var ageMin:NSNumber?
    @NSManaged var ageMax:NSNumber?
    @NSManaged var bio:String?
    @NSManaged var hometown:String?
    @NSManaged var meeting_for:String?
    @NSManaged var relationship_status:String?
    @NSManaged var verified:NSNumber?
    @NSManaged var lastKnownLocation:PFGeoPoint?
    @NSManaged var numPlansCalled: NSNumber?
    @NSManaged var numPlansJoined: NSNumber?
    @NSManaged var numMatches:NSNumber?
    @NSManaged var numMeets:NSNumber?
    @NSManaged var numBails:NSNumber?
    @NSManaged var numRatings:NSNumber?
    @NSManaged var totalRatingScore:NSNumber?
    @NSManaged var interests:NSArray?
    @NSManaged var favoriteCuisine: NSArray?
    @NSManaged var chatUid: String? // auth uid of firebase chat service
    @NSManaged var friends: [User]?
    @NSManaged var launchCounter: NSNumber?
    
    var todaysPlan: Plan? // today's plan, transient object, not saved on server
    
    var profileImageUrl:String? {
        get {
            let profileImageUrl = String(format: FB_PROFILE_URL, self.facebookId!)
            return profileImageUrl
        }
    }
    
    fileprivate func isValid() -> Bool {
        if self.facebookId == nil || self.firstName == nil || self.lastName == nil {
            return false
        }
        return true
    }
    
    class func loginWithCompletion(_ completion: @escaping (_ user: User?, _ error: NSError?) -> Void){
        FBClient.sharedInstance.loginWithCompletion({(user: User?, error: NSError?) in
            if user == nil {
                NSLog("Uh oh. The user cancelled the Facebook login.")
                completion(user: nil, error: error)
            } else {
                if let user = user {
                    if user.isNew {
                        NSLog("User signed up and logged in through Facebook!")
                        // handle the case where user logged out and logged in as a different user for the first time
                        Installation.currentInstallation().clearOnboardingFlags()
                    } else {
                        NSLog("User logged in through Facebook!")
                    }
                    FBClient.sharedInstance.getLoginUserProfile(user, completion: { (fbuser, error) -> Void in
                        if fbuser!.isValid() {
                            fbuser?.saveInBackgroundWithBlock({ (succeeded: Bool, error: NSError?) -> Void in
                                if succeeded {
                                    NSLog("saving user succeeded.")
                                    Analytics.sharedInstance.identifyUser((fbuser?.objectId)!, email: fbuser?.email)
                                    Analytics.sharedInstance.setUserProperty(Analytics.UserAttribute.Gender.rawValue, value: fbuser?.gender)
                                } else {
                                    if error != nil {
                                        NSLog("failed to save facebook user data" + error!.localizedDescription)
                                    }
                                }
                            })
                            completion(user: fbuser, error: nil)
                        } else {
                            completion(user: nil, error: NSError(domain: "InvalidUser", code: 1000, userInfo: ["user": fbuser!]))
                        }
                    })

                    FirebaseService.sharedInstance.loginFirebaseIfNeeded()
                    Installation.currentInstallation().updateInstallationWithUser()
                }
            }
        })
    }
    
    
    func logout() {
        User.logOut()
        FirebaseService.sharedInstance.logout()
    }
    
    // find nearby users who's opened the app within last 30 minutes
    func findNearbyActiveUser(_ location: PFGeoPoint, completion: @escaping (_ users: [User]?, _ error: NSError?) -> Void) {
        
        PFCloud.callFunctionInBackground("findNearbyActiveUser", withParameters: ["latitude": location.latitude, "longitude": location.longitude]) { (users:AnyObject?, error: NSError?) -> Void in
            if error != nil {
                NSLog("Failed to findNearbyActiveUser: " + error!.localizedDescription)
                completion(users: nil, error: error)
            } else {
                print("number of nearby users: \(users == nil ? 0 : users!.count)")
                if users != nil {
                    let nearbyUsers = users as! [User]?
                    completion(users: nearbyUsers, error: nil)
                }
            }

        }
    }
    
    func saveUserCurrentLocation(_ completion: (_ location: PFGeoPoint?, _ error: NSError?) -> Void) {
        PFGeoPoint.geoPointForCurrentLocationInBackground {
            (geoPoint: PFGeoPoint?, error: NSError?) -> Void in
            if error == nil {
                self.lastKnownLocation = geoPoint
                completion(location: geoPoint, error: error)
                self.saveInBackgroundWithBlock({ (succeeded: Bool, error: NSError?) -> Void in
                    if succeeded {
                        NSLog("user current location successfully saved")
                    } else {
                        NSLog("error while saving user location: \(error?.localizedDescription)")
                    }
                })
                if let geo = geoPoint {
                    let userLocation = UserLocation(user: self, geo: geo)
                    userLocation.saveInBackground()
                }
            } else {
                NSLog("Failed to get current location of the user. \(error)")
                completion(location: nil, error: error)
            }
        }
    }

    func updateFriendList() {
        FBClient.sharedInstance.updateFriendList { (friends, error) -> Void in
            if (error != nil) {
                NSLog("Error saving friend list: \(error)")
            } else if friends != nil {
                PFCloud.callFunctionInBackground("saveFriendList", withParameters: ["friendIds": friends!.joinWithSeparator(",")]) { (response: AnyObject?, error: NSError?) -> Void in
                    if error != nil {
                        NSLog("Failed to save friend list: " + error!.localizedDescription)
                    } else {
                        NSLog("saveFriendList success")
                    }
                    
                }
            }
        }
    }
    
    // get common friends between self and given user
    func getCommonFriends(_ user: User, completion: @escaping (_ users: [User], _ error: NSError?) -> Void) {
        var commonFriends: [User] = []

        if (self.friends?.count > 0 && user.friends?.count > 0) {
            let friendIds = self.friends!.map({ (aFriend) -> String in
                return aFriend.objectId!
            })
            
            for friend in user.friends! {
                if friendIds.contains(friend.objectId!) {
                    commonFriends.append(friend)
                }
            }
        }

        // fetch the user data for common friends in background in case full data is not available
        // to avoid crashes later on
        User.fetchAllIfNeededInBackground(commonFriends) { (friends, error) -> Void in
            if error != nil {
                print("Error fetching commong friends: \(error)")
            } else {
                completion(users: friends as! [User], error: error)
            }
        }
    }
    
    func getCommonFriends(_ user: User) -> [User] {
        var commonFriends: [User] = []
        
        if (self.friends?.count > 0 && user.friends?.count > 0) {
            let friendIds = self.friends!.map({ (aFriend) -> String in
                return aFriend.objectId!
            })
            
            for friend in user.friends! {
                if friendIds.contains(friend.objectId!) {
                    commonFriends.append(friend)
                }
            }
        }
        return commonFriends
    }
    
    func getCommonInterests(_ user: User) -> [String] {
        var commonInterests: [String] = []
        if (self.interests?.count > 0 && user.interests?.count > 0) {
            let myInterests = self.interests as! [String]
            let userInterests = user.interests as! [String]
            for interest in userInterests {
                if myInterests.contains(interest) {
                    commonInterests.append(interest)
                }
            }
        }
        return commonInterests
    }
    
    func isTestUser() -> Bool {
        if let email = email {
            return User.testUserEmails.indexOf(email) != nil
        } else {
            return false
        }
    }
}
