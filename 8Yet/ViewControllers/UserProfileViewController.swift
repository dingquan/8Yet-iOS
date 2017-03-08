//
//  UserProfileViewController.swift
//  8Yet
//
//  Created by Quan Ding on 3/7/16.
//  Copyright © 2016 EightYet. All rights reserved.
//

import UIKit

let profileChangeNotification = "profileChangeNotification"

private let basicInfoIdentifier = "profileBasicInfoCell"
private let profileBioIdentifier = "profileBioCell"
private let favoritesIdentifier = "profileFavoritesCell"
private let mutualFriendsIdentifier = "profileMutualFriendsCell"
private let actionsIdentifier = "profileActionsCell"

class UserProfileViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate, ProfileBasicInfoTableViewCellDelegate, ProfileMutualFriendsTableViewCellDelegate, ProfileBioTableViewCellDelegate,ProfileFavoritesTableViewCellDelegate {

    var user: User?
    
    @IBOutlet weak var userProfileTable: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        userProfileTable.estimatedRowHeight = 255
        userProfileTable.rowHeight = UITableViewAutomaticDimension
        
        self.navigationItem.title = "Profile"
        
        NotificationCenter.default.removeObserver(self)
        NotificationCenter.default.addObserver(self, selector: #selector(UserProfileViewController.onProfileChangeNotification(_:)), name: NSNotification.Name(rawValue: profileChangeNotification), object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        if User.currentUser()?.objectId == user?.objectId {
            return 4
        } else {
            var numRows = 4
            if self.user != nil && User.currentUser()?.getCommonFriends(self.user!).count > 0 {
                numRows += 1
            }
            return numRows
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: basicInfoIdentifier, for: indexPath) as! ProfileBasicInfoTableViewCell
            cell.user = self.user
            cell.delegate = self
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: profileBioIdentifier, for: indexPath) as! ProfileBioTableViewCell
            cell.user = self.user
            cell.delegate = self
            return cell
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: favoritesIdentifier, for: indexPath) as! ProfileFavoritesTableViewCell
            cell.setTypeAndUser(ProfileFavoritesTableViewCell.TYPE_FOOD, user: self.user)
            cell.delegate = self
            return cell
        case 3:
            let cell = tableView.dequeueReusableCell(withIdentifier: favoritesIdentifier, for: indexPath) as! ProfileFavoritesTableViewCell
            cell.setTypeAndUser(ProfileFavoritesTableViewCell.TYPE_TOPIC, user: self.user)
            cell.delegate = self
            return cell
        case 4:
            let cell = tableView.dequeueReusableCell(withIdentifier: mutualFriendsIdentifier, for: indexPath) as! ProfileMutualFriendsTableViewCell
            cell.user = self.user
            cell.delegate = self
            return cell
        case 5:
            let cell = tableView.dequeueReusableCell(withIdentifier: actionsIdentifier, for: indexPath) as! ProfileActionsTableViewCell
            cell.user = self.user
            return cell
        default:
            NSLog("UserProfileViewController: Invalid section")
            return UITableViewCell()
        }
    }
    
    // MARK: - UITableViewDelegate

    // MARK: - ProfileBasicInfoTableViewCellDelegate
    func onReportUser() {
        if let user = user {
            Analytics.sharedInstance.event(Analytics.Event.ReportUser.rawValue)
            let userName = user.firstName ?? "User"
            let alertController = UIAlertController(title: "Report \(userName)", message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil)
            alertController.addAction(cancelAction)
            
            let fakeAccountAction = UIAlertAction(title: "Fake Account", style: UIAlertActionStyle.default) { (action) -> Void in
                self.reportUser(user, reason: "fake")
            }
            alertController.addAction(fakeAccountAction)
            
            let offensiveAction = UIAlertAction(title: "Offensive Content", style: UIAlertActionStyle.default) { (action) -> Void in
                self.reportUser(user, reason: "offensive")
            }
            alertController.addAction(offensiveAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    // MARK: - ProfileBioTableViewCellDelegate
    func onEditBio() {
        let storyboard = UIStoryboard(name: "UserProfile", bundle: nil)
        let userBioVC = storyboard.instantiateViewController(withIdentifier: "UserBioViewController") as! UserBioViewController
        self.navigationController?.pushViewController(userBioVC, animated: true)
    }
    
    // MARK: - ProfileFavoritesTableViewCellDelegate
    func onEditFavorites(_ type: Int) {
        let storyboard = UIStoryboard(name: "UserProfile", bundle: nil)
        var vc: UIViewController? = nil
        if type == ProfileFavoritesTableViewCell.TYPE_FOOD {
            vc = storyboard.instantiateViewController(withIdentifier: "FavoriteFoodViewController") as? FavoriteFoodViewController
        } else if type == ProfileFavoritesTableViewCell.TYPE_TOPIC {
            vc = storyboard.instantiateViewController(withIdentifier: "FavoriteTopicsViewController") as? FavoriteTopicsViewController
        }
        if let vc = vc {
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    // MARK: - ProfileMutualFriendsTableViewCellDelegate
    func profileImageTapped(_ user: User) {
        Analytics.sharedInstance.event(Analytics.Event.ViewProfile.rawValue)
        let storyboard = UIStoryboard(name: "UserProfile", bundle: nil)
        let userProfileVC = storyboard.instantiateViewController(withIdentifier: "UserProfileViewController") as! UserProfileViewController
        userProfileVC.user = user
        self.navigationController?.pushViewController(userProfileVC, animated: true)
    }
    
    // MARK: - Private functions
    fileprivate func reportUser(_ user: User, reason: String) {
        let reportUser = ReportUser(fromUser: User.currentUser()!, toUser: user, reason: reason)
        reportUser.saveInBackground()
        let alert:UIAlertView = UIAlertView(title: "Thanks for reporting", message: "We will investigate and suspend/remove the reported user account if there's a violation of our terms and policies.", delegate: self, cancelButtonTitle: "OK")
        alert.show()
    }
    
    // MARK: - Notification handlers
    func onProfileChangeNotification(_ notification: Notification) {
        if let user = (notification.object as? User) {
            self.user = user
            self.userProfileTable.reloadData()
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
