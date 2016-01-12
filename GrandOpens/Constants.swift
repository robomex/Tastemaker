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


// MARK: URLs
let kPrivacyPolicyURL = "https://www.apple.com"
let kTermsOfServiceURL = "https://www.google.com"


// MARK: Colors
let kBlue = UIColor(red: 0x22/255, green: 0xa7/255, blue: 0xf0/255, alpha: 1.0) // Picton Blue
let kRed = UIColor(red: 0xd9/255, green: 0x1e/255, blue: 0x18/255, alpha: 1.0) // Thunderbird
let kPurple = UIColor(red: 0x9b/255, green: 0x59/255, blue: 0xb6/255, alpha: 1.0) // Wisteria
let kGray = UIColor(red: 0x4a/255, green: 0x4a/255, blue: 0x4a/255, alpha: 1.0)


// MARK: Timeframes
let kStandardDaysOfOpeningsCovered = 47


// MARK: User Info Keys
let GOUserVotedUnvotedVenueNotificationUserInfoVotedKey         = "voted"
let GOUserSavedUnsavedVenueNotificationUserInfoSavedKey         = "saved"


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
let kVenuePhoneNumber                           = "phoneNumber"


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