//
//  VenueSorter.swift
//  GrandOpens
//
//  Created by Tony Morales on 2/11/16.
//  Copyright © 2016 Tony Morales. All rights reserved.
//

import Foundation

class VenueSorter {
    
    func sortVenuesByDistanceFromLocation(venueArray: [Venue], location: CLLocation) -> [Venue] {
        let sortedArray = venueArray.sort { (a: Venue, b: Venue) -> Bool in
            let dist1 = location.distanceFromLocation(CLLocation(latitude: a.latitude!, longitude: a.longitude!))
            let dist2 = location.distanceFromLocation(CLLocation(latitude: b.latitude!, longitude: b.longitude!))
            return dist1 < dist2
        }
        return sortedArray
    }
}