//
//  ChatViewController.swift
//  8Yet
//
//  Created by Ding, Quan on 3/8/15.
//  Copyright (c) 2015 EightYet. All rights reserved.
//

import UIKit

private let incomingMsgBubbleColor = UIColor(red: 246/255, green: 246/255, blue: 246/255, alpha: 1)
private let outgoingMsgBubbleColor = UIColor(red: 54/255, green: 212/255, blue: 171/255, alpha: 1)
private let incomingMsgTextColor = UIColor(red: 82/255, green: 82/255, blue: 82/255, alpha: 1)
private let outgoingMsgTextColor = UIColor.white

class ChatViewController: JSQMessagesViewController, UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate,UIGestureRecognizerDelegate {
    
    fileprivate static let FETCH_COUNT:UInt = 10
    
    var chat: Chat?
    
    fileprivate var sinceTime: Date?
    fileprivate var fromUser: User = User.currentUser()!
    fileprivate var messages = [Message]()
    fileprivate var avatars = Dictionary<String, JSQMessagesAvatarImage>()
    fileprivate let jsqMessagesBubbleImageFactory: JSQMessagesBubbleImageFactory = JSQMessagesBubbleImageFactory()
    fileprivate var outgoingBubbleImageView :JSQMessagesBubbleImage!
    fileprivate var incomingBubbleImageView :JSQMessagesBubbleImage!
    fileprivate var senderImageUrl: String!
    
    fileprivate let firebaseService = FirebaseService.sharedInstance
    
    fileprivate var refreshControl: UIRefreshControl!
    fileprivate var activityIndicator: UIActivityIndicatorView!
    
    fileprivate func setupFirebase() {
        if (self.messages.count == 0) {
            activityIndicator.startAnimating()
            // stop the activity indicator animation after 5 seconds incase there's no message in the chat
            Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(ChatViewController.stopActivityIndicator(_:)), userInfo: nil, repeats: false)
        }
        if let chat = chat {
            firebaseService.clearUnreadChat(chat)
            firebaseService.removeObserversForChat(chat) // make sure previous listener were removed or firebase will throw error
            firebaseService.listenForNewMessagesForChatSinceTime(chat, since: sinceTime, completion: { (message, error) -> Void in
                let processedMsg = self.processMessage(message)
                if let processedMsg = processedMsg {
                    self.messages.append(processedMsg)
                }
                self.finishReceivingMessage()
                self.activityIndicator.stopAnimating()
            })
        }
    }
    
    func stopActivityIndicator(_ timer: Timer) {
        self.activityIndicator.stopAnimating()
    }
    
    fileprivate func setupActivityIndicator() {
        let x = self.view.bounds.width / 2
        let y = self.view.bounds.height / 2
        self.activityIndicator = UIActivityIndicatorView(frame: CGRect(x: x-10,y: y-10, width: 20, height: 20)) as UIActivityIndicatorView
        activityIndicator.hidesWhenStopped = true
        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
        view.addSubview(activityIndicator)
    }

    func sendMessage(_ text: String!) {
        if let chat = chat {
            Analytics.sharedInstance.event(Analytics.Event.ChatSendMessage.rawValue, properties: ["type": "text"])
            // *** STEP 3: ADD A MESSAGE TO FIREBASE
            let value = [
                "type": MessageType.Text.rawValue,
                "text": text,
                "sender": fromUser.objectId!,
                "profileImgUrl": fromUser.profileImageUrl!,
                "displayName": fromUser.firstName ?? "",
                "createdAt": Date().timeIntervalSince1970 * 1000
            ]
            firebaseService.sendMessageForChat(chat, value: value)
            self.view.endEditing(true)
            updateChatWithLastMsg(chat, value:value)
        }
    }

    func sendLocation(_ latitude: Double, longitude: Double) {
        if let chat = chat {
            Analytics.sharedInstance.event(Analytics.Event.ChatSendMessage.rawValue, properties: ["type": "location"])
            // *** STEP 3: ADD A MESSAGE TO FIREBASE
            let value = [
                "type": MessageType.Location.rawValue,
                "latitude": latitude,
                "longitude": longitude,
                "sender": fromUser.objectId!,
                "profileImgUrl": fromUser.profileImageUrl!,
                "displayName": fromUser.firstName ?? "",
                "createdAt": Date().timeIntervalSince1970 * 1000
            ]
            firebaseService.sendMessageForChat(chat, value: value)
            self.view.endEditing(true)
            updateChatWithLastMsg(chat, value:value)
        }
    }
    
    func sendImage(_ image: UIImage){
        if let chat = chat {
            Analytics.sharedInstance.event(Analytics.Event.ChatSendMessage.rawValue, properties: ["type": "image"])
            // TODO: firebase only works with image data < 10MB. need to check the file size and scale it if it's larger than 10MB
            let imageData = UIImagePNGRepresentation(image)
            if let imageData = imageData {
                let encodedData = imageData.base64EncodedString(options: NSData.Base64EncodingOptions())
                let value = [
                    "type": MessageType.Image.rawValue,
                    "imageData": encodedData,
                    "sender": fromUser.objectId!,
                    "profileImgUrl": fromUser.profileImageUrl!,
                    "displayName": fromUser.firstName ?? "",
                    "createdAt": Date().timeIntervalSince1970 * 1000
                ]
                // *** STEP 3: ADD A MESSAGE TO FIREBASE
                firebaseService.sendMessageForChat(chat, value: value)
                self.view.endEditing(true)
                updateChatWithLastMsg(chat, value: value)
            } else {
                NSLog("ERROR: failed to create PNG representation of image")
            }
        }
    }
    
    func setupAvatarImage(_ name: String, imageUrl: String?, incoming: Bool) {
        // involves network fetching of image, put it to background thread so it doesn't block UI
        DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.high).async {
            if imageUrl != nil && imageUrl! != "" {
                let stringUrl = imageUrl!
                if let url = URL(string: stringUrl) {
                    if let data = try? Data(contentsOf: url) {
                        let image = UIImage(data: data)
                        let diameter = incoming ? UInt(self.collectionView!.collectionViewLayout.incomingAvatarViewSize.width) : UInt(self.collectionView!.collectionViewLayout.outgoingAvatarViewSize.width)
                        let avatarImage = JSQMessagesAvatarImageFactory.avatarImageWithImage(image, diameter: diameter)
                        self.avatars[name] = avatarImage
                    }
                }
            }
            if self.avatars[name] == nil {
                // At some point, we failed at getting the image (probably broken URL), so default to avatarColor
                self.setupAvatarColor(name, incoming: incoming)
            }
            DispatchQueue.main.async {
                self.collectionView!.reloadData() // reload data to show avatars
            }
        }
    }
    
    func setupAvatarColor(_ name: String, incoming: Bool) {
        let diameter = incoming ? UInt(collectionView!.collectionViewLayout.incomingAvatarViewSize.width) : UInt(collectionView!.collectionViewLayout.outgoingAvatarViewSize.width)
        
        let rgbValue = name.hash
        let r = CGFloat(Float((rgbValue & 0xFF0000) >> 16)/255.0)
        let g = CGFloat(Float((rgbValue & 0xFF00) >> 8)/255.0)
        let b = CGFloat(Float(rgbValue & 0xFF)/255.0)
        let color = UIColor(red: r, green: g, blue: b, alpha: 0.5)
        
        let nameLength = name.utf16.count
        if nameLength == 0 {
            return
        }
        let initials : String? = name.substring(to: name.characters.index(name.startIndex, offsetBy: min(1, nameLength)))
        let userImage = JSQMessagesAvatarImageFactory.avatarImageWithUserInitials(initials, backgroundColor: color, textColor: UIColor.grayColor(), font: UIFont.systemFontOfSize(CGFloat(24)), diameter: diameter)
        
        avatars[name] = userImage
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Analytics.sharedInstance.startTimingEvent("Entering \(String(type(of: self)))", properties: [AnyHashable: Any]())
        
        self.navigationItem.title = "\(chat?.getChatName() ?? "Chat")"
        
        automaticallyScrollsToMostRecentMessage = true
        
        senderId = fromUser.objectId
        senderDisplayName = fromUser.firstName ?? ""

        if let urlString = fromUser.profileImageUrl {
            setupAvatarImage(senderDisplayName, imageUrl: urlString, incoming: false)
        } else {
            setupAvatarColor(senderDisplayName, incoming: false)
        }

        self.outgoingBubbleImageView = jsqMessagesBubbleImageFactory.outgoingMessagesBubbleImageWithColor(outgoingMsgBubbleColor)
        self.incomingBubbleImageView = jsqMessagesBubbleImageFactory.incomingMessagesBubbleImageWithColor(incomingMsgBubbleColor)

        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(ChatViewController.fetchOlderMessages), for: UIControlEvents.valueChanged)
        self.collectionView!.insertSubview(refreshControl, atIndex: 0)
        
        // tap anywhere to dismiss the keyboard
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ChatViewController.dismissKeyboard(_:)))
        tapGestureRecognizer.delegate = self
        self.collectionView?.addGestureRecognizer(tapGestureRecognizer)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupActivityIndicator() //add activityIndicator in viewDidAppear instead of viewDidLoad due to self.view doesn't have the correct frame size in viewDidLoad which is needed to position the activity indicator
        setupFirebase()
//        collectionView.collectionViewLayout.springinessEnabled = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // remove the listener when not needed to improve performance
        if let chat = chat {
            firebaseService.clearUnreadChat(chat)
            firebaseService.removeObserversForChat(chat)
        }
        // update the timestamp so that next time we setup firebase to listen for new messages,
        // it only listens for messages that are created after the given date.
        sinceTime = Date()
        Analytics.sharedInstance.finishTimingEvent("Leaving \(String(type(of: self)))", properties: [AnyHashable: Any]())
    }
    
    // ACTIONS
    
    override func didPressSendButton(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        
        sendMessage(text)
        
        finishSendingMessage()
    }
    
    override func didPressAccessoryButton(_ sender: UIButton!) {
        self.view.endEditing(true)
//        let sheet = UIActionSheet(title: "Media Messages", delegate: self, cancelButtonTitle: nil, destructiveButtonTitle: nil, otherButtonTitles: "Send My Location", "Send Photo")
        let sheet = UIActionSheet(title: "Media Messages", delegate: self, cancelButtonTitle: nil, destructiveButtonTitle: nil, otherButtonTitles: "Send My Location")
        // had to add the cancel button separately instead in the init call because the buttonIndex was wrong when setting the cancel button in the init call.
        sheet.cancelButtonIndex = sheet.addButton(withTitle: "Cancel")
        sheet.showFromToolbar(self.inputToolbar!)
    }
    
    func actionSheet(_ actionSheet: UIActionSheet, clickedButtonAt buttonIndex: Int) {
        if (buttonIndex == actionSheet.cancelButtonIndex) {
            return
        }
        switch buttonIndex {
        case 0:
            PFGeoPoint.geoPointForCurrentLocationInBackground({ (geoPoint:PFGeoPoint?, error: NSError?) -> Void in
                if error == nil {
                    if let geoPoint = geoPoint {
                        self.sendLocation(geoPoint.latitude, longitude: geoPoint.longitude)
                    }
                }
            })

        case 1:
            openPhotoPicker()
        default:
            // shouldn't arrive here
            NSLog("Reaching unreachable case. buttonIndex: \(buttonIndex)")
        }
    }
    
    // MARK: - UICollectionView DataSource
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAtIndexPath indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAtIndexPath: indexPath) as! JSQMessagesCollectionViewCell

        let message = messages[indexPath.item]
        if !message.isMediaMessage {
            if message.senderId == senderId {
                cell.textView!.textColor = outgoingMsgTextColor
            } else {
                cell.textView!.textColor = incomingMsgTextColor
            }
            let attributes : [String: AnyObject] = [NSForegroundColorAttributeName: cell.textView!.textColor!, NSUnderlineStyleAttributeName: 1]
            cell.textView!.linkTextAttributes = attributes
        }

        return cell
    }
    
    // MARK: - JSQMessages collection view flow layout delegate
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellTopLabelAtIndexPath indexPath: IndexPath!) -> CGFloat {
        /**
        *  Each label in a cell has a `height` delegate method that corresponds to its text dataSource method
        */
        
        /**
        *  This logic should be consistent with what you return from `attributedTextForCellTopLabelAtIndexPath:`
        *  The other label height delegate methods should follow similarly
        *
        *  if this is the first message or last message was from more than 15 minutes ago, display the timestamp
        */
        if (shouldDisplayTimestamp(indexPath)) {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        }
        
        return 0.0
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellBottomLabelAtIndexPath indexPath: IndexPath!) -> CGFloat {
        let message = messages[indexPath.item]
        if message.type == MessageType.System {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        }
        return 0.0
    }
    
    override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        let userMessageCellSize = super.collectionView(collectionView, layout: collectionViewLayout, sizeForItemAtIndexPath: indexPath)
        let message = messages[indexPath.item]
        if message.type == MessageType.System {
            // for system message, only show bottom label, plus the top label when timestamp needs to be displayed
            // this will hide the avatar image and message bubble which are not needed for system messages.
            var newHeight: CGFloat = 0
            if (shouldDisplayTimestamp(indexPath)) {
                newHeight = kJSQMessagesCollectionViewCellLabelHeightDefault * 2
            } else {
                newHeight = kJSQMessagesCollectionViewCellLabelHeightDefault
            }
            return CGSize(width: userMessageCellSize.width, height: newHeight)
        } else {
            return super.collectionView(collectionView, layout: collectionViewLayout, sizeForItemAtIndexPath: indexPath)
        }
    }
    
    // View  user names above bubbles. NOTE: not showing the user names as it makes the UI too busy
    //    override func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
    //        let message = messages[indexPath.item]
    //
    //        // Sent by me, skip
    //        if message.senderId == senderId {
    //            return CGFloat(0.0);
    //        }
    //
    //        // Same as previous sender, skip
    //        if indexPath.item > 0 {
    //            let previousMessage = messages[indexPath.item - 1];
    //            if previousMessage.senderId == message.senderId {
    //                return CGFloat(0.0);
    //            }
    //        }
    //
    //        return kJSQMessagesCollectionViewCellLabelHeightDefault
    //    }
    
    // MARK: - JSQMessages CollectionView DataSource
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    // View  user names above bubbles. NOTE: not showing the user names as it makes the UI too busy
    //    override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
    //        let message = messages[indexPath.item];
    //
    //        // Sent by me, skip
    //        if message.senderId == senderId {
    //            return nil;
    //        }
    //
    //        // Same as previous sender, skip
    //        if indexPath.item > 0 {
    //            let previousMessage = messages[indexPath.item - 1];
    //            if previousMessage.senderId == message.senderId {
    //                return nil;
    //            }
    //        }
    //
    //        return NSAttributedString(string:message.senderDisplayName)
    //    }
    
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = messages[indexPath.item]
        
        if message.type == MessageType.System {
            return nil
        }
        
        if message.senderId == senderId{
            return self.outgoingBubbleImageView
        } else {
            return self.incomingBubbleImageView
        }
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageAvatarImageDataSource! {
        let message = messages[indexPath.item]
        
        if message.type == MessageType.System {
            return nil
        }
        
        if let avatar = avatars[message.senderDisplayName] {
            return avatar
        } else {
            setupAvatarImage(message.senderDisplayName, imageUrl: message.profileImgUrl, incoming: true)
            return avatars[message.senderDisplayName]
        }
    }
    
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForCellTopLabelAtIndexPath indexPath: IndexPath!) -> NSAttributedString! {
        /**
        *  This logic should be consistent with what you return from `heightForCellTopLabelAtIndexPath:`
        *  The other label text delegate methods should follow a similar pattern.
        *
        *  Show a timestamp for every 3rd message
        */
        if (shouldDisplayTimestamp(indexPath)) {
            let message = self.messages[indexPath.item]
            return JSQMessagesTimestampFormatter.sharedFormatter().attributedTimestampForDate(message.date)
        }
        
        return nil;
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForCellBottomLabelAtIndexPath indexPath: IndexPath!) -> NSAttributedString! {
        var bottomLabel: NSAttributedString? = nil
        let systemMessageStyle = NSMutableParagraphStyle()
        systemMessageStyle.alignment = .center
        
        let message = self.messages[indexPath.item]
        if message.type == MessageType.System {
            if let sysMsgData = message.sysMsgData {
                if let msgType = sysMsgData["sysMsgType"] as? String {
                    switch msgType {
                    case "join_plan":
                        if let firstName = sysMsgData["fromUserName"] as? String {
                            bottomLabel = NSAttributedString(string: "\(firstName) has joined the group", attributes: [NSParagraphStyleAttributeName: systemMessageStyle])
                        }
                    case "quit_plan":
                        if let firstName = sysMsgData["fromUserName"] as? String {
                            bottomLabel = NSAttributedString(string: "\(firstName) has left the group", attributes: [NSParagraphStyleAttributeName: systemMessageStyle])
                        }
                    default:
                        ();
                    }
                }
            }
        }
        return bottomLabel
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapMessageBubbleAtIndexPath indexPath: IndexPath!) {
        let message = messages[indexPath.item]
        switch message.type! {
        case MessageType.Location:
            self.performSegueWithIdentifier("showLocation", sender: message)
        default:
            ()
        }
        self.view.endEditing(true) // dismiss the keyboard in case it's shown
    }
    
    func imagePickerController(_ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        sendImage(image)
        picker.dismiss(animated: true, completion: nil)
    }
    
    // NOTE: Noticed that this func is called more frequently than I anticipated, like > 22 times for 8 messages.
    // need to figure out why when there's time.
    fileprivate func shouldDisplayTimestamp(_ indexPath: IndexPath) -> Bool{
        var shouldDisplayTimestamp = false
        if indexPath.item == 0 {
            shouldDisplayTimestamp = true
        } else {
            let previousMsg = messages[indexPath.item - 1]
            let currentMsg = messages[indexPath.item]
            if currentMsg.date.timeIntervalSinceDate(previousMsg.date) > 15 * 60 {
                shouldDisplayTimestamp = true
            }
        }
        return shouldDisplayTimestamp
    }
    
    fileprivate func openPhotoPicker() {
        let vc = UIImagePickerController()
        vc.delegate = self
        vc.allowsEditing = false
        vc.sourceType = UIImagePickerControllerSourceType.photoLibrary
        
        self.presentViewController(vc, animated: true, completion: nil)
    }
    
    fileprivate func updateChatWithLastMsg(_ chat: Chat, value: NSDictionary) {
        let type = value["type"] as! String
        if (type == MessageType.Text.rawValue) {
            chat.lastMsg = value["text"] as? String
        } else if type == MessageType.Location.rawValue {
            chat.lastMsg = "[location]"
        } else if type == MessageType.Image.rawValue {
            chat.lastMsg = "[image]"
        }
        chat.lastMsgFromUser = fromUser
        chat.lastMsgTime = Date()
        chat.saveInBackgroundWithBlock { (success:Bool, error: NSError?) -> Void in
            if success {
                // wait until Parse has saved the lastMsg before updating unread chat msg count
                // in firebase, otherwise the unreadChat handler may fetch the old message from
                // Parse as it hasn't been saved yet.
                self.firebaseService.setUnreadChats(chat)
            } else {
                print("failed to save last message: \(error)")
            }
        }
    }
    

    
    // MARK: - pull to refresh
    func fetchOlderMessages() {
        if let chat = chat {
            if messages.count > 0 {
                firebaseService.fetchOlderMessagesForChat(chat, latestTime: messages[0].date, count: ChatViewController.FETCH_COUNT, completion: { (messages, error) -> Void in
                    let processedMsgs = self.processMessages(messages)
                    self.messages = processedMsgs + self.messages
                    self.collectionView!.reloadData()
                    // reloadData() will reset contentOffset and scroll all the way to the top,
                    // scroll to the earliest message prior to the new fetch
                    let indexPath = NSIndexPath(forItem: processedMsgs.count, inSection: 0)
                    self.collectionView!.scrollToItemAtIndexPath(indexPath, atScrollPosition: UICollectionViewScrollPosition.Top, animated: false)
                    self.refreshControl.endRefreshing()
                })
            } else {
                self.refreshControl.endRefreshing()
            }
        }
    }
    
    /*
     * remove duplicate messages just as a safeguard
     * and other processing of the message when needed
     */
    fileprivate func processMessages(_ messages: [Message]) -> [Message] {
        var results = [Message]()
        for message in messages {
            let processedMsg = processMessage(message)
            if let processedMsg = processedMsg {
                results.append(processedMsg)
            }
        }
        return results;
    }
    
    fileprivate func processMessage(_ message: Message?) -> Message? {
        if let message = message {
            if !messageExists(message) { // only include the message if it doesn't already exist
                if message.type == MessageType.Location {
                    // fetch the location and set it again with a completion handler
                    let locationMediaItem = message.media as! JSQLocationMediaItem
                    let location = locationMediaItem.location
                    locationMediaItem.setLocation(location, withCompletionHandler: { () -> Void in
                        self.collectionView!.reloadData()
                    })
                }
                return message
            }
        }
        return nil
    }
    
    fileprivate func messageExists(_ message: Message) -> Bool {
        for msg in self.messages {
            if msg.id == message.id {
                return true
            }
        }
        return false
    }
        
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(_ segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "showLocation" {
            let message = sender as! Message
            let vc = segue.destination as! LocationMapViewController
            vc.message = message
        }
    }

    // MARK: - Gesture recognizer
    func gestureRecognizer(_: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith shouldRecognizeSimultaneouslyWithGestureRecognizer:UIGestureRecognizer) -> Bool {
            return true
    }
    
    func dismissKeyboard(_ gesture: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }

}
