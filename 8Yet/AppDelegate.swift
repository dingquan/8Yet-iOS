//
//  AppDelegate.swift
//  8Yet
//
//  Created by Ding, Quan on 3/2/15.
//  Copyright (c) 2015 EightYet. All rights reserved.
//

import UIKit

import Fabric
import Crashlytics
import GoogleMaps
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


let serifBoldFontName = "GeometricSlab703BT-Bold"
let serifMediumFontName = "GeometricSlab703BT-Medium"
let sansSerifFontName = "HelveticaNeue"
let sansSerifBoldFontName = "HelveticaNeue-Bold"
let sansSerifItalicFontName = "HelveticaNeue-Italic"
let scriptBoldFontName = "SegoePrint-Bold"
let scriptFontName = "SegoePrint"

let screenSizeMultiplier = UIScreen.main.bounds.width / 375

let USER_MATCH_ID = "userMatchId"

private let kLastLeaveAppTime = "lastLeaveAppTime"
private let kOutstandingUserReviews = "outstandingUserReviews"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let configProps = Configuration.sharedInstance
    
    fileprivate var firebaseHandle: UInt?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        setupParse(application, launchOptions:launchOptions)

        Fabric.with([Crashlytics()])
        Analytics.sharedInstance // initialize all analytics tools
        GMSServices.provideAPIKey(configProps.getGoogleMapsApiKey())
        
        if let launchOptions = launchOptions {
            let notificationPayload = launchOptions[UIApplicationLaunchOptionsKey.remoteNotification] as? NSDictionary
            if let notificationPayload = notificationPayload {
                clearNotificationBadge()
                print("launch with option: \(notificationPayload)")
            }

            let payload = launchOptions[UIApplicationLaunchOptionsKey.localNotification] as? UILocalNotification
            if let notification = payload {
                print("launched with local notification: \(notification)")
            }
        }
        
        if let user = User.currentUser() {
            user.launchCounter = (user.launchCounter ?? 0).integerValue + 1
            user.saveInBackgroundWithBlock({ (success, error) -> Void in
                if success {
                    user.fetchIfNeededInBackground()
                }
            })
        }
        
        SVProgressHUD.setDefaultAnimationType(SVProgressHUDAnimationType.Native)
        SVProgressHUD.setDefaultStyle(SVProgressHUDStyle.Custom)
        SVProgressHUD.setBackgroundColor(UIColor.darkGrayColor())
        SVProgressHUD.setForegroundColor(UIColor.whiteColor())
        
        application.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
        
        // change navigation UIBarButtonItem font
        UIBarButtonItem.appearance()
            .setTitleTextAttributes([NSFontAttributeName : UIFont(name: serifMediumFontName, size: 15)!],
                for: UIControlState())
        UIBarButtonItem.appearance().setBackButtonTitlePositionAdjustment(UIOffset(horizontal: 6, vertical: 0), for: UIBarMetrics.default)
        
        AppProperties.sharedInstance.refreshProperties()
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        FirebaseService.sharedInstance.removeObserversForNewUserMatches(firebaseHandle)
        UserDefaults.standard.set(Date(), forKey: kLastLeaveAppTime)
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        AppProperties.sharedInstance.refreshProperties()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        FBSDKAppEvents.activateApp()
        clearNotificationBadge()
        checkNetworkConnection()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(application,
            openURL: url,
            sourceApplication: sourceApplication,
            annotation: annotation)
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("Successfully registered notification")
        let currentInstallation = Installation.currentInstallation()
        currentInstallation.setDeviceTokenFromData(deviceToken)
        currentInstallation.channels = ["global"]
        currentInstallation.saveInBackgroundWithBlock { (isSuccessful: Bool, error:NSError?) -> Void in
            if error != nil {
                NSLog("error in saving installation: \(error)")
            } else {
                NSLog("Successfully saved ParseInstallation")
            }
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        if error.code == 3010 {
            print("Push notifications are not supported in the iOS Simulator.")
        } else {
            print("application:didFailToRegisterForRemoteNotificationsWithError: %@", error)
        }
    }
    
//    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
//        if let userInfo = notification.userInfo {
//            let category = userInfo["category"] as? String
//            if category == NotificationCategories.userMatchReview.rawValue {
//                if let userInfo = notification.userInfo {
//                    let userMatchId = userInfo[USER_MATCH_ID] as? String
//                    self.clearOutstandingUserReview(userMatchId)
//                    print("received local notification for user match: \(userMatchId)")
//                    UserMatch.getUserMatchById(userMatchId, completion: { (userMatch, error) -> Void in
//                        if let userMatch = userMatch {
//                            NSNotificationCenter.defaultCenter().postNotificationName(userMatchReviewNotification, object: userMatch)
//                        } else {
//                            if error != nil {
//                                print("Failed to fetch UserMatch with id: \(userMatchId): \(error)")
//                            }
//                        }
//                    })
//                }
//            }
//        }
//    }
    
    fileprivate func clearOutstandingUserReview(_ userMatchId: String?) {
        NSLog("clear outstanding user review for userMatchId: \(userMatchId)")
        if let userMatchId = userMatchId {
            let outstandingUserReviews = getOutstandingUserReviews()
            outstandingUserReviews.removeObject(forKey: userMatchId)
            UserDefaults.standard.set(outstandingUserReviews, forKey: kOutstandingUserReviews)
        }
    }
    
    fileprivate func clearAllOutstandingUserReview() {
        UserDefaults.standard.removeObject(forKey: kOutstandingUserReviews)
    }

//    func application(application: UIApplication, handleActionWithIdentifier identifier: String?, forLocalNotification notification: UILocalNotification, completionHandler: () -> Void) {
//        if let userInfo = notification.userInfo {
//            let category = userInfo["category"] as? String
//            if category == NotificationCategories.userMatchReview.rawValue {
//                let userMatchId = userInfo[USER_MATCH_ID] as? String
//                self.clearOutstandingUserReview(userMatchId)
//                UserMatch.getUserMatchById(userMatchId, completion: { (userMatch, error) -> Void in
//                    if let userMatch = userMatch {
//                        let action = NotificationActions(rawValue: identifier!)!
//                        switch action {
//                        case .yes:
//                            userMatch.didMeet = true
//                        case .no:
//                            userMatch.didMeet = false
//                        }
//                        NSNotificationCenter.defaultCenter().postNotificationName(userMatchReviewNotification, object: userMatch)
//                    } else {
//                        if error != nil {
//                            print("Failed to fetch UserMatch with id: \(userMatchId): \(error)")
//                        }
//                    }
//                    completionHandler()
//                })
//            } else {
//                completionHandler()
//            }
//        } else {
//            completionHandler()
//        }
//    }

    // NOT used anymore as of issue #9. background service is not reliable as all as we've found out in many instances that the OS doesn't wake up the app at all after installation
//    func application(application: UIApplication, performFetchWithCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
//        UserMatch.findUnreviewedMatches { (userMatches :[UserMatch]!, error: NSError?) -> Void in
//            if error != nil {
//                completionHandler(.NoData)
//            } else if userMatches.count > 0 {
//                self.sentUnreviewedMatchNotification(userMatches)
//                completionHandler(.NewData)
//            } else {
//                completionHandler(.NoData)
//            }
//        }
//    }
    
    fileprivate func checkForUnreviewedMatches() {
        UserMatch.findUnreviewedMatches { (userMatches :[UserMatch]!, error: NSError?) -> Void in
            print("unreviewed userMatch count: \(userMatches.count)")
            if error != nil {
                print("Error getting unreviewed matches: \(error)")
            } else if userMatches.count > 0 {
                self.sentUnreviewedMatchNotification(userMatches)
            }
        }
    }
    
    fileprivate func sentUnreviewedMatchNotification(_ userMatches: [UserMatch]) {
        let outstandingUserReviews = self.getOutstandingUserReviews()
        for userMatch in userMatches {
            if outstandingUserReviews.objectForKey(userMatch.objectId!) == nil { // only prompt again if it hasn't been prompted
                NSLog("Hasn't prompted review for user match id=\(userMatch.objectId!)")
                self.displayUserReviewLocalNotification(userMatch)
                outstandingUserReviews.setValue(true, forKey: userMatch.objectId!)
                Installation.currentInstallation().saveInBackground() //update the badge number in Parse Installation
            } else {
                NSLog("Already prompted review for user match id=\(userMatch.objectId!)")
            }
        }
        UserDefaults.standard.set(outstandingUserReviews, forKey: kOutstandingUserReviews)
    }
    
    // NOTE: NOT Thread-safe
    fileprivate func getOutstandingUserReviews() -> NSMutableDictionary {
        let outstandingUserReviews = UserDefaults.standard.object(forKey: kOutstandingUserReviews) as? NSDictionary
        if outstandingUserReviews == nil {
            return NSMutableDictionary()
        } else {
            return NSMutableDictionary(dictionary: outstandingUserReviews!)
        }
    }
    
    fileprivate func displayUserReviewLocalNotification(_ userMatch: UserMatch) {
        let notification = UILocalNotification()
        notification.fireDate = Date(timeIntervalSinceNow: 0)
        notification.timeZone = Calendar.current.timeZone
        notification.soundName = UILocalNotificationDefaultSoundName
        let firstName = userMatch.toUser.firstName ?? ""
        notification.alertBody = "Did you meet \(firstName) for lunch?"
        notification.category = NotificationCategories.userMatchReview.rawValue
        /* Action settings */
        notification.hasAction = true
        notification.alertAction = "View"
        /* Badge settings */
        Installation.currentInstallation().badge += 1// increment the badge number
        notification.applicationIconBadgeNumber = Installation.currentInstallation().badge
        print("notification badge number \(Installation.currentInstallation().badge)")
        /* Additional information, user info */
        notification.userInfo = ["category": NotificationCategories.userMatchReview.rawValue, USER_MATCH_ID: userMatch.objectId!]
        /* Schedule the notification */
        UIApplication.shared.scheduleLocalNotification(notification)
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        print("receive remote notification: \(userInfo)")
        if application.applicationState == UIApplicationState.inactive {
            PFAnalytics.trackAppOpenedWithRemoteNotificationPayloadInBackground(userInfo, block: nil)
        }
        
        let type = userInfo["type"] as? String
        let contentAvailable = userInfo["aps"]?["content-available"] as? Int
        
        if contentAvailable == 1 { // silent notifications
            if let type = type {
                switch (type) {
                case "USER_REVIEW":
                    // NOTE: the notification payload should have "content-avaiable" set to 1 so this becomes a silent remote notification. Then we'll check to see if the user do  have unreviewed user matches and present local notifications if so
                    UserMatch.findUnreviewedMatches { (userMatches :[UserMatch]!, error: NSError?) -> Void in
                        if error != nil {
                            completionHandler(.noData)
                        } else if userMatches?.count > 0 {
                            self.sentUnreviewedMatchNotification(userMatches)
                            completionHandler(.newData)
                        } else {
                            completionHandler(.noData)
                        }
                    }
                default:
                    completionHandler(.noData)
                }
            }
        } else {
            // only clear badges for non-background fetch type of notifications
            clearNotificationBadge()
            if let type = type {
                switch (type) {
                case "QUIT_PLAN":
                    // silently consume the notification. don't let the default parse notification handler handle it as it will display a popup
                    // the alert popup is handled by lisening for firebase event so that the UserMatch alert works with or without notification enabled.
                    ();
                case "NEW_CHAT_MSG":
                    // silently consume the notification. don't let the default parse notification handler handle it as it will display a popup
                    // the alert popup is handled by lisening for firebase event so that the new message alert works with or without notification enabled.
                    ();
                default:
                    // let the default handler handle other types of notifications
                    PFPush.handlePush(userInfo)
                }
            } else {
                // let the default handler handle other types of notifications
                PFPush.handlePush(userInfo)
            }
            
            completionHandler(UIBackgroundFetchResult.newData)
        }
    }
    
    fileprivate func setupParse(_ application: UIApplication, launchOptions: [AnyHashable: Any]?) {
        User.registerSubclass()
        Swipe.registerSubclass()
        Chat.registerSubclass()
        Contact.registerSubclass()
        ReportUser.registerSubclass()
        Installation.registerSubclass()
        Plan.registerSubclass()
        Location.registerSubclass()
        UserLocation.registerSubclass()

        NSLog("configuration: \(configProps.getConfiguration())")
        NSLog("parseAppId: \(configProps.getParseAppId())")
        NSLog("parseClientKey: \(configProps.getParseClientKey())")
        Parse.setApplicationId(configProps.getParseAppId(), clientKey: configProps.getParseClientKey())
        PFFacebookUtils.initializeFacebookWithApplicationLaunchOptions(launchOptions)
        
        trackAppPushOpen(application, launchOptions: launchOptions)
        setupParsePush(application)
    }

    fileprivate func trackAppPushOpen(_ application: UIApplication, launchOptions: [AnyHashable: Any]?)  -> Void {
        if application.applicationState != UIApplicationState.background {
            // Track an app open here if we launch with a push, unless
            // "content_available" was used to trigger a background push (introduced in iOS 7).
            // In that case, we skip tracking here to avoid double counting the app-open.
            
            let preBackgroundPush = !application.responds(to: #selector(getter: UIApplication.backgroundRefreshStatus))
            let oldPushHandlerOnly = !self.responds(to: #selector(UIApplicationDelegate.application(_:didReceiveRemoteNotification:fetchCompletionHandler:)))
            var pushPayload = false
            if let options = launchOptions {
                pushPayload = options[UIApplicationLaunchOptionsKey.remoteNotification] != nil
            }
            if (preBackgroundPush || oldPushHandlerOnly || pushPayload) {
                PFAnalytics.trackAppOpenedWithLaunchOptionsInBackground( launchOptions, block: nil)
            }
        }
    }
    
//    func onLoginCompletion(notification: NSNotification) {
//        // need to register the listener again on user login
//        // the call in applicationDidBecomeActive on first launch after app install
//        // would have failed because user hasn't logged in yet
//        listenForNewUseMatch()
//    }
    
    // listen for new UserMatch since last time user left the app (app went to background)
//    private func listenForNewUseMatch() {
//        // lastLeaveAppTime is set in applicationDidEnterBackground
//        var lastLeaveAppTime = NSUserDefaults.standardUserDefaults().objectForKey(kLastLeaveAppTime) as? NSDate
//        if lastLeaveAppTime == nil {
//            lastLeaveAppTime = NSDate()
//        }
//        FirebaseService.sharedInstance.removeObserversForNewUserMatches(firebaseHandle)
//        firebaseHandle = FirebaseService.sharedInstance.listenForNewUserMatches(lastLeaveAppTime, completion: { (userMatch, error) -> Void in
//            if error != nil {
//                print("Error in listenForNewUserMatches: \(error)")
//            } else {
//                if let userMatch = userMatch {
//                    NSNotificationCenter.defaultCenter().postNotificationName(userMatchNotification, object: userMatch)
//                }
//            }
//        })
//    }
    
    // request user to allow push notifications
    func setupParsePush(_ application: UIApplication) {
        // update the installation table with whether notification is enabled
        let installation = Installation.currentInstallation()
        installation.notificationEnabled = NotificationHelper.pushNotificationEnabled()
        installation.saveInBackgroundWithBlock(nil)
        
        // defer the push setup if we haven't asked user for push permission yet
        if NotificationHelper.pushPermissionNotRequested() {
            return;
        }
        
        NotificationHelper.registerNotification()
    }
    
    fileprivate func clearNotificationBadge() {
        let currentInstallation = Installation.currentInstallation()
        if currentInstallation.badge != 0 {
            currentInstallation.badge = 0
            currentInstallation.saveEventually(nil)
            // need to clear all outstanding user review record as well because the notification has been cleared and user loses the entry point to the review screen
            clearAllOutstandingUserReview()
        }
    }
    
    fileprivate func checkNetworkConnection() {
        if !hasConnectivity() {
            let alert:UIAlertView = UIAlertView(title: "You've got zero bars", message: "Please check your network connection.", delegate: self, cancelButtonTitle: "OK")
            alert.show()
        }
    }
    
    fileprivate func hasConnectivity() -> Bool {
        let reachability: Reachability = Reachability.reachabilityForInternetConnection()
        let networkStatus = reachability.currentReachabilityStatus() // reachability.currentReachabilityStatus().value
        return networkStatus != NetworkStatus.NotReachable
    }
}

