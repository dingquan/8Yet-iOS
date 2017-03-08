//
//  LoginViewController.swift
//  8Yet
//
//  Created by Ding, Quan on 3/2/15.
//  Copyright (c) 2015 EightYet. All rights reserved.
//

import UIKit

private let showOnboardingIdentifier = "onboarding"

class LoginViewController: BaseViewController {

    @IBOutlet weak var loginBtn: UIButton!
    @IBOutlet weak var loginBtnHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var loginBtnWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var loginBtnBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var loginBtnTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var logoTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var logoName: UILabel!

    @IBOutlet weak var logoHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var logoWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var bodyLabel: UILabel!
    
    @IBOutlet weak var whyFbBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ViewHelpers.roundedCorner(loginBtn, radius: 5 * screenSizeMultiplier)

        // adjust the layout depending out screen sizes
        let screenBounds = UIScreen.main.bounds
        if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad || screenBounds.width * 480 == screenBounds.height * 320 { // iphone 4s and ipads
            logoTopConstraint.constant = screenBounds.height / 12
            loginBtnBottomConstraint.constant = screenBounds.height / 8
            loginBtnTopConstraint.constant = screenBounds.height / 12
        } else {
            logoTopConstraint.constant = screenBounds.height / 8
            loginBtnBottomConstraint.constant = screenBounds.height / 6
            loginBtnTopConstraint.constant = screenBounds.height / 14
        }
        logoHeightConstraint.constant *= screenSizeMultiplier
        logoWidthConstraint.constant *= screenSizeMultiplier
        logoName.font = UIFont(name: serifBoldFontName, size: 30 * screenSizeMultiplier)
        logoName.sizeToFit()
        bodyLabel.font = UIFont(name: sansSerifFontName, size: 20 * screenSizeMultiplier)
        bodyLabel.sizeToFit()
        loginBtnHeightConstraint.constant *= screenSizeMultiplier
        loginBtnWidthConstraint.constant *= screenSizeMultiplier
        whyFbBtn.titleLabel?.font = UIFont(name: sansSerifItalicFontName, size: 14 * screenSizeMultiplier)
        whyFbBtn.sizeToFit()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onFacebookLogin(_ sender: UIButton) {
        Analytics.sharedInstance.event(Analytics.Event.FacebookLogin.rawValue, properties: ["status": "start"])
        User.loginWithCompletion { (user, error) -> Void in
            Analytics.sharedInstance.event(Analytics.Event.FacebookLogin.rawValue, properties: ["status": (error == nil ? "success" : "fail"), "error": (error?.localizedDescription ?? "")])
            if error != nil {
                let alert = UIAlertView(title: "Facebook login failure", message: error?.localizedDescription, delegate: nil, cancelButtonTitle: "OK")
                alert.show()
            } else {
                if let user = user {
                    NotificationCenter.default.post(name: Notification.Name(rawValue: loginCompleteNotification), object: user)
                }
            }
        }
    }

    @IBAction func onWhyFBLogin(_ sender: AnyObject) {
        Analytics.sharedInstance.event(Analytics.Event.WhyFacebookClicked.rawValue)
        performSegue(withIdentifier: "showWhyFBLogin", sender: self)
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
