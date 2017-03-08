//
//  ChatTableViewCell.swift
//  8Yet
//
//  Created by Quan Ding on 5/31/15.
//  Copyright (c) 2015 EightYet. All rights reserved.
//

import UIKit

private let textColor: UIColor = UIColor(red: 147/255, green: 149/255, blue: 152/255, alpha: 1)

class ChatTableViewCell: UITableViewCell {
    fileprivate var users: [User] = []
    
    var chat: Chat? {
        didSet {
            if let chat = chat {
                self.users = chat.users
                let hasNewMsg = chat.hasNewMsg ?? false
                self.name.text = chat.getChatName()
//                if hasNewMsg {
//                    self.name.font = UIFont.boldSystemFontOfSize(14)
//                } else {
//                    self.name.font = UIFont.systemFontOfSize(14)
//                }
//                self.name.font = UIFont(name: serifFontName, size: 24)
                self.name.sizeToFit()
                self.lastMessage.text = chat.lastMsg ?? ""
//                if hasNewMsg {
//                    self.lastMessage.font = UIFont.boldSystemFontOfSize(12)
//                    self.lastMessage.textColor = UIColor.blackColor()
//                } else {
//                    self.lastMessage.font = UIFont.systemFontOfSize(12)
//                    self.lastMessage.textColor = UIColor.darkGrayColor()
//                }
//                self.lastMessage.font = UIFont(name: sansSerifFontName, size: 15)
//                self.lastMessage.textColor = UIColor.darkGrayColor()

                if hasNewMsg {
                    msgIndicator.isHidden = false
                } else {
                    msgIndicator.isHidden = true
                }

                self.lastMessage.sizeToFit()
                self.lastMessageTime.text = (chat.lastMsgTime != nil ? chat.lastMsgTime!.shortTimeAgoSinceNow() : "")
                self.lastMessageTime.sizeToFit()
                if (chat.getImgUrl() != nil && (chat.getImgUrl() != oldValue?.getImgUrl())) {
                    ViewHelpers.fadeInImage(self.profileImage, imgUrl: chat.getImgUrl())
                }
            } else {
                NSLog("ChatTableViewCell, chat is null")
            }
        }
    }
    
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var lastMessage: UILabel!
    @IBOutlet weak var lastMessageTime: UILabel!
    @IBOutlet weak var msgIndicator: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        // change the default margin of the table divider length
        self.preservesSuperviewLayoutMargins = false
        
        if (self.responds(to: #selector(setter: UITableViewCell.separatorInset))){
            self.separatorInset = UIEdgeInsetsMake(0, name.frame.origin.x, 0, 0)
        }
        
        self.layoutMargins = UIEdgeInsets.zero

        ViewHelpers.roundedCorner(msgIndicator, radius: 5)
        ViewHelpers.roundedCorner(self.profileImage, radius: profileImage.bounds.width/2)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
}
