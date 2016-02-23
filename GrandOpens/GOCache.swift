//
//  Cache.swift
//  GrandOpens
//
//  Created by Tony Morales on 9/9/15.
//  Copyright (c) 2015 Tony Morales. All rights reserved.
//

import Foundation

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
    
    // MARK: Venue caching
    
//    func voteCountForVenue(venue: PFObject) -> Int {
//        let attributes: [NSObject: AnyObject]? = self.attributesForVenue(venue)
//        if attributes != nil {
//            return attributes![kVenueAttributesVoteCountKey] as! Int
//        }
//        
//        return 0
//    }
//    
//    func votersForVenue(venue: PFObject) -> [PFUser] {
//        let attributes = attributesForVenue(venue)
//        if attributes != nil {
//            return attributes![kVenueAttributesVotersKey] as! [PFUser]
//        }
//        
//        return [PFUser]()
//    }
    
    
    // MARK: User caching
    
    
    // MARK: ()
    
    func setAttributes(attributes: [String: AnyObject], forUser userId: String) {
        let key: String = self.keyForUser(userId)
        cache.setObject(attributes, forKey: key)
    }
    
    func keyForUser(userId: String) -> String {
        return "user_\(userId)"
    }
}