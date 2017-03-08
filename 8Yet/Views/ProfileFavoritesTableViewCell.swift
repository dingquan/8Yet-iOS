//
//  ProfileFavoritesTableViewCell.swift
//  8Yet
//
//  Created by Quan Ding on 3/7/16.
//  Copyright © 2016 EightYet. All rights reserved.
//

import UIKit

protocol ProfileFavoritesTableViewCellDelegate: class {
    func onEditFavorites(_ type: Int)
}

private let userProfileFavoritesReuseIdentifier = "userProfileFavoritesReuseIdentifier"

class ProfileFavoritesTableViewCell: UITableViewCell {
    static let TYPE_FOOD = 0
    static let TYPE_TOPIC = 1
    
    var delegate: ProfileFavoritesTableViewCellDelegate?
    var user: User? {
        didSet {
            if user?.objectId != User.currentUser()?.objectId {
                editBtn.isHidden = true
            } else {
                editBtn.isHidden = false
            }
            drawFavorites()
        }
    }
    
    var type: Int?
    
    fileprivate var favoriteLabels = [UILabel]()
    
    @IBOutlet weak var editBtn: UIButton!
    @IBOutlet weak var favoritesImage: UIImageView!
    @IBOutlet weak var favoritesLabel: UILabel!
    @IBOutlet weak var favoritesContainerView: UIView!
    @IBOutlet weak var favoritesContainerViewHeight: NSLayoutConstraint!
    @IBOutlet weak var favoritesContarinerLeftConstraint: NSLayoutConstraint!
    @IBOutlet weak var favoritesContainerRightConstraint: NSLayoutConstraint!
    
    
    @IBAction func editFavorites(_ sender: AnyObject) {
        if let type = type {
            delegate?.onEditFavorites(type)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    // MARK: - Private functions
    fileprivate func drawFavorites() {
        if let user = self.user {
            for favoriteLabel in favoriteLabels {
                favoriteLabel.removeFromSuperview()
            }
            
            var favorites: [String]?
            if type == ProfileFavoritesTableViewCell.TYPE_FOOD {
                favorites = user.favoriteCuisine as? [String]
            } else if type == ProfileFavoritesTableViewCell.TYPE_TOPIC {
                favorites = user.interests as? [String]
            }
            
            var x:CGFloat = 0
            var y:CGFloat = 0
            
            let containerWidth = UIScreen.main.bounds.width - favoritesContarinerLeftConstraint.constant - favoritesContainerRightConstraint.constant
            print("container view width: \(containerWidth)")
            for favorite in (favorites ?? []) {
                let favoriteLabel = createFavoriteLabel(favorite, x: &x, y: &y, containerView: self.favoritesContainerView, containerWidth: containerWidth)
                self.favoritesContainerView.addSubview(favoriteLabel)
                favoriteLabels.append(favoriteLabel)
            }
            self.favoritesContainerViewHeight.constant = y + 40
        } else {
            self.favoritesContainerViewHeight.constant = 0
        }
    }
    
    fileprivate func createFavoriteLabel(_ forText: String, x: inout CGFloat, y: inout CGFloat, containerView: UIView, containerWidth: CGFloat) -> UILabel {
        let label = UILabel()
        label.font = UIFont(name: sansSerifFontName, size: 15)
        label.textColor = UIColor(red: 167/255, green: 169/255, blue: 171/255, alpha: 1)
        label.backgroundColor = UIColor.white
        label.text = forText
        label.textAlignment = NSTextAlignment.center
        label.sizeToFit()
        let newWidth = label.bounds.width + 24 // add some padding left and right
        let newHeight = label.bounds.height + 20 //  add some padding top and bottom
        if x + newWidth > containerWidth {
            x = 0
            y += newHeight + 8 // 8 being the vertical padding between cells
        }
        label.frame = CGRect(x: x, y: y, width: newWidth, height: newHeight)
        x += newWidth + 12
        
        let isCommon = isCommonFavorite(forText)
        var boarderColor = UIColor(red: 235/255, green: 235/255, blue: 235/255, alpha: 1)
        if isCommon {
            boarderColor = UIColor(red: 229/255, green: 104/255, blue: 34/255, alpha: 1)
        }
        ViewHelpers.roundedCornerWithBoarder(label, radius: 10, borderWidth: 1, color: boarderColor)
        return label
    }
    
    fileprivate func isCommonFavorite(_ favorite: String?) -> Bool {
        var isCommon = false
        if User.currentUser()?.objectId != self.user?.objectId {
            if let user = User.currentUser() {
                if type == ProfileFavoritesTableViewCell.TYPE_FOOD {
                    if let favoriteFood = user.favoriteCuisine as? [String] {
                        if let favorite = favorite {
                            isCommon = favoriteFood.contains(favorite)
                        }
                    }
                } else if type == ProfileFavoritesTableViewCell.TYPE_TOPIC {
                    if let favoriteTopics = user.interests as? [String] {
                        if let favorite = favorite {
                            isCommon = favoriteTopics.contains(favorite)
                        }
                    }
                }
            }
        }
        return isCommon
    }

    // MARK: - Helper functions
    func setTypeAndUser(_ type: Int, user: User?) {
        
        self.type = type
        self.user = user
        
        if type == ProfileFavoritesTableViewCell.TYPE_FOOD {
            favoritesImage.image = UIImage(named: "favoriteFood")
            favoritesLabel.text = "Favorite Food"
            favoritesLabel.sizeToFit()
        } else if type == ProfileFavoritesTableViewCell.TYPE_TOPIC {
            favoritesImage.image = UIImage(named: "favoriteTopic")
            favoritesLabel.text = "Favorite Topics"
            favoritesLabel.sizeToFit()
        }
    }
}
