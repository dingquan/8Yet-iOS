//
//  PlanDetailsViewController.swift
//  8Yet
//
//  Created by Quan Ding on 2/19/16.
//  Copyright © 2016 EightYet. All rights reserved.
//

import UIKit

private let basicInfoCellIdentifier = "basicInfoCell"
private let mapCellIdentifier = "mapCell"
private let participantCellIdentifier = "participantCell"
private let joinBtnCellIdentifier = "joinBtnCell"

private let buttonDopShadowColor = UIColor(red: 46/255, green: 185/255, blue: 149/255, alpha: 1)

class PlanDetailsViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate, PlanDetailsBasicInfoTableViewCellDelegate, PlanDetailsParticipantTableViewCellDelegate {
    var plan: Plan?
    
    fileprivate let firebaseService = FirebaseService.sharedInstance
    
    @IBOutlet weak var planDetailsTable: UITableView!
    @IBOutlet weak var joinBtnView: UIView!
    @IBOutlet weak var joinBtn: UIButton!
    @IBOutlet weak var joinBtnWidthConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        joinBtnWidthConstraint.constant *= screenSizeMultiplier
        
        // add the edit plan navigation bar button
        if plan?.host.objectId == User.currentUser()?.objectId {
            let buttonImage = UIImage(named: "edit")?.withRenderingMode(UIImageRenderingMode.alwaysOriginal) // this keeps the original color of the button
            let editBtn = UIBarButtonItem(image: buttonImage, style: UIBarButtonItemStyle.plain, target: self, action: #selector(PlanDetailsViewController.editPlan(_:)))
            self.navigationItem.rightBarButtonItem = editBtn
        }
        
        planDetailsTable.estimatedRowHeight = 250
        planDetailsTable.rowHeight = UITableViewAutomaticDimension
        
        self.navigationItem.title = "Details"
        
        NotificationCenter.default.removeObserver(self)
        NotificationCenter.default.addObserver(self, selector: #selector(PlanDetailsViewController.onUpdatePlanNotification(_:)), name: NSNotification.Name(rawValue: updatePlanNotification), object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if User.currentUser()?.todaysPlan != nil {
            joinBtnView.isHidden = true
        } else {
            joinBtnView.isHidden = false
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        setupFirebase()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let plan = plan {
            firebaseService.removeObserverForPlanUpdates(plan)
        }
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        ViewHelpers.addDropShadow(joinBtn, color: buttonDopShadowColor.CGColor, offset: CGSize(width: 0, height: 3), shadowRadius: 0, opacity: 1, cornerRadius: 10)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 2 {
            return self.plan?.participants.count ?? 0
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: basicInfoCellIdentifier, for: indexPath) as! PlanDetailsBasicInfoTableViewCell
            cell.plan = self.plan
            cell.delegate = self
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: mapCellIdentifier, for: indexPath) as! PlanDetailsMapTableViewCell
            cell.plan = self.plan
            return cell
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: participantCellIdentifier, for: indexPath) as! PlanDetailsParticipantTableViewCell
            let user = plan?.participants[indexPath.row]
            if user?.objectId == plan?.host.objectId {
                cell.isHost = true
            }
            cell.delegate = self
            cell.user = user
            return cell
        default:
            NSLog("PlanDetailsViewController: Invalid section")
            return UITableViewCell()
        }
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        self.planDetailsTable.deselectRow(at: indexPath, animated: true)
    }

    // MARK: - PlanDetailsBasicInfoTableViewCellDelegate
    func onQuitPlan() {
        let titleText = self.plan?.host.objectId == User.currentUser()?.objectId ? "Cancel your plan?" : "Quit this plan?"
        let destructActionText = self.plan?.host.objectId == User.currentUser()?.objectId ? "Cancel" : "Quit"
        let alertController = UIAlertController(title: titleText, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        let cancelAction = UIAlertAction(title: "No! Take me back", style: UIAlertActionStyle.cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        let quitAction = UIAlertAction(title: destructActionText, style: UIAlertActionStyle.Destructive) { (action) -> Void in
            Analytics.sharedInstance.event(Analytics.Event.QuitPlan.rawValue)
            self.quitPlan()
        }
        alertController.addAction(quitAction)
        
        self.presentViewController(alertController, animated: true, completion: nil)

    }
    
    // MARK: - PlanDetailsParticipantTableViewCellDelegate
    func profileImageTapped(_ forCell: UITableViewCell) {
        if let cell = forCell as? PlanDetailsParticipantTableViewCell {
            if let user = cell.user {
                Analytics.sharedInstance.event(Analytics.Event.ViewProfile.rawValue)
                let storyboard = UIStoryboard(name: "UserProfile", bundle: nil)
                let userProfileVC = storyboard.instantiateViewController(withIdentifier: "UserProfileViewController") as! UserProfileViewController
                userProfileVC.user = user
                self.navigationController?.pushViewController(userProfileVC, animated: true)
            }
        }
    }
    
    // MARK: - Actions
    
    @IBAction func onJoin(_ sender: AnyObject) {
        SVProgressHUD.show()
        User.currentUser()?.todaysPlan = nil // clear the plan first
        self.plan?.join({ (plan, error) -> Void in
            SVProgressHUD.dismiss()
            Analytics.sharedInstance.event(Analytics.Event.JoinPlan.rawValue)
            if error == nil {
                NotificationCenter.default.post(name: Notification.Name(rawValue: joinPlanNotification), object: plan)
                User.currentUser()?.fetchInBackground() // refresh user data after join
                let storyboard = UIStoryboard(name: "Chat", bundle: nil)
                let planChatVC = storyboard.instantiateViewController(withIdentifier: "PlanChatViewController") as! PlanChatViewController
                self.navigationController?.pushViewController(planChatVC, animated: true)
            } else {
                ViewHelpers.presentErrorMessage(error!, vc: self)
            }
        })
    }
    
    func editPlan(_ sender: AnyObject) {
        let storyboard = UIStoryboard(name: "CreatePlan", bundle: nil)
        let newPlanVC = storyboard.instantiateViewController(withIdentifier: "CreatePlanViewController") as! CreatePlanViewController
        newPlanVC.plan = self.plan
        self.present(newPlanVC, animated: true, completion: nil)
    }
    
    func quitPlan() {
        SVProgressHUD.show()
        self.plan?.quit({ (plan, error) -> Void in
            SVProgressHUD.dismiss()
            Analytics.sharedInstance.event(Analytics.Event.QuitPlan.rawValue)
            if error == nil {
                User.currentUser()?.fetchInBackground()
                NotificationCenter.default.post(name: Notification.Name(rawValue: quitPlanNotification), object: self.plan)
                self.navigationController?.popViewController(animated: true)
            } else {
                ViewHelpers.presentErrorMessage(error, vc: self)
            }
        })
    }
    
    // MARK: - Private functions
    fileprivate func setupFirebase() {
        if let plan = plan {
            firebaseService.removeObserverForPlanUpdates(plan)
            firebaseService.listenForPlanUpdates(plan, completion: { (error) -> Void in
                if error == nil {
                    plan.getPlanDetails({ (fetchedPlan, error) -> Void in
                        if let fetchedPlan = fetchedPlan {
                            self.plan = fetchedPlan
                            self.planDetailsTable.reloadData()
                        } else if error != nil {
                            NSLog("error while getting plan details: \(error)")
                        }
                        
                    })
                }
            })
        }
    }
    
    // MARK: - Notification handlers
    func onUpdatePlanNotification(_ notification: Notification) {
        if let _ = (notification.object as? Plan) {
            self.planDetailsTable.reloadData()
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

