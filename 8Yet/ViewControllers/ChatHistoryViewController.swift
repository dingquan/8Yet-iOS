//
//  ChatHistoryViewController.swift
//  8Yet
//
//  Created by Ding, Quan on 3/14/15.
//  Copyright (c) 2015 EightYet. All rights reserved.
//

import UIKit
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


private let showChatDetailsSegue = "showChatDetails"

class ChatHistoryViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {
    fileprivate var chats:[Chat]!
    fileprivate var oldBarTintColor: UIColor!
    fileprivate let firebaseService: FirebaseService = FirebaseService.sharedInstance
    fileprivate var firebaseHandle:UInt?
    
    @IBOutlet weak var chatsTable: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        chats = [Chat]()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        chatsTable.separatorColor = UIColor(red: 216/255, green: 216/255, blue: 216/255, alpha: 1)
        chatsTable.estimatedRowHeight = 81
        chatsTable.rowHeight = UITableViewAutomaticDimension
        
//        setNavigationBarColor()
        chatsTable.tableFooterView = UIView(frame: CGRect.zero) // this stops table displaying rows that don't have content
        self.activityIndicator.hidesWhenStopped = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if (self.chats.count == 0) {
            self.activityIndicator.startAnimating()
        }
        Chat.getChatList { (chats: [Chat]!) -> Void in
            self.activityIndicator.stopAnimating()
            self.chats = chats
            self.chatsTable.reloadData()
            // IMPORTANT, need to wait until chat list is fetched before listening for unread chats. otherwise we have not chat record to update.
            self.firebaseHandle = self.firebaseService.listenForUnreadChats(self.updateChatsNewMsgIndicator)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // remove listener when not needed to improve performance
        firebaseService.removeObserversForUnreadChats(firebaseHandle)
//        restoreNavigationBarColor()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
    }

    // MARK: - UITableView delegate functions
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chats.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "lunchBuddyTableCell", for: indexPath) as! ChatTableViewCell

        if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_7_1){
            cell.contentView.frame = cell.bounds
            cell.contentView.autoresizingMask = [UIViewAutoresizing.flexibleLeftMargin, UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleRightMargin, UIViewAutoresizing.flexibleTopMargin, UIViewAutoresizing.flexibleHeight, UIViewAutoresizing.flexibleBottomMargin]
        }
        
        let chat = chats[indexPath.row]
        cell.chat = chat

        // change the default margin of the table divider length
        cell.preservesSuperviewLayoutMargins = false
        
        if (cell.responds(to: #selector(setter: UITableViewCell.separatorInset))){
            cell.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0)
        }
        
        cell.layoutMargins = UIEdgeInsets.zero
        
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1;
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 81
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let chat = chats[indexPath.row]
        performSegue(withIdentifier: showChatDetailsSegue, sender: chat)
        self.chatsTable.deselectRow(at: indexPath, animated: true)
    }
    
    // replace/update the chat in the chats table with the given objectId
    // return the index in the arry where the element is replaced
    fileprivate func updateChatForId(_ id: String, chat: Chat) -> Int{
        for index in 0 ..< self.chats.count {
            if self.chats[index].objectId == id {
                self.chats[index] = chat
                return index;
            }
        }
        return -1
    }
    
    // MARK: - Private functions
    fileprivate func setNavigationBarColor() {
        self.oldBarTintColor = self.navigationController?.navigationBar.tintColor
        self.navigationController?.navigationBar.tintColor = UIColor.white
        self.navigationController?.navigationBar.barTintColor = UIColor(red: 101/255, green: 201/255, blue: 241/255, alpha: 1)
        self.navigationController?.navigationBar.isTranslucent = false;
//        self.navigationController?.navigationBar.barStyle = UIBarStyle.Black
    }
    
    fileprivate func restoreNavigationBarColor() {
        self.navigationController?.navigationBar.tintColor = oldBarTintColor
        self.navigationController?.navigationBar.barTintColor = UIColor.white
//        self.navigationController?.navigationBar.translucent = true;
    }
    
    // show/hide the pink unread msg indicator for each chat
    fileprivate func updateChatsNewMsgIndicator(_ chatsWithNewMsgs: [String]?) {
        if chatsWithNewMsgs?.count > 0 {
            for chatId in chatsWithNewMsgs! {
                Chat.getChatByIdWithCompletion(chatId, completion: { (chat, error) -> Void in
                    if let chat = chat {
                        chat.hasNewMsg = true
                        let row = self.updateChatForId(chatId, chat: chat)
                        if row != -1 {
                            let indexPath = IndexPath(row: row, section: 0)
                            self.chatsTable.beginUpdates()
                            self.chatsTable.reloadRows(at: [indexPath], with: UITableViewRowAnimation.none)
                            self.chatsTable.endUpdates()
                        }
                    } else {
                        print("error getting chat with id \(chatId): \(error)")
                    }
                })
            }
        }
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showChatDetailsSegue {
            let vc = segue.destination as! ChatViewController
            let chat = sender as! Chat!
            vc.chat = chat
        }
    }


}
