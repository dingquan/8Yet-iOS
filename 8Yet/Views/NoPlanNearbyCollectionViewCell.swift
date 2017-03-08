//
//  NoPlanNearbyCollectionViewCell.swift
//  8Yet
//
//  Created by Quan Ding on 3/23/16.
//  Copyright © 2016 EightYet. All rights reserved.
//

import UIKit

protocol NoPlanNearbyCollectionViewCellDelegate: class {
    func inviteFriends()
}

class NoPlanNearbyCollectionViewCell: UICollectionViewCell {
    weak var delegate: NoPlanNearbyCollectionViewCellDelegate?
    
    fileprivate let buttonDopShadowColor = UIColor(red: 46/255, green: 185/255, blue: 149/255, alpha: 1)
    fileprivate let cardDopShadowColor = UIColor(red: 235/255, green: 235/255, blue: 235/255, alpha: 1)
    
    @IBOutlet weak var nobodyLabel: UILabel!
    @IBOutlet weak var inviteBtn: UIButton!
    @IBOutlet weak var containerView: UIView!
    
    @IBAction func inviteFriends(_ sender: AnyObject) {
        self.delegate?.inviteFriends()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        ViewHelpers.addDropShadow(containerView.superview!, color: cardDopShadowColor.CGColor, offset: CGSize(width: 0, height: 3), shadowRadius: 0, opacity: 1, cornerRadius: 10)
        ViewHelpers.roundedCorner(containerView, radius: 10)
        ViewHelpers.addDropShadow(inviteBtn, color: buttonDopShadowColor.CGColor, offset: CGSize(width: 0, height: 3), shadowRadius: 0, opacity: 1, cornerRadius: 10)
        
        nobodyLabel.font = UIFont(name: serifMediumFontName, size: 15 * screenSizeMultiplier)
        nobodyLabel.preferredMaxLayoutWidth = nobodyLabel.frame.size.width
        nobodyLabel.sizeToFit()
    }
}
