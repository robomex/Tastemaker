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
    let objectId: String?
    let name: String?
    let openingDate: String?
    let address: String?
    let latitude: Double?
    let longitude: Double?
    let neighborhood: String?
    let phoneNumber: String?
    var foodType: String?
    let description: String?
}

private let openingDateFormat = "yyyy-MM-dd"

class VenueListener {
//    var currentChildAddedHandle: UInt?
//    var currentChildChangedHandle: UInt?
//    var currentChildRemovedHandle: UInt?
    var currentHandle: UInt?
    
    init (//startDate: NSDate,
        endDate: NSDate, callback: ([Venue]) -> ()) {
            let handle = DataService.dataService.VENUES_REF.queryOrderedByChild(kVenueOpeningDate).queryEndingAtValue(openingDateFormatter().stringFromDate(endDate)).queryStartingAtValue(openingDateFormatter().stringFromDate(NSCalendar.currentCalendar().dateByAddingUnit(NSCalendarUnit.Day, value: -(kStandardDaysOfOpeningsCovered), toDate: endDate, options: [])!)).observeEventType(FEventType.Value, withBlock: {
                snapshot in
                var venues = Array<Venue>()
                let enumerator = snapshot.children
                
                while let data = enumerator.nextObject() as? FDataSnapshot {
                    venues.insert(snapshotToVenue(data), atIndex: 0)
                }
                
                DataService.dataService.VENUES_REF.queryOrderedByChild("featured").queryEqualToValue(true).observeSingleEventOfType(.Value, withBlock: {
                    snap in
                    
                    let enumerator = snap.children
                    let reversed = enumerator.reverse()
                    for features in reversed {
                        var featuredVenue: Venue = snapshotToVenue(features as! FDataSnapshot)
                        featuredVenue.foodType = "Featured"
                        venues.insert(featuredVenue, atIndex: 3)
                    }
                    callback(venues)
                })
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
            DataService.dataService.VENUES_REF.removeObserverWithHandle(handle)
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

func openingDateFormatter() -> NSDateFormatter {
    let openingDateFormatter = NSDateFormatter()
    openingDateFormatter.dateFormat = openingDateFormat
    return openingDateFormatter
}

func snapshotToVenue(snapshot: FDataSnapshot) -> Venue {
    let objectId = snapshot.key
    let name = snapshot.value[kVenueName] as? String
    let openingDate = snapshot.value[kVenueOpeningDate] as? String
    let latitude = snapshot.value[kVenueLatitude] as? Double
    let longitude = snapshot.value[kVenueLongitude] as? Double
    let address = snapshot.value[kVenueAddress] as? String
    let neighborhood = snapshot.value[kVenueNeighborhood] as? String
    let phoneNumber = snapshot.value[kVenuePhoneNumber] as? String
    let foodType = snapshot.value[kVenueFoodType] as? String
    let description = snapshot.value[kVenueDescription] as? String
    return Venue(objectId: objectId, name: name, openingDate: openingDate, address: address, latitude: latitude, longitude: longitude, neighborhood: neighborhood, phoneNumber: phoneNumber, foodType: foodType, description: description)
}

private let objectIdKey = "objectId"
private let nameKey = "name"
private let openingDateKey = "openingDate"
private let latitudeKey = "latitude"
private let longitudeKey = "longitude"
private let addressKey = "address"
private let neighborhoodKey = "neighborhood"
private let phoneNumberKey = "phoneNumber"
private let foodTypeKey = "foodType"
private let descriptionKey = "description"

func serializeVenue(venue: Venue) -> Dictionary <String, AnyObject> {
    return [
        objectIdKey: venue.objectId!,
        nameKey: venue.name!,
        openingDateKey: venue.openingDate!,
        latitudeKey: venue.latitude!,
        longitudeKey: venue.longitude!,
        addressKey: venue.address!,
        neighborhoodKey: venue.neighborhood!,
        phoneNumberKey: venue.phoneNumber!,
        foodTypeKey: venue.foodType!,
        descriptionKey: venue.description!
    ]
}

func deserializeVenue(dictionary: Dictionary <String, AnyObject>) -> Venue {
    return Venue(objectId: (dictionary[objectIdKey] as! String), name: (dictionary[nameKey] as! String), openingDate: (dictionary[openingDateKey] as! String), address: (dictionary[addressKey] as! String), latitude: (dictionary[latitudeKey] as! Double), longitude: (dictionary[longitudeKey] as! Double), neighborhood: (dictionary[neighborhoodKey] as! String), phoneNumber: (dictionary[phoneNumberKey] as! String), foodType: (dictionary[foodTypeKey] as! String), description: (dictionary[descriptionKey] as! String))
}