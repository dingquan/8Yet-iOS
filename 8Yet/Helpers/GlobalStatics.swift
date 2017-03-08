//
//  GlobalStatics.swift
//  8Yet
//
//  Created by Quan Ding on 3/22/16.
//  Copyright © 2016 EightYet. All rights reserved.
//

import Foundation

let amPmDateFormatter: DateFormatter = {
    var f = DateFormatter()
    f.dateFormat = "h:mm a"
    f.locale = Locale(identifier: "en_US_POSIX")
    return f
}()

let mmDdYyyyDateFormatter: DateFormatter = {
    var f = DateFormatter()
    f.dateFormat = "MM/dd/yyyy"
    return f
}()
