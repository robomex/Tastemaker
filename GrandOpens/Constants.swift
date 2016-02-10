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
let kPrivacyPolicyURL =     "https://grandopens.com/privacy"
let kTermsOfServiceURL =    "https://grandopens.com/terms"
let kResetEmailURL =        "https://google.com"
let BASE_URL =              "https://grandopens.firebaseio.com"


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


// MARK: User Activity Class
// Class key
let kUserActivityClassKey                       = "UserActivity"

// Field keys
let kUserActivityByUserKey                      = "byUser"
let kUserActivityToUserKey                      = "toUser"
let kUserActivityTypeKey                        = "type"

// Type values
let kUserActivityTypeMute                       = "mute"


// MARK: Activity Class
// Class key
let kVenueActivityClassKey                      = "VenueActivity"

// Field keys
let kVenueActivityByUserKey                     = "byUser"
let kVenueActivityToVenueKey                    = "toVenue"
let kVenueActivityTypeKey                       = "type"

// Type values
let kVenueActivityTypeVote                      = "vote"
let kVenueActivityTypeSave                      = "save"
let kVenueActivityTypeVisit                     = "visit"


// MARK: User Class
// Class key
let kUserClassKey                               = "User"

// Field keys
let kUserNicknameKey                            = "nickname"
let kUserProfilePicKey                          = "profilePicture"
let kUserProfilePicSmallKey                     = "profilePictureSmall"


// MARK: Venue Class
// Class key
let kVenueClassKey                              = "Venue"

// Field keys
let kVenueName                                  = "name"
let kVenueOpeningDate                           = "openingDate"
let kVenueAddress                               = "address"
let kVenueNeighborhood                          = "neighborhood"
//let kVenueLat                                   = "lat"
//let kVenueLong                                  = "long"
let kVenuePhoneNumber                           = "phoneNumber"
let kVenueFoodType                              = "foodType"
let kVenueDescription                           = "description"
// Remove the below after sorting out Geo in Firebase
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
let kUserAttributesIsMutedByCurrentUserKey      = "isMutedByCurrentUser"