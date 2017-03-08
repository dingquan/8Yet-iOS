//
//  ContainerViewController.swift
//  TwitterV2
//
//  Created by Ding, Quan on 2/26/15.
//  Copyright (c) 2015 Codepath. All rights reserved.
//

import UIKit

let menuTappedNotification = "menuTappedNotification"
let menuTapCloseNotification = "menuTapCloseNotification"
let loginCompleteNotification = "loginCompleteNotification"
let onboardingFinishedNotification = "onboardingFinishedNotification"

class ContainerViewController: BaseViewController, MenuViewControllerDelegate, UIAlertViewDelegate {
    
    fileprivate var menuRevealed: Bool = false
    fileprivate var mainVCPanGestureRecognizer: UIPanGestureRecognizer!
    fileprivate let menuScreenOffset:CGFloat = 64
    fileprivate let screenWidth = UIScreen.main.bounds.width
    fileprivate let storyBoard = UIStoryboard(name: "Main", bundle: nil)
    fileprivate let loginStoryBoard = UIStoryboard(name: "Login", bundle: nil)
    fileprivate let onboardingStoryBoard = UIStoryboard(name: "Onboarding", bundle: nil)
    fileprivate let reviewStoryBoard = UIStoryboard(name: "Review", bundle: nil)
    fileprivate let menuStoryBoard = UIStoryboard(name: "Menu", bundle: nil)
    
    var menuViewController: MenuViewController!
    var mainViewController: MainViewController!
    var mainNavController: UINavigationController!
    var onboardingViewController: UIViewController!
    var loginViewController: UIViewController!
    
    fileprivate var currentViewController: UIViewController!
    fileprivate var currentViewControllerOriginalCenter: CGPoint!

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let user = User.currentUser()
        if user == nil || !user!.isAuthenticated() {
            addLoginViewController()
        } else {
            addMainNavController()

            // save the user id into parse installation just incase it hasn't been saved as part of the login
            Installation.currentInstallation().updateInstallationWithUser()
        }
        
        mainVCPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(ContainerViewController.handlePanGesture(_:)))
        
        // remove previous observers first if there is any
        NotificationCenter.default.removeObserver(self)
        NotificationCenter.default.addObserver(self, selector: #selector(ContainerViewController.showHideMenu), name: NSNotification.Name(rawValue: menuTappedNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ContainerViewController.showHideMenu), name: NSNotification.Name(rawValue: menuTapCloseNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ContainerViewController.onLoginCompletion(_:)), name: NSNotification.Name(rawValue: loginCompleteNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ContainerViewController.onOnboardingCompletion), name: NSNotification.Name(rawValue: onboardingFinishedNotification), object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Notification handlers
    
    func showHideMenu(){
        if (menuRevealed == false){
            revealMenu()
        } else {
            closeMenu()
        }
    }
    
    fileprivate func revealMenu() {
        self.mainViewController.disableUserInteraction(true)
        if !menuRevealed { // avoid adding menu controller again if it's already shown
            mainViewController.view.addGestureRecognizer(mainVCPanGestureRecognizer)
            addMenuViewController()
        }
        let xDistance = abs(currentViewController.view.frame.origin.x - (currentViewController.view.bounds.width - menuScreenOffset))
        let duration:Double = 0.4 * Double(xDistance / screenWidth)
        UIView.animate(withDuration: duration, animations: { () -> Void in
            self.currentViewController!.view.frame.origin.x = self.currentViewController.view.frame.width - self.menuScreenOffset
            }, completion: { (finished) -> Void in
                if (finished){
                    self.menuRevealed = true
                }
            }
        )
    }
    
    fileprivate func closeMenu() {
        self.mainViewController.disableUserInteraction(false)
        let xDistance = currentViewController.view.frame.origin.x
        let duration:Double = 0.4 * Double(xDistance / screenWidth)
        UIView.animate(withDuration: duration, animations: { () -> Void in
            self.currentViewController!.view.frame.origin.x = 0
            }, completion: { (finished) -> Void in
                if (finished){
                    if self.menuRevealed {
                        self.mainViewController.view.removeGestureRecognizer(self.mainVCPanGestureRecognizer)
                        self.removeMenuViewController()
                    }
                    self.menuRevealed = false
                }
            }
        )
    }
    
    func handlePanGesture(_ recognizer: UIPanGestureRecognizer){
        let translation = recognizer.translation(in: view)
        switch recognizer.state {
        case .began:
            addMenuViewController()
            currentViewControllerOriginalCenter = currentViewController.view.center
        case .changed:
            // don't over pan to the left, stop as soon as currentViewController is back to the normal position)
            if translation.x > menuScreenOffset - screenWidth {
                currentViewController.view.center = CGPoint(x: currentViewControllerOriginalCenter.x + translation.x, y: currentViewControllerOriginalCenter.y)
            }
        case .ended:
            fallthrough
        case .cancelled:
            if recognizer.state == .cancelled || abs(translation.x) < screenWidth / 4 {
                revealMenu()
            } else {
                closeMenu()
            }
        default:
            NSLog("unreachable")
        }
    }
    
    func onLoginCompletion(_ notification: Notification) {
        let installation = Installation.currentInstallation()
        let onboardingShown = installation.onboardingShown ?? false

        if onboardingShown == false {
            addOnboardingViewController()
            removeMainNavController()
            installation.onboardingShown = true
            installation.saveInBackground()
        } else {
            addMainNavController()
            removeOnboardingViewController()
        }
        removeLoginViewController()
    }
    
    func onOnboardingCompletion() {
        addMainNavController()
        removeOnboardingViewController()
        removeLoginViewController()
    }
    
    // MARK: - add/remove view controllers
    func addMenuViewController() {
        if menuViewController == nil {
            menuViewController = menuStoryBoard.instantiateViewController(withIdentifier: "MenuViewController") as! MenuViewController
            menuViewController.delegate = self
        }
        if menuViewController != nil {
            self.addChildViewController(menuViewController)
            self.menuViewController.view.frame = self.view.frame
            self.view.insertSubview(menuViewController.view, at: 0)
            self.menuViewController.didMove(toParentViewController: self)
        }
    }
    
    func removeMenuViewController() {
        if (menuViewController != nil) {
            self.menuViewController?.willMove(toParentViewController: nil)
            self.menuViewController?.view.removeFromSuperview()
            self.menuViewController.removeFromParentViewController()
        }
    }
    
    func addMainNavController(){
        if mainNavController == nil {
            mainNavController = storyBoard.instantiateViewController(withIdentifier: "MainNavController") as! UINavigationController
            mainViewController = mainNavController.topViewController as! MainViewController
        }
        if mainNavController != nil {
            mainNavController.navigationBar.backIndicatorImage = UIImage(named: "backButton")?.withRenderingMode(UIImageRenderingMode.alwaysOriginal)
            mainNavController.navigationBar.backIndicatorTransitionMaskImage = UIImage(named: "backButton")?.withRenderingMode(UIImageRenderingMode.alwaysOriginal)
            self.addChildViewController(mainNavController)
            self.view.addSubview(mainNavController.view)
            self.mainNavController.didMove(toParentViewController: self)
            if self.currentViewController != nil {
                self.mainNavController.view.frame = self.currentViewController.view.frame
            } else {
                self.mainNavController.view.frame = self.view.frame // this is the initial load case when none of the nav controller has been loaded to the scene yet
            }
            self.currentViewController = mainNavController
        }
    }

    func removeMainNavController() {
        if (mainNavController != nil) {
            self.mainNavController?.willMove(toParentViewController: nil)
            self.mainNavController?.view.removeFromSuperview()
            self.mainNavController.removeFromParentViewController()
        }
    }
    
    func addOnboardingViewController(){
        if onboardingViewController == nil {
            onboardingViewController = onboardingStoryBoard.instantiateViewController(withIdentifier: "OnboardingViewController") as! OnboardingContainerViewController
        }
        if onboardingViewController != nil {
            self.addChildViewController(onboardingViewController)
            self.view.addSubview(onboardingViewController.view)
            self.onboardingViewController.didMove(toParentViewController: self)
            self.onboardingViewController.view.frame = self.currentViewController.view.frame
            self.currentViewController = onboardingViewController
        }
    }
    
    func removeOnboardingViewController() {
        if (onboardingViewController != nil) {
            self.onboardingViewController?.willMove(toParentViewController: nil)
            self.onboardingViewController?.view.removeFromSuperview()
            self.onboardingViewController.didMove(toParentViewController: nil)
        }
    }
    
    func addLoginViewController(){
        if loginViewController == nil {
            loginViewController = loginStoryBoard.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
        }
        if loginViewController != nil {
            self.addChildViewController(loginViewController)
            self.view.addSubview(loginViewController.view)
            self.loginViewController.didMove(toParentViewController: self)
            if self.currentViewController != nil {
                self.loginViewController.view.frame = self.currentViewController.view.frame
            } else {
                self.loginViewController.view.frame = self.view.frame // this is the initial load case when none of the nav controller has been loaded to the scene yet
            }
            self.currentViewController = loginViewController
        }
    }
    
    func removeLoginViewController() {
        if (loginViewController != nil) {
            self.loginViewController?.willMove(toParentViewController: nil)
            self.loginViewController?.view.removeFromSuperview()
            self.loginViewController.didMove(toParentViewController: nil)
        }
    }
    
//    func handlePanGesture(recognizer: UIPanGestureRecognizer){
//        let panLeftToRight = recognizer.velocityInView(view).x > 0
//        var translation = recognizer.translationInView(view)
//        println("panLeftToRight: \(panLeftToRight), translation: \(translation)")
//        if recognizer.state == UIGestureRecognizerState.Began {
//            addMenuViewController()
//            currentViewControllerOriginalCenter = currentViewController.view.center
//        } else if recognizer.state == UIGestureRecognizerState.Changed {
//            currentViewController.view.center.x += translation.x
//        } else if recognizer.state == UIGestureRecognizerState.Ended {
//            if panLeftToRight {
//                revealMenu()
//            } else {
//                closeMenu()
//            }
//        }
//    }
    
    // MARK: - MenuViewControllerDelegate
    
    func onLogOut(){
        User.currentUser()?.logout()
        addLoginViewController()
        removeMainNavController()
        removeOnboardingViewController()
        closeMenu()
    }
    
    func onEula() {
        UIApplication.shared.openURL(URL(string:"http://8yet.parseapp.com/eula.htm")!)
        closeMenu()
    }
    
    func onProfile() {
        if let user = User.currentUser() {
            Analytics.sharedInstance.event(Analytics.Event.ViewOwnProfile.rawValue)
            let storyboard = UIStoryboard(name: "UserProfile", bundle: nil)
            let userProfileVC = storyboard.instantiateViewController(withIdentifier: "UserProfileViewController") as! UserProfileViewController
            userProfileVC.user = user
            mainNavController?.pushViewController(userProfileVC, animated: true)
        }
        closeMenu()
    }
    
    func onFacebookGroup() {
        UIApplication.shared.openURL(URL(string:"https://www.facebook.com/groups/778764922228803/")!)
        closeMenu()
    }
    
    func onFacebookPage() {
        UIApplication.shared.openURL(URL(string:"https://www.facebook.com/8Yet-721689214624204/")!)
        closeMenu()
    }
    
    func onTwitter() {
        let didOpenApp = UIApplication.shared.openURL(URL(string:"twitter:///user?screen_name=@go8yet")!)
        if !didOpenApp {
            UIApplication.shared.openURL(URL(string:"https://twitter.com/go8yet")!)
        }
        closeMenu()
    }
    
    func onRateUs() {
        UIApplication.shared.openURL(URL(string:"itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=1031452258&onlyLatestVersion=true&pageNumber=0&sortOrdering=1&type=Purple+Software")!)
        closeMenu()
    }
    
    func onChat() {
        closeMenu()
        SVProgressHUD.show()
        Chat.get8YetChat { (chat) -> Void in
            SVProgressHUD.dismiss()
            let storyboard = UIStoryboard(name: "Chat", bundle: nil)
            let chatVC = storyboard.instantiateViewController(withIdentifier: "ChatViewController") as! ChatViewController
            chatVC.chat = chat
            self.mainNavController?.pushViewController(chatVC, animated: true)
        }
    }
    
    // MARK: Demo Mode - should only be available in dev builds
    func onDemoMode() {
        let installation = Installation.currentInstallation()
        var demoMode = installation.demoMode?.boolValue ?? false
        demoMode = !demoMode
        installation.demoMode = demoMode
        installation.clearOnboardingFlags()
        
        if demoMode {
            cleanTestUserData()
            setTestUserLocation()
        }
        
        let demoModeStatus = demoMode ? "on" : "off"
        let alert:UIAlertView = UIAlertView(title: nil, message: "Demo mode: \(demoModeStatus)", delegate: self, cancelButtonTitle: "OK")
        alert.show()
        closeMenu()
    }
    
    fileprivate func cleanTestUserData() {
        PFCloud.callFunctionInBackground("cleanTestUserData", withParameters: nil) { (result, error) -> Void in
            if error != nil {
                print("failed to clean test user data: \(error)")
            }
        }
    }
    
    // change all test users' location to the login user's location
    // so that they can appear nearby
    fileprivate func setTestUserLocation() {
        PFCloud.callFunctionInBackground("setTestUserLocations", withParameters: nil) { (result, error) -> Void in
            if error != nil {
                print("failed to set test user location: \(error)")
            }
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
