//
//  FeedTableViewController.swift
//  GrandOpens
//
//  Created by Tony Morales on 6/20/15.
//  Copyright (c) 2015 Tony Morales. All rights reserved.
//

import UIKit
import Instructions
import ReachabilitySwift
import Firebase
import SwiftyDrop
import MapKit
import CoreLocation
import Amplitude_iOS

class FeedTableViewController: UITableViewController, GOVenueCellViewDelegate, MKMapViewDelegate, CLLocationManagerDelegate, CoachMarksControllerDataSource {

    var reusableViews: Set<GOVenueCellView>!
    let coachMarksController = CoachMarksController()
    
    var reachability: Reachability?
    
    var venues = [Venue]()
    
    var venueListener: VenueListener?
    let uid: String = NSUserDefaults.standardUserDefaults().objectForKey("uid") as! String
    var banned: Bool?
    var bannedHandle: UInt?
    
    private var mapViewButton = UIBarButtonItem()
    private var mapView = MKMapView()
    private let regionRadius: CLLocationDistance = 3000
    private var mapCenter: CLLocationCoordinate2D = CLLocationCoordinate2DMake(41.8781136, -87.6297982)
    private var mapIsLoaded: Bool = false
    private let locationManager = CLLocationManager()
    var visits = [String: Bool]()
    
    // MARK: Initialization
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Chicago"
        self.coachMarksController.datasource = self
        self.coachMarksController.overlayBackgroundColor = kGray.colorWithAlphaComponent(0.8)
        self.coachMarksController.allowOverlayTap = true
        
        UIApplication.sharedApplication().statusBarStyle = .LightContent

        setupReachability(true)
        startNotifier()
        
        // Prevents additional cells from being drawn for short lists
        self.tableView.tableFooterView = UIView()
        
        if CLLocationManager.locationServicesEnabled() && (CLLocationManager.authorizationStatus() == .AuthorizedAlways || CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse) {
            
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
        
        self.configureMapViewButton()
    }
    
    deinit {
        stopNotifier()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController!.navigationBar.translucent = false
        
        navigationController!.navigationBar.titleTextAttributes = [NSFontAttributeName: UIFont.systemFontOfSize(22), NSForegroundColorAttributeName: UIColor.whiteColor()]
        navigationController!.view.backgroundColor = UIColor.whiteColor()
        
        self.tabBarController?.tabBar.hidden = false
        
        let todayString = localDateFormatter().stringFromDate(NSDate())
        let todayDate = localDateFormatter().dateFromString(todayString)
        
        if self.isMovingToParentViewController() {
            bannedHandle = DataService.dataService.CURRENT_USER_PRIVATE_REF.childByAppendingPath("banned").observeEventType(FEventType.Value, withBlock: {
                snapshot in
                
                if snapshot.exists() {
                    self.banned = true
                } else {
                    self.banned = nil
                }
            })
        }
        
        if self is ListViewController {
            
        } else if self is GOUserProfileViewController {
            
        } else {
            if self.isMovingToParentViewController() {
                self.tableView.alpha = 0.0
                
                venueListener = VenueListener(endDate: todayDate!, callback: {
                    venues in
                    
                    var newList = [Venue]()
                    var newNSUserDefaultsList: [[String:AnyObject]] = []
                    for venue in venues {
                        newList.append(venue)
                        newNSUserDefaultsList.append(serializeVenue(venue))
                    }
                    
                    self.venues = newList
                    self.tableView.reloadData()
                    NSUserDefaults.standardUserDefaults().setObject(newNSUserDefaultsList, forKey: "venues")
                    
                    // Need to include visit queries in FeedTableVC and its subclasses, ListVC and UserProfileVC, since the visits always need to be pulled after loading that screen's self.venues
                    for venue in self.venues {
                        DataService.dataService.USER_ACTIVITIES_REF.childByAppendingPath("\(self.uid)/visits/\(venue.objectId!)").observeSingleEventOfType(.Value, withBlock: {
                            snapshot in
                            
                            if snapshot.exists() {
                                self.visits[venue.objectId!] = true
                            }
                        })
                    }
                })
            }
            
            let tracker = GAI.sharedInstance().defaultTracker
            tracker.set(kGAIScreenName, value: "NewVenuesFeedViewController")
            let builder = GAIDictionaryBuilder.createScreenView()
            tracker.send(builder.build() as [NSObject: AnyObject])
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        let hasSeenInstructions = NSUserDefaults.standardUserDefaults().boolForKey("HasSeenInstructions")
        if !hasSeenInstructions {
            self.coachMarksController.startOn(self)
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "HasSeenInstructions")
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        if self.isMovingFromParentViewController() {
            DataService.dataService.CURRENT_USER_PRIVATE_REF.childByAppendingPath("banned").removeObserverWithHandle(bannedHandle!)
        }
    }
    
    func feedTableLogoutCleanup() {
        DataService.dataService.CURRENT_USER_PRIVATE_REF.childByAppendingPath("banned").removeObserverWithHandle(bannedHandle!)
        venueListener?.stop()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    // MARK: UITableViewDelegate
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.0
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.0
    }
    
    override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }
    
    
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return venues.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let cellIdentifier = "VenueCell"
        
        var venueCell: GOVenueCellView? = self.tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as? GOVenueCellView
        if venueCell == nil {
            venueCell = GOVenueCellView(frame: CGRectMake(0.0, 0.0, self.view.bounds.size.width, 76.0), buttons: GOVenueCellButtons.Default)
            venueCell!.delegate = self
            venueCell!.selectionStyle = UITableViewCellSelectionStyle.None
        }
        
        // I had to add the following if statement since otherwise I would get array out of index errors when saving a venue for the first time, immediately backing out to the feed, and then immediately clicking on the list tab - CRASH - it appeared this was an issue with trying to create a cell for an empty venue array
        if !venues.isEmpty {
            let venue = venues[indexPath.row]
            venueCell!.venue = venue
            venueCell!.tag = indexPath.row
            venueCell!.voteButton!.tag = indexPath.row

            if self.visits[venue.objectId!] == true {
                venueCell!.setVisitStatus(true)
            } else {
                venueCell!.setVisitStatus(false)
            }
            
            DataService.dataService.VENUE_ACTIVITIES_REF.childByAppendingPath("\(venue.objectId!)/voters").observeSingleEventOfType(FEventType.Value, withBlock: {
                snapshot in

                venueCell!.voteButton!.setTitle(String(snapshot.childrenCount), forState: UIControlState.Normal)
            })
            DataService.dataService.USER_ACTIVITIES_REF.childByAppendingPath("\(uid)/votes/\(venue.objectId!)").observeSingleEventOfType(FEventType.Value, withBlock: {
                snapshot in
                
                if snapshot.exists() {
                    if snapshot.value.objectForKey("voted") as! Bool == true {
                        venueCell!.setVoteStatus(true)
                    } else {
                        venueCell!.setVoteStatus(false)
                    }
                } else {
                    venueCell!.setVoteStatus(false)
                }
                
                if indexPath.row == (self.tableView.indexPathsForVisibleRows?.last?.row)! {
                    UIView.animateWithDuration(0.1, animations: {
                        self.tableView.alpha = 1.0
                        venueCell!.containerView?.alpha = 1.0
                    })
                } else {
                    // For feedTableVC and listVC only the tableView alpha needs to be animated, but the tableView needs to start out at alpha 1.0 for the GOUserProfileVC due to push nav transition, so there the cells need to be animated instead - hence calling immediately below and above regardless of indexPath.row
                    UIView.animateWithDuration(0.1, animations: {
                        venueCell!.containerView?.alpha = 1.0
                    })
                }
            })
            
            return venueCell!
        } else {
            return GOVenueCellView(frame: CGRectMake(0.0, 0.0, self.view.bounds.size.width, 76.0), buttons: GOVenueCellButtons.Default)
        }
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 76.0
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let vc = VenueViewController()
       
        let venue = venues[indexPath.row]
        vc.venue = venue
        vc.venueID = venue.objectId
        if self.banned != nil {
            vc.banned = self.banned
        }
        
        let venueName: String = venue.name!
        vc.title = venueName
        vc.hidesBottomBarWhenPushed = true
        navigationController!.view.backgroundColor = UIColor.whiteColor()
        navigationController?.pushViewController(vc, animated: true)
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        Amplitude.instance().logEvent("Viewed Venue From Home List", withEventProperties: ["Venue Name": venue.name!, "Venue Neighborhood": venue.neighborhood!, "Venue Food Type": venue.foodType!])
    }
    
    
    // MARK: FeedTableViewController
    
    func dequeueReusableView() -> GOVenueCellView? {
        for view: GOVenueCellView in self.reusableViews {
            if view.superview == nil {
                
                // We found a section header that is no longer visible
                return view
            }
        }
        
        return nil
    }
    
    
    // MARK: GOVenueCellViewDelegate
    
    func venueCellView(venueCellView: GOVenueCellView, didTapVoteButton button: UIButton, venueId: String) {
        venueCellView.shouldEnableVoteButton(true)
        
        let voted: Bool = !button.selected
        venueCellView.setVoteStatus(voted)
        
        var voteCount: Int = Int(button.titleLabel!.text!)!
        if (voted) {
            voteCount += 1
            DataService.dataService.USER_ACTIVITIES_REF.childByAppendingPath("\(uid)/votes/\(venueId)").updateChildValues(["voted": true, "updatedOn": dateFormatter().stringFromDate(NSDate())])
            DataService.dataService.VENUE_ACTIVITIES_REF.childByAppendingPath("\(venueId)/voters/\(uid)").childByAutoId().updateChildValues(["voted": true, "date": dateFormatter().stringFromDate(NSDate())])
            
            Amplitude.instance().logEvent("Voted Venue", withEventProperties: ["Venue ID": venueId])
            Amplitude.instance().identify(AMPIdentify().add("Votes", value: 1).append("Votes-Venues", value: venueId))
        } else {
            if voteCount > 0 {
                voteCount -= 1
            }
            DataService.dataService.USER_ACTIVITIES_REF.childByAppendingPath("\(uid)/votes/\(venueId)").updateChildValues(["voted": false, "updatedOn": dateFormatter().stringFromDate(NSDate())])
            DataService.dataService.VENUE_ACTIVITIES_REF.childByAppendingPath("\(venueId)/voters/\(uid)").childByAutoId().updateChildValues(["voted": false, "date": dateFormatter().stringFromDate(NSDate())])
            
            Amplitude.instance().logEvent("Unvoted Venue", withEventProperties: ["Venue Name": venueId])
            Amplitude.instance().identify(AMPIdentify().add("Votes", value: -1))
        }
        
        button.setTitle(String(voteCount), forState: UIControlState.Normal)
        
        if voted {
            let actualVenueCellView: GOVenueCellView? = self.tableView(self.tableView, viewForHeaderInSection: button.tag) as? GOVenueCellView
            actualVenueCellView?.shouldEnableVoteButton(false)
        } else {
            let actualVenueCellView: GOVenueCellView? = self.tableView(self.tableView, viewForHeaderInSection: button.tag) as? GOVenueCellView
            actualVenueCellView?.shouldEnableVoteButton(true)
        }
    }
    
    
    // MARK: CoachMarksControllerDataSource
    
    func numberOfCoachMarksForCoachMarksController(coachMarksController: CoachMarksController) -> Int {
        return 3
    }
    
    func coachMarksController(coachMarksController: CoachMarksController, coachMarksForIndex index: Int) -> CoachMark {
        switch(index) {
        case 0:
            let indexOfFirstTip = NSIndexPath(forRow: 0, inSection: 0)
            return coachMarksController.coachMarkForView(self.tableView.cellForRowAtIndexPath(indexOfFirstTip) as? UIView)
        case 1:
            let indexOfSecondTip = NSIndexPath(forRow: 3, inSection: 0)
            return coachMarksController.coachMarkForView(self.tableView.cellForRowAtIndexPath(indexOfSecondTip) as? UIView)
        case 2:
            let indexOfThirdTip = NSIndexPath(forRow: 3, inSection: 0)
            var thirdCoachMark = coachMarksController.coachMarkForView(self.tableView.cellForRowAtIndexPath(indexOfThirdTip)) {
                (frame: CGRect) -> UIBezierPath in
                return UIBezierPath(ovalInRect: CGRectMake(0, 305, 50, 50))
            }
            thirdCoachMark.maxWidth = 390
            thirdCoachMark.horizontalMargin = 5
            return thirdCoachMark
        default:
            return coachMarksController.coachMarkForView()
        }
    }
    
    func coachMarksController(coachMarksController: CoachMarksController, coachMarkViewsForIndex index: Int, coachMark: CoachMark) -> (bodyView: CoachMarkBodyView, arrowView: CoachMarkArrowView?) {
        
        let coachViews = coachMarksController.defaultCoachViewsWithArrow(true, arrowOrientation: coachMark.arrowOrientation)
        
        switch(index) {
        case 0:
            coachViews.bodyView.hintLabel.text = "Newest places show up on top automatically, 30+ new places a month"
            coachViews.bodyView.nextLabel.text = "OK!"
            coachViews.bodyView.hintLabel.layoutManager.hyphenationFactor = 0.0
            coachViews.bodyView.hintLabel.textAlignment = .Left
        case 1:
            coachViews.bodyView.hintLabel.text = "Places you've visited are highlighted blue, plus each city has a general chat (also highlighted blue) to talk about whatever"
            coachViews.bodyView.hintLabel.textAlignment = .Left
            coachViews.bodyView.nextLabel.text = "Got it!"
        case 2:
            coachViews.bodyView.hintLabel.text = "After you check out somewhere great, vote for it so others know what's good"
            coachViews.bodyView.nextLabel.text = "K!"
            coachViews.bodyView.hintLabel.textAlignment = .Left
        default: break
        }
        
        return (bodyView: coachViews.bodyView, arrowView: coachViews.arrowView)
    }
    
    
    // MARK: ()
    
    
    // MARK: Reachability
    
    func setupReachability(useClosures: Bool) {
        do {
            let reachability = try Reachability.reachabilityForInternetConnection()
            self.reachability = reachability
        } catch ReachabilityError.FailedToCreateWithAddress(let address) {
            print("Reachability error at \(address)")
            return
        } catch {}
        
        if useClosures {
            reachability?.whenUnreachable = { reachability in
                dispatch_async(dispatch_get_main_queue()) {

                    Drop.down("Internet Connection Lost \n We'll refresh automatically when reconnected", state: .Color(kRed), duration: 3.0, action: nil)
                }
            }
        }
    }
    
    func startNotifier() {
        do {
            try reachability?.startNotifier()
        } catch {
            print("Unable to start notifier")
            return
        }
    }
    
    func stopNotifier() {
        reachability?.stopNotifier()
        reachability = nil
    }
    
    
    // MARK: MapView
    
    func mapViewButtonAction(sender: AnyObject) {
        
        // Fix later, lazy new venue check, additional annotation for user location, if location enabled
        if (CLLocationManager.authorizationStatus() == .AuthorizedAlways || CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse) {
            if self.venues.count != self.mapView.annotations.count - 1 {
                self.mapIsLoaded = false
            }
        } else {
            if self.venues.count != self.mapView.annotations.count {
                self.mapIsLoaded = false
            }
        }
        
        // Stop tableView from scrolling upon pressing Map button
        self.tableView.scrollEnabled = false
        self.tableView.setContentOffset(tableView.contentOffset, animated: false)
        
        if !mapIsLoaded {
            self.mapView.mapType = .Standard
            self.mapView.delegate = self
            // Tab bar height = 49, nav bar height = 64 -> 49 + 64 = 113
            self.mapView.frame = CGRectMake(0, self.tableView.contentOffset.y, UIScreen.mainScreen().bounds.width, UIScreen.mainScreen().bounds.height - 113)
            
            if (CLLocationManager.authorizationStatus() == .AuthorizedAlways || CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse) {
                let chicagoLocation = CLLocationCoordinate2DMake(41.8781136, -87.6297982)
                if CLLocation(latitude: chicagoLocation.latitude, longitude: chicagoLocation.longitude).distanceFromLocation(CLLocation(latitude: self.mapCenter.latitude, longitude: self.mapCenter.longitude)) > 15000 {
                    self.mapCenter = CLLocationCoordinate2DMake(41.8781136, -87.6297982)
                }
            }
            
            let coordinateRegion = MKCoordinateRegionMakeWithDistance(self.mapCenter, self.regionRadius * 2.0, self.regionRadius * 2.0)
            self.mapView.setRegion(coordinateRegion, animated: false)
            
            if CLLocationManager.authorizationStatus() == .AuthorizedAlways {
                self.mapView.showsUserLocation = true
            }
            
            for venue in self.venues {
                let venueLocation: CLLocation = CLLocation(latitude: venue.latitude!, longitude: venue.longitude!)
                let coordinate = venueLocation.coordinate
                let title = venue.name
                // Set all VenueAnnotations to default for now
                let typeRawValue = 0
                let type = VenueType(rawValue: typeRawValue)
                let subtitle = venue.description
                let annotation = VenueAnnotation(coordinate: coordinate, title: title!, subtitle: subtitle!, type: type!, venue: venue)
                
                self.mapView.addAnnotation(annotation)
            }
            
            self.view.addSubview(mapView)
            self.mapIsLoaded = true
        } else {
            self.mapView.frame = CGRectMake(0, self.tableView.contentOffset.y, UIScreen.mainScreen().bounds.width, UIScreen.mainScreen().bounds.height - 113)
        }
        
        self.mapView.hidden = false
        self.configureListViewButton()
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId)
        if pinView == nil {
            pinView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure)
        } else {
            pinView!.annotation = annotation
        }
        
        let venueAnnotation = annotation as! VenueAnnotation
        let venue = venueAnnotation.venue
        if venue.foodType == "Featured" {
            pinView!.image = UIImage(named: "Pin-Featured")
        } else if self.visits[venue.objectId!] != nil && self.visits[venue.objectId!] == true {
            pinView!.image = UIImage(named: "Pin-Visited")
        } else {
            pinView!.image = UIImage(named: "Pin-Default")
        }
        
        return pinView
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        let vc = VenueViewController()
        
        let venueAnnotation = view.annotation as! VenueAnnotation
        let venue = venueAnnotation.venue
        vc.venue = venue
        vc.venueID = venue.objectId
        if self.banned != nil {
            vc.banned = self.banned
        }
        
        let venueName: String = venue.name!
        vc.title = venueName
        vc.hidesBottomBarWhenPushed = true
        navigationController!.view.backgroundColor = UIColor.whiteColor()
        navigationController?.pushViewController(vc, animated: true)
        
        Amplitude.instance().logEvent("Viewed Venue From Map", withEventProperties: ["Venue Name": venue.name!, "Venue Neighborhood": venue.neighborhood!, "Venue Food Type": venue.foodType!])
    }
    
    func listViewButtonAction(sender: AnyObject) {
        
        self.mapView.hidden = true
        self.tableView.scrollEnabled = true
        self.configureMapViewButton()
    }
    
    func configureMapViewButton() {
        self.mapViewButton = UIBarButtonItem(title: "Map", style: .Plain, target: self, action: #selector(FeedTableViewController.mapViewButtonAction(_:)))
        self.navigationItem.setLeftBarButtonItem(self.mapViewButton, animated: false)
    }
    
    func configureListViewButton() {
        self.mapViewButton = UIBarButtonItem(title: "List", style: .Plain, target: self, action: #selector(FeedTableViewController.listViewButtonAction(_:)))
        self.navigationItem.setLeftBarButtonItem(self.mapViewButton, animated: false)
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if manager.location != nil {
            self.mapCenter = manager.location!.coordinate
        }
        self.locationManager.stopUpdatingLocation()
    }
}
