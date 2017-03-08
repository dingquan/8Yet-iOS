//
//  CreatePlanViewController.swift
//  8Yet
//
//  Created by Quan Ding on 2/8/16.
//  Copyright © 2016 EightYet. All rights reserved.
//

import UIKit
import GoogleMaps
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


private let HOUR_COLL = 1
private let MINUTE_COLL = 2

private let TOPIC_FIELD = 0
private let LOCATION_FIELD = 1

private let reuseIdentifierHour = "hourCell"
private let reuseIdentifierMinute = "minuteCell"

private let sectionInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

private let cancelBtnShadowColor = UIColor(red: 199/255, green: 88/255, blue: 31/255, alpha: 1)
private let createBtnShadowColor = UIColor(red: 46/255, green: 185/255, blue: 149/255, alpha: 1)
private let createBtnDisabledShadowColor = UIColor(red: 167/255, green: 169/255, blue: 171/255, alpha: 1)
private let createBtnColor = UIColor(red: 54/255, green: 212/255, blue: 171/255, alpha: 1)
private let createBtnDisabledColor = UIColor(red: 235/255, green: 235/255, blue: 235/255, alpha: 1)

class CreatePlanViewController: BaseViewController, UITextFieldDelegate, UIGestureRecognizerDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, MKMapViewDelegate, GMSAutocompleteTableDataSourceDelegate {

    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var scrollViewContentView: UIView!
    @IBOutlet weak var createBtn: UIButton!
    @IBOutlet weak var cancelBtn: UIButton!
    @IBOutlet weak var topicTextField: UITextField!
    @IBOutlet weak var locationTextField: UITextField!
    
    @IBOutlet weak var mapContainerView: UIView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var addressView: UIView!
    @IBOutlet weak var addressLabel: UILabel!

    @IBOutlet weak var hourCollectionView: UICollectionView!
    @IBOutlet weak var minuteCollectionView: UICollectionView!
    
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var hourGradientView: UIView!
    @IBOutlet weak var minuteGradientView: UIView!
    
    fileprivate var hourChoices: [Int] = []
    fileprivate var minuteChoices: [Int] = []
    fileprivate var planTime: Date? = Date()
    fileprivate var planLocation: Location?
    fileprivate let calendar = Calendar.current
    fileprivate let now = Date()
    
    fileprivate var resultView: UITextView?
    fileprivate var tableDataSource: GMSAutocompleteTableDataSource?
    fileprivate var resultsController: UITableViewController?
    fileprivate var searchResultsContentRect: CGRect?
    fileprivate var tapGestureRecognizer: UITapGestureRecognizer?
    fileprivate var autoCompleteTableShown = false
    
    var plan: Plan?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setTimeCollectionChoices()
        setupViews()
        setupLocationSearchAutoComplete()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // do gradient in viewDidLayoutSubviews so that all views have proper sizing
        // otherwise gradient view might be in wrong size compared with the view that it's trying to cover
        ViewHelpers.addTransparentForground(hourGradientView, colors: [UIColor.whiteColor().CGColor, UIColor.clearColor().CGColor, UIColor.clearColor().CGColor, UIColor.whiteColor().CGColor], locations: [0, 0.4, 0.6,1], isVertical: false)
        ViewHelpers.addTransparentForground(minuteGradientView, colors: [UIColor.whiteColor().CGColor, UIColor.clearColor().CGColor, UIColor.clearColor().CGColor, UIColor.whiteColor().CGColor], locations: [0, 0.4, 0.6,1], isVertical: false)
        ViewHelpers.addDropShadow(cancelBtn, color: cancelBtnShadowColor.CGColor, offset: CGSize(width: 0,height: 3), shadowRadius: 0, opacity: 1, cornerRadius: 10)
        if createBtn.isEnabled {
            ViewHelpers.addDropShadow(createBtn, color: createBtnShadowColor.CGColor, offset: CGSize(width: 0,height: 3), shadowRadius: 0, opacity: 1, cornerRadius: 10)
        } else {
            ViewHelpers.addDropShadow(createBtn, color: createBtnDisabledShadowColor.CGColor, offset: CGSize(width: 0,height: 3), shadowRadius: 0, opacity: 1, cornerRadius: 10)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        populateViews()
    }
    
    // MARK: - Actions
    @IBAction func onCancel(_ sender: AnyObject) {
        if self.plan == nil {
            Analytics.sharedInstance.event(Analytics.Event.CancelCreatePlan.rawValue)
        }
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onCreate(_ sender: AnyObject) {
        var isCreate = false
        if validateForm() == false {
            return
        }
        if self.plan == nil {
            self.plan = Plan()
            isCreate = true
        }
        
        if isCreate {
            Analytics.sharedInstance.event(Analytics.Event.FinishCreatePlan.rawValue)
        } else {
            Analytics.sharedInstance.event(Analytics.Event.UpdatePlan.rawValue)
        }
        
        plan?.topic = topicTextField.text
        
        if planLocation == nil {
            planLocation = Location()
            planLocation?.name = locationTextField.text ?? ""
            if let userGeo = User.currentUser()?.lastKnownLocation {
                planLocation?.geo = userGeo
            }
        }

        if let planLocation = planLocation {
            plan?.location = planLocation
        }
        plan?.geo = planLocation?.geo ?? User.currentUser()?.lastKnownLocation
        plan?.startTime = planTime ?? now
        plan?.host = User.currentUser()!
        plan?.participants = [User.currentUser()!]
        plan?.minParticipants = 2
        plan?.maxParticipants = 4
        plan?.numParticipants = 1
        
        plan?.saveInBackgroundWithBlock({ (success, error) -> Void in
            if success {
                NSLog("Plan saved successfully!")
                User.currentUser()?.fetchInBackground()
                self.dismissViewControllerAnimated(true, completion: nil)
                if isCreate {
                    NSNotificationCenter.defaultCenter().postNotificationName(createPlanNotification, object: self.plan)
                } else {
                    NSNotificationCenter.defaultCenter().postNotificationName(updatePlanNotification, object: self.plan)
                }
            } else if error != nil {
                NSLog("Error saving plan: \(error)")
                ViewHelpers.presentErrorMessage(error!, vc: self)
            }
        })
    }

    // MARK: - UITextViewDelegate
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField.tag == LOCATION_FIELD {
            UIView.animate(withDuration: 0.5, animations: { () -> Void in
                self.resultsController?.view.alpha = 0
                }, completion: { (finished) -> Void in
                    self.resultsController?.view.removeFromSuperview()
                    self.resultsController?.removeFromParentViewController()
                    if textField.text?.utf16.count > 0 {
                        self.enableCreateButton(true)
                    } else {
                        self.enableCreateButton(false)
                    }
            })
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if textField.tag == LOCATION_FIELD {
            if textField.text?.utf16.count > 0 {
                enableCreateButton(true)
            } else {
                enableCreateButton(false)
            }
        }
        self.view.removeGestureRecognizer(tapGestureRecognizer!)
        self.view.addGestureRecognizer(tapGestureRecognizer!)
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        if textField.tag == LOCATION_FIELD {
            enableCreateButton(false)
        }
        return true
    }
    
    func textFieldDidChange(_ textField: UITextField) {
        if textField.tag == LOCATION_FIELD && autoCompleteTableShown == false {
            addAutoCompleteTableView()
            autoCompleteTableShown = true
        }
        tableDataSource?.sourceTextHasChanged(textField.text)
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        autoCompleteTableShown = false // reset the flag
    }
    
    // MARK: - MKMapViewDelegate
    func mapView(_ mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        var pinView = self.mapView.dequeueReusableAnnotationViewWithIdentifier("mapPointAnnotation")
        if pinView == nil {
            pinView = MKAnnotationView(annotation: annotation, reuseIdentifier: "mapPointAnnotation")
        }
        pinView?.canShowCallout = true
        pinView?.image = UIImage(named: "mapPin")
        return pinView
    }
    
    // MARK: - Private functions
    
    fileprivate func updateMap() {
        addressLabel.text = ""
        if let planLocation = self.planLocation {
            let address = planLocation.address
            addressLabel.text = address
            addressLabel.preferredMaxLayoutWidth = addressLabel.bounds.width
            addressLabel.sizeToFit()
            let geo = planLocation.geo
            mapView.removeAnnotations(mapView.annotations) // clear previous annotations
            ViewHelpers.showLocationOnMap(mapView, location: planLocation)
            ViewHelpers.centerMapOnLocation(mapView, geo: geo, regionRadius: 500)
        } else {
            if let geo = User.currentUser()?.lastKnownLocation {
                ViewHelpers.showLocationOnMap(mapView, geo: geo)
                ViewHelpers.centerMapOnLocation(mapView, geo: geo, regionRadius: 500)
            }
        }
    }
    
    fileprivate func addAutoCompleteTableView() {
        resultsController?.view.frame = searchResultsContentRect ?? CGRect.zero
        resultsController?.view.alpha = 0.0
        scrollViewContentView.addSubview(resultsController?.view ?? UIView())
        UIView.animate(withDuration: 0.5, animations: { () -> Void in
            self.resultsController?.view.alpha = 1.0
        })
        resultsController?.didMove(toParentViewController: self)
        // remove tap gesture recognizer which interferes with the auto complete table selection
        if let tapGestureRecognizer = tapGestureRecognizer {
            self.view.removeGestureRecognizer(tapGestureRecognizer)
        }
    }
    
    fileprivate func addPaddingView(_ view: UITextField) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: self.view.frame.height))
        view.leftView = paddingView
        view.leftViewMode = UITextFieldViewMode.always
    }
    
    fileprivate func setupViews() {
        
        topicTextField.delegate = self
        topicTextField.tag = TOPIC_FIELD
        //topicTextField.inputAccessoryView = UIView() // remove the toolbar
        locationTextField.delegate = self
        locationTextField.tag = LOCATION_FIELD
        //locationTextField.inputAccessoryView = UIView() // remove the toolbar
        
        // default UITextField rounded corner size is different from what we want, so we manually round the corners
        ViewHelpers.roundedCornerWithBoarder(topicTextField, radius: 10, borderWidth: 1, color: UIColor(red: 235/255, green: 235/255, blue: 235/255, alpha: 1))
        ViewHelpers.roundedCornerWithBoarder(locationTextField, radius: 10, borderWidth: 1, color: UIColor(red: 235/255, green: 235/255, blue: 235/255, alpha: 1))
        // UITextField Left inset becomes zero once we change the textfield style to none, so we manually add some padding to the left
        addPaddingView(topicTextField)
        addPaddingView(locationTextField)
        
        hourCollectionView.delegate = self
        hourCollectionView.dataSource = self
        hourCollectionView.tag = HOUR_COLL
        minuteCollectionView.delegate = self
        minuteCollectionView.dataSource = self
        minuteCollectionView.tag = MINUTE_COLL
        
        ViewHelpers.roundedCornerWithBoarder(hourCollectionView, radius: 10, borderWidth: 1, color: UIColor(red: 235/255, green: 235/255, blue: 235/255, alpha: 1))
        ViewHelpers.roundedCornerWithBoarder(minuteCollectionView, radius: 10, borderWidth: 1, color: UIColor(red: 235/255, green: 235/255, blue: 235/255, alpha: 1))
        
        let cellNib = UINib(nibName: "PlanTimeCollectionViewCell", bundle: nil)
        hourCollectionView.register(cellNib, forCellWithReuseIdentifier: reuseIdentifierHour)
        minuteCollectionView.register(cellNib, forCellWithReuseIdentifier: reuseIdentifierMinute)
       
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(CreatePlanViewController.dismissKeyboard(_:)))
        tapGestureRecognizer?.delegate = self
        tapGestureRecognizer?.cancelsTouchesInView = false // need to set this property, otherwise the set time collection views won't get the touch events
        self.view.addGestureRecognizer(tapGestureRecognizer!)

        if self.plan != nil {
            createBtn.setTitle("Save", for: UIControlState())
            enableCreateButton(true)
        } else {
            // clear all labels' initial values from the storyboard
            self.timeLabel.text = ""
            self.addressLabel.text = ""
            createBtn.setTitle("Create", for: UIControlState())
            enableCreateButton(false)
        }
        createBtn.setTitleColor(UIColor.white, for: UIControlState())
        createBtn.setTitleColor(createBtnDisabledShadowColor, for: UIControlState.disabled)
    }
    
    fileprivate func populateViews() {
        let now = Date()
        var hour: Int
        var minute: Int
        
        if let plan = self.plan {
            headerLabel.text = "Change Your Plan"
            headerLabel.sizeToFit()
            
            if let topic = plan.topic {
                topicTextField.text = topic
            }
            
            if let location = plan.location {
                self.planLocation = location
                if let name = location.name {
                    locationTextField.text = name
                } else {
                    locationTextField.text = location.address
                }
            }
            
            timeLabel.text = amPmDateFormatter.string(from: plan.startTime)
            self.planTime = plan.startTime as Date
            let components = (calendar as NSCalendar).components([.hour, .minute], from: plan.startTime as Date)
            hour = components.hour!
            minute = components.minute!
        } else {
            let currentHour = getCurrentHour()
            if (currentHour > 10 && currentHour < 12) {
                hour = 12
            } else if (currentHour > 17 && currentHour < 19) {
                hour = 19
            } else {
                hour = hourChoices[1]
            }
            minute = 0
            self.planTime = (calendar as NSCalendar).date(bySettingHour: hour, minute: minute, second: 0, of: now, options: NSCalendar.Options())
            if hour < currentHour { // after mid night case
                self.planTime = (calendar as NSCalendar).date(byAdding: NSCalendar.Unit.day, value: 1, to: self.planTime ?? now, options: NSCalendar.Options())
            }
            timeLabel.text = amPmDateFormatter.string(from: self.planTime ?? now)
        }
        
        updateMap() // update map depends on self.planLocation being set above
        
        let hourChoiceIndex = hourChoices.index(of: hour) ?? 0
        let minuteChoiceIndex = minuteChoices.index(of: minute) ?? 0
        let hourIndexPath = IndexPath(item: hourChoiceIndex, section: 0)
        let minuteIndexPath = IndexPath(item: minuteChoiceIndex, section: 0)
        let hourCell = hourCollectionView.cellForItem(at: hourIndexPath) as? PlanTimeCollectionViewCell
        let minuteCell = minuteCollectionView.cellForItem(at: minuteIndexPath) as? PlanTimeCollectionViewCell
        hourCollectionView.selectItem(at: hourIndexPath, animated: true, scrollPosition: UICollectionViewScrollPosition.centeredHorizontally)
        minuteCollectionView.selectItem(at: minuteIndexPath, animated: true, scrollPosition: UICollectionViewScrollPosition.centeredHorizontally)
        hourCell?.setSelectionState()
        minuteCell?.setSelectionState()

    }
    
    // can only set plans for the next 4 hours
    fileprivate func setTimeCollectionChoices() {
        let components = (calendar as NSCalendar).components([NSCalendar.Unit.hour], from: now)
        let hour = components.hour
        hourChoices = [hour, (hour+1)%24, (hour+2)%24, (hour+3)%24]
        minuteChoices = [0,15,30,45]
    }
    
    fileprivate func getCurrentHour() -> Int {
        let components = (calendar as NSCalendar).components([NSCalendar.Unit.hour], from: now)
        let hour = components.hour
        return hour!
    }
    
    fileprivate func updatePlanTime() {
        let hourIndexPaths = hourCollectionView.indexPathsForSelectedItems
        let minuteIndexPaths = minuteCollectionView.indexPathsForSelectedItems
        if hourIndexPaths?.count > 0 && minuteIndexPaths?.count > 0 {
            let currentHour = getCurrentHour()
            let hour = hourChoices[hourIndexPaths![0].row]
            let minute = minuteChoices[minuteIndexPaths![0].row]
            self.planTime = (calendar as NSCalendar).date(bySettingHour: hour, minute: minute, second: 0, of: self.planTime ?? now, options: NSCalendar.Options())
            if hour < currentHour { // after mid night case
                self.planTime = (calendar as NSCalendar).date(byAdding: NSCalendar.Unit.day, value: 1, to: self.planTime ?? now, options: NSCalendar.Options())
            }
            timeLabel.text = amPmDateFormatter.string(from: self.planTime ?? Date())
        }
    }
    
    fileprivate func validateForm() -> Bool {
        var isValid = true
        if locationTextField.text?.utf16.count == 0 {
            isValid = false
        }
        return isValid
    }
    
    // MARK: - Gesture recognizer
    func dismissKeyboard(_ gesture: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }
    
    // MARK: - UIScrollViewDelegate
    // when time collection view stops scrolling, select the middle visible cell
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate { // if the cell is still moving, let scrollViewDidEndDecelerating handle the selection when the cell has stopped moving
            selectCenterCell(scrollView as? UICollectionView)
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        selectCenterCell(scrollView as? UICollectionView)
    }
    
    // MARK: - UICollectionViewDataSource
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView.tag == HOUR_COLL {
            return hourChoices.count
        } else {
            return minuteChoices.count
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var cell: PlanTimeCollectionViewCell
        if collectionView.tag == HOUR_COLL {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifierHour, for: indexPath) as! PlanTimeCollectionViewCell
            cell.time = PlanTimeCollectionViewCell.Time(type: .Hour, value: hourChoices[indexPath.row])
        } else {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifierMinute, for: indexPath) as! PlanTimeCollectionViewCell
            cell.time = PlanTimeCollectionViewCell.Time(type: .Minute, value: minuteChoices[indexPath.row])
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        if let cell = cell { // cell could be nil when it's not visible
            (cell as! PlanTimeCollectionViewCell).setSelectionState()
        }
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        updatePlanTime()
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        if let cell = cell { // cell could be nil when it's not visible
            (cell as! PlanTimeCollectionViewCell).setSelectionState()
        }
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    func collectionView(_ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath) -> CGSize {
            let height = collectionView.bounds.height
            return CGSize(width: height, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int) -> UIEdgeInsets {
            // give some room on left and right so that even first or last item can be scroll to the middle while tapped
            let width = collectionView.bounds.width
            let height = collectionView.bounds.height
            let insets = UIEdgeInsets(top: 0, left: (width - height)/2, bottom: 0, right: (width - height)/2)
            return insets
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    // MARK: - Private functions
    fileprivate func enableCreateButton(_ enable: Bool) {
        if enable && createBtn.isEnabled == false {
            createBtn.isEnabled = true
            createBtn.backgroundColor = createBtnColor
            ViewHelpers.addDropShadow(createBtn, color: createBtnShadowColor.CGColor, offset: CGSize(width: 0,height: 3), shadowRadius: 0, opacity: 1, cornerRadius: 10)
            createBtn.layoutIfNeeded()
        } else if (!enable && createBtn.isEnabled == true){
            createBtn.isEnabled = false
            createBtn.backgroundColor = createBtnDisabledColor
            ViewHelpers.addDropShadow(createBtn, color: createBtnDisabledShadowColor.CGColor, offset: CGSize(width: 0,height: 3), shadowRadius: 0, opacity: 1, cornerRadius: 10)
            createBtn.layoutIfNeeded()
        }
    }
    
    fileprivate func setupLocationSearchAutoComplete() {
        locationTextField.addTarget(self, action: #selector(CreatePlanViewController.textFieldDidChange(_:)), for: UIControlEvents.editingChanged)
        
        searchResultsContentRect = CGRect(x: 0, y: locationTextField.frame.origin.y + locationTextField.bounds.height + 2, width: scrollViewContentView.bounds.size.width, height: scrollViewContentView.bounds.size.height - (locationTextField.frame.origin.y + locationTextField.bounds.height + 2))
        
        tableDataSource = GMSAutocompleteTableDataSource()
        tableDataSource?.delegate = self
        // set bounding box for the place search, east, west, north, south each extends by 5 miles
        if let userLocation = User.currentUser()?.lastKnownLocation {
            let degrees = 0.005624375 * 5
            let northEast = CLLocationCoordinate2DMake(userLocation.latitude + degrees, userLocation.longitude + degrees)
            let southWest = CLLocationCoordinate2DMake(userLocation.latitude - degrees, userLocation.longitude - degrees)
            tableDataSource?.autocompleteBounds = GMSCoordinateBounds(coordinate: southWest, coordinate: northEast)
        }
//        tableDataSource?.autocompleteFilter = GMSAutocompleteFilter()
//        tableDataSource?.autocompleteFilter.type = .Region
        resultsController = UITableViewController.init(style: UITableViewStyle.plain)
        resultsController?.tableView.delegate = tableDataSource
        resultsController?.tableView.dataSource = tableDataSource
    }
    
    fileprivate func createPlanLocation(_ place: GMSPlace) -> Location {
        let location = Location()
        location.googlePlaceId = place.placeID
        location.name = place.name
        location.address = place.formattedAddress ?? ""
        location.priceLevel = place.priceLevel.rawValue
        location.rating = place.rating
        location.geo = PFGeoPoint(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
        return location
    }
    
    fileprivate func selectCenterCell(_ collectionView: UICollectionView?) {
        if let collectionView = collectionView {
            // find the cell that's in the center of the collection view
            let centerPoint = self.view.convert(collectionView.center, to: collectionView)
            if let indexPath = collectionView.indexPathForItem(at: centerPoint) {
                collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
                // programmatically select a cell doesn't trigger didDeselectItemAtIndexPath delegate method
                // so need to call them explicitly
                if let oldSelectionIndexPaths = collectionView.indexPathsForSelectedItems {
                    for selectedIndexPath in oldSelectionIndexPaths {
                        collectionView.deselectItem(at: selectedIndexPath, animated: true)
                        self.collectionView(collectionView, didDeselectItemAt: selectedIndexPath)
                    }
                }
                collectionView.selectItem(at: indexPath, animated: true, scrollPosition: UICollectionViewScrollPosition.centeredHorizontally)
                // programmatically select a cell doesn't trigger didSelectItemAtIndexPath delegate method
                // so need to call them explicitly
                self.collectionView(collectionView, didSelectItemAt: indexPath)
            }
        }
    }
    
    // MARK: - GMSAutocompleteTableDataSourceDelegate
    func tableDataSource(_ tableDataSource: GMSAutocompleteTableDataSource, didAutocompleteWithPlace place: GMSPlace) {
        print("place: \(place)")
        self.view.removeGestureRecognizer(tapGestureRecognizer!)
        self.view.addGestureRecognizer(tapGestureRecognizer!)
        locationTextField.resignFirstResponder()
        locationTextField.text = place.name
        planLocation = createPlanLocation(place)
        updateMap()
        enableCreateButton(true)
    }
    
    func tableDataSource(_ tableDataSource: GMSAutocompleteTableDataSource, didFailAutocompleteWithError error: NSError) {
        NSLog("Autocomplete error: \(error)")
    }
    
    func didUpdateAutocompletePredictionsForTableDataSource(_ tableDataSource: GMSAutocompleteTableDataSource) {
        resultsController?.tableView.reloadData()
    }
    
    func didRequestAutocompletePredictionsForTableDataSource(_ tableDataSource: GMSAutocompleteTableDataSource) {
        resultsController?.tableView.reloadData()
    }
    
    func tableDataSource(_ tableDataSource: GMSAutocompleteTableDataSource, didSelectPrediction prediction: GMSAutocompletePrediction) -> Bool {
        print("prediction: \(prediction)")
        return true
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
