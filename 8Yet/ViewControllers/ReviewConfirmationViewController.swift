//
//  ReviewConfirmationViewController.swift
//  8Yet
//
//  Created by Quan Ding on 11/12/15.
//  Copyright © 2015 EightYet. All rights reserved.
//

import UIKit

protocol ReviewConfirmationViewControllerDelegate: class {
    func viewDismissed()
}

class ReviewConfirmationViewController: BaseViewController, UITextViewDelegate {

    weak var delegate: ReviewConfirmationViewControllerDelegate?
    
    @IBOutlet weak var profileImg: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var starsImg: UIImageView!
    @IBOutlet weak var commentsLabel: UILabel!

    @IBOutlet weak var profileImgWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var profileImgHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var okBtn: UIButton!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var commentsText: UITextView!
    
    @IBOutlet weak var starsImgTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var headerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var starsImgWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var starsImgHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var commentsTextWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var commentsTextHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var commentsLabelTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var okBtnWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var okBtnHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var scoreLabelWidthConstraint: NSLayoutConstraint!
    
    var userMatch:UserMatch!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        profileImgWidthConstraint.constant *= screenSizeMultiplier
        profileImgHeightConstraint.constant *= screenSizeMultiplier
        starsImgTopConstraint.constant *= screenSizeMultiplier
        headerHeightConstraint.constant *= screenSizeMultiplier
        starsImgWidthConstraint.constant *= screenSizeMultiplier
        starsImgHeightConstraint.constant *= screenSizeMultiplier
        commentsTextWidthConstraint.constant *= screenSizeMultiplier
        commentsTextHeightConstraint.constant *= screenSizeMultiplier
        commentsLabelTopConstraint.constant *= screenSizeMultiplier
        okBtnWidthConstraint.constant *= screenSizeMultiplier
        okBtnHeightConstraint.constant *= screenSizeMultiplier
        scoreLabelWidthConstraint.constant *= screenSizeMultiplier
        
        ViewHelpers.roundedCorner(commentsText, radius: 5)
        ViewHelpers.roundedCorner(okBtn, radius: 5)
        
        commentsText.delegate = self
        titleLabel.font = UIFont(name: serifBoldFontName, size: 20 * screenSizeMultiplier)
        titleLabel.sizeToFit()
        
        if let userMatch = self.userMatch {
            if let rating = userMatch.ratingsOfToUser {
                let firstName = userMatch.toUser.firstName ?? ""
                switch rating {
                case 1:
                    self.starsImg.image = UIImage(named: "stars1")
                    self.scoreLabel.text = "\(firstName) got 1 star because you said you don't want to meet \(firstName) again for lunch. \(firstName) would receive 5 stars for \"yes\" and 3 stars for \"maybe\""
                case 3:
                    self.starsImg.image = UIImage(named: "stars3")
                    self.scoreLabel.text = "\(firstName) got 3 stars because you said you may want to meet \(firstName) again for lunch. \(firstName) would receive 5 stars for \"yes\" and 1 star for \"no\""
                case 5:
                    self.starsImg.image = UIImage(named: "stars5")
                    self.scoreLabel.text = "\(firstName) got 5 stars because you said you would like to meet \(firstName) again for lunch. \(firstName) would receive 3 stars for \"maybe\" and 1 star for \"no\""
                default: // should not happen
                    ()
                }
            }
            self.commentsText.text = userMatch.comments ?? ""
            self.commentsLabel.text = "Tell me one thing you didn't know about \(userMatch.toUser.firstName ?? "")"
            self.commentsLabel.sizeToFit()
            self.scoreLabel.sizeToFit()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        ViewHelpers.roundedCornerWithBoarder(profileImg, radius: profileImg.frame.width / 2, borderWidth: 1, color: UIColor.whiteColor())
        ViewHelpers.fadeInImage(profileImg, imgUrl: userMatch.toUser.profileImageUrl)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    @IBAction func hideKeyboard(_ sender: UITapGestureRecognizer) {
        commentsText.endEditing(true)
    }
    
    @IBAction func onOk(_ sender: AnyObject) {
        Analytics.sharedInstance.event(Analytics.Event.UserMactchReviewOkBtnClicked.rawValue, properties: ["withComments": commentsText.text.utf16.count > 0 ? "yes" : "no"])
        if let userMatch = self.userMatch {
            if commentsText.text.utf16.count > 0 {
                userMatch.comments = commentsText.text
                userMatch.saveInBackground()
            }
        }
        self.dismiss(animated: true, completion: nil)
        delegate?.viewDismissed()
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {

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
