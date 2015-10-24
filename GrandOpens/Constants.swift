//
//  Constants.swift
//  GrandOpens
//
//  Created by Tony Morales on 9/7/15.
//  Copyright (c) 2015 Tony Morales. All rights reserved.
//

import Foundation


// MARK: NSNotification
let GOUtilityUserVotedUnvotedVenueCallbackFinishedNotification  = "com.grandopens.utility.userVotedUnvotedVenueCallbackFinished"
let GOUtilityUserVotedUnvotedVenueNotification                  = "com.grandopens.utility.userVotedUnvotedVenueNotification"
let GOUtilityUserSavedUnsavedVenueNotification                  = "com.grandopens.utility.userSavedUnsavedVenueNotification"


// MARK: User Info Keys
let GOUserVotedUnvotedVenueNotificationUserInfoVotedKey         = "voted"


// MARK: Installation Class
let kGOInstallationKey                          = "user"


// MARK: Activity Class
// Class key
let kActivityClassKey                           = "Activity"

// Field keys
let kActivityByUserKey                          = "byUser"
let kActivityToObjectKey                        = "toObject"
let kActivityTypeKey                            = "type"

// Type values
let kActivityTypeVote                           = "vote"
let kActivityTypeSave                           = "save"
let kActivityTypeVisit                          = "visit"

// MARK: User Class
// Field keys
let kUserDisplayNameKey                         = "name"


// MARK: Venue Class
// Class key
let kVenueClassKey                              = "Venue"

// Field keys
let kVenueName                                  = "name"
let kVenueOpeningDate                           = "openingDate"
let kVenueAddress                               = "address"
let kVenueNeighborhood                          = "neighborhood"
let kVenueDescription                           = "description"
let kVenueFoodType                              = "foodType"
let kVenueLocation                              = "location"


// MARK: Cached Venue Attributes
// keys
let kVenueAttributesIsVotedByCurrentUserKey     = "isVotedByCurrentUser" //the example has a semicolon outside the trailing " - any reason for that?
let kVenueAttributesVoteCountKey                = "venueVoteCount"
let kVenueAttributesVotersKey                   = "voters"
let kVenueAttributesIsSavedByCurrentUserKey     = "isSavedByCurrentUser"
let kVenueAttributesIsVisitedByCurrentUserKey   = "isVisitedByCurrentUser"


// MARK: Cached User Attributes
// keys
let kUserAttributesVenueVoteCountKey            = "userVenueVoteCount"
let kUserAttributesIsFollowedByCurrentUserKey   = "isFollowedByCurrentUser"