//
//  UserBioViewController.swift
//  8Yet
//
//  Created by Quan Ding on 3/13/16.
//  Copyright © 2016 EightYet. All rights reserved.
//

import UIKit

private let buttonDopShadowColor = UIColor(red: 46/255, green: 185/255, blue: 149/255, alpha: 1)

class UserBioViewController: BaseViewController {

    @IBOutlet weak var saveBtn: UIButton!
    @IBOutlet weak var saveBtnWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var bioTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        ViewHelpers.roundedCornerWithBoarder(bioTextView, radius: 10, borderWidth: 1, color: UIColor(red: 235/255, green: 235/255, blue: 235/255, alpha: 1))
        bioTextView.textContainerInset = UIEdgeInsetsMake(10, 10, 0, 0)
        bioTextView.text = User.currentUser()?.bio
        saveBtnWidthConstraint.constant *= screenSizeMultiplier
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        ViewHelpers.addDropShadow(saveBtn, color: buttonDopShadowColor.CGColor, offset: CGSize(width: 0, height: 3), shadowRadius: 0, opacity: 1, cornerRadius: 10)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }

    // MARK: - Actions
    @IBAction func onSave(_ sender: AnyObject) {
        Analytics.sharedInstance.event(Analytics.Event.EditBio.rawValue)
        User.currentUser()?.bio = bioTextView.text
        User.currentUser()?.saveInBackground()
        NotificationCenter.defaultCenter.postNotificationName(NSNotification.Name(rawValue: profileChangeNotification), object: User.currentUser())
        self.navigationController?.popViewController(animated: true)
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
