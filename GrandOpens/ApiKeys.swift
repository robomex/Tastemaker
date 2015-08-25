//
//  ApiKeys.swift
//  GrandOpens
//
//  Created by Tony Morales on 6/8/15.
//  Copyright (c) 2015 Tony Morales. All rights reserved.
//

import Foundation

func valueForAPIKey(keyname: String) -> String {
    let filePath = NSBundle.mainBundle().pathForResource("ApiKeys", ofType: "plist")
    let plist = NSDictionary(contentsOfFile: filePath!)
    
    let value: String = plist?.objectForKey(keyname) as! String
    return value
}