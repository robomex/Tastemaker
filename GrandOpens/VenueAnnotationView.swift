////
////  VenueAnnotationView.swift
////  GrandOpens
////
////  Created by Tony Morales on 3/26/16.
////  Copyright © 2016 Tony Morales. All rights reserved.
////
//
//import UIKit
//import MapKit
//
//class VenueAnnotationView: MKAnnotationView {
//
//    override init(annotation: MKAnnotation, reuseIdentifier: String) {
//        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
//        
//        let venueAnnotation = self.annotation as! VenueAnnotation
//        switch (venueAnnotation.type) {
//        case .VenueVisited:
//            image = UIImage(named: "Pin-Visited.png")
//        case .VenueFeatured:
//            image = UIImage(named: "Pin-Featured.png")
//        default:
//            image = UIImage(named: "Pin-Default.png")
//        }
//        
//        self.opaque = false
//        self.centerOffset = CGPointMake(0, -50)
//    }
//    
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//    }
//    
//    required init(coder aDecoder: NSCoder) {
//        super.init(coder: aDecoder)!
//    }
//}