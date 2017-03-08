//
//  ProfileMutualFriendsTableViewCell.swift
//  8Yet
//
//  Created by Quan Ding on 3/7/16.
//  Copyright © 2016 EightYet. All rights reserved.
//

import UIKit

protocol  ProfileMutualFriendsTableViewCellDelegate: class {
    func profileImageTapped(_ user: User)
}

class ProfileMutualFriendsTableViewCell: UITableViewCell {
    fileprivate var commonFriendsImageViews = [UIImageView]()
    fileprivate var commonFriends: [User] = []
    
    var user: User? {
        didSet {
            drawParticipantsProfilePics()
        }
    }
    var delegate: ProfileMutualFriendsTableViewCellDelegate?
    
    @IBOutlet weak var commonFriendsContainerView: UIView!
    @IBOutlet weak var commonFriendsContainerViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var commonFriendsContainerLeftConstraint: NSLayoutConstraint!
    @IBOutlet weak var commonFriendsContainerRightConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    // MARK: - Actions
    func onProfileImageTap(_ gestureRecognizer: UITapGestureRecognizer) {
        if let index = gestureRecognizer.view?.tag {
            delegate?.profileImageTapped(commonFriends[index])
        }
    }
    
    // MARK: - Private functions
    fileprivate func drawParticipantsProfilePics() {
        if let user = self.user {
            let containerWidth = UIScreen.main.bounds.width - commonFriendsContainerLeftConstraint.constant - commonFriendsContainerRightConstraint.constant
            User.currentUser()?.getCommonFriends(user, completion: { (commonFriends, error) -> Void in
                if commonFriends.count > 0 {
                    self.commonFriends = commonFriends
                    
                    for commonFriendImageView in self.commonFriendsImageViews {
                        commonFriendImageView.removeFromSuperview()
                    }
                    
                    var x:CGFloat = 0
                    var y:CGFloat = 0

                    for i in 0 ..< commonFriends.count {
                        let commonFriend = self.commonFriends[i]
                        
                        let profileImageWidth:CGFloat = 42.0
                        let imgUrl = commonFriend.profileImageUrl
                        let profileImage = UIImageView(frame: CGRectMake(x, y, profileImageWidth, profileImageWidth))
                        profileImage.contentMode = UIViewContentMode.ScaleAspectFit
                        profileImage.userInteractionEnabled = true
                        profileImage.tag = i
                        
                        ViewHelpers.roundedCorner(profileImage, radius: profileImageWidth/2)
                        ViewHelpers.fadeInImage(profileImage, imgUrl: imgUrl)
                        
                        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ProfileMutualFriendsTableViewCell.onProfileImageTap(_:)))
                        profileImage.addGestureRecognizer(tapGestureRecognizer)
                        
                        self.commonFriendsContainerView.addSubview(profileImage)
                        self.commonFriendsImageViews.append(profileImage)
                        
                        x += 54
                        if x + profileImageWidth > containerWidth {
                            x = 0
                            y += 54
                        }
                    }
                    
                    self.commonFriendsContainerViewHeightConstraint.constant = y + 54
                }
            })
        }
    }
}
