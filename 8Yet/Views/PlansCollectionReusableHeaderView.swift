//
//  PlansCollectionReusableHeaderView.swift
//  8Yet
//
//  Created by Quan Ding on 2/28/16.
//  Copyright © 2016 EightYet. All rights reserved.
//

import UIKit

class PlansCollectionReusableHeaderView: UICollectionReusableView {
    
    @IBOutlet weak var headerLabel: UILabel!
    
    var headerName: String = "" {
        didSet {
            headerLabel.text = headerName
            headerLabel.sizeToFit()
        }
    }
}
