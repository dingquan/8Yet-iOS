//
//  WhyFacebookViewController.swift
//  8Yet
//
//  Created by Quan Ding on 11/8/15.
//  Copyright © 2015 EightYet. All rights reserved.
//

import UIKit

class WhyFacebookViewController: BaseViewController, UITextFieldDelegate {

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var backBtn: UIButton!
    @IBOutlet weak var otherOptionsBtn: UIButton!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var emailErrorLabel: UILabel!
    
    @IBOutlet weak var imgTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var imgHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var imgWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var bodyLabel: UILabel!
    @IBOutlet weak var invalidEmailLabel: UILabel!
    
    @IBOutlet weak var spinner: UIImageView!
    @IBOutlet weak var tick: UIImageView!
    
    
    @IBOutlet weak var backBtnWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var backBtnHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var emailTextWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var emailTextHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var emailLabelWidthConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.emailTextField.delegate = self
        ViewHelpers.roundedCornerWithBoarder(emailTextField, radius: 5, borderWidth: 1, color: UIColor.whiteColor())
        self.emailTextField.isHidden = true
        self.emailLabel.isHidden = true
        self.otherOptionsBtn.isHidden = false
        self.invalidEmailLabel.isHidden = true
        self.tick.isHidden = true
//        self.spinner.hidden = true
//        self.activityIndicator.hidden = true
        self.activityIndicator.hidesWhenStopped = true
        self.activityIndicator.stopAnimating()
        
        emailTextField.inputAccessoryView = UIView() // remove the toolbar
        
        ViewHelpers.roundedCorner(backBtn, radius: 5)
        ViewHelpers.roundedCorner(otherOptionsBtn, radius: 5)
        
        imgTopConstraint.constant *= screenSizeMultiplier
        imgWidthConstraint.constant *= screenSizeMultiplier
        imgHeightConstraint.constant *= screenSizeMultiplier
        titleLabel.font = UIFont(name: serifBoldFontName, size: 30 * screenSizeMultiplier)
        titleLabel.sizeToFit()
        bodyLabel.font = UIFont(name: sansSerifFontName, size: 18 * screenSizeMultiplier)
        bodyLabel.sizeToFit()
        
        backBtnHeightConstraint.constant *= screenSizeMultiplier
        backBtnWidthConstraint.constant *= screenSizeMultiplier
        emailTextWidthConstraint.constant *= screenSizeMultiplier
        emailTextHeightConstraint.constant *= screenSizeMultiplier
        backBtn.titleLabel?.font = UIFont(name: serifMediumFontName, size: 26 * screenSizeMultiplier)
        emailTextField.font = UIFont(name: serifMediumFontName, size: 24 * screenSizeMultiplier)
        emailLabelWidthConstraint.constant *= screenSizeMultiplier
        emailLabel.font = UIFont(name: sansSerifItalicFontName, size: 15 * screenSizeMultiplier)
        emailLabel.sizeToFit()
        otherOptionsBtn.titleLabel?.font = UIFont(name: sansSerifFontName, size: 15 * screenSizeMultiplier)
        emailErrorLabel.font = UIFont(name: sansSerifFontName, size: 15 * screenSizeMultiplier)

        // hide the image on iPhone4 and iPads as there's no room for them
        let screenBounds = UIScreen.main.bounds
        if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad || screenBounds.width * 480 == screenBounds.height * 320 {
            imgHeightConstraint.constant = 0
            imgWidthConstraint.constant = 0
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.emailTextField.resignFirstResponder()
        if let email = emailTextField.text {
            if email.isEmail {
                Analytics.sharedInstance.event(Analytics.Event.WhyFacebook.rawValue, properties: ["action": "emailEntered"])
//                self.spinner.hidden = false
                self.tick.isHidden = true
//                ViewHelpers.rotateLayerInfinite(spinner.layer)
                self.activityIndicator.startAnimating()
                self.invalidEmailLabel.isHidden = true
                let installation = Installation.currentInstallation()
                installation.noFbEmail = email
                installation.saveInBackgroundWithBlock({ (success, error) -> Void in
//                    self.spinner.hidden = true
                    self.activityIndicator.stopAnimating()
//                    ViewHelpers.stopRotateLayer(self.spinner.layer)
                    self.tick.hidden = false
                    if success {
                        self.emailLabel.text = "Email saved. We'll let you know as soon as we have added other login options."
                        self.emailLabel.sizeToFit()
                    }
                })
            } else {
                self.invalidEmailLabel.isHidden = false
            }
        }
        return true
    }
    
    // MARK: - Actions
    
    @IBAction func onBack(_ sender: AnyObject) {
        Analytics.sharedInstance.event(Analytics.Event.WhyFacebook.rawValue, properties: ["action": "back"])
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onOtherOptions(_ sender: AnyObject) {
        Analytics.sharedInstance.event(Analytics.Event.WhyFacebook.rawValue, properties: ["action": "otherOptions"])
        self.emailTextField.isHidden = false
        self.emailLabel.isHidden = false
        self.otherOptionsBtn.isHidden = true
    }

    @IBAction func hideKeyboard(_ sender: UITapGestureRecognizer) {
        self.emailTextField.endEditing(true)
        self.invalidEmailLabel.isHidden = true
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

extension String {
    var isEmail: Bool {
        do {
            let regex = try NSRegularExpression(pattern: "[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?", options: NSRegularExpression.Options.caseInsensitive)
            return regex.firstMatch(in: self, options: [], range: NSMakeRange(0, self.characters.count)) != nil
        } catch {
            return false
        }
    }
}
