//
//  Chat.swift
//  8Yet
//
//  Created by Quan Ding on 5/31/15.
//  Copyright (c) 2015 EightYet. All rights reserved.
//

import Foundation

class Chat: PFObject, PFSubclassing {
    private static var __once: () = {
            self.registerSubclass()
        }()
    override class func initialize() {
        struct Static {
            static var onceToken : Int = 0;
        }
        _ = Chat.__once
    }
    
    class func parseClassName() -> String {
        return "Chat"
    }
    
    @NSManaged var users: [User]
    @NSManaged var lastMsg: String?
    @NSManaged var lastMsgFromUser: User?
    @NSManaged var lastMsgTime: Date?
    
    var hasNewMsg:Bool? //whether current user has read last message in the chat
    
    // get the list of chat for the current user
    class func getChatList(_ completion: @escaping ([Chat]!) -> Void){
        
        PFCloud.callFunctionInBackground("findChatList", withParameters: nil) { (chats:AnyObject?, error: NSError?) -> Void in
            if error == nil {
                let chatList = chats as! [Chat]?
                completion(chatList)
            } else {
                NSLog("error finding chat list: \(error!.localizedDescription)")
            }
        }
    }
    
    class func get8YetChat(_ completion: @escaping (Chat) -> Void){
        
        PFCloud.callFunctionInBackground("findChatWith8Yet", withParameters: nil) { (chats:AnyObject?, error: NSError?) -> Void in
            if error == nil {
                if let chatList = chats as? [Chat] {
                    if chatList.count > 0 {
                        completion(chatList[0])
                    }
                }
            } else {
                NSLog("error finding chat list: \(error!.localizedDescription)")
            }
        }
    }
    
    class func getChatByIdWithCompletion(_ id: String?, completion: @escaping (_ chat: Chat?, _ error: NSError?) -> Void) {
        if let id = id {
            let query = PFQuery(className: "Chat")
            query.includeKey("users")
            query.includeKey("lastMsgFromUser")
            query.getObjectInBackgroundWithId(id, block: { (chat: PFObject?, error: NSError?) -> Void in
                completion(chat: chat as? Chat, error: error)
            })
        }
    }
    
    func getChatName() -> String {
        var chatName = ""
        if users.count == 2 { // no group chat yet, so count is always 2
            if users[0].objectId == User.currentUser()?.objectId {
                chatName = users[1].firstName ?? ""
            } else {
                chatName = users[0].firstName ?? ""
            }
        } else {
            chatName = "Group Chat \(users.count)"
        }
        return chatName
    }
    
    func getImgUrl() -> String? {
        var url: String? = nil
        if users.count == 2 {
            url = (users[0].objectId == User.currentUser()?.objectId ? users[1].profileImageUrl : users[0].profileImageUrl)
        }
        return url
    }
}
