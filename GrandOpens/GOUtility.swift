//
//  GOUtility.swift
//  GrandOpens
//
//  Created by Tony Morales on 9/12/15.
//  Copyright (c) 2015 Tony Morales. All rights reserved.
//

import Foundation
import Parse
import MapKit

class GOUtility {
    
    
    // MARK: GOUtility
    
    
    // MARK: Vote Venues
    
    class func voteVenueInBackground(venue: PFObject, block completionBlock: ((succeeded: Bool, error: NSError?) -> Void)?) {
        let queryExistingVotes = PFQuery(className: kVenueActivityClassKey)
        queryExistingVotes.whereKey(kVenueActivityToVenueKey, equalTo: venue)
        queryExistingVotes.whereKey(kVenueActivityTypeKey, equalTo: kVenueActivityTypeVote)
        queryExistingVotes.whereKey(kVenueActivityByUserKey, equalTo: PFUser.currentUser()!)
        queryExistingVotes.cachePolicy = PFCachePolicy.NetworkOnly
        queryExistingVotes.findObjectsInBackgroundWithBlock{ (activities, error) in
            if error == nil {
                for activity in activities! {
                    activity.deleteInBackground()
                }
            }
            
            // Proceed to creating new vote
            let voteActivity = PFObject(className: kVenueActivityClassKey)
            voteActivity.setObject(kVenueActivityTypeVote, forKey: kVenueActivityTypeKey)
            voteActivity.setObject(PFUser.currentUser()!, forKey: kVenueActivityByUserKey)
            voteActivity.setObject(venue, forKey: kVenueActivityToVenueKey)
            
            let voteACL = PFACL(user: PFUser.currentUser()!)
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
                        
                        GOCache.sharedCache.setAttributesForVenue(venue, voters: voters, votedByCurrentUser: isVotedByCurrentUser, savedByCurrentUser: isSavedByCurrentUser, visitedByCurrentUser: isVisitedByCurrentUser)
                    }
                    
                    NSNotificationCenter.defaultCenter().postNotificationName(GOUtilityUserVotedUnvotedVenueCallbackFinishedNotification, object: venue, userInfo: [GOUserVotedUnvotedVenueNotificationUserInfoVotedKey: succeeded.boolValue])
                }
            }
        }
    }
    
    class func unvoteVenueInBackground(venue: PFObject, block completionBlock: ((succeeded: Bool, error: NSError?) -> Void)?) {
        let queryExistingVotes = PFQuery(className: kVenueActivityClassKey)
        queryExistingVotes.whereKey(kVenueActivityToVenueKey, equalTo: venue)
        queryExistingVotes.whereKey(kVenueActivityTypeKey, equalTo: kVenueActivityTypeVote)
        queryExistingVotes.whereKey(kVenueActivityByUserKey, equalTo: PFUser.currentUser()!)
        queryExistingVotes.cachePolicy = PFCachePolicy.NetworkOnly
        queryExistingVotes.findObjectsInBackgroundWithBlock { (activities, error) in
            if error == nil {
                for activity in activities! {
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
                        var isSavedByCurrentUser = false
                        var isVisitedByCurrentUser = false
                        
                        for activity in objects! {
                            if (activity.objectForKey(kVenueActivityTypeKey) as! String) == kVenueActivityTypeVote {
                                voters.append(activity.objectForKey(kVenueActivityByUserKey) as! PFUser)
                            }
                            
                            if (activity.objectForKey(kVenueActivityByUserKey) as! PFUser).objectId == PFUser.currentUser()!.objectId {
                                if (activity.objectForKey(kVenueActivityTypeKey) as! String) == kVenueActivityTypeVote {
                                    isVotedByCurrentUser = true
                                } else if (activity.objectForKey(kVenueActivityTypeKey) as! String) == kVenueActivityTypeSave {
                                    isSavedByCurrentUser = true
                                } else if (activity.objectForKey(kVenueActivityTypeKey) as! String) == kVenueActivityTypeVisit {
                                    isVisitedByCurrentUser = true
                                }
                            }
                        }
                        
                        GOCache.sharedCache.setAttributesForVenue(venue, voters: voters, votedByCurrentUser: isVotedByCurrentUser, savedByCurrentUser: isSavedByCurrentUser, visitedByCurrentUser: isVisitedByCurrentUser)
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
    
    
    // MARK: Save Venues
    
    class func saveVenueInBackground(venue: PFObject, block completionBlock: ((succeeded: Bool, error: NSError?) -> Void)?) {
        
        let queryExistingSaves = PFQuery(className: kVenueActivityClassKey)
        queryExistingSaves.whereKey(kVenueActivityToVenueKey, equalTo: venue)
        queryExistingSaves.whereKey(kVenueActivityTypeKey, equalTo: kVenueActivityTypeSave)
        queryExistingSaves.whereKey(kVenueActivityByUserKey, equalTo: PFUser.currentUser()!)
        queryExistingSaves.cachePolicy = PFCachePolicy.NetworkOnly
        queryExistingSaves.findObjectsInBackgroundWithBlock{ (activities, error) in
            if error == nil {
                for activity in activities! {
                    activity.deleteInBackground()
                }
            }
        
            // Proceed to creating new save
            let saveActivity = PFObject(className: kVenueActivityClassKey)
            saveActivity.setObject(PFUser.currentUser()!, forKey: kVenueActivityByUserKey)
            saveActivity.setObject(venue, forKey: kVenueActivityToVenueKey)
            saveActivity.setObject(kVenueActivityTypeSave, forKey: kVenueActivityTypeKey)
            
            let saveACL = PFACL(user: PFUser.currentUser()!)
            saveActivity.ACL = saveACL
            
            saveActivity.saveInBackgroundWithBlock { (succeeded, error) in
                if completionBlock != nil {
                    completionBlock!(succeeded: succeeded.boolValue, error: error)
                }
                
                GOCache.sharedCache.setVenueIsSavedByCurrentUser(true, venue: venue)

                NSNotificationCenter.defaultCenter().postNotificationName(GOUtilityUserSavedUnsavedVenueNotification, object: venue, userInfo: [GOUserSavedUnsavedVenueNotificationUserInfoSavedKey: succeeded.boolValue])
            }
        }
    }
    
    class func saveVenueEventually(venue: PFObject, block completionBlock: ((succeeded: Bool, error: NSError?) -> Void)?) {
        
        let saveActivity = PFObject(className: kVenueActivityClassKey)
        saveActivity.setObject(PFUser.currentUser()!, forKey: kVenueActivityByUserKey)
        saveActivity.setObject(venue, forKey: kVenueActivityToVenueKey)
        saveActivity.setObject(kVenueActivityTypeSave, forKey: kVenueActivityTypeKey)
        
        let saveACL = PFACL(user: PFUser.currentUser()!)
        saveActivity.ACL = saveACL
        
        saveActivity.saveEventually(completionBlock)
        GOCache.sharedCache.setVenueIsSavedByCurrentUser(true, venue: venue)
    }
    
    class func unsaveVenueEventually(venue: PFObject) {
        let query = PFQuery(className: kVenueActivityClassKey)
        query.whereKey(kVenueActivityByUserKey, equalTo: PFUser.currentUser()!)
        query.whereKey(kVenueActivityToVenueKey, equalTo: venue)
        query.whereKey(kVenueActivityTypeKey, equalTo: kVenueActivityTypeSave)
        query.findObjectsInBackgroundWithBlock { (saveActivities, error) in
            // While normally there should only be one save activity returned, we can't guarantee that, yo.
            if error == nil {
                for saveActivity: PFObject in saveActivities! {
                    saveActivity.deleteInBackground()
                }
            }
        }
        
        GOCache.sharedCache.setVenueIsSavedByCurrentUser(false, venue: venue)
    }
    
    
    // MARK: Activities
    
    class func queryForActivitiesOnVenue(venue: PFObject, cachePolicy: PFCachePolicy) -> PFQuery {
        let activitiesQuery: PFQuery = PFQuery(className: kVenueActivityClassKey)
        activitiesQuery.whereKey(kVenueActivityToVenueKey, equalTo: venue)
        let activities = [kVenueActivityTypeVote, kVenueActivityTypeSave, kVenueActivityTypeVisit]
        activitiesQuery.whereKey(kVenueActivityTypeKey, containedIn: activities)
        activitiesQuery.cachePolicy = cachePolicy

        // No need to use the next two lines since we're only getting results from one query, not two
//        let query = PFQuery.orQueryWithSubqueries([queryVotes])
//        query.cachePolicy = cachePolicy
        
//      "Cannot include ByUser because it is not a pointer to another object, including below two lines (at different points) caused vote icon to not display and vote count
//        query.includeKey(kVenueActivityByUserKey)
//        query.includeKey(kVenueActivityToVenueKey)
        
        return activitiesQuery
    }
    
    
    // MARK: Profile Pics
    
    class func userHasProfilePicture(user: PFUser) -> Bool {
        let profilePicture: PFFile? = user.objectForKey(kUserProfilePicKey) as? PFFile
        let profilePictureSmall: PFFile? = user.objectForKey(kUserProfilePicSmallKey) as? PFFile
        
        return profilePicture != nil && profilePictureSmall != nil
    }
    
    class func defaultProfilePicture() -> UIImage? {
        return UIImage(named: "AvatarPlaceholder.png")
    }
    
    
    // MARK: User Muting
    
    class func muteUserInBackground(user: PFUser, block completionBlock: ((succeeded: Bool, error: NSError?) -> Void)?) {
        if user.objectId == PFUser.currentUser()!.objectId {
            return
        }
        
        let muteActivity = PFObject(className: kUserActivityClassKey)
        muteActivity.setObject(PFUser.currentUser()!, forKey: kUserActivityByUserKey)
        muteActivity.setObject(user, forKey: kUserActivityToUserKey)
        muteActivity.setObject(kUserActivityTypeMute, forKey: kUserActivityTypeKey)
        
        let muteACL = PFACL(user: PFUser.currentUser()!)
        muteActivity.ACL = muteACL
        
        muteActivity.saveInBackgroundWithBlock { (succeeded, error) in
            if completionBlock != nil {
                completionBlock!(succeeded: succeeded.boolValue, error: error)
            }
        }
        GOCache.sharedCache.setMuteStatus(true, userId: user.objectId!)
    }
    
    class func unmuteUserInBackground(user: PFUser) {
        let query = PFQuery(className: kUserActivityClassKey)
        query.whereKey(kUserActivityByUserKey, equalTo: PFUser.currentUser()!)
        query.whereKey(kUserActivityToUserKey, equalTo: user)
        query.whereKey(kUserActivityTypeKey, equalTo: kUserActivityTypeMute)
        query.findObjectsInBackgroundWithBlock { (muteActivities, error) in
            // While normally there should only be on mute activity returned, we can't guarantee that, yo
            if error == nil {
                for muteActivity: PFObject in muteActivities! {
                    muteActivity.deleteInBackground()
                }
            }
        }
        GOCache.sharedCache.setMuteStatus(false, userId: user.objectId!)
    }
}


// MARK: ()

func showSimpleAlertWithTitle(title: String!, message: String, actionTitle: String, viewController: UIViewController) {
    let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
    let action = UIAlertAction(title: actionTitle, style: .Default, handler: nil)
    alert.addAction(action)
    viewController.presentViewController(alert, animated: true, completion: nil)
}

// Below may be useful after adding MapKit

func zoomToUserLocationInMapView(mapView: MKMapView) {
    if let coordinate = mapView.userLocation.location?.coordinate {
        let region = MKCoordinateRegionMakeWithDistance(coordinate, 10000, 10000)
        mapView.setRegion(region, animated: true)
    }
}

extension PFGeoPoint {
    func locationCoordinate2D() -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
    }
}