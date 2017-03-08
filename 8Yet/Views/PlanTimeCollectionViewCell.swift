//
//  PlanTimeCollectionViewCell.swift
//  8Yet
//
//  Created by Quan Ding on 2/10/16.
//  Copyright © 2016 EightYet. All rights reserved.
//

import UIKit

class PlanTimeCollectionViewCell: UICollectionViewCell {
    enum Type: String {
        case Hour, Minute
    }
    
    struct Time {
        var type: Type
        var value: Int
    }
    
    var time: Time? {
        didSet {
            if let time = time {
                var value = time.value
                if time.type == .Hour {
                    // calculate am/pm value
                    value %= 12
                    if value == 0 {
                        value = 12
                    }
                    timeLabel.text = String(format: "%d", value)
                } else {
                    timeLabel.text = String(format: "%02d", value)
                }
                setSelectionState()
            }
        }
    }
    
    @IBOutlet weak var timeLabel: UILabel!
    
    func setSelectionState(){
        if self.isSelected {
            timeLabel.textColor = UIColor(red: 54/255, green: 212/255, blue: 171/255, alpha: 1)
        } else {
            timeLabel.textColor = UIColor(red: 167/255, green: 169/255, blue: 171/255, alpha: 1)
        }
    }
}
