//
//  BaseViewController.swift
//  8Yet
//
//  Created by Quan Ding on 11/17/15.
//  Copyright © 2015 EightYet. All rights reserved.
//

import UIKit

class BaseViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        Analytics.sharedInstance.startTimingEvent("Entering \(String(type(of: self)))", properties: [AnyHashable: Any]())
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        Analytics.sharedInstance.finishTimingEvent("Leaving \(String(type(of: self)))", properties: [AnyHashable: Any]())
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
