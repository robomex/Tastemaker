//
//  VenueAnnotation.swift
//  GrandOpens
//
//  Created by Tony Morales on 3/26/16.
//  Copyright © 2016 Tony Morales. All rights reserved.
//

import UIKit
import MapKit

enum VenueType: Int {
    case VenueDefault = 0
    case VenueVisited
    case VenueFeatured
}

class VenueAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    var type: VenueType
    var venue: Venue
    
    init(coordinate: CLLocationCoordinate2D, title: String, subtitle: String, type: VenueType, venue: Venue) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        self.type = type
        self.venue = venue
    }
}