//
//  Swipe.swift
//  8Yet
//
//  Created by Ding, Quan on 3/7/15.
//  Copyright (c) 2015 EightYet. All rights reserved.
//

import Foundation

class Swipe: PFObject, PFSubclassing{

    private static var __once: () = {
            self.registerSubclass()
        }()

    init (fromUser: User, toUser: User, isLike: NSNumber, isSameSex: NSNumber) {
        super.init()
        self.fromUser = fromUser
        self.toUser = toUser
        self.isLike = isLike
        self.isMatched = false
        self.isSameSex = isSameSex
    }
    
    override init(){
        super.init()
    }
    
    override class func initialize() {
        struct Static {
            static var onceToken : Int = 0;
        }
        _ = Swipe.__once
    }
    
    class func parseClassName() -> String {
        return "Swipe"
    }
    
    @NSManaged var fromUser: User
    @NSManaged var toUser: User
    @NSManaged var isLike: NSNumber
    @NSManaged var isMatched: NSNumber
    @NSManaged var isSameSex: NSNumber
    
}
