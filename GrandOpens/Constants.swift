//
//  Constants.swift
//  GrandOpens
//
//  Created by Tony Morales on 9/7/15.
//  Copyright (c) 2015 Tony Morales. All rights reserved.
//

import Foundation


// MARK: User Class
// Field keys
let kUserDisplayNameKey                         = "name"


// MARK: Venue Class
// Field keys
let kVenueName                                  = "name"
let kVenueAddress                               = "address"
let kVenueNeighborhood                          = "neighborhood"
let kVenueDescription                           = "description"
let kVenueFoodType                              = "foodType"


// MARK: Activity Class
// Field keys
let kActivityByUserKey                          = "byUser"
let kActivityToObjectKey                        = "toObject"
let kActivityType                               = "type"

// Type values
let kActivityTypeVote                           = "vote"


// MARK: Cached Venue Attributes
// keys
let kVenueAttributesIsVotedByCurrentUserKey     = "isVotedByCurrentUser" //the example has a semicolon outside the trailing " - any reason for that?
let kVenueAttributesVoteCountKey                = "venueVoteCount"
let kVenueAttributesVotersKey                   = "voters"


// MARK: Cached User Attributes
// keys
let kUserAttributesVenueVoteCountKey            = "userVenueVoteCount"
let kUserAttributesIsFollowedByCurrentUserKey   = "isFollowedByCurrentUser"