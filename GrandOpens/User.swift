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
    
    func getProfilePhoto(callback:(UIImage) -> ()) {
        let imageFile = pfUser.objectForKey(kUserProfilePicKey) as! PFFile
        imageFile.getDataInBackgroundWithBlock({
            data, error in
            if let data = data {
                callback(UIImage(data: data)!)
            }
        })
    }
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