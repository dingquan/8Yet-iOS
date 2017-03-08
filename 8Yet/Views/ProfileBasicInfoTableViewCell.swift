//
//  ProfileBasicInfoTableViewCell.swift
//  8Yet
//
//  Created by Quan Ding on 3/7/16.
//  Copyright © 2016 EightYet. All rights reserved.
//

import UIKit

protocol ProfileBasicInfoTableViewCellDelegate: class {
    func onReportUser()
}

class ProfileBasicInfoTableViewCell: UITableViewCell {
    var delegate: ProfileBasicInfoTableViewCellDelegate?
    var user: User? {
        didSet {
            if let user = user {
                ViewHelpers.fadeInImage(profileImage, imgUrl: user.profileImageUrl)
                nameLabel.text = user.firstName
                nameLabel.sizeToFit()
                
                if user.objectId == User.currentUser()?.objectId {
                    reportBtn.isHidden = true
                } else {
                    reportBtn.isHidden = false
                }
                
                let numJoined = user.numPlansJoined ??  0
                let numCalled = user.numPlansCalled ?? 0
                numCalledLabel.text = "\(numCalled)"
                numCalledLabel.sizeToFit()
                numJoinedLabel.text = "\(numJoined)"
                numJoinedLabel.sizeToFit()
            }
        }
    }
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var numCalledLabel: UILabel!
    @IBOutlet weak var numJoinedLabel: UILabel!
    @IBOutlet weak var reportBtn: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setupViews()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    // MARK: - Actions
    @IBAction func onReportUser(_ sender: AnyObject) {
        delegate?.onReportUser()
    }
    
    // MARK: - Private function
    func setupViews() {
        ViewHelpers.roundedCorner(profileImage, radius: profileImage.bounds.width/2)
        ViewHelpers.addDropShadow(containerView, color: UIColor(red: 218/255, green: 177/255, blue: 36/255, alpha: 1).CGColor, offset: CGSize(width: 0, height: 3), shadowRadius: 0, opacity: 1, cornerRadius: 0)
    }
}
