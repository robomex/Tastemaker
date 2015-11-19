//
//  Cache.swift
//  GrandOpens
//
//  Created by Tony Morales on 9/9/15.
//  Copyright (c) 2015 Tony Morales. All rights reserved.
//

import Foundation
import Parse

final class GOCache {
    private var cache: NSCache
    
    
    // MARK: Initialization
    
    static let sharedCache = GOCache()
    
    private init() {
        self.cache = NSCache()
    }
    
    
    // MARK: GOCache
    
    func clear() {
        cache.removeAllObjects()
    }
    
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
    
    func setAttributesForUser(user: PFUser, venueVoteCount count: Int, followedByCurrentUser following: Bool) {
        let attributes = [
            kUserAttributesVenueVoteCountKey: count,
            kUserAttributesIsFollowedByCurrentUserKey: following
        ]
        
        setAttributes(attributes as! [String: AnyObject], forUser: user)
    }
    
    func attributesForUser(user: PFUser) -> [String: AnyObject]? {
        let key = keyForUser(user)
        return cache.objectForKey(key) as? [String: AnyObject]
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
    
    func isVenueVistedByCurrentUser(venue: PFObject) -> Bool {
        let attributes = attributesForVenue(venue)
        if attributes != nil {
            return attributes![kVenueAttributesIsVisitedByCurrentUserKey] as! Bool
        }
        
        return false
    }
    
    
    // MARK: ()
    
    func setAttributes(attributes: [String: AnyObject], forVenue venue: PFObject) {
        let key: String = self.keyForVenue(venue)
        cache.setObject(attributes, forKey: key)
    }
    
    func setAttributes(attributes: [String: AnyObject], forUser user: PFUser) {
        let key: String = self.keyForUser(user)
        cache.setObject(attributes, forKey: key)
    }
    
    func keyForVenue(venue: PFObject) -> String {
        return "venue_\(venue.objectId)"
    }
    
    func keyForUser(user: PFUser) -> String {
        return "user_\(user.objectId)"
    }
}