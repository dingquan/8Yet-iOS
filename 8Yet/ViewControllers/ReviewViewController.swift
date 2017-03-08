//
//  ReviewViewController.swift
//  8Yet
//
//  Created by Quan Ding on 6/21/15.
//  Copyright (c) 2015 EightYet. All rights reserved.
//

import UIKit

private let DID_YOU_MEET_MSG = "Did you meet %@ for lunch?"
private let MEET_AGAIN_MSG = "Hope you enjoyed the meeting.\nWould you meet %@ again?"
private let WHY_NOT_MEET_MSG = "What prevented you guys\nfrom meeting each other?"

class ReviewViewController: BaseViewController, ReviewConfirmationViewControllerDelegate {
    var userMatch:UserMatch?

    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var imgTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var imgWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var imgHeightConstraint: NSLayoutConstraint!

    @IBOutlet weak var questionGrpDidMeet: UIView!
    @IBOutlet weak var questionGrpDidMeetHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var didMeetLabel: UILabel!
    @IBOutlet weak var didMeetYesBtn: UIButton!
    @IBOutlet weak var didMeetNoBtn: UIButton!
    @IBOutlet weak var didMeetNoBtnBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var didMeetYesBtnWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var didMeetYesBtnHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var didMeetNoBtnWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var didMeetNoBtnHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var didMeetAspectConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var questionGrpWhyBail: UIView!
    @IBOutlet weak var questionGrpBailHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var bailHeader: UILabel!
    @IBOutlet weak var bailBody: UILabel!
    @IBOutlet weak var bailBothBtn: UIButton!
    @IBOutlet weak var bailHimBtn: UIButton!
    @IBOutlet weak var bailMeBtn: UIButton!
    @IBOutlet weak var bailBothBtnWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var bailBothBtnHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var bailHimBtnHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var bailHimBtnWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var bailMeBtnWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var bailMeBtnHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var bailMeBtnBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var questionGrpMeetAgain: UIView!
    @IBOutlet weak var questionGrpMeetAgainHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var meetAgainHeader: UILabel!
    @IBOutlet weak var meetAgainLabel: UILabel!
    @IBOutlet weak var meetAgainYesBtn: UIButton!
    @IBOutlet weak var meetAgainMaybeBtn: UIButton!
    @IBOutlet weak var meetAgainNoBtn: UIButton!
    @IBOutlet weak var meetAgainYesHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var meetAgainYesWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var meetAgainNoHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var meetAgainNoWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var meetAgainMaybeHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var meetAgainMaybeWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var meetAgainMaybeBottomConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let screenBounds = UIScreen.main.bounds
        if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad || screenBounds.width * 480 == screenBounds.height * 320 {
            didMeetNoBtnBottomConstraint.constant = 12
            bailMeBtnBottomConstraint.constant = 12
            meetAgainMaybeBottomConstraint.constant = 12
            questionGrpDidMeetHeightConstraint.constant = screenBounds.width * 0.85
            questionGrpBailHeightConstraint.constant = screenBounds.width * 0.85
            questionGrpMeetAgainHeightConstraint.constant = screenBounds.width * 0.85

        } else {
            didMeetNoBtnBottomConstraint.constant *= screenSizeMultiplier
            bailMeBtnBottomConstraint.constant *= screenSizeMultiplier
            meetAgainMaybeBottomConstraint.constant *= screenSizeMultiplier
            questionGrpDidMeetHeightConstraint.constant *= screenSizeMultiplier
            questionGrpBailHeightConstraint.constant *= screenSizeMultiplier
            questionGrpMeetAgainHeightConstraint.constant *= screenSizeMultiplier
        }
        
        imgTopConstraint.constant *= screenSizeMultiplier
        imgWidthConstraint.constant *= screenSizeMultiplier
        imgHeightConstraint.constant *= screenSizeMultiplier
        
        name.font = UIFont(name: serifBoldFontName, size: 30 * screenSizeMultiplier)
        didMeetLabel.font = UIFont(name: sansSerifFontName, size: 21 * screenSizeMultiplier)
        
        didMeetYesBtnHeightConstraint.constant *= screenSizeMultiplier
        didMeetYesBtnWidthConstraint.constant *= screenSizeMultiplier
        didMeetNoBtnHeightConstraint.constant *= screenSizeMultiplier
        didMeetNoBtnWidthConstraint.constant *= screenSizeMultiplier
        
        didMeetYesBtn.titleLabel?.font = UIFont(name: serifMediumFontName, size: 30 * screenSizeMultiplier)
        didMeetNoBtn.titleLabel?.font = UIFont(name: serifMediumFontName, size: 24 * screenSizeMultiplier)
        
        bailHeader.font = UIFont(name: serifBoldFontName, size: 30 * screenSizeMultiplier)
        bailBody.font = UIFont(name: sansSerifFontName, size: 21 * screenSizeMultiplier)
        
        bailBothBtnHeightConstraint.constant *= screenSizeMultiplier
        bailBothBtnWidthConstraint.constant *= screenSizeMultiplier
        bailHimBtnHeightConstraint.constant *= screenSizeMultiplier
        bailHimBtnWidthConstraint.constant *= screenSizeMultiplier
        bailMeBtnHeightConstraint.constant *= screenSizeMultiplier
        bailMeBtnWidthConstraint.constant *= screenSizeMultiplier
        
        bailBothBtn.titleLabel?.font = UIFont(name: serifMediumFontName, size: 21 * screenSizeMultiplier)
        bailMeBtn.titleLabel?.font = UIFont(name: serifMediumFontName, size: 21 * screenSizeMultiplier)
        bailHimBtn.titleLabel?.font = UIFont(name: serifMediumFontName, size: 21 * screenSizeMultiplier)
        
        meetAgainHeader.font = UIFont(name: serifBoldFontName, size: 30 * screenSizeMultiplier)
        meetAgainLabel.font = UIFont(name: sansSerifFontName, size: 21 * screenSizeMultiplier)
        
        meetAgainMaybeHeightConstraint.constant *= screenSizeMultiplier
        meetAgainMaybeWidthConstraint.constant *= screenSizeMultiplier
        meetAgainYesHeightConstraint.constant *= screenSizeMultiplier
        meetAgainYesWidthConstraint.constant *= screenSizeMultiplier
        meetAgainNoHeightConstraint.constant *= screenSizeMultiplier
        meetAgainNoWidthConstraint.constant *= screenSizeMultiplier
        
        meetAgainYesBtn.titleLabel?.font = UIFont(name: serifMediumFontName, size: 30 * screenSizeMultiplier)
        meetAgainNoBtn.titleLabel?.font = UIFont(name: serifMediumFontName, size: 24 * screenSizeMultiplier)
        meetAgainMaybeBtn.titleLabel?.font = UIFont(name: serifMediumFontName, size: 24 * screenSizeMultiplier)
        
        // the frame size hasn't changed yet because layout hasn't happened. so need to use the width or height constraint to round corners
        ViewHelpers.roundedCorner(image, radius: imgWidthConstraint.constant/2)
        ViewHelpers.roundedCorner(didMeetYesBtn, radius: 5)
        ViewHelpers.roundedCorner(didMeetNoBtn, radius: 5)
        ViewHelpers.roundedCorner(bailBothBtn, radius: 5)
        ViewHelpers.roundedCorner(bailHimBtn, radius: 5)
        ViewHelpers.roundedCorner(bailMeBtn, radius: 5)
        ViewHelpers.roundedCorner(meetAgainYesBtn, radius: 5)
        ViewHelpers.roundedCorner(meetAgainNoBtn, radius: 5)
        ViewHelpers.roundedCorner(meetAgainMaybeBtn, radius: 5)
        
        if let userMatch = userMatch {
            name.text = userMatch.toUser.firstName ?? ""
            didMeetLabel.text = String(format: DID_YOU_MEET_MSG, userMatch.toUser.firstName ?? "")
            didMeetLabel.preferredMaxLayoutWidth = didMeetLabel.bounds.size.width
            didMeetLabel.sizeToFit()
            
            meetAgainLabel.text = String(format: MEET_AGAIN_MSG, userMatch.toUser.firstName ?? "")
            meetAgainLabel.preferredMaxLayoutWidth = meetAgainLabel.bounds.size.width
            meetAgainLabel.sizeToFit()
            
            if userMatch.didMeet == nil {
                questionGrpDidMeet.isHidden = false
                questionGrpMeetAgain.isHidden = true
                questionGrpWhyBail.isHidden = true
                ViewHelpers.fadeInImage(image, imgUrl: userMatch.toUser.profileImageUrl)
            } else if userMatch.didMeet == true {
                questionGrpDidMeet.isHidden = true
                questionGrpMeetAgain.isHidden = false
                questionGrpWhyBail.isHidden = true
                image.image = UIImage(named: "awesome")
            } else {
                questionGrpDidMeet.isHidden = true
                questionGrpMeetAgain.isHidden = true
                questionGrpWhyBail.isHidden = false
                image.image = UIImage(named: "bummer")
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        if userMatch == nil {
            print("UserMatch record not set for ReviewViewController")
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Actions
    @IBAction func onDidMeetYes(_ sender: AnyObject) {
        Analytics.sharedInstance.event(Analytics.Event.UserMatchDidMeet.rawValue, properties: ["didMeet": "yes"])
        userMatch?.didMeet = true
        
        UIView.transition(with: questionGrpDidMeet.superview!, duration: 0.3, options: UIViewAnimationOptions.transitionCrossDissolve, animations: { () -> Void in
            self.questionGrpDidMeet.isHidden = true
            self.questionGrpMeetAgain.isHidden = false
            self.image.image = UIImage(named: "awesome")
        }) { (isFinished: Bool) -> Void in
        }
    }
    
    @IBAction func onDidMeetNo(_ sender: AnyObject) {
        Analytics.sharedInstance.event(Analytics.Event.UserMatchDidMeet.rawValue, properties: ["didMeet": "no"])
        userMatch?.didMeet = false
        
        UIView.transition(with: questionGrpDidMeet.superview!, duration: 0.3, options: UIViewAnimationOptions.transitionCrossDissolve, animations: { () -> Void in
            self.questionGrpDidMeet.isHidden = true
            self.questionGrpWhyBail.isHidden = false
            self.image.image = UIImage(named: "bummer")
            }) { (isFinished: Bool) -> Void in
        }
    }
    
    @IBAction func onBailBoth(_ sender: AnyObject) {
        Analytics.sharedInstance.event(Analytics.Event.UserMatchBail.rawValue, properties: ["reason": "both"])
        userMatch?.bailOutReason = BailOutReason.didNotArrange.rawValue
        userMatch?.saveInBackgroundWithBlock(nil)
        
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onBailHim(_ sender: AnyObject) {
        Analytics.sharedInstance.event(Analytics.Event.UserMatchBail.rawValue, properties: ["reason": "other"])
        userMatch?.bailOutReason = BailOutReason.otherUserNoShow.rawValue
        userMatch?.saveInBackgroundWithBlock(nil)
        
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onBailMe(_ sender: AnyObject) {
        Analytics.sharedInstance.event(Analytics.Event.UserMatchBail.rawValue, properties: ["reason": "me"])
        userMatch?.bailOutReason = BailOutReason.didNotGo.rawValue
        userMatch?.saveInBackgroundWithBlock(nil)
        
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onMeetAgainYes(_ sender: AnyObject) {
        Analytics.sharedInstance.event(Analytics.Event.UserMatchMeetAgain.rawValue, properties: ["meetAgain": "yes"])
        userMatch?.willMeetAgain = MeetAgain.yes.rawValue
        userMatch?.ratingsOfToUser = 5
        userMatch?.saveInBackgroundWithBlock(nil)
        performSegue(withIdentifier: "showReviewConfirmation", sender: self)
    }
    
    @IBAction func onMeetAgainMaybe(_ sender: AnyObject) {
        Analytics.sharedInstance.event(Analytics.Event.UserMatchMeetAgain.rawValue, properties: ["meetAgain": "maybe"])
        userMatch?.willMeetAgain = MeetAgain.maybe.rawValue
        userMatch?.ratingsOfToUser = 3
        userMatch?.saveInBackgroundWithBlock(nil)
        performSegue(withIdentifier: "showReviewConfirmation", sender: self)
    }
    
    @IBAction func onMeetAgainNo(_ sender: AnyObject) {
        Analytics.sharedInstance.event(Analytics.Event.UserMatchMeetAgain.rawValue, properties: ["meetAgain": "no"])
        userMatch?.willMeetAgain = MeetAgain.no.rawValue
        userMatch?.ratingsOfToUser = 1
        userMatch?.saveInBackgroundWithBlock(nil)
        performSegue(withIdentifier: "showReviewConfirmation", sender: self)
    }

    func viewDismissed() {
        // user has closed thew review confirmation screen. dismiss this view controller as well
        self.dismiss(animated: true, completion: nil)
    }
    
    fileprivate func showReviewScoreAlert() {
        let firstName = userMatch?.toUser.firstName ?? ""
        let rating = userMatch?.ratingsOfToUser ?? 0
        let alert:UIAlertView = UIAlertView(title: "Thanks for the review!", message: "\(firstName) just received a score of \(rating) out of 5 for this meetup. (5 for \"yes\", 3 for \"maybe\" and 1 for \"no\")", delegate: self, cancelButtonTitle: "OK")
        alert.show()
    }


    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        let reviewConfirmationVC = segue.destination as! ReviewConfirmationViewController
        reviewConfirmationVC.userMatch = self.userMatch
        reviewConfirmationVC.delegate = self
    }


}
