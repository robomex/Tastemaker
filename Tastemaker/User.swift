//
//  User.swift
//  Tastemaker
//
//  Created by Tony Morales on 6/18/15.
//  Copyright (c) 2015 Tony Morales. All rights reserved.
//

import Foundation
import Firebase

struct User {
    let id: String
    let nickname: String
//    private let pfUser: PFUser
//    
//    func getProfilePhoto(callback:(UIImage) -> ()) {
//        let imageFile = pfUser.objectForKey(kUserProfilePicKey) as! PFFile
//        imageFile.getDataInBackgroundWithBlock({
//            data, error in
//            if let data = data {
//                callback(UIImage(data: data)!)
//            }
//        })
//    }
}

func snapshotToUser(snapshot: FIRDataSnapshot) -> User {
    let id = snapshot.key
    let nickname = snapshot.value!.objectForKey(kUserNicknameKey) as? String
    return User(id: id, nickname: nickname!)
}

//func pfUserToUser(user: PFUser) -> User {
//    return User(id: user.objectId!, name: user.objectForKey(kUserDisplayNameKey) as! String, pfUser: user)
//}
//
//func currentUser() -> User? {
//    if let user = PFUser.currentUser() {
//        return pfUserToUser(user)
//    }
//    return nil
//}