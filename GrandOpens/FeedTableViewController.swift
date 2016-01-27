//
//  FeedTableViewController.swift
//  GrandOpens
//
//  Created by Tony Morales on 6/20/15.
//  Copyright (c) 2015 Tony Morales. All rights reserved.
//

import UIKit
import Parse
import ParseUI
import Synchronized
import Instructions
import ReachabilitySwift
import Whisper

class FeedTableViewController: PFQueryTableViewController, GOVenueCellViewDelegate, CoachMarksControllerDataSource {

    var shouldReloadOnAppear: Bool = false
    var reusableViews: Set<GOVenueCellView>!
    var outstandingVenueCellViewQueries: [NSObject: AnyObject]
    let coachMarksController = CoachMarksController()
    let reachability = try! Reachability.reachabilityForInternetConnection()
    
    // MARK: Initialization
    
    override init(style: UITableViewStyle, className: String?) {
        self.outstandingVenueCellViewQueries = [NSObject: AnyObject]()
        super.init(style: style, className: kVenueClassKey)
        
        // The className to query on
        self.parseClassName = kVenueClassKey
        
        // Whether the built-in pull-to-refresh is enabled
        self.pullToRefreshEnabled = true
        
        // Whether the built-in pagination is enabled
        self.paginationEnabled = false
        
        // The number of objects to show per page
        // self.objectsPerPage = 10
        
        // Improve scrolling performance by reusing views
        self.reusableViews = Set<GOVenueCellView>(minimumCapacity: 3)

        self.shouldReloadOnAppear = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        self.title = "Chicago"
        self.coachMarksController.datasource = self
        self.coachMarksController.overlayBackgroundColor = kGray.colorWithAlphaComponent(0.8)
        self.coachMarksController.allowOverlayTap = true
        
        UIApplication.sharedApplication().statusBarStyle = .LightContent
        self.navigationController!.navigationBar.translucent = false
        
        // Register to be notified when a voted/unvoted callback finished
        let defaultNotificationCenter = NSNotificationCenter.defaultCenter()
        defaultNotificationCenter.addObserver(self, selector: Selector("userDidVoteOrUnvoteVenue:"), name: GOUtilityUserVotedUnvotedVenueCallbackFinishedNotification, object: nil)
        defaultNotificationCenter.addObserver(self, selector: Selector("userDidVoteOrUnvoteVenue:"), name: GOUtilityUserVotedUnvotedVenueNotification, object: nil)
        defaultNotificationCenter.addObserver(self, selector: "reachabilityChanged:", name: ReachabilityChangedNotification, object: reachability)
        try! reachability.startNotifier()
        
        // Cache muted users
        if PFUser.currentUser() != nil {
            let mutedUsers = PFQuery(className: kUserActivityClassKey)
            mutedUsers.whereKey(kUserActivityTypeKey, equalTo: kUserActivityTypeMute)
            mutedUsers.whereKey(kUserActivityByUserKey, equalTo: PFUser.currentUser()!)
            mutedUsers.includeKey(kUserActivityToUserKey)
            mutedUsers.cachePolicy = PFCachePolicy.NetworkOnly
            mutedUsers.findObjectsInBackgroundWithBlock { (activities, error) in
                if error == nil {
                    for activity in activities as! [PFObject] {
                        let user: PFUser? = activity.objectForKey(kUserActivityToUserKey) as? PFUser
                        GOCache.sharedCache.setAttributesForUser(user!.objectId!, mutedByCurrentUser: true)
                    }
                }
            }
        }
        
        PFUser.currentUser()?.fetchInBackground()
    }
    
    deinit {
        let defaultNotificationCenter = NSNotificationCenter.defaultCenter()
        defaultNotificationCenter.removeObserver(self, name: GOUtilityUserVotedUnvotedVenueCallbackFinishedNotification, object: nil)
        defaultNotificationCenter.removeObserver(self, name: GOUtilityUserVotedUnvotedVenueNotification, object: nil)
        defaultNotificationCenter.removeObserver(self, name: ReachabilityChangedNotification, object: reachability)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        navigationController!.navigationBar.titleTextAttributes = [NSFontAttributeName: UIFont.systemFontOfSize(26), NSForegroundColorAttributeName: UIColor.whiteColor()]
        navigationController!.view.backgroundColor = UIColor.whiteColor()
        
        self.tabBarController?.tabBar.hidden = false
    }
    
    override func viewDidAppear(animated: Bool) {
        
        let hasSeenInstructions = NSUserDefaults.standardUserDefaults().boolForKey("HasSeenInstructions")
        if !hasSeenInstructions {
            self.coachMarksController.startOn(self)
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "HasSeenInstructions")
        }
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
        return self.objects!.count
    }

    
    // MARK: PFQueryTableViewController
    
    override func queryForTable() -> PFQuery {
        if (PFUser.currentUser() == nil) {
            let query = PFQuery(className: self.parseClassName!)
            query.limit = 0
            return query
        }
        
        var today = NSDate()
        let calendar = NSCalendar.autoupdatingCurrentCalendar()
        calendar.timeZone = NSTimeZone.localTimeZone()
        today = calendar.startOfDayForDate(NSCalendar.currentCalendar().dateByAddingUnit(.Day, value: 1, toDate: today, options: NSCalendarOptions())!)
        let standardOpeningDateCoverage = calendar.startOfDayForDate(NSCalendar.currentCalendar().dateByAddingUnit(.Day, value: -(kStandardDaysOfOpeningsCovered), toDate: today, options: NSCalendarOptions())!)
        
        let query = PFQuery(className: self.parseClassName!)
        query.whereKey("openingDate", greaterThanOrEqualTo: standardOpeningDateCoverage)
        query.whereKey("openingDate", lessThan: today)
        query.orderByDescending("openingDate")
        
        // A pull-to-refresh should always trigger a network request.
        query.cachePolicy = PFCachePolicy.NetworkOnly
        
        // If no objects are loaded in memory, we look to the cache first to fill the table 
        // and then subsequently do a query against the network.
        //
        // If there is no network connection, we will hit the cache first.
        
        if self.objects!.count == 0
            //|| (UIApplication.sharedApplication().delegate!.performSelector(Selector("isParseReachable")) == nil) 
        {
            query.cachePolicy = PFCachePolicy.CacheThenNetwork
        }
        
        return query
    }
    
    override func objectAtIndexPath(indexPath: NSIndexPath?) -> PFObject? {
        let index = self.indexForObjectAtIndexPath(indexPath!)
        if (index < self.objects!.count) {
            return self.objects![index] as? PFObject
        }
        
        return nil
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath, object: PFObject?) -> PFTableViewCell? {

        let CellIdentifier = "VenueCell"
        
        let index: Int = self.indexForObjectAtIndexPath(indexPath)
        
        var venueCell: GOVenueCellView? = self.tableView.dequeueReusableCellWithIdentifier(CellIdentifier) as? GOVenueCellView
        if venueCell == nil {
            venueCell = GOVenueCellView(frame: CGRectMake(0.0, 0.0, self.view.bounds.size.width, 76.0), buttons: GOVenueCellButtons.Default)
            venueCell!.delegate = self
            venueCell!.selectionStyle = UITableViewCellSelectionStyle.None
        }
        
        let object: PFObject? = objectAtIndexPath(indexPath)
        venueCell!.venue = object
        venueCell!.tag = index
        venueCell!.voteButton!.tag = index
        
        let attributesForVenue = GOCache.sharedCache.attributesForVenue(object!)
        
        if attributesForVenue != nil {
            venueCell!.setVisitStatus(GOCache.sharedCache.isVenueVistedByCurrentUser(object!))
            venueCell!.setVoteStatus(GOCache.sharedCache.isVenueVotedByCurrentUser(object!))
            venueCell!.voteButton!.setTitle(GOCache.sharedCache.voteCountForVenue(object!).description, forState: UIControlState.Normal)
            
            if venueCell!.voteButton!.alpha < 1.0 {
                UIView.animateWithDuration(0.200, animations: {
                    venueCell!.voteButton!.alpha = 1.0
                })
            }
        } else {
            venueCell!.voteButton!.alpha = 0.0
            
            synchronized(self) {
                // Check if we can update the cache
                let outstandingVenueCellViewQueryStatus: Int? = self.outstandingVenueCellViewQueries[index] as? Int
                
                if outstandingVenueCellViewQueryStatus == nil {
                    let query: PFQuery = GOUtility.queryForActivitiesOnVenue(object!, cachePolicy: PFCachePolicy.NetworkOnly)
                    query.findObjectsInBackgroundWithBlock{ (objects, error) in
                        synchronized(self) {
                            self.outstandingVenueCellViewQueries.removeValueForKey(index)
                            
                            if error != nil {
                                return
                            }
                            
                            var voters = [PFUser]()
                            
                            var isVotedByCurrentUser = false
                            var isSavedByCurrentUser = false
                            var isVisitedByCurrentUser = false
                            
                            for activity in objects as! [PFObject] {
                                if (activity.objectForKey(kVenueActivityTypeKey) as! String) == kVenueActivityTypeVote && activity.objectForKey(kVenueActivityByUserKey) != nil {
                                    voters.append(activity.objectForKey(kVenueActivityByUserKey) as! PFUser)
                                }
                                
                                if (activity.objectForKey(kVenueActivityByUserKey) as? PFUser)?.objectId == PFUser.currentUser()!.objectId {
                                    if (activity.objectForKey(kVenueActivityTypeKey) as! String) == kVenueActivityTypeVote {
                                        isVotedByCurrentUser = true
                                    } else if (activity.objectForKey(kVenueActivityTypeKey) as! String) == kVenueActivityTypeSave {
                                        isSavedByCurrentUser = true
                                    } else if (activity.objectForKey(kVenueActivityTypeKey) as! String) == kVenueActivityTypeVisit {
                                        isVisitedByCurrentUser = true
                                    }
                                }
                            }
                            
                            GOCache.sharedCache.setAttributesForVenue(object!, voters: voters, votedByCurrentUser: isVotedByCurrentUser, savedByCurrentUser: isSavedByCurrentUser, visitedByCurrentUser: isVisitedByCurrentUser)
                            
                            if venueCell!.tag != index {
                                return
                            }
                            
                            venueCell!.setVisitStatus(GOCache.sharedCache.isVenueVistedByCurrentUser(object!))
                            venueCell!.setVoteStatus(GOCache.sharedCache.isVenueVotedByCurrentUser(object!))
                            venueCell!.voteButton!.setTitle(GOCache.sharedCache.voteCountForVenue(object!).description, forState: UIControlState.Normal)
                            
                            if venueCell!.voteButton!.alpha < 1.0 {
                                UIView.animateWithDuration(0.200, animations: {
                                    venueCell!.voteButton!.alpha = 1.0
                                })
                            }
                            
                        }
                        
                    }
                }
                
            }
        }
        
        return venueCell!
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 76.0
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let vc = VenueViewController(transitionStyle: .Scroll, navigationOrientation: .Horizontal, options: nil)
       
        let object: PFObject? = objectAtIndexPath(indexPath)
        vc.venue = object
        vc.venueID = object?.objectId
        
        let venueName: String = object!.objectForKey(kVenueName) as! String
        vc.title = venueName
        vc.hidesBottomBarWhenPushed = true
        navigationController!.view.backgroundColor = UIColor.whiteColor()
        navigationController?.pushViewController(vc, animated: true)
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
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
    
    func venueCellView(venueCellView: GOVenueCellView, didTapVoteButton button: UIButton, venue: PFObject) {
        venueCellView.shouldEnableVoteButton(true)
        
        let voted: Bool = !button.selected
        venueCellView.setVoteStatus(voted)
        
        let originalButtonTitle = button.titleLabel!.text
        
        var voteCount: Int = Int(button.titleLabel!.text!)!
        if (voted) {
            voteCount++
            GOCache.sharedCache.incrementVoteCountForVenue(venue)
        } else {
            if voteCount > 0 {
                voteCount--
            }
            GOCache.sharedCache.decrementVoteCountForVenue(venue)
        }
        
        GOCache.sharedCache.setVenueIsVotedByCurrentUser(venue, voted: voted)
        
        button.setTitle(String(voteCount), forState: UIControlState.Normal)
        
        if voted {
            GOUtility.voteVenueInBackground(venue, block: { (succeeded, error) in
                let actualVenueCellView: GOVenueCellView? = self.tableView(self.tableView, viewForHeaderInSection: button.tag) as? GOVenueCellView
                actualVenueCellView?.shouldEnableVoteButton(false)
                actualVenueCellView?.setVoteStatus(succeeded)
                
                if !succeeded {
                    actualVenueCellView?.voteButton!.setTitle(originalButtonTitle, forState: UIControlState.Normal)
                }
            })
        } else {
            GOUtility.unvoteVenueInBackground(venue, block: { (succeeded, error) in
                let actualVenueCellView: GOVenueCellView? = self.tableView(self.tableView, viewForHeaderInSection: button.tag) as? GOVenueCellView
                actualVenueCellView?.shouldEnableVoteButton(true)
                actualVenueCellView?.setVoteStatus(!succeeded)
                
                if !succeeded{
                    actualVenueCellView?.voteButton!.setTitle(originalButtonTitle, forState: UIControlState.Normal)
                }
            })
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
            coachViews.bodyView.hintLabel.text = "Places you've visited are highlighted blue, visit a place to unlock its chat and voting (P.S. each city has a general chat open to everyone)"
            coachViews.bodyView.hintLabel.textAlignment = .Left
            coachViews.bodyView.nextLabel.text = "Got it!"
        case 2:
            coachViews.bodyView.hintLabel.text = "If you check out somewhere great, vote for it so others know what's good"
            coachViews.bodyView.nextLabel.text = "K!"
            coachViews.bodyView.hintLabel.textAlignment = .Left
        default: break
        }
        
        return (bodyView: coachViews.bodyView, arrowView: coachViews.arrowView)
    }
    
    
    // MARK: ()
    
    func userDidVoteOrUnvoteVenue(note: NSNotification) {
        self.tableView.beginUpdates()
        self.tableView.endUpdates()
    }

    func reachabilityChanged(note: NSNotification) {
        let reachability = note.object as! Reachability
        
        dispatch_async(dispatch_get_main_queue()) {
            if reachability.isReachable() {
                if reachability.isReachableViaWiFi() {
                    print("reachable via wifi - feedTableVC")
                } else {
                    print("reachable via cellular - feedTableVC")
                }
            } else {
                let announcement = Announcement(title: "Internet Connection Lost!", subtitle: "Try again in a bit", image: nil, duration: 4.0, action: nil)
                ColorList.Shout.background = kRed
                ColorList.Shout.title = UIColor.whiteColor()
                ColorList.Shout.subtitle = UIColor.whiteColor()
                Shout(announcement, to: self)
            }
        }
    }
    
    func indexForObjectAtIndexPath(indexPath: NSIndexPath) -> Int {
        return indexPath.row
    }
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        

    }
    */
}
