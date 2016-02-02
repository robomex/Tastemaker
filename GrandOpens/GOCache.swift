//
//  Cache.swift
//  GrandOpens
//
//  Created by Tony Morales on 9/9/15.
//  Copyright (c) 2015 Tony Morales. All rights reserved.
//

import Foundation
import Parse
//import OSCache

final class GOCache {
    private var cache: OSCache
    
    
    // MARK: Initialization
    
    static let sharedCache = GOCache()
    
    private init() {
        self.cache = OSCache()
    }
    
    
    // MARK: GOCache
    
    func clear() {
        cache.removeAllObjects()
    }
    
    // Venue caching
    
    func setAttributesForVenue(venue: PFObject, voters: [PFUser], votedByCurrentUser: Bool, savedByCurrentUser: Bool, visitedByCurrentUser: Bool) {
        let attributes = [
            kVenueAttributesIsVotedByCurrentUserKey: votedByCurrentUser,
            kVenueAttributesVoteCountKey: voters.count,
            kVenueAttributesVotersKey: voters,
            kVenueAttributesIsSavedByCurrentUserKey: savedByCurrentUser,
            kVenueAttributesIsVisitedByCurrentUserKey: visitedByCurrentUser
        ]
        setAttributes(attributes as! [String: AnyObject], forVenue: venue)
    }
    
    func attributesForVenue(venue: PFObject) -> [String: AnyObject]? {
        let key: String = self.keyForVenue(venue)
        return cache.objectForKey(key) as? [String: AnyObject]
    }
    
    func voteCountForVenue(venue: PFObject) -> Int {
        let attributes: [NSObject: AnyObject]? = self.attributesForVenue(venue)
        if attributes != nil {
            return attributes![kVenueAttributesVoteCountKey] as! Int
        }
        
        return 0
    }
    
    func votersForVenue(venue: PFObject) -> [PFUser] {
        let attributes = attributesForVenue(venue)
        if attributes != nil {
            return attributes![kVenueAttributesVotersKey] as! [PFUser]
        }
        
        return [PFUser]()
    }
    
    func setVenueIsVotedByCurrentUser(venue: PFObject, voted: Bool) {
        var attributes = attributesForVenue(venue)
        attributes![kVenueAttributesIsVotedByCurrentUserKey] = voted
        setAttributes(attributes!, forVenue: venue)
    }
    
    func isVenueVotedByCurrentUser(venue: PFObject) -> Bool {
        let attributes = attributesForVenue(venue)
        if attributes != nil {
            return attributes![kVenueAttributesIsVotedByCurrentUserKey] as! Bool
        }
        
        return false
    }
    
    func incrementVoteCountForVenue(venue: PFObject) {
        let voteCount = voteCountForVenue(venue) + 1
        var attributes = attributesForVenue(venue)
        attributes![kVenueAttributesVoteCountKey] = voteCount
        setAttributes(attributes!, forVenue: venue)
    }
    
    func decrementVoteCountForVenue(venue: PFObject) {
        let voteCount = voteCountForVenue(venue) - 1
        if voteCount < 0 {
            return
        }
        var attributes = attributesForVenue(venue)
        attributes![kVenueAttributesVoteCountKey] = voteCount
        setAttributes(attributes!, forVenue: venue)
    }
    
    func saveStatusForVenue(venue: PFObject) -> Bool {
        if let attributes = attributesForVenue(venue) {
            if let saveStatus = attributes[kVenueAttributesIsSavedByCurrentUserKey] as? Bool {
                return saveStatus
            }
        }
        
        return false
    }
    
    func setVenueIsSavedByCurrentUser(saved: Bool, venue: PFObject) {
        if var attributes = attributesForVenue(venue) {
            attributes[kVenueAttributesIsSavedByCurrentUserKey] = saved
            setAttributes(attributes, forVenue: venue)
        }
    }
    
    func setVenueIsVisitedByCurrentUser(venue: PFObject, visited: Bool) {
        var attributes = attributesForVenue(venue)
        attributes![kVenueAttributesIsVisitedByCurrentUserKey] = visited
        setAttributes(attributes!, forVenue: venue)
    }
    
    func isVenueVisitedByCurrentUser(venue: PFObject) -> Bool {
        let attributes = attributesForVenue(venue)
        if attributes != nil {
            return attributes![kVenueAttributesIsVisitedByCurrentUserKey] as! Bool
        }
        
        return false
    }
    
    
    // User caching
    
    func setAttributesForUser(userId: String,
        //venueVoteCount count: Int, followedByCurrentUser following: Bool, 
        mutedByCurrentUser muted: Bool) {
        let attributes = [
            //kUserAttributesVenueVoteCountKey: count,
            //kUserAttributesIsFollowedByCurrentUserKey: following,
            kUserAttributesIsMutedByCurrentUserKey: muted
        ]
        
        setAttributes(attributes as [String: AnyObject], forUser: userId)
    }
    
    func attributesForUser(userId: String) -> [String: AnyObject]? {
        let key = keyForUser(userId)
        return cache.objectForKey(key) as? [String: AnyObject]
    }
    
    func setMuteStatus(muting: Bool, userId: String) {
        if var attributes = attributesForUser(userId) {
            attributes[kUserAttributesIsMutedByCurrentUserKey] = muting
            setAttributes(attributes, forUser: userId)
        }
    }
    
    func isUserMutedByCurrentUser(userId: String) -> Bool {
        let attributes = attributesForUser(userId)
        if attributes != nil {
            return attributes![kUserAttributesIsMutedByCurrentUserKey] as! Bool
        }
        
        return false
    }
    
    
    // MARK: ()
    
    func setAttributes(attributes: [String: AnyObject], forVenue venue: PFObject) {
        let key: String = self.keyForVenue(venue)
        cache.setObject(attributes, forKey: key)
    }
    
    func setAttributes(attributes: [String: AnyObject], forUser userId: String) {
        let key: String = self.keyForUser(userId)
        cache.setObject(attributes, forKey: key)
    }
    
    func keyForVenue(venue: PFObject) -> String {
        return "venue_\(venue.objectId)"
    }
    
    func keyForUser(userId: String) -> String {
        return "user_\(userId)"
    }
}