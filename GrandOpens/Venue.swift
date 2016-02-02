//
//  Venue.swift
//  GrandOpens
//
//  Created by Tony Morales on 6/18/15.
//  Copyright (c) 2015 Tony Morales. All rights reserved.
//

import Foundation
import Firebase

struct Venue {
    let name: String?
    let openingDate: String?
    let address: String?
//    let lat: String
//    let long: String
    let neighborhood: String?
    let phoneNumber: String?
    let foodType: String?
    let description: String?
}

class VenueListener {
//    var currentChildAddedHandle: UInt?
//    var currentChildChangedHandle: UInt?
//    var currentChildRemovedHandle: UInt?
    var currentHandle: UInt?
    
    init (//startDate: NSDate,
        endDate: NSDate, callback: ([Venue]) -> ()) {
            let handle = ref.queryOrderedByChild(kVenueOpeningDate).queryEndingAtValue(dateFormatter().stringFromDate(endDate)).queryStartingAtValue(dateFormatter().stringFromDate(NSCalendar.currentCalendar().dateByAddingUnit(NSCalendarUnit.Day, value: -(kStandardDaysOfOpeningsCovered), toDate: endDate, options: [])!)).observeEventType(FEventType.Value, withBlock: { snapshot in
                var venues = Array<Venue>()
                let enumerator = snapshot.children
                
                while let data = enumerator.nextObject() as? FDataSnapshot {
                    venues.append(snapshotToVenue(data))
                }
                print(venues)
                callback(venues)
            })
            self.currentHandle = handle
//        let childAddedHandle = ref.queryOrderedByChild(kVenueOpeningDate).queryStartingAtValue(dateFormatter().stringFromDate(startDate)).queryEndingAtValue(dateFormatter().stringFromDate(endDate)).observeEventType(FEventType.ChildAdded, withBlock: { snapshot in
//            let venue = snapshotToVenue(snapshot)
//            callback(venue)
//        })
//        self.currentChildAddedHandle = childAddedHandle
//        
//        let childChangedHandle = ref.queryOrderedByChild(kVenueOpeningDate).queryStartingAtValue(dateFormatter().stringFromDate(startDate)).queryEndingAtValue(dateFormatter().stringFromDate(endDate)).observeEventType(FEventType.ChildChanged, withBlock: { snapshot in
//            let venue = snapshotToVenue(snapshot)
//            callback(venue)
//        })
//        self.currentChildChangedHandle = childChangedHandle
//        
//        let childRemovedHandle = ref.queryOrderedByChild(kVenueOpeningDate).queryStartingAtValue(dateFormatter().stringFromDate(startDate)).queryEndingAtValue(dateFormatter().stringFromDate(endDate)).observeEventType(FEventType.ChildRemoved, withBlock: { snapshot in
//            let venue = snapshotToVenue(snapshot)
//            callback(venue)
//        })
//        self.currentChildRemovedHandle = childRemovedHandle
    }
    func stop() {
        if let handle = currentHandle {
            ref.removeObserverWithHandle(handle)
            currentHandle = nil
        }
//        if let addHandle = currentChildAddedHandle {
//            ref.removeObserverWithHandle(addHandle)
//            currentChildAddedHandle = nil
//        }
//        if let changeHandle = currentChildChangedHandle {
//            ref.removeObserverWithHandle(changeHandle)
//            currentChildChangedHandle = nil
//        }
//        if let removeHandle = currentChildRemovedHandle {
//            ref.removeObserverWithHandle(removeHandle)
//            currentChildRemovedHandle = nil
//        }
    }
}

private let ref = Firebase(url: "https://grandopens.firebaseio.com/venues")
private let dateFormat = "yyyy-MM-dd"

private func dateFormatter() -> NSDateFormatter {
    let dateFormatter = NSDateFormatter()
    dateFormatter.dateFormat = dateFormat
    return dateFormatter
}

private func snapshotToVenue(snapshot: FDataSnapshot) -> Venue {
    let name = snapshot.value.objectForKey(kVenueName) as? String
    let openingDate = snapshot.value.objectForKey(kVenueOpeningDate) as? String
    //let openingDate = dateFormatter().dateFromString(snapshot.value.objectForKey(kVenueOpeningDate))//unformattedDate!)
//    let openingDate = dateFormatter().dateFromString(unformattedDate!)
    let address = snapshot.value.objectForKey(kVenueAddress) as? String
    let neighborhood = snapshot.value.objectForKey(kVenueNeighborhood) as? String
    let phoneNumber = snapshot.value.objectForKey(kVenuePhoneNumber) as? String
    let foodType = snapshot.value.objectForKey(kVenueFoodType) as? String
    let description = snapshot.value.objectForKey(kVenueDescription) as? String
    return Venue(name: name, openingDate: openingDate, address: address, neighborhood: neighborhood, phoneNumber: phoneNumber, foodType: foodType, description: description)
}








