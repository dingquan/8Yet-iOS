//
//  UserMatchViewController.swift
//  8Yet
//
//  Created by Ding, Quan on 3/4/15.
//  Copyright (c) 2015 EightYet. All rights reserved.
//

import UIKit
import CoreLocation
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
fileprivate func <= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l <= r
  default:
    return !(rhs < lhs)
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

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func >= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l >= r
  default:
    return !(lhs < rhs)
  }
}


private let kUserMatchAlert = 0

private let kChatInactive = 0
private let kChatActive = 1

private let kLastFetchNearbyUsersTime = "lastFetchNearbyUsersTime"

class UserMatchViewController: BaseViewController, UIAlertViewDelegate, UIActionSheetDelegate, CLLocationManagerDelegate {
    fileprivate var xDelta: CGFloat!
    fileprivate var yDelta: CGFloat!
    fileprivate var widthDelta: CGFloat!
    fileprivate var cardInitialWidth: CGFloat = 0
    fileprivate var cardInitialHeight: CGFloat = 0
    fileprivate var cardInitialY: CGFloat!
    fileprivate var panTranslationXThreshold: CGFloat! // The minimum x distance to trigger like or dislike action
    fileprivate var stampAlphaTranslationXThreshold: CGFloat! // The minimum x distance at which the like/dislike stampe will have alpha value of 1
    
    fileprivate var locationManager = CLLocationManager()
    fileprivate var nearbyUsers:[User]?
    fileprivate var nearbyUserIndex:Int = 0 // track the index of the user being shown in the top card
    fileprivate var cardViews:[DraggableCardView?] = [nil, nil, nil, nil]
    fileprivate var topCardIndex = 0 // top of the three cards in cardViews
    fileprivate var bottomCardIndex = 0 // bottom of the three cards in cardViews
    fileprivate var matchChat: Chat? // chat object for the matching swipe
    fileprivate var cardInitialCenter: CGPoint!
    fileprivate var tapPointInBottomHalfOfView:Bool!
    fileprivate var translationWhenDraggingEnded: CGPoint = CGPoint.zero
    fileprivate var velocityWhenDraggingEnded: CGFloat = 0
    fileprivate let cardAnimationDuration = 0.5
    fileprivate var likeSwipeCnt = 0
    fileprivate var totalSwipeCnt = 0
    
    fileprivate var screenWidth: CGFloat!
    fileprivate var screenHeight: CGFloat!
    
    fileprivate var framesBeforePan: [CGRect?] = [nil, nil, nil, nil]
    
    fileprivate var needToFetchNearbyUsers = true
    fileprivate var locationAlertShown = false
    
    fileprivate var firebaseHandle: UInt?
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var choiceBtnGrp: UIView!
    
    @IBOutlet weak var noMoreCardsGrp: UIView!
    @IBOutlet weak var notificationBtn: UIButton!
    @IBOutlet weak var notificationLabel: UILabel!
    @IBOutlet weak var notificationBtnHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var notificationBtnWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var notificationBtnBottomConstraint: NSLayoutConstraint!

    @IBOutlet weak var noMoreCardIconTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var noMoreCardIconWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var noMoreCardIconHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var noMoreCardTitle: UILabel!
    @IBOutlet weak var noMoreCardBody1: UILabel!
    @IBOutlet weak var noMoreCardBody2: UILabel!
    @IBOutlet weak var noMoreCardBody1LeftConstraint: NSLayoutConstraint!
    @IBOutlet weak var noMoreCardBody1RightConstraint: NSLayoutConstraint!
    @IBOutlet weak var noMoreCardBody2LeftConstraint: NSLayoutConstraint!
    @IBOutlet weak var noMoreCardBody2RightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var btnGrpBottomContstraint: NSLayoutConstraint!
    @IBOutlet weak var btnGrpHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var btnGrpWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var chatBtn: UIBarButtonItem!
    
    @IBOutlet weak var blockerView: UIView!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.startUpdatingLocation()
        
        noMoreCardsGrp.isHidden = true
        noMoreCardsGrp.alpha = 0
        choiceBtnGrp.isHidden = false
        blockerView.isHidden = true

        ViewHelpers.roundedCorner(notificationBtn, radius: 5)
        
        self.chatBtn.tag = kChatInactive
        
        btnGrpBottomContstraint.constant *= screenSizeMultiplier
        btnGrpWidthConstraint.constant *= screenSizeMultiplier
        btnGrpHeightConstraint.constant *= screenSizeMultiplier
        
        screenWidth = view.bounds.width
        screenHeight = view.bounds.height
        
        cardInitialWidth = ceil(screenWidth * 0.93333) // 350 on iphone6
        cardInitialHeight = ceil(cardInitialWidth * 485 / 350) // 485 on iphone6
        widthDelta = -ceil(screenWidth * 0.03125) // -10 on iphone5
        xDelta = ceil(screenWidth * 0.015625) // 5 on iphone5
        yDelta = ceil(screenWidth * 0.015625) // 5 on iphone5
        panTranslationXThreshold = ceil(screenWidth * 0.28125) // 90 on iphone5
        stampAlphaTranslationXThreshold = ceil(screenWidth * 0.15625) // 50 on iphone5
        cardInitialY = (70 - 64) * screenSizeMultiplier // (distance to top of the screen - status bar (20) - nav bar (44)) * size multipler
        
        NotificationCenter.default.removeObserver(self)
        // UIApplicationDidBecomeActiveNotification will fire when user come back from enable location dialog
        NotificationCenter.default.addObserver(self, selector: #selector(UserMatchViewController.checkLocationService), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(UserMatchViewController.checkRefreshNearbyUsers), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reportUser", name: reportUserNotification, object: nil)
        
        self.activityIndicator.hidesWhenStopped = true

        noMoreCardIconTopConstraint.constant *= screenSizeMultiplier
        noMoreCardIconWidthConstraint.constant *= screenSizeMultiplier
        noMoreCardIconHeightConstraint.constant *= screenSizeMultiplier
        noMoreCardTitle.font = UIFont(name: serifBoldFontName, size: 30 * screenSizeMultiplier)
        noMoreCardTitle.sizeToFit()
        noMoreCardBody1.font = UIFont(name: sansSerifFontName, size: 18 * screenSizeMultiplier)
        noMoreCardBody1.sizeToFit()
        noMoreCardBody1LeftConstraint.constant *= screenSizeMultiplier
        noMoreCardBody1RightConstraint.constant *= screenSizeMultiplier
        noMoreCardBody2LeftConstraint.constant *= screenSizeMultiplier
        noMoreCardBody2RightConstraint.constant *= screenSizeMultiplier
        noMoreCardBody2.font = UIFont(name: sansSerifFontName, size: 18 * screenSizeMultiplier)
        noMoreCardBody2.sizeToFit()
        notificationBtnBottomConstraint.constant *= screenSizeMultiplier
        notificationBtnHeightConstraint.constant *= screenSizeMultiplier
        notificationBtnWidthConstraint.constant *= screenSizeMultiplier
        notificationBtn.titleLabel?.font = UIFont(name: serifMediumFontName, size: 20 * screenSizeMultiplier)
        
        // hide the meet and pass buttons on iPhone4 and iPads as there's no room for them
        let screenBounds = UIScreen.main.bounds
        if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad || screenBounds.width * 480 == screenBounds.height * 320 {
            choiceBtnGrp.isHidden = true
            notificationBtnBottomConstraint.constant = 24
            // make the card even smaller to fit the 3.5 inch screen
            cardInitialWidth *= 0.97
            cardInitialHeight *= 0.97
        }
        
        User.currentUser()?.updateFriendList()
        User.currentUser()?.fetchInBackground() 
        
        // the following two lines is to get rid of the horizontal line below the nav bar
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        
        customizeNavBarTitle()
        
        // somehow I need to explicitly set userInteractionEnabled here. The setting in the storyboard wasn't honored resulting the user interactions to be propergated to the views below, making blockerView ineffective.
        blockerView.isUserInteractionEnabled = true
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // remove listener when not needed to improve performance
        FirebaseService.sharedInstance.removeObserversForUnreadChats(firebaseHandle)
        locationAlertShown = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        checkRefreshNearbyUsers()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        firebaseHandle = FirebaseService.sharedInstance.listenForUnreadChats(updateChatIcon)

        checkLocationService() // call this from viewDidAppear instead of viewDidLoad to get rid of the "Presenting view controllers on detached view controllers is discouraged" warning
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func disableUserInteraction(_ disable: Bool) {
        if disable == true {
            blockerView.isHidden = false
        } else {
            blockerView.isHidden = true
        }
    }
    
    // check to see if nearby users needs to be refetched again
    func checkRefreshNearbyUsers() {
        let refreshUsersInterval:NSNumber = AppProperties.sharedInstance.getPropertyWithDefault("refreshUsersInterval", defaultValue: 1800) as! NSNumber // the interval after which nearby users should be refreshed
        let lastFetchNearbyUserTime = UserDefaults.standard.object(forKey: kLastFetchNearbyUsersTime) as? Date
        if lastFetchNearbyUserTime != nil && abs(lastFetchNearbyUserTime!.timeIntervalSinceNow) > refreshUsersInterval.doubleValue {
            // refetch the nearby users to have fresh data to show
            resetCards()
            self.noMoreCardsGrp.isHidden = true
            self.needToFetchNearbyUsers = true
        }
    }
    
    // check to see if location service is enabled
    func checkLocationService() {
        if !needToFetchNearbyUsers {
            return
        }

        var status = ""
        if CLLocationManager.locationServicesEnabled() {
            let locationAuthStatus = CLLocationManager.authorizationStatus()
            switch locationAuthStatus {
            case .notDetermined:
                status = "NotDetermined"
                // if location service hasn't been requested, load the view to request location service
                let storyboard = UIStoryboard(name: "Permissions", bundle: nil)
                let locationVC = storyboard.instantiateViewController(withIdentifier: "LocationViewController") as! LocationViewController
                self.present(locationVC, animated: true, completion: nil)
            case CLAuthorizationStatus.authorizedWhenInUse:
                status = "AuthorizedWhenInUse"
                fallthrough
            case CLAuthorizationStatus.authorizedAlways:
                // all good, let's fetch the location
                status = "AuthorizedAlways"
                needToFetchNearbyUsers = false
                getUserCurrentLocation()
            case .denied:
                status = "Denied"
                fallthrough
            case .restricted:
                status = "Restricted"
                if !locationAlertShown {
                    let alert:UIAlertView = UIAlertView(title: "Location Service Disabled", message: "Location service turned off.\nPlease go to Settings > Privacy > Location and turn 8Yet back on.", delegate: self, cancelButtonTitle: "OK")
                    // checkLocationService can be called twice: once by notification center and once from ViewDidLoad. We do need it in both places to cover all scenarios
                    // but use this flag to avoid showing the alert twice sometimes which is anoying.
                    alert.show()
                    locationAlertShown = true
                }
            }
        } else {
            if !locationAlertShown {
                // location service is disabled for all apps
                let alert:UIAlertView = UIAlertView(title: "Location Service Disabled", message: "Location service turned off.\nPlease go to Settings > Privacy > Location and turn it back on.", delegate: self, cancelButtonTitle: "OK")
                alert.show()
                locationAlertShown = true
            }
        }
        print("location service status: \(status)")
    }
    
    // MARK: - Actions
    @IBAction func onMenu(_ sender: AnyObject) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: menuTappedNotification), object: self)
    }
    
    @IBAction func onTapCloseMenu(_ sender: UITapGestureRecognizer) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: menuTapCloseNotification), object: self)
    }
    
    fileprivate func resetCards() {
        nearbyUsers = []
        nearbyUserIndex = 0
        for cardView in cardViews {
            if let cardView = cardView {
                cardView.removeFromSuperview()
            }
        }
        // some times I see dangling card views after removing views from cardViews array
        // do another round of sweeping to be sure
        for view in self.view.subviews {
            if view is DraggableCardView {
                view.removeFromSuperview()
            }
        }
        cardViews = [nil, nil, nil, nil]
        topCardIndex = 0
        bottomCardIndex = 0
        likeSwipeCnt = 0
    }
    
    @IBAction func onEnableNotification(_ sender: AnyObject) {
        Analytics.sharedInstance.event(Analytics.Event.NotificationPermissionFromNoMoreCards.rawValue, properties: ["permissionGranted": "yes"])
        NotificationHelper.registerNotification()
    }
    
    @IBAction func onLike(_ sender: AnyObject) {
        if cardViews[topCardIndex] == nil { // no card
            return
        }
        likeSwipeCnt += 1
        totalSwipeCnt += 1
        let oldTopCardView = cardViews[topCardIndex]!
        cardViews[topCardIndex] = nil
        topCardIndex = (topCardIndex + 1) % 4
        
        let fromUser = User.currentUser()!
        let toUser = oldTopCardView.user
        let isSameSex: NSNumber = fromUser.gender == toUser.gender
        Analytics.sharedInstance.event(Analytics.Event.UserSwipe.rawValue, properties: ["like": "yes", "isSameSex": isSameSex.boolValue ? "true" : "false"])

        let animationValues = calculateAnimationValues(sender, isLike: true, startPosition: oldTopCardView.layer.position)
        animateCardAway(oldTopCardView, isLike: true, delay: animationValues.delay, newPosition: animationValues.newPosition, rotation: animationValues.rotation, initialVelocity: animationValues.initialVelocity)
        if User.currentUser()?.objectId != oldTopCardView.user.objectId { // just to be safe. don't save the swipe if fromUser and toUser are the same. shouldn't happen in theory
            let swipe = Swipe(fromUser: fromUser, toUser: toUser, isLike: true, isSameSex: isSameSex)
            swipe.saveInBackgroundWithBlock { (finished, error) -> Void in
                let demoMode = Installation.currentInstallation().demoMode?.boolValue ?? false
                if demoMode {
                    // for demo purpose, automatically match the test users
                    if finished && error == nil {
                        if Installation.currentInstallation().demoMode == true {
                            oldTopCardView.user.fetchIfNeededInBackgroundWithBlock({ (user, error) -> Void in
                                if error == nil {
                                    let user = user as! User
                                    if user.isTestUser() {
                                        let matchingSwipe = Swipe(fromUser: oldTopCardView.user, toUser: User.currentUser()!, isLike: true, isSameSex: isSameSex)
                                        matchingSwipe.saveInBackground()
                                    }
                                }
                            })
                        }
                    }
                }
            }
        }
        insertNewCardAtBottom()
    }
    
    
    @IBAction func onDislike(_ sender: AnyObject) {
        if cardViews[topCardIndex] == nil { // no card
            return
        }
        totalSwipeCnt += 1
        let oldTopCardView = cardViews[topCardIndex]!
        cardViews[topCardIndex] = nil
        topCardIndex = (topCardIndex + 1) % 4
        
        let fromUser = User.currentUser()!
        let toUser = oldTopCardView.user
        let isSameSex: NSNumber = fromUser.gender == toUser.gender
        Analytics.sharedInstance.event(Analytics.Event.UserSwipe.rawValue, properties: ["like": "no", "isSameSex": isSameSex.boolValue ? "true" : "false"])

        let animationValues = calculateAnimationValues(sender, isLike: false, startPosition: oldTopCardView.layer.position)
        animateCardAway(oldTopCardView, isLike: false, delay: animationValues.delay, newPosition: animationValues.newPosition, rotation: animationValues.rotation, initialVelocity: animationValues.initialVelocity)
        
        let swipe = Swipe(fromUser: User.currentUser()!, toUser: oldTopCardView.user, isLike: false, isSameSex: isSameSex)
        swipe.saveInBackgroundWithBlock(nil)
        insertNewCardAtBottom()
    }
    
    // handler for the push notification request alert view
    func alertView(_ alertView: UIAlertView, clickedButtonAt buttonIndex: Int) {
        if (alertView.tag == kUserMatchAlert) {
            if buttonIndex == 1 {
                if let chat = self.matchChat {
                    let chatVC = storyboard!.instantiateViewController(withIdentifier: "ChatViewController") as! ChatViewController
                    chatVC.chat = chat
                    self.navigationController!.pushViewController(chatVC, animated: true)
                }
            }
        }
    }

    func getUserCurrentLocation() {

        self.activityIndicator.startAnimating()
        UserDefaults.standard.set(Date(), forKey: kLastFetchNearbyUsersTime)
        
        User.currentUser()?.saveUserCurrentLocation{(location, error) -> Void in
            print("currentLocation: \(location)")
            if let error = error {
                print(error)
            } else {
                print("finding nearby users")
                self.findNearbyUsers(location)
            }
        }
    }
    
    func findNearbyUsers(_ currentLocation: PFGeoPoint?) {
        if let currentLocation = currentLocation {
            User.currentUser()?.findNearbyActiveUser(currentLocation, completion: { (users, error) -> Void in
                print("findNearbyUsers done")
                self.activityIndicator.stopAnimating()
                if error == nil {
                    if users!.count == 0 {
                        let nobodyVC = self.storyboard!.instantiateViewControllerWithIdentifier("NobodyViewController") as! NobodyViewController
                        self.presentViewController(nobodyVC, animated: true, completion: nil)
                    } else {
                        
                        self.resetCards()
                        self.nearbyUsers = users
                        // populate 3 cards
                        for _ in 1...4 {
                            self.insertNewCardAtBottom()
                        }
                    }
                } else {
                    NSLog("UserMatchViewController->findNearbyUsers failed: " + error!.localizedDescription)
                }
            })
        } else {
            self.activityIndicator.stopAnimating()
            let alert:UIAlertView = UIAlertView(title: "Where are you?", message: "We couldn't get your current location. Please try later", delegate: self, cancelButtonTitle: "OK")
            alert.show()
        }
    }
    
    func onPanGesture(_ panGestureRecognizer: UIPanGestureRecognizer) {
        let cardView = panGestureRecognizer.view! as! DraggableCardView
        let translation = panGestureRecognizer.translation(in: view) //translation is relative to superview
        let point = panGestureRecognizer.location(in: cardView) // point is relative to the cardView
        let velocity = panGestureRecognizer.velocity(in: view)

        switch panGestureRecognizer.state {
        case .began:
            self.translationWhenDraggingEnded = CGPoint.zero
            self.velocityWhenDraggingEnded = 0
            cardInitialCenter = cardView.center
            tapPointInBottomHalfOfView = point.y > (cardView.frame.height / 2)
            for i in 0...3 {
                framesBeforePan[i] = cardViews[i]?.layer.frame
            }
        case .changed:
            var rotation = tenDegrees * (translation.x * 2 / screenWidth)
            if tapPointInBottomHalfOfView != nil && tapPointInBottomHalfOfView! {
                rotation = -rotation
            }
            // can't modify the center or the frame which will mess up with the auto layout constraints. need to modify the layer directly
            cardView.layer.position = CGPoint(x: cardInitialCenter.x + translation.x, y: cardInitialCenter.y + translation.y)
            cardView.layer.transform = CATransform3DMakeRotation(rotation, 0, 0, 1)
//            adjustCardSizesWhenPanning(panGestureRecognizer)
            let alpha = (abs(translation.x) / stampAlphaTranslationXThreshold) < 1 ? (abs(translation.x) / stampAlphaTranslationXThreshold) : 1
            if (translation.x > 0){
                cardView.meetLabel.alpha = alpha
                cardView.passLabel.alpha = 0
            } else {
                cardView.passLabel.alpha = alpha
                cardView.meetLabel.alpha = 0
            }
        case .ended:
            fallthrough
        case .cancelled:
            self.translationWhenDraggingEnded = translation
            // velocity is points per second
            self.velocityWhenDraggingEnded = velocity.x
            if (panGestureRecognizer.state == .cancelled || (translation.x >= -panTranslationXThreshold && translation.x <= panTranslationXThreshold)) {
                // restore the cards if card not moved far enough or pan gesture was cancelled
                self.translationWhenDraggingEnded = CGPoint.zero
                self.velocityWhenDraggingEnded = 0
                self.tapPointInBottomHalfOfView = nil
                // restore the top card
                UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.65, initialSpringVelocity: 0, options: [], animations: { () -> Void in
                    cardView.center = self.cardInitialCenter
                    cardView.transform = CGAffineTransform.identity
                    cardView.passLabel.alpha = 0;
                    cardView.meetLabel.alpha = 0;
                    }, completion: { (finished) -> Void in
                        ();
                })
                
                // restore the bottom cards
                var index = (self.topCardIndex + 1) % 4
                for _ in 1...2 {
                    if let cardView = self.cardViews[index]{
                        cardView.layer.frame = framesBeforePan[index]!
                        index = (index + 1) % 4
                    }
                }
            } else if (translation.x > panTranslationXThreshold){
                onLike(panGestureRecognizer)
            } else if (translation.x < -panTranslationXThreshold) {
                onDislike(panGestureRecognizer)
            }
        default:
            NSLog("unreachable")
        }
    }
    
    func reportUser() {
        //        let toEmail = "8yet@outlook.com"
        //        let subject = "Reporting offensive user/content"
        //        let body = "Please include the details of the user/content that you feel is offensive. We'll investigate and get back to you.\n\n-8Yet? Team"
        //
        //        if let
        //            urlString = ("mailto:\(toEmail)?subject=\(subject)&body=\(body)").stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding),
        //            url = NSURL(string:urlString)
        //        {
        //            UIApplication.sharedApplication().openURL(url)
        //        }
        let actionSheet = UIActionSheet(title: "Report Current User", delegate: self, cancelButtonTitle: "Cancel", destructiveButtonTitle: nil, otherButtonTitles: "Fake Account", "Offensive Content")
        actionSheet.show(in: self.view)
    }
    
    func actionSheet(_ actionSheet: UIActionSheet, clickedButtonAt buttonIndex: Int) {
        print("clicked button index: \(buttonIndex)")
        var reason = ""
        let toUser:User? = cardViews[topCardIndex]?.user
        
        if buttonIndex == 0 { // cancel
            return
        }
        else if let toUser = toUser {
            if buttonIndex == 1 {
                reason = "fake"
            } else if buttonIndex == 2 {
                reason = "offsensive"
            }
            let reportUser = ReportUser(fromUser: User.currentUser()!, toUser: toUser, reason: reason)
            reportUser.saveInBackground()
            let alert:UIAlertView = UIAlertView(title: "Thanks for reporting", message: "We will investigate and suspend/remove the reported user account if there's indeed a violation of our terms and policies.", delegate: self, cancelButtonTitle: "OK")
            alert.show()
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let lastLocation = locations[locations.count-1] // last location is the latest location
        Analytics.sharedInstance.setLocation(lastLocation.coordinate.latitude, longitude: lastLocation.coordinate.longitude, horizontalAccuracy: Float((lastLocation.horizontalAccuracy)), verticalAccuracy: Float((lastLocation.verticalAccuracy)))
        locationManager.stopUpdatingLocation()
    }
    
    // MARK: - Private functions
    
    fileprivate func restoreCardPositions() {
        self.translationWhenDraggingEnded = CGPoint.zero
        self.velocityWhenDraggingEnded = 0
        self.tapPointInBottomHalfOfView = nil
        
        // restore the top card
        cardViews[topCardIndex]?.transform = CGAffineTransform.identity
        cardViews[topCardIndex]?.center = self.cardInitialCenter
        cardViews[topCardIndex]?.passLabel.alpha = 0;
        cardViews[topCardIndex]?.meetLabel.alpha = 0;
        
        // restore the bottom cards
        var index = (self.topCardIndex + 1) % 4
        for _ in 1...2 {
            if let cardView = self.cardViews[index]{
                cardView.layer.frame = framesBeforePan[index]!
                index = (index + 1) % 4
            }
        }
    }
    
    fileprivate func calculateAnimationValues(_ sender: AnyObject, isLike: Bool, startPosition: CGPoint) -> (delay: Double, newPosition: CGPoint, rotation: CGFloat, initialVelocity: CGFloat) {
        
        var delay = 0.2
        if sender is UIPanGestureRecognizer {
            delay = 0
        }
        
        var newPosition = startPosition
        var rotation:CGFloat
        // since the cards are slightly rotated. add extra travel distance 50 to newPosition.x to compensate
        if isLike {
            newPosition.x += self.view.bounds.width + 50
            rotation = tenDegrees
        } else {
            newPosition.x -= self.view.bounds.width + 50
            rotation = -tenDegrees
        }

        if tapPointInBottomHalfOfView != nil && tapPointInBottomHalfOfView! {
            rotation = -rotation
        }
        
        if (self.translationWhenDraggingEnded != CGPoint.zero) { // move the card in the direction when dragging ended
            newPosition.y = self.translationWhenDraggingEnded.y * (newPosition.x - startPosition.x) / self.translationWhenDraggingEnded.x + startPosition.y
        }

        // from the doc: A value of 1 corresponds to the total animation distance traversed in one second. For example, if the total animation distance is 200 points and you want the start of the animation to match a view velocity of 100 pt/s, use a value of 0.5.
        let animationDististance = (newPosition.x - startPosition.x) / CGFloat(self.cardAnimationDuration)
        let initialVelocity = velocityWhenDraggingEnded / animationDististance

        return (delay, newPosition, rotation, initialVelocity)
    }
    
    fileprivate func animateCardAway(_ card: DraggableCardView, isLike: Bool, delay:Double, newPosition: CGPoint, rotation: CGFloat, initialVelocity: CGFloat){
        
        // first animation's duration is the second animation's delay
        UIView.animate(withDuration: delay, animations: { () -> Void in
            if isLike {
                card.meetLabel.alpha = 1
            } else {
                card.passLabel.alpha = 1
            }
            }, completion: { (finished) -> Void in
                if (finished) {
                    UIView.animate(withDuration: self.cardAnimationDuration, delay: delay, usingSpringWithDamping: 1.0, initialSpringVelocity: initialVelocity, options: [], animations: { () -> Void in
                        card.layer.position = newPosition
                        card.layer.transform = CATransform3DMakeRotation(rotation, 0, 0, 1)
                        }, completion: { (isFinished) -> Void in
                            self.removeCardFromView(card)
                            self.translationWhenDraggingEnded = CGPoint.zero
                            self.velocityWhenDraggingEnded = 0
                            self.tapPointInBottomHalfOfView = nil
                            
                            if isLike && self.likeSwipeCnt == 1 && NotificationHelper.pushPermissionNotRequested() == true {
                                let reminderTime = UserDefaults.standard.double(forKey: kNotificationReminderTime)
                                // show vc if reminder hasn't been set or the reminder has expired
                                if reminderTime == 0 || reminderTime < Date().timeIntervalSince1970 {
                                    let storyboard = UIStoryboard(name: "Permissions", bundle: nil)
                                    let vc = storyboard.instantiateViewController(withIdentifier: "NotificationPermissionViewController") as! NotificationPermissionViewController
                                    self.present(vc, animated: true, completion: nil)
                                }
                            }
                    })
                }
        }) 
    }
    
    // NOTE: not used in the v2.0 as only one card is visible now instead of 3 in v1.0
    fileprivate func adjustCardSizes(){
        var width = cardInitialWidth
        let height = cardInitialHeight
        var x: CGFloat = ceil((screenWidth - width) / 2)
        var y: CGFloat = cardInitialY
        
        var index = self.topCardIndex
        for _ in 1...3 {
            if let cardView = self.cardViews[index] {
                // Create the CABasicAnimation for the shadow
                let shadowAnimation = CABasicAnimation(keyPath: "shadowPath")
                shadowAnimation.duration = 0.3
                shadowAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut); // Match the easing of the UIView block animation
                shadowAnimation.fromValue = cardView.layer.shadowPath;
                
                // animate the frame change to the view
                UIView.animate(withDuration: 0.3, animations: { () -> Void in
                    cardView.frame = CGRect(x: x, y: y, width: width, height: height)
                })
                
                // Set the toValue for the animation to the new frame of the view
                shadowAnimation.toValue = UIBezierPath(roundedRect: cardView.layer.bounds, cornerRadius: cardCornerRadius).cgPath
                
                // Add the shadow path animation
                cardView.layer.add(shadowAnimation, forKey: "shadowPath")
                
                // Set the new shadow path
                cardView.layer.shadowPath = UIBezierPath(roundedRect: cardView.layer.bounds, cornerRadius: cardCornerRadius).cgPath
                
                x += self.xDelta
                y += self.yDelta
                width = width + self.widthDelta
                index = (index + 1) % 4
            }
        }
    }
    
    // NOTE: not used in the v2.0 as only one card is visible now instead of 3 in v1.0
    // move the bottom three cards when the top card is being panned
    fileprivate func adjustCardSizesWhenPanning(_ sender: UIPanGestureRecognizer){
        let translation = sender.translation(in: view)
        let pannedDistance = sqrt(pow(translation.x, 2) + pow(translation.y, 2))
        let xDelta: CGFloat = -self.xDelta * min(pannedDistance, stampAlphaTranslationXThreshold) / stampAlphaTranslationXThreshold
        let yDelta: CGFloat = -self.yDelta * min(pannedDistance, stampAlphaTranslationXThreshold) / stampAlphaTranslationXThreshold
        let widthDelta: CGFloat = -self.widthDelta * min(pannedDistance, stampAlphaTranslationXThreshold) / stampAlphaTranslationXThreshold
        
        var index = (self.topCardIndex + 1) % 4
        for _ in 1...2 {
            if let cardView = self.cardViews[index]{
                let x = framesBeforePan[index]!.origin.x + xDelta
                let y = framesBeforePan[index]!.origin.y + yDelta
                let width = framesBeforePan[index]!.width + widthDelta
                let height = framesBeforePan[index]!.height
                cardView.layer.frame = CGRect(x: x, y: y, width: width, height: height)
                index = (index + 1) % 4
            }
        }
        
    }
    
    // populate image and data into the cards
    fileprivate func populateCards(_ numCards: Int, startIndex: Int){
        var cardViewIndex = startIndex
        if let nearbyUsers = nearbyUsers {
            for _ in 0 ..< numCards {
                if nearbyUserIndex >= nearbyUsers.count {
                    NSLog("No more matched users")
                    break;
                }
                let user = nearbyUsers[nearbyUserIndex]
                nearbyUserIndex += 1
                cardViews[cardViewIndex]!.user = user
                cardViewIndex += 1
            }
        }
    }
    
    fileprivate func insertNewCardAtBottom(){
//        adjustCardSizes()
        if nearbyUserIndex >= nearbyUsers?.count {
            NSLog("No more nearby users to create new card.")
            return
        }
        let width = cardInitialWidth
        let height = cardInitialHeight
        let x: CGFloat = (screenWidth - width) / 2
        let y: CGFloat = cardInitialY
        let cardView = DraggableCardView(frame: CGRect(x: x, y: y, width: width, height: height))
        self.cardViews[self.bottomCardIndex] = cardView
        populateCards(1, startIndex: bottomCardIndex)
        // NOTE: insert the card above yes/no button group, activity indicator and noMoreCardGrp. If the design changes, the index needs to be adjusted accordingly. Otherwise blockerView might be at the wrong z-index and not blocking user interactions
        view.insertSubview(cardView, at: 3)
        bottomCardIndex = (bottomCardIndex + 1) % 4
        setPanGestureHandler(cardView)
    }
    
    fileprivate func setPanGestureHandler(_ cardView: DraggableCardView){
        cardView.isUserInteractionEnabled = true
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(UserMatchViewController.onPanGesture(_:)))
        cardView.addGestureRecognizer(panGestureRecognizer)
    }
    
    fileprivate func noMoreCards() -> Bool{
        return cardViews[0] == nil && cardViews[1] == nil && cardViews[2] == nil && cardViews[3] == nil
    }
    
    fileprivate func removeCardFromView(_ cardView: DraggableCardView) {
        cardView.removeFromSuperview()
        if self.noMoreCards(){
            if NotificationHelper.pushPermissionNotRequested() {
                notificationBtn.isHidden = false
                notificationLabel.isHidden = false
            } else {
                notificationBtn.isHidden = true
                notificationLabel.isHidden = true
            }
            self.noMoreCardsGrp.isHidden = false
            UIView.animate(withDuration: 0.3, animations: { () -> Void in
                self.choiceBtnGrp.alpha = 0
                self.noMoreCardsGrp.alpha = 1
                }, completion: { (finished) -> Void in
                    self.choiceBtnGrp.isHidden = true
            })
        }
    }

    fileprivate func updateChatIcon(_ chatsWithNewMsgs: [String]?) {
        if chatsWithNewMsgs?.count > 0 {
            if self.chatBtn.tag == kChatInactive {
                self.chatBtn.tag = kChatActive
                // this is to preserve the color of the bar button icon
                let buttonImage = UIImage(named: "chatActive")?.withRenderingMode(UIImageRenderingMode.alwaysOriginal)
                self.chatBtn.image = buttonImage
            }
        } else {
            if self.chatBtn.tag == kChatActive {
                self.chatBtn.tag = kChatInactive
                let buttonImage = UIImage(named: "chat")?.withRenderingMode(UIImageRenderingMode.alwaysOriginal)
                self.chatBtn.image = buttonImage
            }
        }
    }
    
    // change the font of title to the custom font
    fileprivate func customizeNavBarTitle() {
        let shadow = NSShadow()
        shadow.shadowColor = UIColor.white
        shadow.shadowOffset = CGSize(width: 0, height: 1)
        self.navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName: UIFont(name: serifMediumFontName, size: 17)!, NSShadowAttributeName: shadow, NSForegroundColorAttributeName: UIColor.white]
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
//    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
//
//    }

}
