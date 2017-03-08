//
//  PlanDetailsParticipantTableViewCell.swift
//  8Yet
//
//  Created by Quan Ding on 2/22/16.
//  Copyright © 2016 EightYet. All rights reserved.
//

import UIKit

protocol PlanDetailsParticipantTableViewCellDelegate : class {
    func profileImageTapped(_ forCell: UITableViewCell)
}

class PlanDetailsParticipantTableViewCell: UITableViewCell {
    weak var delegate: PlanDetailsParticipantTableViewCellDelegate?
    
    var user: User? {
        didSet{
            if let user = user {
                ViewHelpers.fadeInImage(profileImage, imgUrl: user.profileImageUrl)
                nameLabel.text = user.firstName
                nameLabel.sizeToFit()
                if user.objectId != User.currentUser()?.objectId {
                    let numMutualFriends = User.currentUser()?.getCommonFriends(user).count ?? 0
                    let numCommonInterests = User.currentUser()?.getCommonInterests(user).count ?? 0
                    commonInterestsLabel.text = "\(numCommonInterests) common interests"
                    commonInterestsLabel.sizeToFit()
                    mutualFriendsLabel.text = "\(numMutualFriends) mutual friends"
                    mutualFriendsLabel.sizeToFit()
                    commonsView.isHidden = false
                } else {
                    commonsView.isHidden = true
                }
                
                if isHost {
                    hostLabel.isHidden = false
                } else {
                    hostLabel.isHidden = true
                }
            }
        }
    }
    
    var isHost = false
    
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var hostLabel: UILabel!
    @IBOutlet weak var commonInterestsLabel: UILabel!
    @IBOutlet weak var mutualFriendsLabel: UILabel!
    @IBOutlet weak var commonsView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        ViewHelpers.roundedCorner(profileImage, radius: profileImage.bounds.width/2)
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(PlanDetailsParticipantTableViewCell.onProfileImageTap(_:)))
        self.profileImage.isUserInteractionEnabled = true
        self.profileImage.addGestureRecognizer(tapGestureRecognizer)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    // MARK: - Actions
    func onProfileImageTap(_ gestureRecognizer: UITapGestureRecognizer) {
        delegate?.profileImageTapped(self)
    }
}
