//
//  WordCollectionViewCell.swift
//  8Yet
//
//  Created by Quan Ding on 4/17/15.
//  Copyright (c) 2015 EightYet. All rights reserved.
//

import UIKit

private let borderColorUnselected: UIColor = UIColor(red: 235/255, green: 235/255, blue: 235/255, alpha: 1)
private let borderColorSelected: UIColor = UIColor.white
private let backgroundColorSelected = UIColor(red: 235/255, green: 235/255, blue: 235/255, alpha: 1)
private let backgroundColorUnselected = UIColor.white
private let textColorSelected: UIColor = UIColor(red: 147/255, green: 149/255, blue: 152/255, alpha: 1) //UIColor.whiteColor()
private let textColorUnselected: UIColor = UIColor(red: 147/255, green: 149/255, blue: 152/255, alpha: 1)

class WordCollectionViewCell: UICollectionViewCell {

    var word: String? {
        didSet {
            wordLabel.text = word
            setSelectionState()
        }
    }
    
    @IBOutlet weak var wordLabel: UILabel!
   
    // update the colors and stuff based on the selection state
    func setSelectionState(){
        let collectionCellView = wordLabel.superview!
        if self.isSelected {
            collectionCellView.backgroundColor = backgroundColorSelected
            ViewHelpers.roundedCornerWithBoarder(collectionCellView, radius: 10, borderWidth: 1, color: borderColorSelected)
            wordLabel.textColor = textColorSelected
        } else {
            collectionCellView.backgroundColor = backgroundColorUnselected
            ViewHelpers.roundedCornerWithBoarder(collectionCellView, radius: 10, borderWidth: 1, color: borderColorUnselected)
            wordLabel.textColor = textColorUnselected
        }
    }
}
