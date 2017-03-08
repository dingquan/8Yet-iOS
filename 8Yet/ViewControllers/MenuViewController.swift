//
//  MenuViewController.swift
//  TwitterV2
//
//  Created by Ding, Quan on 2/25/15.
//  Copyright (c) 2015 Codepath. All rights reserved.
//

import UIKit

protocol MenuViewControllerDelegate: class {
    func onLogOut()
    func onEula()
    func onDemoMode()
    func onProfile()
    func onFacebookPage()
    func onTwitter()
    func onFacebookGroup()
    func onChat()
    func onRateUs()
}

class MenuViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {
    enum Menu: String {
        case TermOfService = "Terms of Service"
        case ContactUs = "Contact Us"
        case FacebookPage = "Like Us on Facebook"
        case Twitter = "Follow Us on Twitter"
        case FacebookGroup = "Help & Support"
        case Chat = "Chat with Us"
        case Rate = "Rate Us in App Store"
    }
    
    fileprivate var chatWith8Yet: Chat?
    fileprivate var unreadChatFirebaseHandle: UInt?
    fileprivate var chatMenuCell: MenuTableViewCell?
    fileprivate var contactUsMenuCell: MenuTableViewCell?
    fileprivate var expandedSections:NSMutableIndexSet = NSMutableIndexSet()
    fileprivate var msgCnt:Int = 0
    
    fileprivate let menuOptions:[[(label: String, image: String)]] = [[(label: Menu.TermOfService.rawValue, image: "eula")], [(label: Menu.ContactUs.rawValue, image: "contactUs"), (label: Menu.FacebookPage.rawValue, image: ""), (label: Menu.Twitter.rawValue, image: ""), (label: Menu.FacebookGroup.rawValue, image: ""), (label: Menu.Chat.rawValue, image: ""), (label: Menu.Rate.rawValue, image: "")] ]

    weak var delegate: MenuViewControllerDelegate?
    
    @IBOutlet weak var profileNameLabel: UILabel!
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var menuTable: UITableView!
    @IBOutlet weak var menuTableHeader: UIView!
    @IBOutlet weak var logOutBtn: UIButton!
    @IBOutlet weak var versionLabel: UILabel!
    
    
    // MARK: - Actions
    @IBAction func onLogOut(_ sender: AnyObject) {
        delegate?.onLogOut()
    }
    
    // MARK: - UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        // only show cells with data (remove empty cells so that it doesn't show the separator for empty cells
        self.navigationController?.navigationBar.tintColor = UIColor.white
        self.navigationController?.navigationBar.barStyle = UIBarStyle.black
        
        profileNameLabel.text = User.currentUser()?.firstName
        profileNameLabel.sizeToFit()
        
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
        self.versionLabel.text = "v \(version)"
        self.versionLabel.sizeToFit()
//        self.menuTable.tableFooterView = UIView(frame: CGRectZero)
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(MenuViewController.onProfileImageTap(_:)))
        self.profileImage.isUserInteractionEnabled = true
        self.profileImage.addGestureRecognizer(tapGestureRecognizer)
        
        Chat.get8YetChat { (chat) -> Void in
            self.chatWith8Yet = chat
            self.unreadChatFirebaseHandle = FirebaseService.sharedInstance.listenForUnreadChat(chat, completion: { (newMsgCount) -> Void in
                self.msgCnt = newMsgCount ?? 0
                self.updateMessageLabel()
            })
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let chatWith8Yet = chatWith8Yet {
            unreadChatFirebaseHandle = FirebaseService.sharedInstance.listenForUnreadChat(chatWith8Yet, completion: { (newMsgCount) -> Void in
                self.msgCnt = newMsgCount ?? 0
                self.updateMessageLabel()
            })
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let user = User.currentUser() {
            
            ViewHelpers.roundedCorner(profileImage, radius: profileImage.frame.width/2)
            ViewHelpers.fadeInImage(profileImage, imgUrl: user.profileImageUrl)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if chatWith8Yet != nil && unreadChatFirebaseHandle != nil {
            FirebaseService.sharedInstance.removeObserversForUnreadChat(chatWith8Yet!, handle: unreadChatFirebaseHandle)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }

    // MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return menuOptions.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 && !expandedSections.contains(section) {
            return 1 // only show top row
        }
        return menuOptions[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "MenuCell", for: indexPath) as! MenuTableViewCell
        cell.msg = nil // clear the state first to avoid cell reuse lingering effect
        
        let label = menuOptions[indexPath.section][indexPath.row].label
        let image = menuOptions[indexPath.section][indexPath.row].image
        
        cell.menuName = label
        cell.menuIconName = image
        
        if indexPath.section == 1 && indexPath.row > 0 {
            cell.isSubMenu = true
        }

        if label == Menu.Chat.rawValue {
            chatMenuCell = cell
            if msgCnt > 0 {
                cell.msg = "\(msgCnt)"
            }
        }
        if label == Menu.ContactUs.rawValue {
            contactUsMenuCell = cell
            if msgCnt > 0 {
                cell.msg = "\(msgCnt)"
            }
        }

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.menuTable.deselectRow(at: indexPath, animated: true)
        Analytics.sharedInstance.event(Analytics.Event.MenuItemClicked.rawValue, properties: ["item": menuOptions[indexPath.section][indexPath.row].label])
        
        let cell = menuTable.cellForRow(at: indexPath) as! MenuTableViewCell
        
        if self.tableView(menuTable, canCollapseSection: indexPath.section) {
            if indexPath.row == 0 {
                expandCollapseSection(indexPath)
            } else {
                let topCellIndexPath = IndexPath(row: 0, section: indexPath.section)
                expandCollapseSection(topCellIndexPath) // closes the section upon handling of the menu option
                handleMenuOption(cell)
            }
        } else {
            handleMenuOption(cell)
        }
    }
    
    func tableView(_ tableView: UITableView, canCollapseSection section: Int) -> Bool {
        if (section == 1) {
            return true
        }
        return false
    }

    // MARK: - Gesture recognizer
    @IBAction func onTapTableFooter(_ sender: UITapGestureRecognizer) {
        delegate?.onDemoMode()
    }
    
    func onProfileImageTap(_ gestureRecognizer: UITapGestureRecognizer) {
        delegate?.onProfile()
    }
    
    // MARK: - Private functions
    fileprivate func updateMessageLabel() {
        let msg: String? = self.msgCnt > 0 ? "\(self.msgCnt)" : nil
        if let chatMenuCell = chatMenuCell {
            chatMenuCell.msg = msg
        }
        if let contactUsMenuCell = contactUsMenuCell {
            contactUsMenuCell.msg = msg
        }
    }
    
    fileprivate func handleMenuOption(_ cell: MenuTableViewCell) {
        let label = cell.menuLabel.text
        if let label = label {
            switch label {
            case Menu.TermOfService.rawValue:
                delegate?.onEula()
            case Menu.FacebookPage.rawValue:
                delegate?.onFacebookPage()
            case Menu.FacebookGroup.rawValue:
                delegate?.onFacebookGroup()
            case Menu.Twitter.rawValue:
                delegate?.onTwitter()
            case Menu.Chat.rawValue:
                delegate?.onChat()
            case Menu.Rate.rawValue:
                delegate?.onRateUs()
            default:
                (); // nothing to do
            }
        }
    }
    
    fileprivate func expandCollapseSection(_ indexPath: IndexPath) {
        let currentlyExpanded = expandedSections.contains(indexPath.section)
        let section = indexPath.section
        var rows:Int = 0
        var tmpArray = [IndexPath]()
        
        if currentlyExpanded {
            rows = self.tableView(self.menuTable, numberOfRowsInSection: section)
            expandedSections.remove(section)
        } else {
            expandedSections.add(section)
            rows = self.tableView(self.menuTable, numberOfRowsInSection: section)
        }
        
        for i in 1 ..< rows {
            let tmpIndexPath = IndexPath(row: i, section: section)
            tmpArray.append(tmpIndexPath)
        }
        
        if currentlyExpanded {
            menuTable.deleteRows(at: tmpArray, with: UITableViewRowAnimation.automatic)
        } else {
            menuTable.insertRows(at: tmpArray, with: UITableViewRowAnimation.automatic)
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
