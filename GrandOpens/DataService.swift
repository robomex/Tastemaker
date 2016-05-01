//
//  DataService.swift
//  GrandOpens
//
//  Created by Tony Morales on 2/3/16.
//  Copyright © 2016 Tony Morales. All rights reserved.
//

import Foundation
import Firebase

class DataService {
    static let dataService = DataService()
    
    private var _BASE_REF = Firebase(url: "\(BASE_URL)")
    private var _USERS_PUBLIC_REF = Firebase(url: "\(BASE_URL)/users/public")
    private var _USERS_PRIVATE_REF = Firebase(url: "\(BASE_URL)/users/private")
    private var _VENUES_REF = Firebase(url: "\(BASE_URL)/venues")
    private var _USER_ACTIVITIES_REF = Firebase(url: "\(BASE_URL)/userActivities")
    private var _VENUE_ACTIVITIES_REF = Firebase(url: "\(BASE_URL)/venueActivities")
    private var _MESSAGES_REF = Firebase(url: "\(BASE_URL)/messages")
    private var _LISTS_REF = Firebase(url: "\(BASE_URL)/lists")
    
    var BASE_REF: Firebase {
        return _BASE_REF
    }
    
    var USERS_PUBLIC_REF: Firebase {
        return _USERS_PUBLIC_REF
    }
    
    var USERS_PRIVATE_REF: Firebase {
        return _USERS_PRIVATE_REF
    }
    
    var CURRENT_USER_PUBLIC_REF: Firebase {
        let userID = NSUserDefaults.standardUserDefaults().valueForKey("uid") as! String
        let currentPublicUser = Firebase(url: "\(USERS_PUBLIC_REF)").childByAppendingPath(userID)
        
        return currentPublicUser!
    }
    
    var CURRENT_USER_PRIVATE_REF: Firebase {
        let userID = NSUserDefaults.standardUserDefaults().valueForKey("uid") as! String
        let currentPrivateUser = Firebase(url: "\(USERS_PRIVATE_REF)").childByAppendingPath(userID)
        
        return currentPrivateUser!
    }
    
    var MESSAGES_REF: Firebase {
        return _MESSAGES_REF
    }
    
    var LISTS_REF: Firebase {
        return _LISTS_REF
    }
    
    var VENUES_REF: Firebase {
        return _VENUES_REF
    }
    
    var USER_ACTIVITIES_REF: Firebase {
        return _USER_ACTIVITIES_REF
    }
    
    var VENUE_ACTIVITIES_REF: Firebase {
        return _VENUE_ACTIVITIES_REF
    }
    
    func createNewPrivateAccount(uid: String, user: Dictionary<String, String>) {
        USERS_PRIVATE_REF.childByAppendingPath(uid).setValue(user)
    }
    
    func createNewPublicAccount(uid: String, publicUser: Dictionary<String, String>) {
        USERS_PUBLIC_REF.childByAppendingPath(uid).setValue(publicUser)
    }
}