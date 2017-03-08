//
//  ProfileActionsTableViewCell.swift
//  8Yet
//
//  Created by Quan Ding on 3/7/16.
//  Copyright © 2016 EightYet. All rights reserved.
//

import UIKit

class ProfileActionsTableViewCell: UITableViewCell {
    var user: User?
    
    @IBOutlet weak var actionButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        ViewHelpers.addDropShadow(actionButton, color: UIColor(red: 199/255, green: 88/255, blue: 31/255, alpha: 1).CGColor, offset: CGSize(width: 0,height: 3), shadowRadius: 0, opacity: 1, cornerRadius: 10)
    }

    @IBAction func onButtonClick(_ sender: AnyObject) {
    }
}
