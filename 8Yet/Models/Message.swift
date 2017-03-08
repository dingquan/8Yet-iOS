//
//  Message.swift
//  8Yet
//
//  Created by Ding, Quan on 3/9/15.
//  Copyright (c) 2015 EightYet. All rights reserved.
//

import Foundation

enum MessageType:String {
    case Text = "text"
    case Location = "location"
    case Image = "image"
    case System = "system"
}

class Message: JSQMessage {
    var id: String!
    var type: MessageType!
    var profileImgUrl: String!
    var sysMsgData: NSDictionary?
    
    init(id: String, senderId: String, senderDisplayName: String, profileImgUrl: String, date: Date, text: String) {
        super.init(senderId: senderId, senderDisplayName: senderDisplayName, date: date, text: text)
        self.type = MessageType.Text
        self.profileImgUrl = profileImgUrl
        self.id = id
    }

    init(id: String, senderId: String, senderDisplayName: String, profileImgUrl: String, date: Date, location: CLLocation) {
        let locationItem = JSQLocationMediaItem()
        locationItem.location = location
//        locationItem.setLocation(location, withCompletionHandler: completion)
        super.init(senderId: senderId, senderDisplayName: senderDisplayName, date: date, media: locationItem)
        self.type = MessageType.Location
        self.profileImgUrl = profileImgUrl
        self.id = id
    }
    
    init(id: String, senderId: String, senderDisplayName: String, profileImgUrl: String, date: Date, image: UIImage) {
        let photoItem = JSQPhotoMediaItem(image: image)
        super.init(senderId: senderId, senderDisplayName: senderDisplayName, date: date, media: photoItem)
        self.type = MessageType.Image
        self.profileImgUrl = profileImgUrl
        self.id = id
    }
    
    init(id: String, senderId: String, senderDisplayName: String, profileImgUrl: String, date: Date, sysMsgData: NSDictionary) {
        super.init(senderId: senderId, senderDisplayName: senderDisplayName, date: date, text: "")
        self.type = MessageType.System
        self.profileImgUrl = profileImgUrl
        self.id = id
        self.sysMsgData = sysMsgData
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
