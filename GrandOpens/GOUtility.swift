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
            
            // Proceed to creating new vote
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
                                } else if (activity.objectForKey(kActivityTypeKey) as! String) == kActivityTypeVisit {
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
                        var isSavedByCurrentUser = false
                        var isVisitedByCurrentUser = false
                        
                        for activity in objects as! [PFObject] {
                            if (activity.objectForKey(kActivityTypeKey) as! String) == kActivityTypeVote {
                                voters.append(activity.objectForKey(kActivityByUserKey) as! PFUser)
                            }
                            
                            if (activity.objectForKey(kActivityByUserKey) as! PFUser).objectId == PFUser.currentUser()!.objectId {
                                if (activity.objectForKey(kActivityTypeKey) as! String) == kActivityTypeVote {
                                    isVotedByCurrentUser = true
                                } else if (activity.objectForKey(kActivityTypeKey) as! String) == kActivityTypeSave {
                                    isSavedByCurrentUser = true
                                } else if (activity.objectForKey(kActivityTypeKey) as! String) == kActivityTypeVisit {
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
        
        let queryExistingSaves = PFQuery(className: kActivityClassKey)
        queryExistingSaves.whereKey(kActivityToObjectKey, equalTo: venue)
        queryExistingSaves.whereKey(kActivityTypeKey, equalTo: kActivityTypeSave)
        queryExistingSaves.whereKey(kActivityByUserKey, equalTo: PFUser.currentUser()!)
        queryExistingSaves.cachePolicy = PFCachePolicy.NetworkOnly
        queryExistingSaves.findObjectsInBackgroundWithBlock{ (activities, error) in
            if error == nil {
                for activity in activities as! [PFObject] {
                    activity.deleteInBackground()
                }
            }
        
            // Proceed to creating new save
            let saveActivity = PFObject(className: kActivityClassKey)
            saveActivity.setObject(PFUser.currentUser()!, forKey: kActivityByUserKey)
            saveActivity.setObject(venue, forKey: kActivityToObjectKey)
            saveActivity.setObject(kActivityTypeSave, forKey: kActivityTypeKey)
            
            let saveACL = PFACL(user: PFUser.currentUser()!)
            saveACL.setPublicReadAccess(true)
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
        
        let saveActivity = PFObject(className: kActivityClassKey)
        saveActivity.setObject(PFUser.currentUser()!, forKey: kActivityByUserKey)
        saveActivity.setObject(venue, forKey: kActivityToObjectKey)
        saveActivity.setObject(kActivityTypeSave, forKey: kActivityTypeKey)
        
        let saveACL = PFACL(user: PFUser.currentUser()!)
        saveACL.setPublicReadAccess(true)
        saveActivity.ACL = saveACL
        
        saveActivity.saveEventually(completionBlock)
        GOCache.sharedCache.setVenueIsSavedByCurrentUser(true, venue: venue)
    }
    
    class func unsaveVenueEventually(venue: PFObject) {
        let query = PFQuery(className: kActivityClassKey)
        query.whereKey(kActivityByUserKey, equalTo: PFUser.currentUser()!)
        query.whereKey(kActivityToObjectKey, equalTo: venue)
        query.whereKey(kActivityTypeKey, equalTo: kActivityTypeSave)
        query.findObjectsInBackgroundWithBlock { (saveActivities, error) in
            // While normally there should only be one save activity returned, we can't guarantee that, yo.
            if error == nil {
                for saveActivity: PFObject in saveActivities as! [PFObject] {
                    saveActivity.deleteInBackground()
                }
            }
        }
        
        GOCache.sharedCache.setVenueIsSavedByCurrentUser(false, venue: venue)
    }
    
    
    // MARK: Activities
    
    class func queryForActivitiesOnVenue(venue: PFObject, cachePolicy: PFCachePolicy) -> PFQuery {
        let activitiesQuery: PFQuery = PFQuery(className: kActivityClassKey)
        activitiesQuery.whereKey(kActivityToObjectKey, equalTo: venue)
        let activities = [kActivityTypeVote, kActivityTypeSave, kActivityTypeVisit]
        activitiesQuery.whereKey(kActivityTypeKey, containedIn: activities)
        activitiesQuery.cachePolicy = cachePolicy

        // No need to use the next two lines since we're only getting results from one query, not two
//        let query = PFQuery.orQueryWithSubqueries([queryVotes])
//        query.cachePolicy = cachePolicy
        
//      "Cannot include ByUser because it is not a pointer to another object, including below two lines (at different points) caused vote icon to not display and vote count
//        query.includeKey(kActivityByUserKey)
//        query.includeKey(kActivityToObjectKey)
        
        return activitiesQuery
    }
    
    
    // MARK: Profile Pics
    
    class func userHasProfilePicture(user: PFUser) -> Bool {
        let profilePicture: PFFile? = user.objectForKey(kGOUserProfilePicKey) as? PFFile
        let profilePictureSmall: PFFile? = user.objectForKey(kGOUserProfilePicSmallKey) as? PFFile
        
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
        
        let muteActivity = PFObject(className: kActivityClassKey)
        muteActivity.setObject(PFUser.currentUser()!, forKey: kActivityByUserKey)
        muteActivity.setObject(user, forKey: kActivityToObjectKey)
        muteActivity.setObject(kActivityTypeMute, forKey: kActivityTypeKey)
        
        let muteACL = PFACL(user: PFUser.currentUser()!)
        muteACL.setPublicReadAccess(true)
        muteActivity.ACL = muteACL
        
        muteActivity.saveInBackgroundWithBlock { (succeeded, error) in
            if completionBlock != nil {
                completionBlock!(succeeded: succeeded.boolValue, error: error)
            }
        }
        GOCache.sharedCache.setMuteStatus(true, user: user)
    }
    
    class func unmuteUserInBackground(user: PFUser) {
        let query = PFQuery(className: kActivityClassKey)
        query.whereKey(kActivityByUserKey, equalTo: PFUser.currentUser()!)
        query.whereKey(kActivityToObjectKey, equalTo: user)
        query.whereKey(kActivityTypeKey, equalTo: kActivityTypeMute)
        query.findObjectsInBackgroundWithBlock { (muteActivities, error) in
            // While normally there should only be on mute activity returned, we can't guarantee that, yo
            if error == nil {
                for muteActivity: PFObject in muteActivities as! [PFObject] {
                    muteActivity.deleteInBackground()
                }
            }
        }
        GOCache.sharedCache.setMuteStatus(false, user: user)
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