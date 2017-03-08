//
//  NewPlanCollectionViewCell.swift
//  8Yet
//
//  Created by Quan Ding on 2/26/16.
//  Copyright © 2016 EightYet. All rights reserved.
//

import UIKit

protocol NewPlanCollectionViewCellDelegate: class {
    func createPlan()
}

class NewPlanCollectionViewCell: UICollectionViewCell {
    weak var delegate: NewPlanCollectionViewCellDelegate?
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var createBtn: UIButton!
    @IBOutlet weak var createLabel: UILabel!
    
    fileprivate let buttonDopShadowColor = UIColor(red: 46/255, green: 185/255, blue: 149/255, alpha: 1)
    fileprivate let cardDopShadowColor = UIColor(red: 235/255, green: 235/255, blue: 235/255, alpha: 1)
    
    @IBAction func onCreate(_ sender: AnyObject) {
        delegate?.createPlan()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        ViewHelpers.addDropShadow(containerView.superview!, color: cardDopShadowColor.CGColor, offset: CGSize(width: 0, height: 3), shadowRadius: 0, opacity: 1, cornerRadius: 10)
        ViewHelpers.roundedCorner(containerView, radius: 10)
        ViewHelpers.addDropShadow(createBtn, color: buttonDopShadowColor.CGColor, offset: CGSize(width: 0, height: 3), shadowRadius: 0, opacity: 1, cornerRadius: 10)
        
        createLabel.font = UIFont(name: serifMediumFontName, size: 15 * screenSizeMultiplier)
        createLabel.preferredMaxLayoutWidth = createLabel.frame.size.width
        createLabel.sizeToFit()
    }
}
