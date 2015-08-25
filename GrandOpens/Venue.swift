//
//  Venue.swift
//  GrandOpens
//
//  Created by Tony Morales on 6/18/15.
//  Copyright (c) 2015 Tony Morales. All rights reserved.
//

import Foundation
import Parse

struct Venue {
    let id: String
    let name: String
    let openingDate: NSDate
    let address: String
    let neighborhood: String
    let description: String
    let foodType: String
}

func fetchVenues (callback: ([Venue]) -> ()) {
    
    let date = NSCalendar.currentCalendar().dateByAddingUnit(.CalendarUnitDay, value: -60, toDate: NSDate(), options: nil)!
    
    PFQuery(className: "Venue")
        .whereKey("openingDate", greaterThanOrEqualTo: date)
        .findObjectsInBackgroundWithBlock({
            objects, error in
            
            if let venues = objects as? [PFObject] {
                let fetchedVenues = venues.map({
                    (object: PFObject) -> (venueId: String, venueName: String, venueOpeningDate: NSDate, venueAddress: String, venueNeighborhood: String, venueDescription: String, venueFoodType: String) in
                    (object.objectId! as String, object.objectForKey("name") as! String, object.objectForKey("openingDate") as! NSDate, object.objectForKey("address") as! String, object.objectForKey("neighborhood") as! String, object.objectForKey("description") as! String, object.objectForKey("foodType") as! String)
                })
                
                var v: [Venue] = []
                for (index, venue) in enumerate(fetchedVenues) {
                    v.append(Venue(id: fetchedVenues[index].venueId, name: fetchedVenues[index].venueName, openingDate: fetchedVenues[index].venueOpeningDate, address: fetchedVenues[index].venueAddress, neighborhood: fetchedVenues[index].venueNeighborhood, description: fetchedVenues[index].venueDescription, foodType: fetchedVenues[index].venueFoodType))
                }
                callback(v)
            }
        })
}