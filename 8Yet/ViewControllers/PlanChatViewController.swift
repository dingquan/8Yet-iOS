//
//  PlanChatViewController.swift
//  8Yet
//
//  Created by Quan Ding on 3/3/16.
//  Copyright © 2016 EightYet. All rights reserved.
//

import UIKit

class PlanChatViewController: BaseViewController, UIGestureRecognizerDelegate {
    fileprivate var plan: Plan?
    fileprivate var chatVC: ChatViewController?
    
    @IBOutlet weak var planInfoView: UIView!
    @IBOutlet weak var chatContainerView: UIView!
    @IBOutlet weak var address1: UILabel!
    @IBOutlet weak var address2: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        address1.text = ""
        address2.text = ""
        timeLabel.text = ""
        
        plan = User.currentUser()?.todaysPlan
        if plan == nil {
            Plan.findMyTodaysPlan({ (plan, error) -> Void in
                if error == nil && plan != nil {
                    self.plan = plan
                    self.setupViews()
                    self.populateViews()
                } else if let error = error {
                    ViewHelpers.presentErrorMessage(error, vc: self)
                }
            })
        } else {
            setupViews()
            populateViews()
        }
        
        self.navigationItem.title = "Chat"
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        chatVC?.view.frame = chatContainerView.bounds // adjust chat vc frame
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func showPlanDetails() {
        let storyboard = UIStoryboard(name: "PlanDetails", bundle: nil)
        let planDetailsVC = storyboard.instantiateViewController(withIdentifier: "PlanDetailsViewController") as! PlanDetailsViewController
        planDetailsVC.plan = plan
        self.navigationController?.pushViewController(planDetailsVC, animated: true)
    }
    
    // MARK: - Private functions
    fileprivate func setupViews() {
//        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: "showPlanDetails")
//        tapGestureRecognizer.delegate = self
//        self.planInfoView?.addGestureRecognizer(tapGestureRecognizer)
        
        let storyboard = UIStoryboard(name: "Chat", bundle: nil)
        chatVC = storyboard.instantiateViewController(withIdentifier: "ChatViewController") as? ChatViewController
        if let chatVC = chatVC {
            if let plan = plan {
                if let chat = plan.chat {
                    chatVC.chat = chat
                    self.addChildViewController(chatVC)
                    chatContainerView.insertSubview(chatVC.view, atIndex: 0)
                    chatVC.didMoveToParentViewController(self)
                    print("chatContainerView: \(chatContainerView.bounds)")
                    chatVC.view.frame = chatContainerView.bounds
                }
            }
        }
    }
    
    fileprivate func populateViews() {
        if let plan = plan {
            if let location = plan.location {
                if let locationName = location.name {
                    address1.text = locationName
                    address2.text = location.address
                } else {
                    address1.text = location.address
                    address2.text = ""
                }
            }
            address1.sizeToFit()
            address2.sizeToFit()
            timeLabel.text = amPmDateFormatter.string(from: plan.startTime ?? Date())
            timeLabel.sizeToFit()
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
