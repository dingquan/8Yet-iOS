//
//  DraggableCardView.swift
//  8Yet
//
//  Created by Ding, Quan on 3/5/15.
//  Copyright (c) 2015 EightYet. All rights reserved.
//

import UIKit
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


let tenDegrees:CGFloat = CGFloat(10 * M_PI / 180)
let cardCornerRadius:CGFloat = 9

private let greyColor = UIColor(red: 204/255, green: 204/255, blue: 204/255, alpha: 1)
private let meetColor = UIColor(red: 228/255, green: 102/255, blue: 34/255, alpha: 1)
private let passColor = UIColor(red: 253/255, green: 203/255, blue: 40/255, alpha: 1)
private let FAV_FOOD_COLL = 1
private let FAV_TOPICS_COLL = 2

private let sectionInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 5.0)

class DraggableCardView: UIView {
    fileprivate var profileImgSize:CGFloat = 75
    fileprivate var pinImgSize:CGFloat = 15
    fileprivate var scoreFontSize:CGFloat = 26
    fileprivate var scoreLabelFontSize:CGFloat = 15
    fileprivate var sizeMultiplier: CGFloat = 1
    fileprivate var friendsImgViews: [UIImageView] = []
    
    var user:User! {
        didSet {
            profileImageUrl = user.profileImageUrl
            if profileImageUrl != nil {
                ViewHelpers.fadeInImage(self.profileImage, imgUrl: self.profileImageUrl)
            }
            
            distanceLabel.text = "NA"
            if let toUserLocation = user.lastKnownLocation {
                if let fromUserLocation = User.currentUser()?.lastKnownLocation {
                    let distance = max(fromUserLocation.distanceInMilesTo(toUserLocation), 0.1)
                    distanceLabel.text = NSString(format: "%.1f miles away", distance) as String
                }
            }
            distanceLabel.sizeToFit()
            distanceLabel.center = CGPoint(x: self.bounds.width/2 + 10 * sizeMultiplier, y: 120 * sizeMultiplier)
            
            pinImgSize *= sizeMultiplier
            pinIcon.frame = CGRect(x: distanceLabel.frame.origin.x - pinImgSize, y: distanceLabel.center.y - pinImgSize / 2, width: pinImgSize, height: pinImgSize)
            
            scoreFontSize = ceil(scoreFontSize * sizeMultiplier)
            scoreLabelFontSize = ceil(scoreLabelFontSize * sizeMultiplier)
            let scoreFont = UIFont(name: sansSerifBoldFontName, size: scoreFontSize)
            let scoreLabelFont = UIFont(name: serifMediumFontName, size: scoreLabelFontSize)
            
            numMeets.font = scoreFont
            numMeets.text = "\(user.numMeets ?? 0)"
            numMeets.sizeToFit()
            numMeets.center.x = numMeets.superview!.bounds.width / 2
            numMeetsLabel.font = scoreLabelFont
            numMeetsLabel.sizeToFit()
            numMeetsLabel.center.x = numMeets.superview!.bounds.width / 2
            
            numBails.font = scoreFont
            numBails.text = "\(user.numBails ?? 0)"
            numBails.sizeToFit()
            numBails.center.x = numBails.superview!.bounds.width / 2
            numBailsLabel.font = scoreLabelFont
            numBailsLabel.sizeToFit()
            numBailsLabel.center.x = numBails.superview!.bounds.width / 2
            
            var ratingScore:Float = 0
            if (user.numRatings != nil && user.numRatings?.int32Value > 0 && user.totalRatingScore != nil) {
                ratingScore = Float(user.totalRatingScore!) / Float(user.numRatings!)
            }
            rating.font = scoreFont
            rating.text = ((ratingScore != 0) ? NSString(format: "%.1f", ratingScore) as String : "NA")
            rating.sizeToFit()
            rating.center.x = rating.superview!.bounds.width / 2
            ratingLabel.font = scoreLabelFont
            ratingLabel.sizeToFit()
            ratingLabel.center.x = numMeets.superview!.bounds.width / 2
            
            User.currentUser()!.getCommonFriends(user) { (commonFriends, error) -> Void in
                if commonFriends.count > 0 {
                    var x:CGFloat = 0
                    let y:CGFloat = 0
                    var friendIdx = 0
                    for friend in commonFriends {
                        if friendIdx == 5 {
                            break; // screen only has room for 5 common friends
                        }
                        let friendImgUrl = friend.profileImageUrl
                        let friendImgView = UIImageView(frame: CGRectMake(x, y, 36, 36))
                        friendImgView.contentMode = UIViewContentMode.ScaleAspectFill
                        self.commonFriendsImgs.addSubview(friendImgView)
                        self.friendsImgViews.append(friendImgView)
                        ViewHelpers.roundedCorner(friendImgView, radius: 18)
                        ViewHelpers.fadeInImage(friendImgView, imgUrl: friendImgUrl)
                        x += 46
                        friendIdx += 1
                    }
                }
            }

            loadFavoriteFoods()
            loadFavoriteTopics()
        }
    }
    var profileImageUrl:String?

    @IBOutlet var containerView: UIView!
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var pinIcon: UIImageView!
    
    @IBOutlet weak var topPanel: UIView!
    @IBOutlet weak var midPanel: UIView!
    @IBOutlet weak var bottomPanel: UIView!
    
    @IBOutlet weak var foodLabel: UILabel!
    @IBOutlet weak var topicsLabel: UILabel!
    
    @IBOutlet weak var favoriteFoodView: UIView!
    @IBOutlet weak var favoriteTopicsView: UIView!
    
    @IBOutlet weak var hangOutsView: UIView!
    @IBOutlet weak var bailOutsView: UIView!
    @IBOutlet weak var ratingView: UIView!
    
    @IBOutlet weak var numMeets: UILabel!
    @IBOutlet weak var numBails: UILabel!
    @IBOutlet weak var rating: UILabel!
    
    @IBOutlet weak var numMeetsLabel: UILabel!
    @IBOutlet weak var numBailsLabel: UILabel!
    @IBOutlet weak var ratingLabel: UILabel!

    @IBOutlet weak var meetLabel: UILabel!
    @IBOutlet weak var passLabel: UILabel!
    
    @IBOutlet weak var commonFriendsLabel: UILabel!
    @IBOutlet weak var commonFriendsImgs: UIView!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initSubviews()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initSubviews()
    }
    
    func initSubviews() {
        // standard initialization logic
        let nib = UINib(nibName: "DraggableCardView", bundle: nil)
        nib.instantiate(withOwner: self, options: nil)
        containerView.frame = bounds
        
        sizeMultiplier = UIScreen.main.bounds.width / 375
        
        ViewHelpers.roundedCornerWithBoarder(containerView, radius: cardCornerRadius, borderWidth: 0.5, color: greyColor)
        
        // meet and pass label
        var newMeetLabelBounds = meetLabel.bounds
        newMeetLabelBounds.size.width *= sizeMultiplier
        newMeetLabelBounds.size.height *= sizeMultiplier
        meetLabel.center.x = meetLabel.frame.origin.x * sizeMultiplier + newMeetLabelBounds.size.width / 2
        meetLabel.center.y = meetLabel.frame.origin.y * sizeMultiplier + newMeetLabelBounds.size.height / 2
        meetLabel.bounds = newMeetLabelBounds
        meetLabel.font = UIFont(name: serifBoldFontName, size: ceil(26 * sizeMultiplier))
        meetLabel.transform = CGAffineTransform(rotationAngle: -tenDegrees)
        meetLabel.alpha = 0
        ViewHelpers.roundedCornerWithBoarder(meetLabel, radius: 5, borderWidth: 3, color: meetColor)
        
        var newPassLabelBounds = passLabel.bounds
        newPassLabelBounds.size.width *= sizeMultiplier
        newPassLabelBounds.size.height *= sizeMultiplier
        passLabel.center.x = self.bounds.width - meetLabel.center.x
        passLabel.center.y = passLabel.frame.origin.y * sizeMultiplier + newPassLabelBounds.size.height / 2
        passLabel.bounds = newPassLabelBounds
        passLabel.font = UIFont(name: serifBoldFontName, size: ceil(26 * sizeMultiplier))
        passLabel.transform = CGAffineTransform(rotationAngle: tenDegrees)
        passLabel.alpha = 0
        ViewHelpers.roundedCornerWithBoarder(passLabel, radius: 5, borderWidth: 3, color: passColor)

        // top panel
        profileImgSize *= sizeMultiplier
        profileImage.frame = CGRect(x: (self.bounds.width - profileImgSize)/2, y: 30 * sizeMultiplier, width: profileImgSize, height: profileImgSize)
        ViewHelpers.roundedCorner(profileImage, radius: profileImgSize/2)
        
        distanceLabel.font = UIFont(name: sansSerifFontName, size: 11 * sizeMultiplier)
        
        let scoresViewWidth = self.bounds.width / 3
        self.hangOutsView.frame = CGRect(x: 0, y: 0, width: scoresViewWidth, height: bottomPanel.frame.height)
        self.bailOutsView.frame = CGRect(x: scoresViewWidth, y: 0, width: scoresViewWidth, height: bottomPanel.frame.height)
        self.ratingView.frame = CGRect(x: scoresViewWidth * 2, y: 0, width: scoresViewWidth, height: bottomPanel.frame.height)

        // mid panel
        foodLabel.font = UIFont(name: serifMediumFontName, size: 15 * sizeMultiplier)
        foodLabel.sizeToFit()
        
        topicsLabel.font = UIFont(name: serifMediumFontName, size: 15 * sizeMultiplier)
        topicsLabel.sizeToFit()
        
        // bottom panel
        commonFriendsLabel.font = UIFont(name: serifMediumFontName, size: 15 * sizeMultiplier)
        commonFriendsLabel.sizeToFit()
        
        addSubview(containerView)
        layoutIfNeeded() //triggers the call to layoutSubviews() immediatedly
        
        // custom initialization logic
        
    }
    
    fileprivate func loadFavoriteFoods() {
        var x: CGFloat = 0
        var y: CGFloat = 0
        if let favoriteCuisine = user.favoriteCuisine {
            for favoriteFood in favoriteCuisine {
                if let favoriteFood = favoriteFood as? String {
                    let foodLabel = createFavoritesLabel(favoriteFood, x: &x, y: &y, containerView: favoriteFoodView)
                    self.favoriteFoodView.addSubview(foodLabel)
                    if x + foodLabel.bounds.width <= favoriteFoodView.bounds.width {
                        x += foodLabel.bounds.width + 10
                    } else {
                        x = 0
                        y += foodLabel.bounds.height + 6
                    }
                }
            }
        }
    }
    
    fileprivate func loadFavoriteTopics() {
        var x: CGFloat = 0
        var y: CGFloat = 0
        if let interests = user.interests {
            for interest in interests {
                if let interest = interest as? String {
                    let topicLabel = createFavoritesLabel(interest, x: &x, y: &y, containerView: favoriteTopicsView)
                    self.favoriteTopicsView.addSubview(topicLabel)
                    x = topicLabel.frame.origin.x + topicLabel.frame.width + 10 // 10 being the horizontal padding between cells
                    y = topicLabel.frame.origin.y
                }
            }
        }
    }
    
    fileprivate func createFavoritesLabel(_ forText: String, x: inout CGFloat, y: inout CGFloat, containerView: UIView) -> UILabel {
        let label = UILabel()
        label.font = UIFont(name: sansSerifFontName, size: 12 * screenSizeMultiplier)
        label.textColor = UIColor(red: 129/255, green: 131/255, blue: 134/255, alpha: 1)
        label.backgroundColor = UIColor(red: 235/255, green: 235/255, blue: 235/255, alpha: 1)
        label.text = forText
        label.textAlignment = NSTextAlignment.center
        label.sizeToFit()
        let newWidth = label.bounds.width + 16 // add some padding left and right
        let newHeight = label.bounds.height + 8 //  add some padding top and bottom
        if x + newWidth <= containerView.bounds.width {
            label.frame = CGRect(x: x, y: y, width: newWidth, height: newHeight)
        } else {
            x = 0
            y += newHeight + 6 // 6 being the vertical padding between cells
            label.frame = CGRect(x: x, y: y, width: newWidth, height: newHeight)
        }
        ViewHelpers.roundedCorner(label, radius: newHeight / 2)
        return label
    }
    
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */
    
}
