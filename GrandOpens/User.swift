//
//  User.swift
//  GrandOpens
//
//  Created by Tony Morales on 6/18/15.
//  Copyright (c) 2015 Tony Morales. All rights reserved.
//

import Foundation
import Parse

struct User {
    let id: String
    let name: String
    private let pfUser: PFUser
}

func pfUserToUser(user: PFUser) -> User {
    return User(id: user.objectId!, name: user.objectForKey("name") as! String, pfUser: user)
}

func currentUser() -> User? {
    if let user = PFUser.currentUser() {
        return pfUserToUser(user)
    }
    return nil
}

func saveVenueVote(venueId: String) {
    
    let vote = PFObject(className: "Activity")
    vote.setObject(PFUser.currentUser()!.objectId!, forKey: "byUser")
    vote.setObject(venueId, forKey: "toObject")
    vote.setObject("venueVote", forKey: "type")
    vote.saveInBackgroundWithBlock(nil)
    
    PFQuery(className: "Venue")
        .getObjectInBackgroundWithId(venueId) {
            (retrievedVenue: PFObject?, error: NSError?) -> Void in
            if error != nil {
                print(error)
            } else {
                retrievedVenue?.incrementKey("votes", byAmount: 1)
            }
            
            retrievedVenue?.saveInBackground()
        }
}
