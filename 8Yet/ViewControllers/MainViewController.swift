//
//  MainViewController.swift
//  8Yet
//
//  Created by Quan Ding on 1/27/16.
//  Copyright © 2016 EightYet. All rights reserved.
//

import UIKit
import CoreLocation

private let kChatInactive = 0
private let kChatActive = 1

private let kLastFetchNearbyPlansTime = "lastFetchNearbyPlansTime"

private let kIdentifierMyPlanCell = "myPlanCell"
private let kIdentifierNewPlanCell = "newPlanCell"
private let kIdentifierNearbyPlansCell = "nearbyPlansCell"
private let kIdentifierNoPlansCell = "noPlansCell"

class MainViewController: BaseViewController, UIAlertViewDelegate, CLLocationManagerDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, NewPlanCollectionViewCellDelegate, NearbyPlansCollectionViewCellDelegate, MyPlanCollectionViewCellDelegate, NoPlanNearbyCollectionViewCellDelegate, FBSDKAppInviteDialogDelegate {
    
    fileprivate var locationManager = CLLocationManager()
    
    fileprivate var screenWidth: CGFloat!
    fileprivate var screenHeight: CGFloat!
    
    fileprivate var needToFetchLocation = true
    fileprivate var locationAlertShown = false
    
    fileprivate var firebaseService = FirebaseService.sharedInstance
    fileprivate var firebaseHandle: UInt?
    
    fileprivate var nearbyPlans = [Plan]()
    
    fileprivate var refreshControl: UIRefreshControl!
    
    @IBOutlet weak var plansCollection: UICollectionView!
    @IBOutlet weak var blockerView: UIView!
    
    fileprivate var myPlanSizingCell: MyPlanCollectionViewCell!
    fileprivate var newPlanSizingCell: NewPlanCollectionViewCell!
    fileprivate var nearbyPlansSizingCell: NearbyPlansCollectionViewCell!
    fileprivate var noPlansSizingCell: NoPlanNearbyCollectionViewCell!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.startUpdatingLocation()
        
        blockerView.isHidden = true
        
        screenWidth = view.bounds.width
        screenHeight = view.bounds.height
        
        let myPlanCellNib = UINib(nibName: "MyPlanCollectionViewCell", bundle: nil)
        plansCollection.register(myPlanCellNib, forCellWithReuseIdentifier: kIdentifierMyPlanCell)
        let newPlanCellNib = UINib(nibName: "NewPlanCollectionViewCell", bundle: nil)
        plansCollection.register(newPlanCellNib, forCellWithReuseIdentifier: kIdentifierNewPlanCell)
        let nearbyPlansCellNib = UINib(nibName: "NearbyPlansCollectionViewCell", bundle: nil)
        plansCollection.register(nearbyPlansCellNib, forCellWithReuseIdentifier: kIdentifierNearbyPlansCell)
        let noPlansCellNib = UINib(nibName: "NoPlanNearbyCollectionViewCell", bundle: nil)
        plansCollection.register(noPlansCellNib, forCellWithReuseIdentifier: kIdentifierNoPlansCell)
        
        // get a cell as template for sizing, the NIB file should contain only one top level view (retrived at index 0)
        myPlanSizingCell = myPlanCellNib.instantiate(withOwner: nil, options: nil)[0] as! MyPlanCollectionViewCell
        newPlanSizingCell = newPlanCellNib.instantiate(withOwner: nil, options: nil)[0] as! NewPlanCollectionViewCell
        nearbyPlansSizingCell = nearbyPlansCellNib.instantiate(withOwner: nil, options: nil)[0] as! NearbyPlansCollectionViewCell
        noPlansSizingCell = noPlansCellNib.instantiate(withOwner: nil, options: nil)[0] as! NoPlanNearbyCollectionViewCell

        NotificationCenter.default.removeObserver(self)
        // UIApplicationDidBecomeActiveNotification will fire when user come back from enable location dialog
        NotificationCenter.default.addObserver(self, selector: #selector(MainViewController.checkTodaysPlan), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MainViewController.checkRefreshNearbyPlans), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MainViewController.onCRUDPlanNotification(_:)), name: NSNotification.Name(rawValue: createPlanNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MainViewController.onCRUDPlanNotification(_:)), name: NSNotification.Name(rawValue: updatePlanNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MainViewController.onCRUDPlanNotification(_:)), name: NSNotification.Name(rawValue: joinPlanNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MainViewController.onCRUDPlanNotification(_:)), name: NSNotification.Name(rawValue: quitPlanNotification), object: nil)
        
        User.currentUser()?.updateFriendList()
        User.currentUser()?.fetchInBackground()
        
        // the following two lines is to get rid of the horizontal line below the nav bar
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        
        customizeNavBar()
        
        // somehow I need to explicitly set userInteractionEnabled here. The setting in the storyboard wasn't honored resulting the user interactions to be propergated to the views below, making blockerView ineffective.
        blockerView.isUserInteractionEnabled = true
        
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(MainViewController.refreshPlans), for: UIControlEvents.valueChanged)
        self.plansCollection.insertSubview(refreshControl, at: 0)
        self.plansCollection.alwaysBounceVertical = true
        
        checkTodaysPlan()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // remove listener when not needed to improve performance
        firebaseService.removeObserversForUnreadChats(firebaseHandle)
        for nearbyPlan in self.nearbyPlans {
            firebaseService.removeObserverForPlanUpdates(nearbyPlan)
        }
        if let myPlan = User.currentUser()?.todaysPlan {
            firebaseService.removeObserverForPlanUpdates(myPlan)
        }
        locationAlertShown = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkRefreshNearbyPlans()
        listenForMyPlanChanges()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Plans
    func checkTodaysPlan() {
        if !self.refreshControl.isRefreshing {
            SVProgressHUD.show()
        }
        Plan.findMyTodaysPlan { (plan, error) -> Void in
            SVProgressHUD.dismiss()
            self.refreshControl.endRefreshing()

            if error != nil {
                NSLog("MainViewController->checkTodaysPlan failed: " + error!.localizedDescription)
            }
            
            User.currentUser()?.todaysPlan = plan
            self.plansCollection.reloadSections(IndexSet(integer: 0))
            // need to listen for changes again in addition to the call in viewDidLoad since the plan is now available
            self.listenForMyPlanChanges()
            
            // fetch the plan first before fetch nearby plans (called by checkLocationService)
            // as we need data from nextPlan to render nearby plans
            if self.needToFetchLocation {
                self.checkLocationService()
            } else {
                self.findNearbyPlans(User.currentUser()?.lastKnownLocation)
            }
        }
    }
    
    // check to see if nearby lunch calls needs to be refetched again
    func checkRefreshNearbyPlans() {
        let refreshPlansInterval:NSNumber = AppProperties.sharedInstance.getPropertyWithDefault("refreshPlansInterval", defaultValue: 1800) as! NSNumber // the interval after which nearby users should be refreshed
        let lastFetchNearbyPlansTime = UserDefaults.standard.object(forKey: kLastFetchNearbyPlansTime) as? Date
        if lastFetchNearbyPlansTime != nil && abs(lastFetchNearbyPlansTime!.timeIntervalSinceNow) > refreshPlansInterval.doubleValue {
            // refetch the nearby users to have fresh data to show
            self.needToFetchLocation = true
        }
    }
    
    func findNearbyPlans(_ currentLocation: PFGeoPoint?) {
        if let currentLocation = currentLocation {
            SVProgressHUD.show()
            Plan.findNearbyPlans(currentLocation, completion: { (plans, error) -> Void in
                SVProgressHUD.dismiss()
                if error == nil {
                    self.nearbyPlans = plans.filter({ (plan: Plan) -> Bool in
                        return plan.objectId != User.currentUser()?.todaysPlan?.objectId
                    })
                    
                    for index in 0 ..< self.nearbyPlans.count {
                        let plan = self.nearbyPlans[index]
                        self.firebaseService.removeObserverForPlanUpdates(plan)
                        self.firebaseService.listenForPlanUpdates(plan, completion: { (error) -> Void in
                            if error == nil {
                                plan.getPlanDetails({ (fetchedPlan, error) -> Void in
                                    if let fetchedPlan = fetchedPlan {
                                        if let itemIdx = self.findMatchPlanIndex(fetchedPlan) {
                                            let indexPath = NSIndexPath(forItem: itemIdx, inSection: 1)
                                            self.nearbyPlans[itemIdx] = fetchedPlan
                                            let cell = self.plansCollection.cellForItemAtIndexPath(indexPath)
                                            if let _ = cell { // invisible cells will be nil
                                                self.plansCollection.reloadItemsAtIndexPaths([indexPath])
                                            }
                                        }
                                    } else if error != nil {
                                        NSLog("error while getting plan details: \(error)")
                                    }

                                })
                            }
                        })
                    }
                    
                    if self.plansCollection.numberOfSections() > 0 {
                        // only reload section 2 to avoid flickering of section 1
                        self.plansCollection.reloadSections(NSIndexSet(index: 1))
                    } else {
                        self.plansCollection.reloadData()
                    }
                } else {
                    NSLog("MainViewController->findNearbyPlans failed: " + error!.localizedDescription)
                }
            })
        } else {
            let alert:UIAlertView = UIAlertView(title: "Where are you?", message: "We couldn't get your current location. Please try later", delegate: self, cancelButtonTitle: "OK")
            alert.show()
        }
    }
    
    func refreshPlans() {
        checkTodaysPlan()
    }
    
    // MARK: - Location service
    // check to see if location service is enabled
    func checkLocationService() {
        if !needToFetchLocation {
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
                needToFetchLocation = false
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
    
    func getUserCurrentLocation() {
        UserDefaults.standard.set(Date(), forKey: kLastFetchNearbyPlansTime)
        
        User.currentUser()?.saveUserCurrentLocation{(location, error) -> Void in
            if let error = error {
                print(error)
            } else {
                self.findNearbyPlans(location)
            }
        }
    }

    // MARK: - Actions
    func onMenu(_ sender: AnyObject) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: menuTappedNotification), object: self)
    }
    
    @IBAction func onTapCloseMenu(_ sender: UITapGestureRecognizer) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: menuTapCloseNotification), object: self)
    }
    
    // MARK: - UICollectionViewDataSource
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return section == 0 ? 1 : (nearbyPlans.count > 0 ? nearbyPlans.count : 1)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var cell: UICollectionViewCell
        
        if indexPath.section == 0 {
            if let myPlan = User.currentUser()?.todaysPlan {
                cell = collectionView.dequeueReusableCell(withReuseIdentifier: kIdentifierMyPlanCell, for: indexPath) as! MyPlanCollectionViewCell
                (cell as! MyPlanCollectionViewCell).plan = myPlan
                (cell as! MyPlanCollectionViewCell).delegate = self
            } else {
                cell = collectionView.dequeueReusableCell(withReuseIdentifier: kIdentifierNewPlanCell, for: indexPath) as! NewPlanCollectionViewCell
                (cell as! NewPlanCollectionViewCell).delegate = self
            }
        } else {
            if nearbyPlans.count > 0 && indexPath.row < nearbyPlans.count {
                cell = collectionView.dequeueReusableCell(withReuseIdentifier: kIdentifierNearbyPlansCell, for: indexPath) as! NearbyPlansCollectionViewCell
                let plan = nearbyPlans[indexPath.row]
                (cell as! NearbyPlansCollectionViewCell).plan = plan
                (cell as! NearbyPlansCollectionViewCell).delegate = self
            } else {
                cell = collectionView.dequeueReusableCell(withReuseIdentifier: kIdentifierNoPlansCell, for: indexPath) as! NoPlanNearbyCollectionViewCell
                (cell as! NoPlanNearbyCollectionViewCell).delegate = self
            }
        }

        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        plansCollection.deselectItem(at: indexPath, animated: true)
        var plan: Plan?
        if indexPath.section == 0 {
            plan = User.currentUser()?.todaysPlan
        } else {
            if nearbyPlans.count > 0 && indexPath.row < nearbyPlans.count {
                let cell = self.plansCollection.cellForItem(at: indexPath) as! NearbyPlansCollectionViewCell
                plan = cell.plan
            }
        }
        if let plan = plan {
            Analytics.sharedInstance.event(Analytics.Event.ViewPlanDetails.rawValue)
            let storyboard = UIStoryboard(name: "PlanDetails", bundle: nil)
            let planDetailsVC = storyboard.instantiateViewController(withIdentifier: "PlanDetailsViewController") as! PlanDetailsViewController
            planDetailsVC.plan = plan
            self.navigationController?.pushViewController(planDetailsVC, animated: true)
        } else {
            NSLog("Plan not found at indexPath \(indexPath)")
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionElementKindSectionHeader {
            let cell = plansCollection.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "planCollectionHeader", for: indexPath) as! PlansCollectionReusableHeaderView
            if indexPath.section == 1 {
                cell.headerName = "Nearby Plans"
            } else {
                cell.headerName = "My Plan Today"
            }
            return cell
        } else {
            return UICollectionReusableView(frame: CGRect.zero)
        }
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        if indexPath.section == 0 {
            if let myPlan = User.currentUser()?.todaysPlan {
                myPlanSizingCell.plan = myPlan
                
                myPlanSizingCell.bounds = CGRect(x: 0, y: 0, width: plansCollection.bounds.width, height: myPlanSizingCell.bounds.height)
                myPlanSizingCell.contentView.bounds = myPlanSizingCell.bounds
                myPlanSizingCell.setNeedsLayout()
                myPlanSizingCell.layoutIfNeeded()
                
                var size = myPlanSizingCell.systemLayoutSizeFitting(UILayoutFittingCompressedSize)
                // Still need to force the width, since width can be smalled due to break mode of labels
                size.width = plansCollection.bounds.width
                return size
            } else {
                newPlanSizingCell.bounds = CGRect(x: 0, y: 0, width: plansCollection.bounds.width, height: newPlanSizingCell.bounds.height)
                newPlanSizingCell.contentView.bounds = newPlanSizingCell.bounds
                newPlanSizingCell.setNeedsLayout()
                newPlanSizingCell.layoutIfNeeded()
                
                var size = newPlanSizingCell.systemLayoutSizeFitting(UILayoutFittingCompressedSize)
                // Still need to force the width, since width can be smalled due to break mode of labels
                size.width = plansCollection.bounds.width
                return size
            }
        } else {
            if self.nearbyPlans.count > 0 && indexPath.row < nearbyPlans.count {
                let plan = nearbyPlans[indexPath.row]
                nearbyPlansSizingCell.plan = plan
                
                nearbyPlansSizingCell.bounds = CGRect(x: 0, y: 0, width: plansCollection.bounds.width, height: nearbyPlansSizingCell.bounds.height)
                nearbyPlansSizingCell.contentView.bounds = nearbyPlansSizingCell.bounds
                nearbyPlansSizingCell.setNeedsLayout()
                nearbyPlansSizingCell.layoutIfNeeded()
                
                var size = nearbyPlansSizingCell.systemLayoutSizeFitting(UILayoutFittingCompressedSize)
                // Still need to force the width, since width can be smalled due to break mode of labels
                size.width = plansCollection.bounds.width
                return size
            } else {
                noPlansSizingCell.bounds = CGRect(x: 0, y: 0, width: plansCollection.bounds.width, height: noPlansSizingCell.bounds.height)
                noPlansSizingCell.contentView.bounds = noPlansSizingCell.bounds
                noPlansSizingCell.setNeedsLayout()
                noPlansSizingCell.layoutIfNeeded()
                
                var size = noPlansSizingCell.systemLayoutSizeFitting(UILayoutFittingCompressedSize)
                // Still need to force the width, since width can be smalled due to break mode of labels
                size.width = plansCollection.bounds.width
                return size
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int) -> UIEdgeInsets {
            let insets = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
            return insets
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 16
    }
    
    // MARK: - NewPlanCollectionViewCellDelegate
    func createPlan() {
        Analytics.sharedInstance.event(Analytics.Event.StartCreatePlan.rawValue)
        let storyboard = UIStoryboard(name: "CreatePlan", bundle: nil)
        let newPlanVC = storyboard.instantiateViewController(withIdentifier: "CreatePlanViewController") as! CreatePlanViewController
        self.present(newPlanVC, animated: true, completion: nil)
    }
    
    // MARK: - NearbyPlansCollectionViewCellDelegate
    func joinPlan(_ plan: Plan?) {
        SVProgressHUD.show()
        plan?.join({ (plan, error) -> Void in
            SVProgressHUD.dismiss()
            Analytics.sharedInstance.event(Analytics.Event.JoinPlan.rawValue)
            if error == nil {
                self.showNotificationPermissionVC()
                User.currentUser()?.fetchInBackground() // refresh user data after join
                self.checkTodaysPlan()
            } else {
                ViewHelpers.presentErrorMessage(error!, vc: self)
            }
        })
    }
    
    // MARK: - MyPlanCollectionViewCellDelegate
    func onChat(_ plan: Plan?) {
        if let plan = plan {
            if let _ = plan.chat {
                let storyboard = UIStoryboard(name: "Chat", bundle: nil)
                let planChatVC = storyboard.instantiateViewController(withIdentifier: "PlanChatViewController") as! PlanChatViewController
                self.navigationController?.pushViewController(planChatVC, animated: true)
            }
        }
    }
    
    // MARK: - NoPlanNearbyCollectionViewCellDelegate
    func inviteFriends() {
        let content = FBSDKAppInviteContent()
        content.appLinkURL = URL(string: "https://fb.me/951850291598355")
        content.appInvitePreviewImageURL = URL(string: "http://a1.mzstatic.com/us/r30/Purple69/v4/3c/5a/1b/3c5a1be7-3289-3a94-99e7-a4364bfa9e3e/screen322x572.jpeg")
        FBSDKAppInviteDialog.showWithContent(content, delegate: self)
    }
    
    // MARK: - FBSDKAppInviteDialogDelegate
    func appInviteDialog(_ appInviteDialog: FBSDKAppInviteDialog!, didCompleteWithResults results: [AnyHashable: Any]!) {
        NSLog("Success inviting friends: \(results)")
        Analytics.sharedInstance.event(Analytics.Event.InviteUsers.rawValue)
    }
    
    func appInviteDialog(_ appInviteDialog: FBSDKAppInviteDialog!, didFailWithError error: NSError!) {
        if let error = error {
            NSLog("Error inviting friends: \(error)")
            Analytics.sharedInstance.event(Analytics.Event.SystemError.rawValue, properties: ["code": error.code, "message" : error.localizedDescription])
            ViewHelpers.presentErrorMessage(error, vc: self)
        }
    }
    
    // MARK: - Notification Handlers
    func onCRUDPlanNotification(_ notification: Notification) {
        if let _ = (notification.object as? Plan) {
            checkTodaysPlan()
            showNotificationPermissionVC()
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let lastLocation = locations[locations.count-1] // last location is the latest location
        Analytics.sharedInstance.setLocation(lastLocation.coordinate.latitude, longitude: lastLocation.coordinate.longitude, horizontalAccuracy: Float((lastLocation.horizontalAccuracy)), verticalAccuracy: Float((lastLocation.verticalAccuracy)))
        locationManager.stopUpdatingLocation()
    }
    
    // MARK: - Misc
    
    func disableUserInteraction(_ disable: Bool) {
        if disable == true {
            blockerView.isHidden = false
        } else {
            blockerView.isHidden = true
        }
    }
    
    // MARK: - Private functions
    fileprivate func listenForMyPlanChanges() {
        if let myPlan = User.currentUser()?.todaysPlan {
            self.firebaseService.removeObserversForUnreadChats(self.firebaseHandle)
            self.firebaseHandle = self.firebaseService.listenForUnreadChats(self.updateChatIcon)
            let indexPath = IndexPath(item: 0, section: 0)
            self.firebaseService.removeObserverForPlanUpdates(myPlan)
            self.firebaseService.listenForPlanUpdates(myPlan, completion: { (error) -> Void in
                if error == nil {
                    myPlan.getPlanDetails({ (fetchedPlan, error) -> Void in
                        if let fetchedPlan = fetchedPlan {
                            User.currentUser()?.todaysPlan = fetchedPlan
                            let cell = self.plansCollection.cellForItemAtIndexPath(indexPath)
                            if let _ = cell {
                                self.plansCollection.reloadItemsAtIndexPaths([indexPath])
                            }
                        } else if error != nil {
                            NSLog("error while getting plan details: \(error)")
                        }
                        
                    })
                }
            })
        }
    }
    
    fileprivate func updateChatIcon(_ chatsWithNewMsgs: [String]?) {
        
        if let chat = User.currentUser()?.todaysPlan?.chat {
            let chatId = chat.objectId!
            if let chatsWithNewMsgs = chatsWithNewMsgs {
                if chatsWithNewMsgs.contains(chatId) {
                    Chat.getChatByIdWithCompletion(chatId, completion: { (chat, error) -> Void in
                        if let chat = chat {
                            chat.hasNewMsg = true
                            User.currentUser()?.todaysPlan?.chat = chat
                            self.plansCollection.reloadSections(NSIndexSet(index: 0))
                        }
                    })
                } else {
                    chat.hasNewMsg = false
                    self.plansCollection.reloadSections(IndexSet(integer: 0))
                }
            }
        }
    }
    
    // change the font of title to the custom font
    fileprivate func customizeNavBar() {
        // change title font
        let shadow = NSShadow()
        shadow.shadowColor = UIColor.white
        shadow.shadowOffset = CGSize(width: 0, height: 1)
        self.navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName: UIFont(name: serifMediumFontName, size: 17)!, NSShadowAttributeName: shadow, NSForegroundColorAttributeName: UIColor.white]
        
        // add hamburger menu
        let buttonImage = UIImage(named: "hamburger")?.withRenderingMode(UIImageRenderingMode.alwaysOriginal)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: buttonImage, style: UIBarButtonItemStyle.plain, target: self, action: #selector(MainViewController.onMenu(_:)))
    }
    
    fileprivate func showNotificationPermissionVC() {
        if NotificationHelper.pushPermissionNotRequested() == true {
            let reminderTime = UserDefaults.standard.double(forKey: kNotificationReminderTime)
            // show vc if reminder hasn't been set or the reminder has expired
            if reminderTime == 0 || reminderTime < Date().timeIntervalSince1970 {
                let storyboard = UIStoryboard(name: "Permissions", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "NotificationPermissionViewController") as! NotificationPermissionViewController
                self.present(vc, animated: true, completion: nil)
            }
        }
    }
    
    fileprivate func findMatchPlanIndex(_ planToMatch: Plan) -> Int? {
        return self.nearbyPlans.indexOf { (plan: Plan) -> Bool in
            return planToMatch.objectId == plan.objectId
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
