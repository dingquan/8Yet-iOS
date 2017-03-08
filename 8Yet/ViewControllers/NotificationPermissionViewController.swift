//
//  NotificationPermissionViewController.swift
//  8Yet
//
//  Created by Quan Ding on 10/6/15.
//  Copyright © 2015 EightYet. All rights reserved.
//

import UIKit

let kNotificationReminderTime = "kNotificationReminderTime"

class NotificationPermissionViewController: BaseViewController {


    @IBOutlet weak var imgTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var imgWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var imgHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var bodyLabel: UILabel!
    
    @IBOutlet weak var okBtn: UIButton!
    @IBOutlet weak var laterBtn: UIButton!
    
    @IBOutlet weak var okBtnWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var okBtnHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var laterBtnWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var laterBtnHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var laterBtnBottomConstraint: NSLayoutConstraint!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let screenBounds = UIScreen.main.bounds
        if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad || screenBounds.width * 480 == screenBounds.height * 320 {
            laterBtnBottomConstraint.constant = 12
        } else {
            laterBtnBottomConstraint.constant *= screenSizeMultiplier
        }
        
        imgTopConstraint.constant *= screenSizeMultiplier
        imgWidthConstraint.constant *= screenSizeMultiplier
        imgHeightConstraint.constant *= screenSizeMultiplier
        
        headerLabel.font = UIFont(name: serifBoldFontName, size: 30 * screenSizeMultiplier)
        bodyLabel.font = UIFont(name: sansSerifFontName, size: 21 * screenSizeMultiplier)
        
        okBtn.titleLabel?.font = UIFont(name: serifMediumFontName, size: 30 * screenSizeMultiplier)
        laterBtn.titleLabel?.font = UIFont(name: serifMediumFontName, size: 24 * screenSizeMultiplier)
        ViewHelpers.roundedCorner(okBtn, radius: 5)
        ViewHelpers.roundedCorner(laterBtn, radius: 5)
        okBtnWidthConstraint.constant *= screenSizeMultiplier
        okBtnHeightConstraint.constant *= screenSizeMultiplier
        laterBtnWidthConstraint.constant *= screenSizeMultiplier
        laterBtnHeightConstraint.constant *= screenSizeMultiplier
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onOk(_ sender: AnyObject) {
        Analytics.sharedInstance.event(Analytics.Event.NotificationPermissionFromCardsView.rawValue, properties: ["permissionGranted": "yes"])
        NotificationHelper.registerNotification()
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func onLater(_ sender: AnyObject) {
        Analytics.sharedInstance.event(Analytics.Event.NotificationPermissionFromCardsView.rawValue, properties: ["permissionGranted": "no"])
        // save the timestamp and don't prompt user again until at least one day later
        UserDefaults.standard.set(Date().timeIntervalSince1970 + 24*3600, forKey: kNotificationReminderTime)
        UserDefaults.standard.synchronize()
        self.dismiss(animated: true, completion: nil)
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
