//
//  Analytics.swift
//  8Yet
//
//  Created by Quan Ding on 11/17/15.
//  Copyright © 2015 EightYet. All rights reserved.
//

import Foundation

open class Analytics {
    enum Event:String {
        case FacebookLogin, WhyFacebookClicked, LocationPermission, NobodyAround, NotificationPermissionFromCardsView,  NotificationPermissionFromInstruction, NotificationPermissionFromNoMoreCards, OnboardingNextBtnClicked, UserMactchReviewOkBtnClicked, UserMatchDidMeet, UserMatchBail, UserMatchMeetAgain, UserSwipe, WhyFacebook, ChatSendMessage, MenuItemClicked, JoinPlan, QuitPlan, CancelPlan, StartCreatePlan, CancelCreatePlan, FinishCreatePlan, UpdatePlan, ViewPlanDetails, ViewProfile, EditBio, EditFavoriteFood, EditFavoriteTopics, ViewOwnProfile, ReportUser, InviteUsers, SystemError
    }
    
    enum UserAttribute: String {
        case Age, Gender
    }
    
    static let sharedInstance = Analytics()
    
    fileprivate var mixPanel:Mixpanel

    init() {
        let configProps = Configuration.sharedInstance
        Appsee.start(configProps.getAppseeApiKey())
        Flurry.startSession(configProps.getFlurryApiKey())
        mixPanel = Mixpanel.sharedInstanceWithToken(configProps.getMixpanelApiKey())
    }
    
    func event(_ name: String) {
        Flurry.logEvent(name)
        mixPanel.track(name)
        Appsee.addEvent(name)
    }
    
    func event(_ name: String, properties: [AnyHashable: Any]!) {
        Flurry.logEvent(name, withParameters: properties)
        mixPanel.track(name, properties: properties)
        Appsee.addEvent(name, withProperties: properties)
    }
    
    func addEventSuperProperties(_ superProperties: [AnyHashable: Any]!) {
        mixPanel.registerSuperProperties(superProperties)
        
    }
    
    func startTimingEvent(_ event: String, properties: [AnyHashable: Any]!) {
        Flurry.logEvent(event, withParameters: properties, timed: true)
        mixPanel.timeEvent(event)
    }
    
    func finishTimingEvent(_ event: String, properties: [AnyHashable: Any]!) {
        Flurry.endTimedEvent(event, withParameters: properties)
        mixPanel.track(event)
    }
    
    func identifyUser(_ userId: String, email: String?) {
        Flurry.setUserID(userId)
        mixPanel.identify(userId)
        mixPanel.people.set("email", to: email ?? "")
        Appsee.setUserID(userId)
    }
    
    func setLocation(_ latitude: Double, longitude: Double, horizontalAccuracy: Float, verticalAccuracy: Float) {
        Flurry.setLatitude(latitude, longitude: longitude, horizontalAccuracy: horizontalAccuracy, verticalAccuracy: verticalAccuracy)
        Appsee.setLocation(latitude, longitude: longitude, horizontalAccuracy: horizontalAccuracy, verticalAccuracy: verticalAccuracy)
    }
    
    func setUserProperty(_ property: String, value: String?) {
        if let value = value {
            mixPanel.people.set(property, to: value)
            if (property == UserAttribute.Gender.rawValue) {
                Flurry.setGender(value)
            }
        }
    }
    
}
