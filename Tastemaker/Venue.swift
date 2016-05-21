//
//  Venue.swift
//  Tastemaker
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
    let website: String?
}

private let openingDateFormat = "yyyy-MM-dd"

class VenueListener {

    var currentHandle: UInt?
    
    init (endDate: NSDate, callback: ([Venue]) -> ()) {
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
                    venues.insert(featuredVenue, atIndex: 0)
                }
                callback(venues)
            })
        })
        self.currentHandle = handle
    }
    
    func stop() {
        if let handle = currentHandle {
            DataService.dataService.VENUES_REF.removeObserverWithHandle(handle)
            currentHandle = nil
        }
    }
}

func openingDateFormatter() -> NSDateFormatter {
    let openingDateFormatter = NSDateFormatter()
    openingDateFormatter.dateFormat = openingDateFormat
    return openingDateFormatter
}

func snapshotToVenue(snapshot: FDataSnapshot) -> Venue {
    let objectId = snapshot.key
    let name = snapshot.value.objectForKey(kVenueName) as? String
    let openingDate = snapshot.value.objectForKey(kVenueOpeningDate) as? String
    let latitude = snapshot.value.objectForKey(kVenueLatitude) as? Double
    let longitude = snapshot.value.objectForKey(kVenueLongitude) as? Double
    let address = snapshot.value.objectForKey(kVenueAddress) as? String
    let neighborhood = snapshot.value.objectForKey(kVenueNeighborhood) as? String
    let phoneNumber = snapshot.value.objectForKey(kVenuePhoneNumber) as? String
    let foodType = snapshot.value.objectForKey(kVenueFoodType) as? String
    let description = snapshot.value.objectForKey(kVenueDescription) as? String
    let website = snapshot.value.objectForKey(kVenueWebsite) as? String
    return Venue(objectId: objectId, name: name, openingDate: openingDate, address: address, latitude: latitude, longitude: longitude, neighborhood: neighborhood, phoneNumber: phoneNumber, foodType: foodType, description: description, website: website)
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
private let websiteKey = "website"

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
        descriptionKey: venue.description!,
        websiteKey: venue.website!
    ]
}

func deserializeVenue(dictionary: Dictionary <String, AnyObject>) -> Venue {
    return Venue(objectId: (dictionary[objectIdKey] as! String), name: (dictionary[nameKey] as! String), openingDate: (dictionary[openingDateKey] as! String), address: (dictionary[addressKey] as! String), latitude: (dictionary[latitudeKey] as! Double), longitude: (dictionary[longitudeKey] as! Double), neighborhood: (dictionary[neighborhoodKey] as! String), phoneNumber: (dictionary[phoneNumberKey] as! String), foodType: (dictionary[foodTypeKey] as! String), description: (dictionary[descriptionKey] as! String), website: (dictionary[websiteKey] as! String))
}