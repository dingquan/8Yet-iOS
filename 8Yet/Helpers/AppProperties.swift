//
//  AppProperties.swift
//  8Yet
//
//  Created by Quan Ding on 11/13/15.
//  Copyright © 2015 EightYet. All rights reserved.
//

import Foundation

open class AppProperties {
    static let sharedInstance = AppProperties()
    fileprivate var properties: PFConfig?
    
    func refreshProperties () {
        print("Getting the latest config...");
        PFConfig.getConfigInBackgroundWithBlock {
            ( config: PFConfig?, error: NSError?) -> Void in
            if error == nil {
                print("Yay! Config was fetched from the server.")
                self.properties = config
            } else {
                print("Failed to fetch. Using Cached Config.")
                self.properties = PFConfig.currentConfig()
            }
        };
    }
    
    func getPropertyWithDefault(_ propName: String, defaultValue: AnyObject) -> AnyObject {
        let value = properties?[propName]
        return value == nil ? defaultValue : value!
    }
    
    func getProperty(_ propName: String) -> AnyObject? {
        let value = properties?[propName]
        return value
    }
}
