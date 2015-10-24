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
import CoreLocation

class FeedTableViewController: PFQueryTableViewController, GOVenueCellViewDelegate, CLLocationManagerDelegate {

    var shouldReloadOnAppear: Bool = false
    var reusableViews: Set<GOVenueCellView>!
    var outstandingVenueCellViewQueries: [NSObject: AnyObject]
    let locationManager = CLLocationManager()
    
    // MARK: Initialization
    
    deinit {
        let defaultNotificationCenter = NSNotificationCenter.defaultCenter()
        defaultNotificationCenter.removeObserver(self, name: GOUtilityUserVotedUnvotedVenueCallbackFinishedNotification, object: nil)
        defaultNotificationCenter.removeObserver(self, name: GOUtilityUserVotedUnvotedVenueNotification, object: nil)
    }
    
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
        
        // CoreLocation items
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        
        UIApplication.sharedApplication().statusBarStyle = .LightContent
        
        // Register to be notified when a voted/unvoted callback finished
        let defaultNotificationCenter = NSNotificationCenter.defaultCenter()
        defaultNotificationCenter.addObserver(self, selector: Selector("userDidVoteOrUnvoteVenue:"), name: GOUtilityUserVotedUnvotedVenueCallbackFinishedNotification, object: nil)
        defaultNotificationCenter.addObserver(self, selector: Selector("userDidVoteOrUnvoteVenue:"), name: GOUtilityUserVotedUnvotedVenueNotification, object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        navigationController!.navigationBar.topItem!.title = "Chicago"

        if let font = UIFont(name: "Muli", size: 26) {
            navigationController!.navigationBar.topItem!.title = "Chicago"
            navigationController!.navigationBar.titleTextAttributes = [NSFontAttributeName: font, NSForegroundColorAttributeName: UIColor.whiteColor()]
            navigationController!.view.backgroundColor = UIColor.whiteColor()
        }
        
        self.tabBarController?.tabBar.hidden = false
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
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return self.objects!.count
    }

    
    // MARK: PFQueryTableViewController
    
    override func queryForTable() -> PFQuery {
        if (PFUser.currentUser() == nil) {
            let query = PFQuery(className: self.parseClassName!)
            query.limit = 0
            return query
        }
        
        let query = PFQuery(className: self.parseClassName!)
        query.orderByDescending("openingDate")
        
        // A pull-to-refresh should always trigger a network request.
        query.cachePolicy = PFCachePolicy.NetworkOnly
        
        // If no objects are loaded in memory, we look to the cache first to fill the table 
        // and then subsequently do a query against the network.
        //
        // If there is no network connection, we will hit the cache first.
        
        if self.objects!.count == 0 || (UIApplication.sharedApplication().delegate!.performSelector(Selector("isParseReachable")) == nil) {
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
                                if (activity.objectForKey(kActivityTypeKey) as! String) == kActivityTypeVote && activity.objectForKey(kActivityByUserKey) != nil {
                                    voters.append(activity.objectForKey(kActivityByUserKey) as! PFUser)
                                }
                                
                                if (activity.objectForKey(kActivityByUserKey) as? PFUser)?.objectId == PFUser.currentUser()!.objectId {
                                    if (activity.objectForKey(kActivityTypeKey) as! String) == kActivityTypeVote {
                                        isVotedByCurrentUser = true
                                    } else if (activity.objectForKey(kActivityTypeKey) as! String) == kActivityTypeSave {
                                        isSavedByCurrentUser = true
                                    } else if (activity.objectForKey(kActivityTypeVisit) as! String) == kActivityTypeVisit {
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

//        super.tableView(tableView, didDeselectRowAtIndexPath: indexPath)
        
        let vc = VenueViewController(transitionStyle: .Scroll, navigationOrientation: .Horizontal, options: nil)
       
        let object: PFObject? = objectAtIndexPath(indexPath)
        vc.venue = object
        vc.venueID = object?.objectId
        
        let venueName: String = object!.objectForKey(kVenueName) as! String
        vc.title = venueName
        navigationItem.title = " "
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
        venueCellView.shouldEnableVoteButton(false)
        
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
                actualVenueCellView?.shouldEnableVoteButton(true)
                actualVenueCellView?.setVoteStatus(succeeded)
                
                if !succeeded {
                    actualVenueCellView?.voteButton!.setTitle(originalButtonTitle, forState: UIControlState.Normal)
                }
            })
        } else {
            GOUtility.unvoteVenueInBackground(venue, block: { (succeeded, error) in
                let actualVenueCellView: GOVenueCellView? = self.tableView(self.tableView, viewForHeaderInSection: button.tag) as? GOVenueCellView
                actualVenueCellView?.shouldEnableVoteButton(false)
                actualVenueCellView?.setVoteStatus(!succeeded)
                
                if !succeeded{
                    actualVenueCellView?.voteButton!.setTitle(originalButtonTitle, forState: UIControlState.Normal)
                }
            })
        }
    }
    
    
    // MARK: ()
    
    func userDidVoteOrUnvoteVenue(note: NSNotification) {
        self.tableView.beginUpdates()
        self.tableView.endUpdates()
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
