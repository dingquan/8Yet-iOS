//
//  MenuTableViewCell.swift
//  TwitterV2
//
//  Created by Ding, Quan on 2/26/15.
//  Copyright (c) 2015 Codepath. All rights reserved.
//

import UIKit

class MenuTableViewCell: UITableViewCell {
    var isSubMenu: Bool? {
        didSet {
            if isSubMenu == true {
                containerView.backgroundColor = UIColor(red: 246/255, green: 246/255, blue: 246/255, alpha: 1)
                separatorView.isHidden = true
            } else {
                containerView.backgroundColor = UIColor.white
                separatorView.isHidden = false
            }
        }
    }
    
    var msg: String? {
        didSet{
            if let msg = msg {
                if msg.utf16.count > 0 {
                    msgView.isHidden = false
                    msgLabel.text = msg
                } else {
                    msgView.isHidden = true
                }
            } else {
                msgView.isHidden = true
            }
        }
    }
    
    var menuName: String? {
        didSet {
            menuLabel.text = menuName ?? ""
        }
    }
    
    var menuIconName: String? {
        didSet {
            if menuIconName != nil && menuIconName != "" {
                icon.image = UIImage(named: menuIconName!)
            }
        }
    }
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var menuLabel: UILabel!
    @IBOutlet weak var msgView: UIView!
    @IBOutlet weak var msgLabel: UILabel!
    @IBOutlet weak var separatorView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        msgView.isHidden = true
    }

    override func layoutSubviews() {
        ViewHelpers.roundedCorner(msgView, radius: msgView.bounds.height/2)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
