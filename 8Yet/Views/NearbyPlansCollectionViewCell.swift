//
//  NearbyPlansCollectionViewCell.swift
//  8Yet
//
//  Created by Quan Ding on 2/26/16.
//  Copyright © 2016 EightYet. All rights reserved.
//

import UIKit

protocol NearbyPlansCollectionViewCellDelegate: class {
    func joinPlan(_ plan: Plan?)
}

private let joinBtnShadowColor = UIColor(red: 46/255, green: 185/255, blue: 149/255, alpha: 1)
private let joinBtnDisabledShadowColor = UIColor(red: 167/255, green: 169/255, blue: 171/255, alpha: 1)
private let joinBtnColor = UIColor(red: 54/255, green: 212/255, blue: 171/255, alpha: 1)
private let joinBtnDisabledColor = UIColor(red: 235/255, green: 235/255, blue: 235/255, alpha: 1)

class NearbyPlansCollectionViewCell: UICollectionViewCell {
    weak var delegate: NearbyPlansCollectionViewCellDelegate?
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var hostProfileImage: UIImageView!
    @IBOutlet weak var planTopic: UILabel!
    @IBOutlet weak var joinBtn: UIButton!
    @IBOutlet weak var address1: UILabel!
    @IBOutlet weak var address2: UILabel!
    @IBOutlet weak var startTime: UILabel!
    @IBOutlet weak var firstJoinLabel: UILabel!
    @IBOutlet weak var leftView: UIView!
    @IBOutlet weak var planTopicImage: UIImageView!
    @IBOutlet weak var participantsView: UIView!
    
    @IBOutlet weak var planTopicLabelBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var planTopicLabelHeightConstraint: NSLayoutConstraint!
    
    fileprivate var participantsImgViews: [UIView] = []
    
    fileprivate let buttonDopShadowColor = UIColor(red: 46/255, green: 185/255, blue: 149/255, alpha: 1)
    fileprivate let cardDopShadowColor = UIColor(red: 235/255, green: 235/255, blue: 235/255, alpha: 1)
    
    var plan: Plan? {
        didSet {
            if let plan = plan {
                let owner = plan.host
                ViewHelpers.fadeInImage(hostProfileImage, imgUrl: owner.profileImageUrl)
                planTopic.text = plan.topic ?? ""
                planTopic.preferredMaxLayoutWidth = planTopic.bounds.width
                if planTopic.text != "" {
                    planTopicLabelHeightConstraint.constant = 18
                    planTopicLabelBottomConstraint.constant = 8
                    planTopicImage.isHidden = false
                } else {
                    planTopicLabelHeightConstraint.constant = 0
                    planTopicLabelBottomConstraint.constant = 0
                    planTopicImage.isHidden = true
                }
                
                if let location = plan.location {
                    if let locationName = location.name {
                        address1.text = locationName
                        address2.text = location.address
                    } else {
                        address1.text = location.address
                        address2.text = ""
                    }
                }
                
                address1.preferredMaxLayoutWidth = address1.bounds.width
                address2.preferredMaxLayoutWidth = address2.bounds.width
                startTime.text = amPmDateFormatter.string(from: plan.startTime)
                startTime.preferredMaxLayoutWidth = startTime.bounds.width
                
                drawParticipantsProfilePics()
                if plan.participants.count > 1 {
                    firstJoinLabel.isHidden = true
                } else {
                    firstJoinLabel.isHidden = false
                }
                if User.currentUser()?.todaysPlan != nil {
                    joinBtn.isEnabled = false
                } else {
                    joinBtn.isEnabled = true
                }
            }
            
            setNeedsLayout()
            layoutIfNeeded()
        }
    }
    
    // this line seems to fixed the problem of autolayout constraints error that causes card dropshadow having wrong frame size
    // http://stackoverflow.com/questions/25804588/auto-layout-in-uicollectionviewcell-not-working
    override var bounds: CGRect {
        didSet {
            contentView.frame = bounds
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        joinBtn.setTitleColor(UIColor.white, for: UIControlState())
        joinBtn.setTitleColor(joinBtnDisabledShadowColor, for: UIControlState.disabled)
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        ViewHelpers.roundedCorners(leftView, corners: [.TopLeft, .BottomLeft], radius: 10)
        ViewHelpers.roundedCorner(hostProfileImage, radius: hostProfileImage.bounds.width/2)
        ViewHelpers.addDropShadow(containerView.superview!, color: cardDopShadowColor.CGColor, offset: CGSize(width: 0, height: 3), shadowRadius: 0, opacity: 1, cornerRadius: 10)
        ViewHelpers.roundedCorner(containerView, radius: 10)
        ViewHelpers.addDropShadow(joinBtn, color: buttonDopShadowColor.CGColor, offset: CGSize(width: 0, height: 3), shadowRadius: 0, opacity: 1, cornerRadius: 10)
        if joinBtn.isEnabled {
            ViewHelpers.addDropShadow(joinBtn, color: joinBtnShadowColor.CGColor, offset: CGSize(width: 0,height: 3), shadowRadius: 0, opacity: 1, cornerRadius: 10)
            joinBtn.backgroundColor = joinBtnColor
        } else {
            ViewHelpers.addDropShadow(joinBtn, color: joinBtnDisabledShadowColor.CGColor, offset: CGSize(width: 0,height: 3), shadowRadius: 0, opacity: 1, cornerRadius: 10)
            joinBtn.backgroundColor = joinBtnDisabledColor
        }
        drawParticipantsProfilePics()
    }
    
    @IBAction func onJoin(_ sender: AnyObject) {
        delegate?.joinPlan(plan)
    }
    
    fileprivate func drawParticipantsProfilePics() {
        for participantsImgView in participantsImgViews {
            participantsImgView.removeFromSuperview()
        }
        if let participants = plan?.participants {
            let profileImageWidth:CGFloat = 34.0
            if participants.count > 0 {
                var x:CGFloat = 9
                let y:CGFloat = 0

                for i in 0 ..< participants.count {
                    let participant = participants[i]
                    // don't draw the owner of the plan
                    if participant.objectId == plan?.host.objectId {
                        continue
                    }
                    let imgUrl = participant.profileImageUrl
                    let imgView = UIImageView(frame: CGRect(x: x, y: y, width: profileImageWidth, height: profileImageWidth))
                    imgView.contentMode = UIViewContentMode.scaleAspectFit
                    self.participantsView.addSubview(imgView)
                    self.participantsImgViews.append(imgView)
                    ViewHelpers.roundedCorner(imgView, radius: profileImageWidth/2)
                    ViewHelpers.fadeInImage(imgView, imgUrl: imgUrl)
                    x += 42

                    if (i < participants.count - 1) && (x + 42 + profileImageWidth) > participantsView.bounds.width { // no more room to draw more profile pics
                        let remainderCount = participants.count - (i+1)
                        let remainderCountLabel = UILabel(frame: CGRect(x: x, y: y, width: profileImageWidth, height: profileImageWidth))
                        remainderCountLabel.text = "+\(remainderCount)"
                        remainderCountLabel.font = UIFont.systemFont(ofSize: 14)
                        remainderCountLabel.textColor = UIColor(red: 229/255, green: 104/255, blue: 34/255, alpha: 1)
                        remainderCountLabel.backgroundColor = UIColor(red: 253/255, green: 203/255, blue: 40/255, alpha: 1)
                        remainderCountLabel.textAlignment = .center
                        self.participantsView.addSubview(remainderCountLabel)
                        self.participantsImgViews.append(remainderCountLabel)
                        ViewHelpers.roundedCorner(remainderCountLabel, radius: profileImageWidth/2)
                        break;
                    }
                }
            }
        }
    }
}
