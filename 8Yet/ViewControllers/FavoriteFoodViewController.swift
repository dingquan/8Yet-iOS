//
//  FavoriteFoodViewController.swift
//  8Yet
//
//  Created by Quan Ding on 3/14/16.
//  Copyright © 2016 EightYet. All rights reserved.
//

import UIKit

private let reuseIdentifier = "foodCell"
private let sectionInsets = UIEdgeInsets(top: 20, left: 5.0, bottom: 20, right: 5.0)
private let defaultFoodCategories = ["American", "Asian Fusion", "Bistros", "Chinese", "Fast Food", "Filipino", "French", "Greek", "Indian", "Italian", "Japanese", "Korean", "Latin American", "Mediterranean", "Mexican",  "Thai", "Pakistani", "Southern", "Vegan", "Vegetarian", "Vietnamese"]

private let buttonDopShadowColor = UIColor(red: 46/255, green: 185/255, blue: 149/255, alpha: 1)

class FavoriteFoodViewController: BaseViewController,  UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    fileprivate var foodCategories:[String]!
    fileprivate var selectedCategories:NSMutableSet!
    fileprivate var sizingCell:WordCollectionViewCell! // a cell used to calculate the size. since collection view cell size is calculated prior to the cell being created, we had to use a seragate cell just to calculate the size
    
    @IBOutlet weak var foodPreferencesCollectionView: UICollectionView!
    
    @IBOutlet weak var gradientView: UIView!
    
    @IBOutlet weak var saveBtn: UIButton!
    @IBOutlet weak var saveBtnWidthConstraint: NSLayoutConstraint!
    
    @IBAction func onSave(_ sender: AnyObject) {
        Analytics.sharedInstance.event(Analytics.Event.EditFavoriteFood.rawValue)
        saveSelections()
        NotificationCenter.defaultCenter.postNotificationName(NSNotification.Name(rawValue: profileChangeNotification), object: User.currentUser())
        self.navigationController?.popViewController(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        foodCategories = (AppProperties.sharedInstance.getPropertyWithDefault("foodCategories", defaultValue: defaultFoodCategories) as! [String]).sorted()
        
        selectedCategories = NSMutableSet()
        
        foodPreferencesCollectionView.allowsMultipleSelection = true
        foodPreferencesCollectionView.allowsSelection = true
        
        // use the left align flow layout
        let layout = UICollectionViewLeftAlignedLayout()
        layout.minimumInteritemSpacing = 10.0
        layout.minimumLineSpacing = 10.0
        self.foodPreferencesCollectionView.setCollectionViewLayout(layout, animated: true)
        
        // couldn't get the cell auto-resizing to work using a prototype cell in the storyboard, so use a separate XIB file
        // following this tutorial: http://www.cocoanetics.com/2013/08/variable-sized-items-in-uicollectionview/
        let cellNib = UINib(nibName: "WordCollectionViewCell", bundle: nil)
        foodPreferencesCollectionView.register(cellNib, forCellWithReuseIdentifier: reuseIdentifier)
        
        // get a cell as template for sizing, the NIB file should contain only one top level view (retrived at index 0)
        sizingCell = cellNib.instantiate(withOwner: nil, options: nil)[0] as! WordCollectionViewCell
        
        saveBtnWidthConstraint.constant *= screenSizeMultiplier
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadSelections()
    }
    
    override func viewDidLayoutSubviews() {
        ViewHelpers.addTransparentForground(self.gradientView, colors: [UIColor.whiteColor().CGColor, UIColor.clearColor().CGColor, UIColor.clearColor().CGColor, UIColor.whiteColor().CGColor], locations: [0, 0.05, 0.95, 1], isVertical: true)
        ViewHelpers.addDropShadow(saveBtn, color: buttonDopShadowColor.CGColor, offset: CGSize(width: 0, height: 3), shadowRadius: 0, opacity: 1, cornerRadius: 10)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - UICollectionViewDataSource
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return foodCategories.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! WordCollectionViewCell
        
        // Configure the cell
        let foodCategory = self.foodCategories[indexPath.row]
        if self.selectedCategories.contains(foodCategory) {
            print("select \(foodCategory)")
            self.foodPreferencesCollectionView.selectItem(at: indexPath, animated: true, scrollPosition: UICollectionViewScrollPosition())
            cell.isSelected = true //seems really stupid, but collectionView.selectItemAtIndexPath above doesn't seem to flip the selected flag on the cell and I have to do it manually
        }
        cell.word = foodCategory
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! WordCollectionViewCell
        self.selectedCategories.add(cell.word!)
        cell.setSelectionState()
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! WordCollectionViewCell
        self.selectedCategories.remove(cell.word!)
        cell.setSelectionState()
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    func collectionView(_ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath) -> CGSize {
            
            let foodCategory = self.foodCategories[indexPath.row]
            sizingCell.word = foodCategory
            return sizingCell.systemLayoutSizeFitting(UILayoutFittingCompressedSize)
    }
    
    func collectionView(_ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int) -> UIEdgeInsets {
            return sectionInsets
    }
    
    // MARK: - Private functions
    fileprivate func loadSelections() {
        if let currentUser = User.currentUser() {
            self.selectedCategories = NSMutableSet()
            if let favoriteCuisine = currentUser.favoriteCuisine {
                self.selectedCategories.addObjectsFromArray(favoriteCuisine as [AnyObject])
            }
            print("loaded favorite cuisine: \(self.selectedCategories)")
        }
    }
    
    fileprivate func saveSelections() {
        if let currentUser = User.currentUser() {
            print("saving favorite cuisine: \(self.selectedCategories.description)")
            currentUser.favoriteCuisine = self.selectedCategories.allObjects
            currentUser.saveInBackgroundWithBlock({ (success, error: NSError?) -> Void in
                if success {
                    print("Favorite cuisine saved successfully")
                }
            })
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
