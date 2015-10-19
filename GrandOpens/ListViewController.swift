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

class ListViewController: FeedTableViewController {
    
    
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

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController!.navigationBar.topItem!.title = "My List"
        
        self.tabBarController?.tabBar.hidden = false
    }
    
    override func queryForTable() -> PFQuery {
        if PFUser.currentUser() == nil {
            let query = PFQuery(className: self.parseClassName!)
            query.limit = 0
            return query
        }
        
        let activityQuery = PFQuery(className: kActivityClassKey)
        activityQuery.cachePolicy = PFCachePolicy.NetworkOnly
        activityQuery.whereKey(kActivityByUserKey, equalTo: PFUser.currentUser()!)
        activityQuery.whereKey(kActivityTypeKey, equalTo: kActivityTypeSave)
        activityQuery.orderByDescending("createdAt")
        activityQuery.includeKey(kActivityToObjectKey)
        
//        let venueQuery = PFQuery(className: self.parseClassName!)
//        venueQuery.cachePolicy = PFCachePolicy.NetworkOnly
//        venueQuery.whereKey("objectId", matchesQuery: activityQuery)
//        venueQuery.whereKey(kActivityTypeKey, equalTo: kActivityTypeSave)
//        venueQuery.includeKey(kActivityToObjectKey)
//        venueQuery.orderByDescending("createdAt")

//        If reformatting the activity object works, come back and implement a check like the following 3 lines
//        if self.objects!.count == 0 {
//            venueQuery.cachePolicy = PFCachePolicy.CacheThenNetwork
//        }
        
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
        let object: PFObject? = activity?.objectForKey(kActivityToObjectKey) as! PFObject
        venueCell!.venue = object
        venueCell!.tag = index
        venueCell!.voteButton!.tag = index
        
        let attributesForVenue = GOCache.sharedCache.attributesForVenue(object!)
        
        if attributesForVenue != nil {
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
                            
                            for activity in objects as! [PFObject] {
                                if (activity.objectForKey(kActivityTypeKey) as! String) == kActivityTypeVote && activity.objectForKey(kActivityByUserKey) != nil {
                                    voters.append(activity.objectForKey(kActivityByUserKey) as! PFUser)
                                }
                                
                                if (activity.objectForKey(kActivityByUserKey) as? PFUser)?.objectId == PFUser.currentUser()!.objectId {
                                    if (activity.objectForKey(kActivityTypeKey) as! String) == kActivityTypeVote {
                                        isVotedByCurrentUser = true
                                    } else if (activity.objectForKey(kActivityTypeKey) as! String) == kActivityTypeSave {
                                        isSavedByCurrentUser = true
                                    }
                                }
                            }
                            
                            GOCache.sharedCache.setAttributesForVenue(object!, voters: voters, votedByCurrentUser: isVotedByCurrentUser, savedByCurrentUser: isSavedByCurrentUser)
                            
                            if venueCell!.tag != index {
                                return
                            }
                            
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
        let object: PFObject? = activity?.objectForKey(kActivityToObjectKey) as! PFObject
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
