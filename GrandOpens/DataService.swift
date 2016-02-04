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
    private var _USERS_REF = Firebase(url: "\(BASE_URL)/users")
    private var _VENUES_REF = Firebase(url: "\(BASE_URL)/venues")
    private var _USER_ACTIVITIES_REF = Firebase(url: "\(BASE_URL)/userActivities")
    private var _VENUE_ACTIVITIES_REF = Firebase(url: "\(BASE_URL)/venueActivities")
    
    var BASE_REF: Firebase {
        return _BASE_REF
    }
    
    var USERS_REF: Firebase {
        return _USERS_REF
    }
    
    var CURRENT_USER_REF: Firebase {
        let userID = NSUserDefaults.standardUserDefaults().valueForKey("uid") as! String
        let currentUser = Firebase(url: "\(USERS_REF)").childByAppendingPath(userID)
        
        return currentUser!
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
    
    func createNewAccount(uid: String, user: Dictionary<String, String>) {
        USERS_REF.childByAppendingPath(uid).setValue(user)
    }
}