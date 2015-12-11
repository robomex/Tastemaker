//
//  VenueDetailsViewController.swift
//  GrandOpens
//
//  Created by Tony Morales on 7/29/15.
//  Copyright (c) 2015 Tony Morales. All rights reserved.
//

import UIKit
import Parse
import MapKit
import Contacts

class VenueDetailsViewController: UIViewController, MKMapViewDelegate, UITableViewDataSource, UITableViewDelegate {

    var venue: PFObject?
    let regionRadius: CLLocationDistance = 500
    var mapView: MKMapView!
    var mapItem: MKMapItem? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Description label
        
        let venueDescriptionLabel = UILabel(frame: CGRectMake(0, 0, 355, 80))
        venueDescriptionLabel.center = CGPointMake(UIScreen.mainScreen().bounds.width/2, 150)
        
        let venueDescription: String = venue!.objectForKey(kVenueDescription) as! String
        venueDescriptionLabel.text = venueDescription
        venueDescriptionLabel.textAlignment = NSTextAlignment.Left
        venueDescriptionLabel.font = UIFont.systemFontOfSize(17) //(name: "Muli", size: 17)
        venueDescriptionLabel.lineBreakMode = NSLineBreakMode.ByWordWrapping
        venueDescriptionLabel.numberOfLines = 2
        venueDescriptionLabel.sizeToFit()
        venueDescriptionLabel.backgroundColor = UIColor.whiteColor()
        self.view.addSubview(venueDescriptionLabel)
        
        // Opening date and food type label
        
        let venueFoodTypeAndOpeningDateLabel = UILabel(frame: CGRectMake(0, 0, 355, 40))
        venueFoodTypeAndOpeningDateLabel.center = CGPointMake(UIScreen.mainScreen().bounds.width/2, 175)
        
        let venueFoodType: String = venue!.objectForKey(kVenueFoodType) as! String
        let venueOpeningDate: NSDate = venue!.objectForKey(kVenueOpeningDate) as! NSDate
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "MMMM d"
        // Need to add a day in seconds since iOS is reading a 00:00 time as the previous day
        let OpeningDateString = dateFormatter.stringFromDate(venueOpeningDate.dateByAddingTimeInterval(60 * 60 * 24))
        venueFoodTypeAndOpeningDateLabel.text = venueFoodType + " - Opened " + OpeningDateString
        venueFoodTypeAndOpeningDateLabel.textAlignment = NSTextAlignment.Left
        venueFoodTypeAndOpeningDateLabel.font = UIFont.italicSystemFontOfSize(13.0) //UIFont(name: "Muli", size: 13)
        venueFoodTypeAndOpeningDateLabel.lineBreakMode = NSLineBreakMode.ByWordWrapping
        venueFoodTypeAndOpeningDateLabel.numberOfLines = 1
        venueFoodTypeAndOpeningDateLabel.sizeToFit()
        venueFoodTypeAndOpeningDateLabel.backgroundColor = UIColor.whiteColor()
        self.view.addSubview(venueFoodTypeAndOpeningDateLabel)
        
        // Map
        
        let mapView = MKMapView()
        mapView.mapType = .Standard
        mapView.delegate = self
        mapView.frame = CGRectMake(0, 0, UIScreen.mainScreen().bounds.width, 160)
        mapView.center = CGPointMake(UIScreen.mainScreen().bounds.width/2, 265)
        
        let venueAddress = venue!.objectForKey(kVenueAddress) as! String
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(venueAddress, completionHandler: {(placemarks, error) -> Void in
            if ((error) != nil) {
                print("Error", error)
            }
            if let placemark = placemarks?.first {
                let venueLocation: CLLocation = placemark.location!
                
                // Next three lines for Maps directions
                let addressDictionary = [String(CNPostalAddressStreetKey): self.venue?.objectForKey(kVenueName) as! String]
                let mapPlacemark = MKPlacemark(coordinate: venueLocation.coordinate, addressDictionary: addressDictionary)
                self.mapItem = MKMapItem(placemark: mapPlacemark)
                
                let coordinateRegion = MKCoordinateRegionMakeWithDistance(venueLocation.coordinate, self.regionRadius * 2.0, self.regionRadius * 2.0)
                mapView.setRegion(coordinateRegion, animated: false)
                
                // Add annotation pin
                let venuePin = MKPointAnnotation()
                venuePin.coordinate = venueLocation.coordinate
                mapView.addAnnotation(venuePin)
            }
        })
        self.view.addSubview(mapView)
        
        // Address and neighborhood
        
        let addressAndNeighborhoodTableView = UITableView()
        addressAndNeighborhoodTableView.frame = CGRectMake(0, 350, UIScreen.mainScreen().bounds.width, 80)
        addressAndNeighborhoodTableView.dataSource = self
        addressAndNeighborhoodTableView.delegate = self
        addressAndNeighborhoodTableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
        self.view.addSubview(addressAndNeighborhoodTableView)
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "cell")
        cell.textLabel?.text = venue!.objectForKey(kVenueAddress) as? String
        cell.detailTextLabel?.text = venue!.objectForKey(kVenueNeighborhood) as? String
        cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let alertController = UIAlertController(title: "Open the Maps app to navigate to this venue?", message: nil,
            //"Choose below to navigate to this venue in the Maps app", 
            preferredStyle: .Alert)
        alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: { (action: UIAlertAction!) in
            print("Cancel")
        }))
        alertController.addAction(UIAlertAction(title: "Open in Maps", style: UIAlertActionStyle.Default, handler: { (action: UIAlertAction!) in
            let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
            self.mapItem?.openInMapsWithLaunchOptions(launchOptions)
        }))
        UIApplication.sharedApplication().keyWindow?.rootViewController?.presentViewController(alertController, animated: true, completion: nil)
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
//    
//    func centerMapOnLocation(location: CLLocation) {
//        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, regionRadius * 2.0, regionRadius * 2.0)
//        mapView.setRegion(coordinateRegion, animated: true)
//    }
}