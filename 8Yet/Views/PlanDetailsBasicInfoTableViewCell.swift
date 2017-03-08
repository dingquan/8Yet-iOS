//
//  PlanDetailsBasicInfoTableViewCell.swift
//  8Yet
//
//  Created by Quan Ding on 2/22/16.
//  Copyright © 2016 EightYet. All rights reserved.
//

import UIKit

protocol PlanDetailsBasicInfoTableViewCellDelegate: class {
    func onQuitPlan()
}

class PlanDetailsBasicInfoTableViewCell: UITableViewCell {
    fileprivate var rating = 0

    weak var delegate: PlanDetailsBasicInfoTableViewCellDelegate?

    var plan: Plan? {
        didSet {
            if let plan = plan {
                timeLabel.text = amPmDateFormatter.string(from: plan.startTime)
                timeLabel.sizeToFit()
                if let location = plan.location {
                    if let locationName = location.name {
                        locationLabel.text = locationName
                    } else {
                        locationLabel.text = location.address
                    }
                    if let cuisines = location.cuisines {
                        cuisineLabel.isHidden = false
                        cuisineLabel.text = cuisines.joined(separator: ",")
                    } else {
                        cuisineLabel.isHidden = true
                    }
                    priceLevelLabel.text = location.getPriceLevelString()
                    rating = location.rating?.intValue ?? 0
                    switch rating {
                    case 1:
                        ratingsImg.image = UIImage(named: "ratingStars1")
                    case 2:
                        ratingsImg.image = UIImage(named: "ratingStars2")
                    case 3:
                        ratingsImg.image = UIImage(named: "ratingStars3")
                    case 4:
                        ratingsImg.image = UIImage(named: "ratingStars4")
                    case 5:
                        ratingsImg.image = UIImage(named: "ratingStars5")
                    default:
                        ratingsImg.isHidden = true
                        priceLevelLabel.isHidden = true
                    }
                }
                
                locationLabel.sizeToFit()
                cuisineLabel.sizeToFit()
                priceLevelLabel.sizeToFit()
                topicLabel.text = plan.topic ?? ""
                topicLabel.sizeToFit()
                if topicLabel.text == "" {
                    topicLabel.isHidden = true
                    topicImg.isHidden = true
                } else {
                    topicLabel.isHidden = false
                    topicImg.isHidden = false
                }
                
                locationLabelBottomConstraint.constant = 14
                if plan.topic != nil && plan.topic != "" {
                    locationLabelBottomConstraint.constant += topicLabel.frame.height + 14
                }
                if rating != 0 {
                    locationLabelBottomConstraint.constant += 22
                }
                
                if plan.objectId == User.currentUser()?.todaysPlan?.objectId {
                    var quitPlanText = "Quit Plan"
                    if plan.host.objectId == User.currentUser()?.objectId {
                        quitPlanText = "Cancel Plan"
                    }
                    let mutableString = quitPlanBtn.titleLabel?.attributedText as! NSMutableAttributedString
                    mutableString.mutableString.setString(quitPlanText)
                    quitPlanBtn.setTitle(quitPlanText, for: UIControlState())
                    quitPlanBtn.setAttributedTitle(mutableString, for: UIControlState())
                    quitPlanBtn.titleLabel?.sizeToFit()
                    quitPlanBtn.sizeToFit()
                    
                    if plan.participants.count > 1 && plan.host.objectId == User.currentUser()?.objectId { // ower can't cancel the plan if some one has joined in
                        quitPlanBtn.isEnabled = false
                        quitPlanBtn.titleLabel?.textColor = UIColor(red: 167/255, green: 169/255, blue: 171/255, alpha: 1)
                    } else {
                        quitPlanBtn.isEnabled = true
                        quitPlanBtn.titleLabel?.textColor = UIColor(red: 229/255, green: 104/255, blue: 34/255, alpha: 1)
                    }
                } else {
                    quitPlanBtn.isHidden = true
                }
            }
        }
    }
    
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var cuisineLabel: UILabel!
    @IBOutlet weak var ratingsImg: UIImageView!
    @IBOutlet weak var priceLevelLabel: UILabel!
    @IBOutlet weak var topicLabel: UILabel!
    @IBOutlet weak var topicImg: UIImageView!
    @IBOutlet weak var quitPlanBtn: UIButton!
    
    @IBOutlet weak var locationLabelBottomConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBAction func onQuitPlan(_ sender: AnyObject) {
        delegate?.onQuitPlan()
    }
}
