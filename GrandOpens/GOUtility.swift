//
//  GOUtility.swift
//  GrandOpens
//
//  Created by Tony Morales on 9/12/15.
//  Copyright (c) 2015 Tony Morales. All rights reserved.
//

import Foundation
import Parse

class GOUtility {
    
    
    // MARK: GOUtility
    
    
    // MARK: Vote Venues
    
    class func voteVenueInBackground(venue: PFObject, block completionBlock: ((succeeded: Bool, error: NSError?) -> Void)?) {
        let queryExistingVotes = PFQuery(className: kActivityClassKey)
        queryExistingVotes.whereKey(kActivityToObjectKey, equalTo: venue)
        queryExistingVotes.whereKey(kActivityTypeKey, equalTo: kActivityTypeVote)
        queryExistingVotes.whereKey(kActivityByUserKey, equalTo: PFUser.currentUser()!)
        queryExistingVotes.cachePolicy = PFCachePolicy.NetworkOnly
        queryExistingVotes.findObjectsInBackgroundWithBlock{ (activities, error) in
            if error == nil {
                for activity in activities as! [PFObject] {
                    activity.deleteInBackground()
                }
            }
            
            // proceed to creating new vote
            let voteActivity = PFObject(className: kActivityClassKey)
            voteActivity.setObject(kActivityTypeVote, forKey: kActivityTypeKey)
            voteActivity.setObject(PFUser.currentUser()!, forKey: kActivityByUserKey)
            voteActivity.setObject(venue, forKey: kActivityToObjectKey)
            
            let voteACL = PFACL(user: PFUser.currentUser()!)
            voteACL.setPublicReadAccess(true)
            voteActivity.ACL = voteACL
            
            voteActivity.saveInBackgroundWithBlock{ (succeeded, error) in
                if completionBlock != nil {
                    completionBlock!(succeeded: succeeded.boolValue, error: error)
                }
                
                // refresh cache
                let query = GOUtility.queryForActivitiesOnVenue(venue, cachePolicy: PFCachePolicy.NetworkOnly)
                query.findObjectsInBackgroundWithBlock{ (objects, error) in
                    if error == nil {
                        var voters = [PFUser]()
                        
                        var isVotedByCurrentUser = false
                        
                        for activity in objects as! [PFObject] {
                            if (activity.objectForKey(kActivityTypeKey) as! String) == kActivityTypeVote && activity.objectForKey(kActivityByUserKey) != nil {
                                voters.append(activity.objectForKey(kActivityByUserKey) as! PFUser)
                            }
                            
                            if (activity.objectForKey(kActivityByUserKey) as? PFUser)?.objectId == PFUser.currentUser()!.objectId {
                                if (activity.objectForKey(kActivityTypeKey) as! String) == kActivityTypeVote {
                                    isVotedByCurrentUser = true
                                }
                            }
                        }
                        
                        GOCache.sharedCache.setAttributesForVenue(venue, voters: voters, votedByCurrentUser: isVotedByCurrentUser)
                    }
                    
                    NSNotificationCenter.defaultCenter().postNotificationName(GOUtilityUserVotedUnvotedVenueCallbackFinishedNotification, object: venue, userInfo: [GOUserVotedUnvotedVenueNotificationUserInfoVotedKey: succeeded.boolValue])
                }
            }
        }
    }
    
    class func unvoteVenueInBackground(venue: PFObject, block completionBlock: ((succeeded: Bool, error: NSError?) -> Void)?) {
        let queryExistingVotes = PFQuery(className: kActivityClassKey)
        queryExistingVotes.whereKey(kActivityToObjectKey, equalTo: venue)
        queryExistingVotes.whereKey(kActivityTypeKey, equalTo: kActivityTypeVote)
        queryExistingVotes.whereKey(kActivityByUserKey, equalTo: PFUser.currentUser()!)
        queryExistingVotes.cachePolicy = PFCachePolicy.NetworkOnly
        queryExistingVotes.findObjectsInBackgroundWithBlock { (activities, error) in
            if error == nil {
                for activity in activities as! [PFObject] {
                    activity.deleteInBackground()
                }
                
                if completionBlock != nil {
                    completionBlock!(succeeded: true, error: nil)
                }
                
                // refresh cache
                let query = GOUtility.queryForActivitiesOnVenue(venue, cachePolicy: PFCachePolicy.NetworkOnly)
                query.findObjectsInBackgroundWithBlock { (objects, error) in
                    if error == nil {
                        
                        var voters = [PFUser]()
                        
                        var isVotedByCurrentUser = false
                        
                        for activity in objects as! [PFObject] {
                            if (activity.objectForKey(kActivityTypeKey) as! String) == kActivityTypeVote {
                                voters.append(activity.objectForKey(kActivityByUserKey) as! PFUser)
                            }
                            
                            if (activity.objectForKey(kActivityByUserKey) as! PFUser).objectId == PFUser.currentUser()!.objectId {
                                if (activity.objectForKey(kActivityTypeKey) as! String) == kActivityTypeVote {
                                    isVotedByCurrentUser = true
                                }
                            }
                        }
                        
                        GOCache.sharedCache.setAttributesForVenue(venue, voters: voters, votedByCurrentUser: isVotedByCurrentUser)
                    }
                    
                    NSNotificationCenter.defaultCenter().postNotificationName(GOUtilityUserVotedUnvotedVenueCallbackFinishedNotification, object: venue, userInfo: [GOUserVotedUnvotedVenueNotificationUserInfoVotedKey: false])
                }
            } else {
                if completionBlock != nil {
                    completionBlock!(succeeded: false, error: error)
                }
            }
        }
    }
    
    
    // MARK: Activities
    
    class func queryForActivitiesOnVenue(venue: PFObject, cachePolicy: PFCachePolicy) -> PFQuery {
        let queryVotes: PFQuery = PFQuery(className: kActivityClassKey)
        queryVotes.whereKey(kActivityToObjectKey, equalTo: venue)
        queryVotes.whereKey(kActivityTypeKey, equalTo: kActivityTypeVote)
        
        let query = PFQuery.orQueryWithSubqueries([queryVotes])
        query.cachePolicy = cachePolicy
//      "Cannot include ByUser because it is not a pointer to another object, including below two lines (at different points) caused vote icon to not display and vote count
//        query.includeKey(kActivityByUserKey)
//        query.includeKey(kActivityToObjectKey)
        
        return query
    }
}