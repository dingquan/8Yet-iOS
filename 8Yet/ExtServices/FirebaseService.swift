//
//  FirebaseService.swift
//  8Yet
//
//  Created by Quan Ding on 6/17/15.
//  Copyright (c) 2015 EightYet. All rights reserved.
//

import Foundation

class FirebaseService {
    static let sharedInstance = FirebaseService()
    
    fileprivate let firebaseUrl = Configuration.sharedInstance.getFirebaseUrl()
    
    fileprivate var firebaseRef: Firebase!
    fileprivate var messagesRef: Firebase!
    fileprivate var usersRef : Firebase!
    fileprivate var plansRef : Firebase!
    fileprivate var chatQueryMap : [String: FQuery?]

    init(){
        NSLog("Initialize Firebase singleton. firebaseUrl: \(Configuration.sharedInstance.getFirebaseUrl())")
        Firebase.defaultConfig().persistenceEnabled = true
        firebaseRef = Firebase(url: firebaseUrl)
        messagesRef = Firebase(url: firebaseUrl + "/messages/")
        usersRef = Firebase(url: firebaseUrl + "/users/")
        plansRef = Firebase(url: firebaseUrl + "/plans/")
        chatQueryMap = [String: FQuery?]()
        loginFirebaseIfNeeded()
    }
    
    func loginFirebaseIfNeeded() {
        firebaseRef.observeAuthEventWithBlock({ authData in
            if authData != nil {
                // user authenticated with Firebase
                NSLog("firebase logged in. \(authData)")
            } else {
                NSLog("firebase not logged in")
                if let user = User.currentUser() {
                    self.loginFirebase(user)
                }
            }
        })
    }
    
    func logout() {
        firebaseRef.unauth()
    }
    
    func loginFirebase(_ user: User){
        if user.isAuthenticated(){
            let accessToken = FBSDKAccessToken.currentAccessToken().tokenString
            firebaseRef.authWithOAuthProvider("facebook", token: accessToken,
                withCompletionBlock: { error, authData in
                    if error != nil {
                        NSLog("Firebase Login failed. \(error)")
                    } else {
                        NSLog("Firebase Login success! \(authData)")
                        if user.chatUid == nil {
                            let auth = authData as FAuthData
                            user.chatUid = auth.uid
                            user.saveInBackground()
                        }
                    }
            })
        } else {
            NSLog("Firebase login, user not authenticated")
        }
    }

    func listenForNewMessagesForChatSinceTime(_ chat: Chat, since: Date?, completion: @escaping (_ message: Message?, _ error: NSError?) -> Void) -> UInt {
        NSLog("listenForNewMessagesForChatSinceTime for chat \(chat.objectId!) since \(since)")
        let chatRef = messagesRef.childByAppendingPath(chat.objectId!)
        var query = chatRef.queryOrderedByChild("createdAt").queryLimitedToLast(20)
        chatQueryMap[chat.objectId!] = query
        if let since = since {
            query = query.queryStartingAtValue(since.timeIntervalSince1970 * 1000)
        }
        let handle = query.observeEventType(FEventType.ChildAdded, withBlock: { (snapshot: FDataSnapshot!) -> Void in
            let message = self.parseMessage(snapshot)
            completion(message: message, error: nil)
            }) { (error: NSError!) -> Void in
                NSLog("error listening for new Chat messages: \(error)")
                completion(message: nil, error: error)
        }
        return handle
    }
    
    func fetchOlderMessagesForChat(_ chat: Chat, latestTime: Date, count: UInt, completion: @escaping (_ messages: [Message], _ error: NSError?) -> Void) {
        NSLog("fetchMoreMessagesForChat for chat \(chat.objectId!), latestTime \(latestTime), count: \(count)")
        let chatRef = messagesRef.childByAppendingPath(chat.objectId!)
        // queryEndingAtValue is inclusive, so let's query till one millisecond prior to that so that it doesn't include the message we already have
        let query = chatRef.queryOrderedByChild("createdAt").queryEndingAtValue(latestTime.timeIntervalSince1970 * 1000 - 1).queryLimitedToLast(count)
        
        query.observeSingleEventOfType(FEventType.Value, withBlock: { (snapshot: FDataSnapshot!) -> Void in
            var messages = [Message]()
            for childSnapshot in snapshot.children {
                let message = self.parseMessage(childSnapshot as! FDataSnapshot)
                if let message = message {
                    messages.append(message)
                }
            }
            completion(messages: messages, error: nil)
            }) { (error: NSError!) -> Void in
                NSLog("error listening for new Chat messages: \(error)")
                completion(messages:[], error: error)
        }
    }
    
    func listenForUnreadChats(_ completion: @escaping (_ chatsWithNewMsgs: [String]?) -> Void) -> UInt?{
        NSLog("listenForUnreadChats for user \(User.currentUser()?.objectId)")
        var handle:UInt?
        if let user = User.currentUser() {
            let unreadChatsRef = usersRef.childByAppendingPath("\(user.objectId!)/unreadChats");
            handle = unreadChatsRef.observeEventType(FEventType.Value, withBlock: { snapshot in
                var chatsWithNewMsgs:[String] = []
                for chatState in snapshot.children.allObjects as! [FDataSnapshot] {
                    let chatId = chatState.key as String
                    let msgCnt = chatState.value as? Int
                    if msgCnt > 0 {
                        chatsWithNewMsgs.append(chatId)
                    }
                }
                NSLog("New unread chat messages: \(chatsWithNewMsgs)")
                completion(chatsWithNewMsgs: chatsWithNewMsgs)
            }, withCancelBlock:  { error in
                NSLog("Error listening for unread chats: \(error)")
            })
        }
        return handle
    }
    
    func listenForUnreadChat(_ chat: Chat, completion: @escaping (_ newMsgCount: Int?) -> Void) -> UInt?{
        NSLog("listenForUnreadChat for userId=\(User.currentUser()?.objectId), chatId=\(chat.objectId)")
        var handle:UInt?
        if let user = User.currentUser() {
            let unreadChatRef = usersRef.childByAppendingPath("\(user.objectId!)/unreadChats/\(chat.objectId!)");
            handle = unreadChatRef.observeEventType(FEventType.Value, withBlock: { snapshot in
                let count = snapshot.value as? Int
                completion(newMsgCount: count)
                }, withCancelBlock:  { error in
                    NSLog("Error listening for unread chat: \(error)")
            })
        }
        return handle
    }
    
//    func listenForNewUserMatches(since: NSDate?, completion: (userMatch: UserMatch?, error: NSError?) -> Void) -> UInt? {
//        NSLog("listenForNewUserMatches since: \(since)")
//        var handle:UInt?
//        if let user = User.currentUser() {
//            let userMatchRef = usersRef.childByAppendingPath("\(user.objectId!)/userMatch")
//            // For some reason, maybe it's a firebase bug, without the 'queryLimitedToLast' part, 
//            // the firing of the child added event was very unreliable. sometimes only fires once, sometimes not at all
//            var query = userMatchRef.queryOrderedByChild("createdAt").queryLimitedToLast(20)
//            if let since = since {
//                query = query.queryStartingAtValue(since.timeIntervalSince1970 * 1000)
//            }
//            handle = query.observeEventType(FEventType.ChildAdded, withBlock: { snapshot in
//                let userMatchId = snapshot.key
//                NSLog("New firebase UserMatch created \(userMatchId)")
//                UserMatch.getUserMatchById(userMatchId, completion: completion)
//            }, withCancelBlock:  { error in
//                NSLog("Error listening for new userMatches: \(error)")
//                completion(userMatch: nil, error: error)
//            })
//        }
//        NSLog("Finished listenForNewUserMatches, handle=\(handle)")
//        return handle
//    }
    
    func listenForPlanUpdates(_ plan: Plan, completion: @escaping (_ error: NSError?) -> Void) -> UInt? {
        NSLog("listenForPlanUpdates. planId=\(plan.objectId)")
        var handle: UInt?
        
        let planId = plan.objectId!
        let planRef = plansRef.childByAppendingPath("\(planId)")
        handle = planRef.observeEventType(.ChildChanged, withBlock: { (snapshot) -> Void in
            NSLog("Firebase plan updates, planId=\(planId)")
            completion(error: nil)
            }) { (error) -> Void in
                NSLog("Error listenForPlanUpdates. planId=\(planId), error: \(error)")
                completion(error: error)
        }
        
        NSLog("Finished listenForPlanUpdates, planId=\(plan.objectId), handle=\(handle)")
        return handle
    }
    
    func removeObserverForPlanUpdates(_ plan: Plan) {
        NSLog("removeObserverForPlanUpdates: \(plan.objectId)")
        let planId = plan.objectId!
        let planRef = plansRef.childByAppendingPath("\(planId)")
        planRef.removeAllObservers()
    }
    
    // set the boolean flag in /users/{userId}/unreadChats to indicate that there's unread messages
    func setUnreadChats(_ chat: Chat){
        for user in chat.users {
            if user.objectId == User.currentUser()?.objectId {
                continue
            }
            if chat.objectId == nil {
                print("ERROR in setUnreadChats, objectId for chat \(chat) is null")
                continue
            }
            
            let unreadChatRef = usersRef.childByAppendingPath("\(user.objectId!)/unreadChats/\(chat.objectId!)")
            unreadChatRef.runTransactionBlock({ (currentData: FMutableData!) -> FTransactionResult! in
                let value = currentData.value as? Int
                currentData.value = (value ?? 0) + 1
                return FTransactionResult.successWithValue(currentData)
            })
        }
    }
    
    // clear the boolean flag for self upon opening the chat
    func clearUnreadChat(_ chat: Chat) {
        if let user = User.currentUser() {
            let unreadChatsRef = usersRef.childByAppendingPath("\(user.objectId!)/unreadChats")
            let data = [chat.objectId!: 0]
            unreadChatsRef.updateChildValues(data)
        }
    }
    
    func sendMessageForChat(_ chat: Chat, value: NSDictionary) {
        let chatRef = messagesRef.childByAppendingPath(chat.objectId!)
        chatRef.childByAutoId().setValue(value,
            withCompletionBlock: {
                (error:NSError?, ref:Firebase!) in
                if (error != nil) {
                    NSLog("Data could not be saved. \(error)")
                } else {
                    NSLog("Data saved successfully!")
                }
        })
    }
    
    func removeObserversForChat(_ chat: Chat){
        NSLog("removeObserversForChat. chatId=\(chat.objectId!)")
        // see http://stackoverflow.com/questions/30838825/compile-error-on-firebasehandle
        // need to call removeAllObservers on FQuery, not Firebase when query is used
        let query = chatQueryMap[chat.objectId!]
        if let query = query {
            query?.removeAllObservers()
        }
    }
    
    func removeObserversForUnreadChats(_ handle: UInt?) {
        NSLog("removeObserversForUnreadChats: \(handle)")
        if let handle = handle {
            if let user = User.currentUser() {
                let unreadChatsRef = usersRef.childByAppendingPath("\(user.objectId!)/unreadChats");
                unreadChatsRef.removeObserverWithHandle(handle)
            }
        }
    }
    
    func removeObserversForUnreadChat(_ chat: Chat, handle: UInt?) {
        NSLog("removeObserversForUnreadChats: \(handle)")
        if let handle = handle {
            if let user = User.currentUser() {
                let unreadChatRef = usersRef.childByAppendingPath("\(user.objectId!)/unreadChats/\(chat.objectId)");
                unreadChatRef.removeObserverWithHandle(handle)
            }
        }
    }
    
    func removeObserversForNewUserMatches(_ handle: UInt?) {
        NSLog("removeObserversForNewUserMatches: \(handle)")
        if let handle = handle {
            if let user = User.currentUser() {
                let userMatchRef = usersRef.childByAppendingPath("\(user.objectId!)/userMatch");
                userMatchRef.removeObserverWithHandle(handle)
            }
        }
    }
    
    fileprivate func parseMessage(_ snapshot: FDataSnapshot) -> Message? {
        let id = snapshot.key
        let type = snapshot.value["type"] as? String
        let sender = snapshot.value["sender"] as? String
        let displayName = snapshot.value["displayName"] as? String
        let createdAt = snapshot.value["createdAt"] as? NSNumber
        let profileImgUrl = snapshot.value["profileImgUrl"] as? String
        
        var message: Message?
        if type != nil && sender != nil && displayName != nil && profileImgUrl != nil  && createdAt != nil{
            let date: Date = Date(timeIntervalSince1970: createdAt!.doubleValue/1000)
            
            switch type! {
            case MessageType.Text.rawValue:
                let text = snapshot.value["text"] as? String
                if let text = text {
                    message = Message(id: id, senderId: sender!, senderDisplayName: displayName!, profileImgUrl: profileImgUrl!, date: date, text: text)
                }
            case MessageType.Location.rawValue:
                let latitude = snapshot.value["latitude"] as? NSNumber
                let longitude = snapshot.value["longitude"] as? NSNumber
                if latitude != nil && longitude != nil {
                    let location = CLLocation(latitude: latitude!.doubleValue, longitude: longitude!.doubleValue)
                    message = Message(id: id, senderId: sender!, senderDisplayName: displayName!, profileImgUrl: profileImgUrl!, date: date, location: location)
                }
            case MessageType.Image.rawValue:
                let base64EncodedImage = snapshot.value["imageData"] as? String
                if base64EncodedImage != nil {
                    let decodedData = Data(base64EncodedString: base64EncodedImage!, options: NSData.Base64DecodingOptions())
                    if decodedData != nil {
                        let decodedImage = UIImage(data: decodedData!)
                        if decodedImage != nil {
                            message = Message(id: id, senderId: sender!, senderDisplayName: displayName!, profileImgUrl: profileImgUrl!, date: date, image: decodedImage!)
                        }
                    }
                }
            case MessageType.System.rawValue:
                let sysMsgData = snapshot.value["data"] as? NSDictionary
                if let sysMsgData = sysMsgData {
                    message = Message(id: id, senderId: sender!, senderDisplayName: displayName!, profileImgUrl: profileImgUrl!, date: date, sysMsgData: sysMsgData)
                }
            default:
                ()
            }
        }
        return message
    }
}
