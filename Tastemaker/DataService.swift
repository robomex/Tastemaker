//
//  DataService.swift
//  Tastemaker
//
//  Created by Tony Morales on 2/3/16.
//  Copyright © 2016 Tony Morales. All rights reserved.
//

import Foundation
import Firebase

class DataService {
    static let dataService = DataService()
    
    private var _BASE_REF = FIRDatabase.database().reference()
    private var _USERS_PUBLIC_REF = FIRDatabase.database().reference().child("users").child("public")
    private var _USERS_PRIVATE_REF = FIRDatabase.database().reference().child("users").child("private")
    private var _VENUES_REF = FIRDatabase.database().reference().child("venues")
    private var _USER_ACTIVITIES_REF = FIRDatabase.database().reference().child("userActivities")
    private var _VENUE_ACTIVITIES_REF = FIRDatabase.database().reference().child("venueActivities")
    private var _MESSAGES_REF = FIRDatabase.database().reference().child("messages")
    private var _LISTS_REF = FIRDatabase.database().reference().child("lists")
    
    var BASE_REF: FIRDatabaseReference {
        return _BASE_REF
    }
    
    var USERS_PUBLIC_REF: FIRDatabaseReference {
        return _USERS_PUBLIC_REF
    }
    
    var USERS_PRIVATE_REF: FIRDatabaseReference {
        return _USERS_PRIVATE_REF
    }
    
    var CURRENT_USER_PUBLIC_REF: FIRDatabaseReference {
        let userID = NSUserDefaults.standardUserDefaults().valueForKey("uid") as! String
        let currentPublicUser = FIRDatabase.database().reference().child("users").child("public").child(userID)
        
        return currentPublicUser
    }
    
    var CURRENT_USER_PRIVATE_REF: FIRDatabaseReference {
        let userID = NSUserDefaults.standardUserDefaults().valueForKey("uid") as! String
        let currentPrivateUser = FIRDatabase.database().reference().child("users").child("private").child(userID)
        
        return currentPrivateUser
    }
    
    var MESSAGES_REF: FIRDatabaseReference {
        return _MESSAGES_REF
    }
    
    var LISTS_REF: FIRDatabaseReference {
        return _LISTS_REF
    }
    
    var VENUES_REF: FIRDatabaseReference {
        return _VENUES_REF
    }
    
    var USER_ACTIVITIES_REF: FIRDatabaseReference {
        return _USER_ACTIVITIES_REF
    }
    
    var VENUE_ACTIVITIES_REF: FIRDatabaseReference {
        return _VENUE_ACTIVITIES_REF
    }
    
    func createNewPrivateAccount(uid: String, user: Dictionary<String, String>) {
        USERS_PRIVATE_REF.child(uid).setValue(user)
    }
    
    func createNewPublicAccount(uid: String, publicUser: Dictionary<String, String>) {
        USERS_PUBLIC_REF.child(uid).setValue(publicUser)
    }
}