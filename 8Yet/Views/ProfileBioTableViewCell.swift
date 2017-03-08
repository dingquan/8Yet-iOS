//
//  ProfileBioTableViewCell.swift
//  8Yet
//
//  Created by Quan Ding on 3/12/16.
//  Copyright © 2016 EightYet. All rights reserved.
//

import UIKit

protocol ProfileBioTableViewCellDelegate: class {
    func onEditBio()
}

class ProfileBioTableViewCell: UITableViewCell {
    var delegate: ProfileBioTableViewCellDelegate?
    
    var user: User? {
        didSet {
            if let user = user {
                let firstName = user.firstName ?? "User"
                userBioLabel.text = user.bio ?? "\(firstName) is busy chalking up his/her bio, stay tuned..."
                userBioLabel.preferredMaxLayoutWidth = userBioLabel.bounds.width
                userBioLabel.sizeToFit()
                if user.objectId != User.currentUser()?.objectId {
                    editBtn.isHidden = true
                } else {
                    editBtn.isHidden = false
                }
            }
        }
    }
    
    @IBOutlet weak var editBtn: UIButton!
    @IBOutlet weak var userBioLabel: UILabel!
    
    @IBAction func editBio(_ sender: AnyObject) {
        delegate?.onEditBio()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
