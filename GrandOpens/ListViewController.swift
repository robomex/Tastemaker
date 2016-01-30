//
//  ListViewController.swift
//  GrandOpens
//
//  Created by Tony Morales on 6/9/15.
//  Copyright (c) 2015 Tony Morales. All rights reserved.
//

import UIKit
import ParseUI
import Parse
import Synchronized
import DZNEmptyDataSet

class ListViewController: FeedTableViewController, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    // MARK: Initialization
    
    deinit {
        let defaultNotificationCenter = NSNotificationCenter.defaultCenter()
        defaultNotificationCenter.removeObserver(self, name: GOUtilityUserSavedUnsavedVenueNotification, object: nil)
    }
    
    override init(style: UITableViewStyle, className: String?) {
//        self.outstandingVenueCellViewQueries = [NSObject: AnyObject]()
        
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

        let defaultNotificationCenter = NSNotificationCenter.defaultCenter()
        defaultNotificationCenter.addObserver(self, selector: "userDidSaveOrUnsaveVenue:", name: GOUtilityUserSavedUnsavedVenueNotification, object: nil)
        self.title = "My List"
        
        self.tableView.emptyDataSetSource = self
        self.tableView.emptyDataSetDelegate = self
        self.tableView.tableFooterView = UIView()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.tabBarController?.tabBar.hidden = false
        self.tableView.separatorStyle = UITableViewCellSeparatorStyle.SingleLine
        
        self.loadObjects()
    }
    
    override func queryForTable() -> PFQuery {
        if PFUser.currentUser() == nil {
            let query = PFQuery(className: self.parseClassName!)
            query.limit = 0
            return query
        }
        
        let activityQuery = PFQuery(className: kVenueActivityClassKey)
        activityQuery.cachePolicy = PFCachePolicy.NetworkOnly
        activityQuery.whereKey(kVenueActivityByUserKey, equalTo: PFUser.currentUser()!)
        activityQuery.whereKey(kVenueActivityTypeKey, equalTo: kVenueActivityTypeSave)
        activityQuery.orderByAscending("createdAt")
        activityQuery.includeKey(kVenueActivityToVenueKey)
        
        return activityQuery
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
        
        let activity: PFObject? = objectAtIndexPath(indexPath)
        let object: PFObject? = activity?.objectForKey(kVenueActivityToVenueKey) as? PFObject
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
                            
                            for activity in objects! {
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
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let vc = VenueViewController(transitionStyle: .Scroll, navigationOrientation: .Horizontal, options: nil)

        
        let activity: PFObject? = objectAtIndexPath(indexPath)
        let object: PFObject? = activity?.objectForKey(kVenueActivityToVenueKey) as? PFObject
        vc.venue = object
        vc.venueID = object?.objectId
        
        let venueName: String = object!.objectForKey(kVenueName) as! String
        vc.title = venueName
        vc.hidesBottomBarWhenPushed = true
        navigationController!.view.backgroundColor = UIColor.whiteColor()
        navigationController?.pushViewController(vc, animated: true)
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }

    
    // MARK: ()
    
    @objc func userDidSaveOrUnsaveVenue(note: NSNotification) {
        self.loadObjects()
    }
    
    
    // MARK: DZNEmptyDataSet
    
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let title = "/.-("
        let attributes = [NSFontAttributeName: UIFont.systemFontOfSize(50.0)]
        return NSAttributedString(string: title, attributes: attributes)
    }
    
    func descriptionForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let description = "You haven't saved any venues yet. \nIf a new place catches your eye, save it and it'll pop up here!"
        let attributes = [NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleBody)]
        return NSAttributedString(string: description, attributes: attributes)
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
