//
//  FeedTableViewController.swift
//  Tastemaker
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
import EasyAnimation
import PermissionScope

class FeedTableViewController: UITableViewController, VenueCellViewDelegate, MKMapViewDelegate, CLLocationManagerDelegate, CoachMarksControllerDataSource {

    var reusableViews: Set<VenueCellView>!
    let coachMarksController = CoachMarksController()
    
    var reachability: Reachability?
    
    var venues = [Venue]()
    var dateSort = [Venue]()
    var chatSort = [Venue]()
    var voteSort = [Venue]()
    
    weak var venueListener: VenueListener?
    let uid: String = NSUserDefaults.standardUserDefaults().objectForKey("uid") as! String
    var banned: Bool?
    var bannedHandle: UInt?
    private var recentChatsVenueListHandle: UInt?
    private var recentChatsVenueList = [String]()
    private var venueVoteCountsHandle: UInt?
    private var venueVoteCounts = [String: Int]()
    private var userVotesHandle: UInt?
    private var userVotes = [String]()
    private var votedVenue = String()
    private var unvotedVenue = String()
    
    private var mapViewButton = UIBarButtonItem()
    private var mapView = MKMapView()
    private let regionRadius: CLLocationDistance = 3000
    private var mapCenter: CLLocationCoordinate2D = CLLocationCoordinate2DMake(41.8781136, -87.6297982)
    private var mapIsLoaded: Bool = false
    private let locationManager = CLLocationManager()
    var visits = [String: Bool]()
    private var sortButton = UIBarButtonItem()
    private var sortedBy = String()
    
    weak private var todayDate = localDateFormatter().dateFromString(localDateFormatter().stringFromDate(NSDate()))
    
    // MARK: Initialization
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Chicago"
        coachMarksController.dataSource = self
        coachMarksController.overlayBackgroundColor = kGray.colorWithAlphaComponent(0.8)
        coachMarksController.allowOverlayTap = true
        
        UIApplication.sharedApplication().statusBarStyle = .LightContent

        setupReachability(true)
        startNotifier()
        
        // Prevents additional cells from being drawn for short lists
        tableView.tableFooterView = UIView()
        
        if CLLocationManager.locationServicesEnabled() && (CLLocationManager.authorizationStatus() == .AuthorizedAlways || CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse) {
            
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
        
        configureMapViewButton()
        
        // Prevent the tableView from displaying behind the tabBar
        edgesForExtendedLayout = UIRectEdge.None
        extendedLayoutIncludesOpaqueBars = false
        automaticallyAdjustsScrollViewInsets = false
        
        // Add observer to handle when the FeedTableVC should update its list
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(FeedTableViewController.appDidEnterForeground(_:)), name: UIApplicationWillEnterForegroundNotification, object: nil)
    }
    
    deinit {
        stopNotifier()
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        navigationController!.navigationBar.translucent = false
        
        navigationController!.navigationBar.titleTextAttributes = [NSFontAttributeName: UIFont.systemFontOfSize(22), NSForegroundColorAttributeName: UIColor.whiteColor()]
        navigationController!.view.backgroundColor = UIColor.whiteColor()
        
        tabBarController?.tabBar.hidden = false
        
        if isMovingToParentViewController() {
            bannedHandle = DataService.dataService.CURRENT_USER_PRIVATE_REF.childByAppendingPath("banned").observeEventType(FEventType.Value, withBlock: {
                snapshot in
                
                if snapshot.exists() {
                    self.banned = true
                } else {
                    self.banned = nil
                }
            })
            recentChatsVenueListHandle = DataService.dataService.LISTS_REF.childByAppendingPath("venues/recentChats").observeEventType(.Value, withBlock: {
                snapshot in
                
                if snapshot.exists() {
                    let enumerator = snapshot.children
                    self.recentChatsVenueList = []
                    while let recentChatsVenues = enumerator.nextObject() as? FDataSnapshot {
                        self.recentChatsVenueList.append(recentChatsVenues.key)
                    }
                    self.tableView.reloadData()
                }
            })
            venueVoteCountsHandle = DataService.dataService.LISTS_REF.childByAppendingPath("venues/votes").observeEventType(.Value, withBlock: {
                snapshot in
                
                let enumerator = snapshot.children
                self.venueVoteCounts = [:]
                while let voteCounts = enumerator.nextObject() as? FDataSnapshot {
                    self.venueVoteCounts[voteCounts.key] = voteCounts.value as? Int
                }
                self.tableView.reloadData()
            })
            userVotesHandle = DataService.dataService.USER_ACTIVITIES_REF.childByAppendingPath("\(uid)/votes/").queryOrderedByValue().observeEventType(.Value, withBlock: {
                snapshot in
                
                self.userVotes = []
                if snapshot.exists() {
                    let enumerator = snapshot.children
                    while let userVotesVenues = enumerator.nextObject() as? FDataSnapshot {
                        self.userVotes.append(userVotesVenues.key)
                    }
                }
            })
        }
        
        if self is ListViewController {
            
        } else if self is UserProfileViewController {
            
        } else {
            if isMovingToParentViewController() || todayDate != localDateFormatter().dateFromString(localDateFormatter().stringFromDate(NSDate())) {
                tableView.alpha = 0.0
                todayDate = localDateFormatter().dateFromString(localDateFormatter().stringFromDate(NSDate()))
                
                venueListener = VenueListener(endDate: todayDate!, callback: {
                    [weak self] venues in
                    
                    if let throwawayFeedTableVC = self {
                        var newList = [Venue]()
                        var newNSUserDefaultsList: [[String:AnyObject]] = []
                        for venue in venues {
                            newList.append(venue)
                            newNSUserDefaultsList.append(serializeVenue(venue))
                        }
                        
                        throwawayFeedTableVC.venues = newList
                        throwawayFeedTableVC.dateSort = throwawayFeedTableVC.venues
                        throwawayFeedTableVC.sortedBy = "Opening Date"
                        throwawayFeedTableVC.tableView.reloadData()
                        throwawayFeedTableVC.mapIsLoaded = false
                        NSUserDefaults.standardUserDefaults().setObject(newNSUserDefaultsList, forKey: "venues")
                        
                        // Need to include visit queries in FeedTableVC and its subclasses, ListVC and UserProfileVC, since the visits always need to be pulled after loading that screen's self.venues
                        for venue in throwawayFeedTableVC.venues {
                            DataService.dataService.USER_ACTIVITIES_REF.childByAppendingPath("\(throwawayFeedTableVC.uid)/visits/\(venue.objectId!)").observeSingleEventOfType(.Value, withBlock: {
                                snapshot in
                                
                                if snapshot.exists() {
                                    throwawayFeedTableVC.visits[venue.objectId!] = true
                                }
                            })
                        }
                    }
                })
            }
            
            if mapView.hidden || !mapIsLoaded {
                configureSortButton()
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
            coachMarksController.startOn(self)
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "HasSeenInstructions")
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        if isMovingFromParentViewController() {
            DataService.dataService.CURRENT_USER_PRIVATE_REF.childByAppendingPath("banned").removeObserverWithHandle(bannedHandle!)
            DataService.dataService.LISTS_REF.childByAppendingPath("venues/recentChats").removeObserverWithHandle(recentChatsVenueListHandle!)
            DataService.dataService.LISTS_REF.childByAppendingPath("venues/votes").removeObserverWithHandle(venueVoteCountsHandle!)
            DataService.dataService.USER_ACTIVITIES_REF.childByAppendingPath("\(uid)/votes/").removeObserverWithHandle(userVotesHandle!)
            venues.removeAll()
            visits.removeAll()
            dateSort.removeAll()
            chatSort.removeAll()
            voteSort.removeAll()
            banned = nil
            recentChatsVenueList.removeAll()
            venueVoteCounts.removeAll()
            userVotes.removeAll()
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
        
        var venueCell: VenueCellView? = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as? VenueCellView
        if venueCell == nil {
            venueCell = VenueCellView(frame: CGRectMake(0.0, 0.0, view.bounds.size.width, 76.0), buttons: VenueCellButtons.Default)
            venueCell!.delegate = self
            venueCell!.selectionStyle = UITableViewCellSelectionStyle.None
        }
        
        // I had to add the following if statement since otherwise I would get array out of index errors when saving a venue for the first time, immediately backing out to the feed, and then immediately clicking on the list tab - CRASH - it appeared this was an issue with trying to create a cell for an empty venue array
        if !venues.isEmpty {
            let venue = venues[indexPath.row]
            venueCell!.venue = venue
            venueCell!.tag = indexPath.row
            venueCell!.voteButton!.tag = indexPath.row
            
            if recentChatsVenueList.contains(venue.objectId!) {
                venueCell?.venueNeighborhoodLabel?.text = (venueCell?.venueNeighborhoodLabel!.text)! + " 🔥"
            }
            
            if venueVoteCounts[venue.objectId!] != nil {
                venueCell!.voteButton!.setTitle(String(venueVoteCounts[venue.objectId!]!), forState: UIControlState.Normal)
            } else {
                venueCell!.voteButton!.setTitle("0", forState: .Normal)
            }
            
            if visits[venue.objectId!] == true {
                venueCell!.setVisitStatus(true)
            } else {
                venueCell!.setVisitStatus(false)
            }
            
            if userVotes.contains(venue.objectId!) {
                if venue.objectId! != votedVenue {
                    venueCell!.voteButton!.selected = true
                    venueCell!.voteButton!.layer.cornerRadius = 20
                    venueCell!.voteButton!.layer.borderWidth = 0
                    venueCell!.voteButton!.backgroundColor = kPurple
                    venueCell!.voteButton!.titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
                    venueCell!.voteButton!.titleLabel!.font = UIFont.boldSystemFontOfSize(18.0)
                    venueCell!.triangle?.alpha = 0
                }
            } else if !userVotes.contains(venue.objectId!) && (visits[venue.objectId!] == true || venue.name! == "Chicago Chat") {
                if venue.objectId! != unvotedVenue {
                    venueCell!.voteButton!.selected = false
                    venueCell!.voteButton!.layer.cornerRadius = 5.0
                    venueCell!.voteButton!.layer.borderWidth = 1.5
                    venueCell!.voteButton!.layer.borderColor = kGray.CGColor
                    venueCell!.triangle!.alpha = 1.0
                }
            }
            
            if venue.objectId! == votedVenue {
                venueCell!.voteButton!.selected = true
                UIView.animateAndChainWithDuration(0.8, delay: 0.0, usingSpringWithDamping: 0.3, initialSpringVelocity: 0.0, options: [], animations: {
                    
                    venueCell!.voteButton!.layer.transform = CATransform3DMakeScale(1.2, 1.2, 1.0)
                    venueCell!.voteButton!.layer.cornerRadius = 20
                    venueCell!.voteButton!.layer.borderWidth = 0
                    venueCell!.voteButton!.backgroundColor = kPurple
                    venueCell!.voteButton!.titleLabel!.font = UIFont.boldSystemFontOfSize(18.0)
                    venueCell!.voteButton!.titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
                    venueCell!.voteButton!.layoutIfNeeded()
                    venueCell!.triangle?.alpha = 0
                    }, completion: nil).animateWithDuration(0.2, delay: 0.0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.0, options: [], animations: {
                        
                        venueCell!.voteButton!.layer.transform = CATransform3DIdentity
                        }, completion: nil)
                votedVenue = ""
            }
            
            if venue.objectId! == unvotedVenue {
                venueCell!.voteButton!.selected = false
                UIView.animateAndChainWithDuration(0.4, delay: 0.0, options: [], animations: {

                    venueCell!.voteButton!.layer.cornerRadius = 5.0
                    venueCell!.voteButton!.layer.borderWidth = 1.5
                    venueCell!.voteButton!.backgroundColor = UIColor.clearColor()
                    venueCell!.voteButton!.titleLabel!.font = UIFont.systemFontOfSize(14.0)
                    venueCell!.voteButton!.titleEdgeInsets = UIEdgeInsets(top: 14, left: 0, bottom: 0, right: 0)
                    venueCell!.voteButton!.layoutIfNeeded()
                    venueCell!.triangle?.alpha = 1.0
                    }, completion: nil).animateWithDuration(0.1, delay: 0.0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.0, options: [], animations: {
                    
                    venueCell!.voteButton!.layer.transform = CATransform3DIdentity
                    }, completion: nil)

                unvotedVenue = ""
            }
            
            if indexPath.row == (tableView.indexPathsForVisibleRows?.last?.row)! {
                UIView.animateWithDuration(0.1, animations: {
                    tableView.alpha = 1.0
                    venueCell!.containerView?.alpha = 1.0
                    self.tableView.reloadData()
                })
            }
            
            return venueCell!
        } else {
            return VenueCellView(frame: CGRectMake(0.0, 0.0, view.bounds.size.width, 76.0), buttons: VenueCellButtons.Default)
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
        if banned != nil {
            vc.banned = banned
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
    
    func dequeueReusableView() -> VenueCellView? {
        for view: VenueCellView in reusableViews {
            if view.superview == nil {
                
                // We found a section header that is no longer visible
                return view
            }
        }
        
        return nil
    }
    
    
    // MARK: VenueCellViewDelegate
    
    func venueCellView(venueCellView: VenueCellView, didTapVoteButton button: UIButton, venueId: String) {
        
        let voted: Bool = !venueCellView.voteButton!.selected
        
        if voted {
            venueCellView.shouldEnableVoteButton(false)
        } else {
            venueCellView.shouldEnableVoteButton(true)
        }
        
        var voteCount: Int = Int(button.titleLabel!.text!)!
        if (voted) {
            votedVenue = venueId
            voteCount += 1
            DataService.dataService.LISTS_REF.childByAppendingPath("venues/votes/\(venueId)").runTransactionBlock({
                (currentData: FMutableData!) in
                var value = currentData.value as? Int
                if (value == nil) {
                    value = 0
                }
                currentData.value = value! + 1
                return FTransactionResult.successWithValue(currentData)
                }, andCompletionBlock: {
                    _ in
                    DataService.dataService.USER_ACTIVITIES_REF.childByAppendingPath("\(self.uid)/votes/\(venueId)").setValue(dateFormatter().stringFromDate(NSDate()))
            })
            DataService.dataService.VENUE_ACTIVITIES_REF.childByAppendingPath("\(venueId)/voters/\(uid)").setValue(dateFormatter().stringFromDate(NSDate()))
            
            Amplitude.instance().logEvent("Voted Venue", withEventProperties: ["Venue Name": (venueCellView.venue?.name)!, "Venue Neighborhood": (venueCellView.venue?.neighborhood)!, "Venue Food Type": (venueCellView.venue?.foodType)!])
            Amplitude.instance().identify(AMPIdentify().add("Votes", value: 1))
        } else {
            unvotedVenue = venueId
            if voteCount > 0 {
                voteCount -= 1
                DataService.dataService.LISTS_REF.childByAppendingPath("venues/votes/\(venueId)").runTransactionBlock({
                    (currentData: FMutableData!) in
                    let value = currentData.value as? Int
                    currentData.value = value! - 1
                    return FTransactionResult.successWithValue(currentData)
                    }, andCompletionBlock: {
                        _ in
                        DataService.dataService.USER_ACTIVITIES_REF.childByAppendingPath("\(self.uid)/votes/\(venueId)").removeValue()
                })
            }
            DataService.dataService.VENUE_ACTIVITIES_REF.childByAppendingPath("\(venueId)/voters/\(uid)").removeValue()
            
            Amplitude.instance().logEvent("Unvoted Venue", withEventProperties: ["Venue Name": (venueCellView.venue?.name)!, "Venue Neighborhood": (venueCellView.venue?.neighborhood)!, "Venue Food Type": (venueCellView.venue?.foodType)!])
            Amplitude.instance().identify(AMPIdentify().add("Votes", value: -1))
        }
        
        button.setTitle(String(voteCount), forState: UIControlState.Normal)
    }
    
    
    // MARK: CoachMarksControllerDataSource
    
    func numberOfCoachMarksForCoachMarksController(coachMarksController: CoachMarksController) -> Int {
        return 3
    }
    
    func coachMarksController(coachMarksController: CoachMarksController, coachMarksForIndex index: Int) -> CoachMark {
        switch(index) {
        case 0:
            let indexOfFirstTip = NSIndexPath(forRow: 0, inSection: 0)
            return coachMarksController.coachMarkForView(tableView.cellForRowAtIndexPath(indexOfFirstTip) as? UIView)
        case 1:
            let indexOfSecondTip = NSIndexPath(forRow: 3, inSection: 0)
            return coachMarksController.coachMarkForView(tableView.cellForRowAtIndexPath(indexOfSecondTip) as? UIView)
        case 2:
            let indexOfThirdTip = NSIndexPath(forRow: 3, inSection: 0)
            var thirdCoachMark = coachMarksController.coachMarkForView(self.tableView.cellForRowAtIndexPath(indexOfThirdTip)) {
                (frame: CGRect) -> UIBezierPath in
                return UIBezierPath(ovalInRect: CGRectMake(0, 304, 52, 52))
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
            if (PermissionScope().statusLocationAlways() == .Unauthorized || PermissionScope().statusLocationAlways() == .Unknown) {
                coachViews.bodyView.hintLabel.text = "Enable location data in the Settings tab so places you've visited are automatically highlighted blue - plus each city has a general chat (also highlighted blue) to talk about whatever"
            } else {
                coachViews.bodyView.hintLabel.text = "Places you've visited are highlighted blue, plus each city has a general chat (also highlighted blue) to talk about whatever"
            }
            coachViews.bodyView.hintLabel.textAlignment = .Left
            coachViews.bodyView.hintLabel.layoutManager.hyphenationFactor = 0.0
            coachViews.bodyView.nextLabel.text = "Got it!"
        case 2:
            if (PermissionScope().statusLocationAlways() == .Unauthorized || PermissionScope().statusLocationAlways() == .Unknown) {
                coachViews.bodyView.hintLabel.text = "After you enable location data, vote for a place you visited that was great so others know what's good"
            } else {
                coachViews.bodyView.hintLabel.text = "After you check out somewhere great, vote for it so others know what's good"
            }
            coachViews.bodyView.nextLabel.text = "👍"
            coachViews.bodyView.hintLabel.layoutManager.hyphenationFactor = 0.0
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
        
        // Stop tableView from scrolling upon pressing Map button
        tableView.scrollEnabled = false
        tableView.setContentOffset(tableView.contentOffset, animated: false)
        
        if !mapIsLoaded {
            let annotationsToRemove = mapView.annotations.filter {$0 !== mapView.userLocation}
            mapView.removeAnnotations(annotationsToRemove)
            mapView.mapType = .Standard
            mapView.delegate = self
            // Tab bar height = 49, nav bar height = 64 -> 49 + 64 = 113
            mapView.frame = CGRectMake(0, tableView.contentOffset.y, UIScreen.mainScreen().bounds.width, UIScreen.mainScreen().bounds.height - 113)
            
            if (CLLocationManager.authorizationStatus() == .AuthorizedAlways || CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse) {
                let chicagoLocation = CLLocationCoordinate2DMake(41.8781136, -87.6297982)
                if CLLocation(latitude: chicagoLocation.latitude, longitude: chicagoLocation.longitude).distanceFromLocation(CLLocation(latitude: mapCenter.latitude, longitude: mapCenter.longitude)) > 15000 {
                    mapCenter = CLLocationCoordinate2DMake(41.8781136, -87.6297982)
                }
            }
            
            let coordinateRegion = MKCoordinateRegionMakeWithDistance(mapCenter, regionRadius * 2.0, regionRadius * 2.0)
            mapView.setRegion(coordinateRegion, animated: false)
            
            if CLLocationManager.authorizationStatus() == .AuthorizedAlways {
                mapView.showsUserLocation = true
            }
            
            for venue in venues {
                let venueLocation: CLLocation = CLLocation(latitude: venue.latitude!, longitude: venue.longitude!)
                let coordinate = venueLocation.coordinate
                let title = venue.name
                // Set all VenueAnnotations to default for now
                let typeRawValue = 0
                let type = VenueType(rawValue: typeRawValue)
                let subtitle = venue.description
                let annotation = VenueAnnotation(coordinate: coordinate, title: title!, subtitle: subtitle!, type: type!, venue: venue)
                
                mapView.addAnnotation(annotation)
            }
            
            view.addSubview(mapView)
            mapIsLoaded = true
        } else {
            mapView.frame = CGRectMake(0, tableView.contentOffset.y, UIScreen.mainScreen().bounds.width, UIScreen.mainScreen().bounds.height - 113)
        }
        
        mapView.hidden = false
        navigationItem.rightBarButtonItem = nil
        configureListViewButton()
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
        } else if visits[venue.objectId!] != nil && visits[venue.objectId!] == true {
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
        if banned != nil {
            vc.banned = banned
        }
        
        let venueName: String = venue.name!
        vc.title = venueName
        vc.hidesBottomBarWhenPushed = true
        navigationController!.view.backgroundColor = UIColor.whiteColor()
        navigationController?.pushViewController(vc, animated: true)
        
        Amplitude.instance().logEvent("Viewed Venue From Map", withEventProperties: ["Venue Name": venue.name!, "Venue Neighborhood": venue.neighborhood!, "Venue Food Type": venue.foodType!])
    }
    
    func listViewButtonAction(sender: AnyObject) {
        
        mapView.hidden = true
        tableView.scrollEnabled = true
        configureMapViewButton()
        configureSortButton()
    }
    
    func configureMapViewButton() {
        mapViewButton = UIBarButtonItem(title: "Map", style: .Plain, target: self, action: #selector(FeedTableViewController.mapViewButtonAction(_:)))
        navigationItem.setLeftBarButtonItem(mapViewButton, animated: false)
    }
    
    func configureListViewButton() {
        mapViewButton = UIBarButtonItem(title: "List", style: .Plain, target: self, action: #selector(FeedTableViewController.listViewButtonAction(_:)))
        navigationItem.setLeftBarButtonItem(mapViewButton, animated: false)
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if manager.location != nil {
            mapCenter = manager.location!.coordinate
        }
        locationManager.stopUpdatingLocation()
    }
    
    
    // MARK: Sort
    
    func configureSortButton() {
        sortButton = UIBarButtonItem(title: "Sort", style: .Plain, target: self, action: #selector(FeedTableViewController.sortButtonAction(_:)))
        navigationItem.setRightBarButtonItem(sortButton, animated: false)
    }
    
    func sortButtonAction(sender: AnyObject) {
        
        let sortMenu = UIAlertController(title: "Sort Venues By", message: nil, preferredStyle: .ActionSheet)
        
        if sortedBy == "Opening Date" {
            let sortByOpeningDate = UIAlertAction(title: "Opening Date ✅", style: .Default, handler: {
                (alert: UIAlertAction!) -> Void in
                
                self.sortedBy = "Opening Date"
                self.venues = self.dateSort
                self.tableView.reloadData()
            })
            sortMenu.addAction(sortByOpeningDate)
        } else {
            let sortByOpeningDate = UIAlertAction(title: "Opening Date", style: .Default, handler: {
                (alert: UIAlertAction!) -> Void in
                
                self.sortedBy = "Opening Date"
                self.venues = self.dateSort
                self.tableView.reloadData()
            })
            sortMenu.addAction(sortByOpeningDate)
        }
        
        if self.sortedBy == "Votes" {
            let sortByVotes = UIAlertAction(title: "Votes ✅", style: .Default, handler: {
                (alert: UIAlertAction!) -> Void in
                
                self.sortedBy = "Votes"
                self.voteSort = self.venues.sort{ (a: Venue, b: Venue) -> Bool in
                    let aVotes = self.venueVoteCounts[a.objectId!]
                    let bVotes = self.venueVoteCounts[b.objectId!]
                    return aVotes > bVotes
                }
                self.venues = self.voteSort
                self.tableView.reloadData()
            })
            sortMenu.addAction(sortByVotes)
        } else {
            let sortByVotes = UIAlertAction(title: "Votes", style: .Default, handler: {
                (alert: UIAlertAction!) -> Void in
                
                self.sortedBy = "Votes"
                self.voteSort = self.venues.sort{ (a: Venue, b: Venue) -> Bool in
                    let aVotes = self.venueVoteCounts[a.objectId!]
                    let bVotes = self.venueVoteCounts[b.objectId!]
                    return aVotes > bVotes
                }
                self.venues = self.voteSort
                self.tableView.reloadData()
            })
            sortMenu.addAction(sortByVotes)
        }
        
        if self.sortedBy == "Recent Chats" {
            let sortByChats = UIAlertAction(title: "Recent Chats ✅", style: .Default, handler: {
                (alert: UIAlertAction!) -> Void in
                
                self.sortedBy = "Recent Chats"
                self.chatSort = self.venues.sort{ (a: Venue, b: Venue) -> Bool in
                    return self.recentChatsVenueList.contains(a.objectId!) == true && self.recentChatsVenueList.contains(b.objectId!) != true
                }
                self.venues = self.chatSort
                self.tableView.reloadData()
            })
            sortMenu.addAction(sortByChats)
        } else {
            let sortByChats = UIAlertAction(title: "Recent Chats", style: .Default, handler: {
                (alert: UIAlertAction!) -> Void in
                
                self.sortedBy = "Recent Chats"
                self.chatSort = self.venues.sort{ (a: Venue, b: Venue) -> Bool in
                    return self.recentChatsVenueList.contains(a.objectId!) == true && self.recentChatsVenueList.contains(b.objectId!) != true
                }
                self.venues = self.chatSort
                self.tableView.reloadData()
            })
            sortMenu.addAction(sortByChats)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        sortMenu.addAction(cancelAction)

        presentViewController(sortMenu, animated: true, completion: nil)
    }
    
    
    // MARK: Update FeedTableVC if entering app on screen on a new day
    
    func appDidEnterForeground(notification: NSNotification) {

        if todayDate != localDateFormatter().dateFromString(localDateFormatter().stringFromDate(NSDate())) {
            viewWillAppear(false)
        }
    }
}