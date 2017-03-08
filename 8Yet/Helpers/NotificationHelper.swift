//
//  NotificationHelper.swift
//  8Yet
//
//  Created by Quan Ding on 7/9/15.
//  Copyright (c) 2015 EightYet. All rights reserved.
//

import Foundation

enum NotificationActions:String {
    case yes = "USER_MATCH_MEET_YES"
    case no = "USER_MATCH_MEET_NO"
}

enum NotificationCategories:String {
    case userMatchReview = "USER_MATCH_REVIEW"
}

class NotificationHelper {
    
    class func registerNotification() {
        let application = UIApplication.sharedApplication()
        if #available(iOS 8.0, *) {
            let userNotificationTypes: UIUserNotificationType = [UIUserNotificationType.Alert, UIUserNotificationType.Badge, UIUserNotificationType.Sound]
            let notificationCategories = getNotificationCategories()
            let settings = UIUserNotificationSettings(forTypes: userNotificationTypes, categories: Set(notificationCategories))
            application.registerUserNotificationSettings(settings)
            application.registerForRemoteNotifications()

        } else {
            // Fallback on earlier versions
            let types: UIRemoteNotificationType = [UIRemoteNotificationType.Badge, UIRemoteNotificationType.Alert, UIRemoteNotificationType.Sound, UIRemoteNotificationType.NewsstandContentAvailability]
            application.registerForRemoteNotificationTypes(types)
        }
    }
    
    class func pushPermissionNotRequested() -> Bool {
        if #available(iOS 8.0, *) {
            let types = UIApplication.sharedApplication().currentUserNotificationSettings()?.types
            if types == UIUserNotificationType.None {
                return true
            }
        } else {
            // Fallback on earlier versions
            let types = UIApplication.sharedApplication().enabledRemoteNotificationTypes()
            if types == UIRemoteNotificationType.None {
                return true
            }
        }
        return false
    }
    
    class func pushNotificationEnabled() -> Bool {
        if #available(iOS 8.0, *) {
            let types = UIApplication.sharedApplication().currentUserNotificationSettings()?.types
            if types == UIUserNotificationType.None {
                return false
            }
        } else {
            // Fallback on earlier versions
            let types = UIApplication.sharedApplication().enabledRemoteNotificationTypes()
            if types == UIRemoteNotificationType.None {
                return false
            }
        }

        return true
    }
    
    @available(iOS 8.0, *)
    fileprivate class func getNotificationCategories() -> [UIUserNotificationCategory] {
        // 1. Create the actions **************************************************
        
        // yes Action to the unreviewed UserMatch local notification
        let yesAction = UIMutableUserNotificationAction()
        yesAction.identifier = NotificationActions.yes.rawValue
        yesAction.title = "Yes"
        yesAction.activationMode = UIUserNotificationActivationMode.Foreground
        yesAction.authenticationRequired = true
        yesAction.destructive = false
        
        // no Action to the unreviewed UserMatch local notification
        let noAction = UIMutableUserNotificationAction()
        noAction.identifier = NotificationActions.no.rawValue
        noAction.title = "No"
        noAction.activationMode = UIUserNotificationActivationMode.Foreground
        noAction.authenticationRequired = true
        noAction.destructive = false
        
        
        // 2. Create the category ***********************************************
        
        // Category
        let userMatchReviewCategory = UIMutableUserNotificationCategory()
        userMatchReviewCategory.identifier = NotificationCategories.userMatchReview.rawValue
        
        // A. Set actions for the default context
        userMatchReviewCategory.setActions([yesAction, noAction], forContext: UIUserNotificationActionContext.Default)
        
        // B. Set actions for the minimal context
        userMatchReviewCategory.setActions([yesAction, noAction], forContext: UIUserNotificationActionContext.Minimal)
        
        return [userMatchReviewCategory]
    }
}
