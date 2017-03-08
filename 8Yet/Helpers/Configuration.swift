//
//  Configuration.swift
//  8Yet
//
//  Created by Quan Ding on 8/6/15.
//  Copyright (c) 2015 EightYet. All rights reserved.
//

import Foundation

open class Configuration {
    static let sharedInstance = Configuration()

    fileprivate var configuration: String?
    fileprivate var properties: NSDictionary?

    init() {
        let mainBundle = Bundle.main
        self.configuration = mainBundle.infoDictionary?["Configuration"] as? String
        let path = mainBundle.path(forResource: "Configurations", ofType: "plist")

        if let path = path {
            let configurations = NSDictionary(contentsOfFile: path)
            if let configuration = self.configuration {
                self.properties = configurations?.object(forKey: configuration) as? NSDictionary
            }
        }
    }

    func getConfiguration() -> String {
        return configuration ?? "Debug"
    }

    func getParseAppId() -> String {
        let value = self.properties?.object(forKey: "parseAppId") as? String
        return value ?? ""
    }

    func getParseClientKey() -> String {
        let value = self.properties?.object(forKey: "parseClientKey") as? String
        return value ?? ""
    }

    func getFirebaseUrl() -> String {
        let value = self.properties?.object(forKey: "firebaseUrl") as? String
        return value ?? ""
    }
    
    func getAppseeApiKey() -> String {
        let value = self.properties?.object(forKey: "appseeApiKey") as? String
        return value ?? ""
    }
    
    func getFlurryApiKey() -> String {
        let value = self.properties?.object(forKey: "flurryApiKey") as? String
        return value ?? ""
    }
    
    func getMixpanelApiKey() -> String {
        let value = self.properties?.object(forKey: "mixPanelApiToken") as? String
        return value ?? ""
    }
    
    func getGoogleMapsApiKey() -> String {
        let value = self.properties?.object(forKey: "googleMapsApiKey") as? String
        return value ?? ""
    }
}
