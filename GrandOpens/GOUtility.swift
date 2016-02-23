//
//  GOUtility.swift
//  GrandOpens
//
//  Created by Tony Morales on 9/12/15.
//  Copyright (c) 2015 Tony Morales. All rights reserved.
//

import Foundation
import MapKit

class GOUtility {
    
    
    // MARK: GOUtility
    
    
    // MARK: Vote Venues
    
    
    // MARK: Save Venues
    
    
    // MARK: Activities
    
    
    // MARK: Profile Pics
    
//    class func userHasProfilePicture(user: PFUser) -> Bool {
//        let profilePicture: PFFile? = user.objectForKey(kUserProfilePicKey) as? PFFile
//        let profilePictureSmall: PFFile? = user.objectForKey(kUserProfilePicSmallKey) as? PFFile
//        
//        return profilePicture != nil && profilePictureSmall != nil
//    }
    
    class func defaultProfilePicture() -> UIImage? {
        return UIImage(named: "AvatarPlaceholder.png")
    }
    
    
    // MARK: User Muting
    
}


// MARK: ()

func showSimpleAlertWithTitle(title: String!, message: String, actionTitle: String, viewController: UIViewController) {
    let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
    let action = UIAlertAction(title: actionTitle, style: .Default, handler: nil)
    alert.addAction(action)
    viewController.presentViewController(alert, animated: true, completion: nil)
}

let dateFormat = "yyyy-MM-dd HH:mm:ss ZZZZ"
func dateFormatter() -> NSDateFormatter {
    let dateFormatter = NSDateFormatter()
    dateFormatter.timeZone = NSTimeZone(abbreviation: "UTC")
    dateFormatter.dateFormat = dateFormat
    return dateFormatter
}

let localDateFormat = "yyyy-MM-dd"
func localDateFormatter() -> NSDateFormatter {
    let localDateFormatter = NSDateFormatter()
    localDateFormatter.timeZone = NSTimeZone.localTimeZone()
    localDateFormatter.dateFormat = localDateFormat
    return localDateFormatter
}

func delay(delay: Double, closure: () -> ()) {
    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            Int64(delay * Double(NSEC_PER_SEC))
        ),
        dispatch_get_main_queue(), closure
    )
}

// May NOT want to use nscalendar.currentCalendar(). below - I initially tried to not use it to prevent changes to/from local time, but had to due to errors
extension NSDate {
    func yearsFrom(date: NSDate) -> Int {
        return NSCalendar.currentCalendar().components(NSCalendarUnit.Year, fromDate: date, toDate: self, options: []).year
    }
    
    func monthsFrom(date: NSDate) -> Int {
        return NSCalendar.currentCalendar().components(NSCalendarUnit.Month, fromDate: date, toDate: self, options: []).month
    }
    
    func weeksFrom(date: NSDate) -> Int {
        return NSCalendar.currentCalendar().components(NSCalendarUnit.WeekOfYear, fromDate: date, toDate: self, options: []).weekOfYear
    }
    
    func daysFrom(date: NSDate) -> Int {
        return NSCalendar.currentCalendar().components(NSCalendarUnit.Day, fromDate: date, toDate: self, options: []).day
    }
    
    func hoursFrom(date: NSDate) -> Int {
        return NSCalendar.currentCalendar().components(NSCalendarUnit.Hour, fromDate: date, toDate: self, options: []).hour
    }
    
    func minutesFrom(date: NSDate) -> Int {
        return NSCalendar.currentCalendar().components(NSCalendarUnit.Minute, fromDate: date, toDate: self, options: []).minute
    }
    
    func secondsFrom(date: NSDate) -> Int {
        return NSCalendar.currentCalendar().components(NSCalendarUnit.Second, fromDate: date, toDate: self, options: []).second
    }
    
    func offsetFrom(date: NSDate) -> String {
        if yearsFrom(date)  > 0 { return "\(yearsFrom(date))y"  }
        if monthsFrom(date) > 0 { return "\(monthsFrom(date))M" }
        if weeksFrom(date)  > 0 { return "\(weeksFrom(date))w"  }
        if daysFrom(date)   > 0 { return "\(daysFrom(date))d"   }
        if hoursFrom(date)  > 0 { return "\(hoursFrom(date))h"  }
        if minutesFrom(date) > 0 { return "\(minutesFrom(date))m"}
        if secondsFrom(date) > 0 { return "\(secondsFrom(date))s"}
        return ""
    }
}

// Below may be useful after adding MapKit

func zoomToUserLocationInMapView(mapView: MKMapView) {
    if let coordinate = mapView.userLocation.location?.coordinate {
        let region = MKCoordinateRegionMakeWithDistance(coordinate, 10000, 10000)
        mapView.setRegion(region, animated: true)
    }
}