//
//  NobodyViewController.swift
//  8Yet
//
//  Created by Quan Ding on 9/26/15.
//  Copyright © 2015 EightYet. All rights reserved.
//

import UIKit

class NobodyViewController: BaseViewController {

    @IBOutlet weak var iconHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var iconWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var iconTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var okBtnBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var btnInvite: UIButton!
    @IBOutlet weak var btnOk: UIButton!
    @IBOutlet weak var nobodyLabel: UILabel!
    @IBOutlet weak var nobodyTitle: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let screenBounds = UIScreen.main.bounds
        if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad || screenBounds.width * 480 == screenBounds.height * 320 {
            okBtnBottomConstraint.constant = screenBounds.height / 12
        } else {
            okBtnBottomConstraint.constant *= screenSizeMultiplier
        }
        ViewHelpers.roundedCorner(btnInvite, radius: 5)
        ViewHelpers.roundedCorner(btnOk, radius: 5)
        nobodyTitle.font = UIFont(name: serifBoldFontName, size: 30 * screenSizeMultiplier)
        nobodyLabel.font = UIFont(name: sansSerifFontName, size: 21 * screenSizeMultiplier)
        iconTopConstraint.constant *= screenSizeMultiplier
        iconWidthConstraint.constant *= screenSizeMultiplier
        iconHeightConstraint.constant *= screenSizeMultiplier
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onInviteFriends(_ sender: AnyObject) {
        Analytics.sharedInstance.event(Analytics.Event.NobodyAround.rawValue, properties: ["inviteFriends": "yes"])
        let alert:UIAlertView = UIAlertView(title: "Wow, Thanks!", message: "Didn't expect you to tap it so I haven't implemented it yet... Stay tuned.", delegate: self, cancelButtonTitle: "OK")
        alert.show()
    }

    @IBAction func onClose(_ sender: AnyObject) {
        Analytics.sharedInstance.event(Analytics.Event.NobodyAround.rawValue)
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
