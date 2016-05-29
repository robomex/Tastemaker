//
//  VenueDetailsViewController.swift
//  Tastemaker
//
//  Created by Tony Morales on 7/29/15.
//  Copyright (c) 2015 Tony Morales. All rights reserved.
//

import UIKit
import MapKit
import Contacts
import Amplitude_iOS
import SafariServices
import Firebase
import MessageUI

class VenueDetailsViewController: UIViewController, MKMapViewDelegate, UITableViewDataSource, UITableViewDelegate, SFSafariViewControllerDelegate, MFMessageComposeViewControllerDelegate {

    var venue: Venue?
    let regionRadius: CLLocationDistance = 500
    var mapView = MKMapView()
    var mapItem: MKMapItem? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Description label
        
        let venueDescriptionLabel = UILabel(frame: CGRectMake(0, 0, UIScreen.mainScreen().bounds.width - 20, 80))
        venueDescriptionLabel.center = CGPointMake(UIScreen.mainScreen().bounds.width/2, 50)
        
        let venueDescription: String = (venue?.description)!
        venueDescriptionLabel.text = venueDescription
        venueDescriptionLabel.textAlignment = NSTextAlignment.Left
        venueDescriptionLabel.font = UIFont.systemFontOfSize(17)
        venueDescriptionLabel.lineBreakMode = NSLineBreakMode.ByWordWrapping
        venueDescriptionLabel.numberOfLines = 2
        venueDescriptionLabel.sizeToFit()
        venueDescriptionLabel.backgroundColor = UIColor.whiteColor()
        view.addSubview(venueDescriptionLabel)
        
        // Opening date and food type label
        
        let venueFoodTypeAndOpeningDateLabel = UILabel(frame: CGRectMake(0, 0, UIScreen.mainScreen().bounds.width - 20, 40))
        venueFoodTypeAndOpeningDateLabel.center = CGPointMake(UIScreen.mainScreen().bounds.width/2, 75)
        
        let venueFoodType: String = (venue?.foodType)!
        let venueOpeningDate: String = (venue?.openingDate)!
        let expandedOpeningDateFormatter = NSDateFormatter()
        expandedOpeningDateFormatter.dateFormat = "yyyy-MM-dd"
        let date = expandedOpeningDateFormatter.dateFromString(venueOpeningDate)
        expandedOpeningDateFormatter.dateFormat = "MMMM d"
        let OpeningDateString = expandedOpeningDateFormatter.stringFromDate(date!)
        
        venueFoodTypeAndOpeningDateLabel.text = venueFoodType + " - Opened " + OpeningDateString
        venueFoodTypeAndOpeningDateLabel.textAlignment = NSTextAlignment.Left
        venueFoodTypeAndOpeningDateLabel.font = UIFont.italicSystemFontOfSize(13.0)
        venueFoodTypeAndOpeningDateLabel.lineBreakMode = NSLineBreakMode.ByWordWrapping
        venueFoodTypeAndOpeningDateLabel.numberOfLines = 1
        venueFoodTypeAndOpeningDateLabel.sizeToFit()
        venueFoodTypeAndOpeningDateLabel.backgroundColor = UIColor.whiteColor()
        view.addSubview(venueFoodTypeAndOpeningDateLabel)
        
        // Map
        
        mapView.mapType = .Standard
        mapView.delegate = self
        mapView.frame = CGRectMake(0, 0, UIScreen.mainScreen().bounds.width, 160)
        mapView.center = CGPointMake(UIScreen.mainScreen().bounds.width/2, 165)
        
        // Show user location on map if location services are .AuthorizedAlways
        if CLLocationManager.authorizationStatus() == .AuthorizedAlways {
            mapView.showsUserLocation = true
        }
        
        let venueLocation: CLLocation = CLLocation(latitude: self.venue!.latitude!, longitude: self.venue!.longitude!)
        
        // Next three lines for Maps directions
        let addressDictionary = [String(CNPostalAddressStreetKey): self.venue?.name as String!]
        let mapPlacemark = MKPlacemark(coordinate: venueLocation.coordinate, addressDictionary: addressDictionary)
        mapItem = MKMapItem(placemark: mapPlacemark)
        
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(venueLocation.coordinate, regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: false)
        
        // Add annotation pin
        let venuePin = MKPointAnnotation()
        venuePin.coordinate = venueLocation.coordinate
        mapView.addAnnotation(venuePin)
        view.addSubview(mapView)
        
        // Address, neighborhood, phone number, and website label
        
        let addressNeighborhoodPhoneTableView = UITableView()
        addressNeighborhoodPhoneTableView.frame = CGRectMake(0, 250, UIScreen.mainScreen().bounds.width, 176)
        addressNeighborhoodPhoneTableView.dataSource = self
        addressNeighborhoodPhoneTableView.delegate = self
        addressNeighborhoodPhoneTableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
        addressNeighborhoodPhoneTableView.scrollEnabled = false
        view.addSubview(addressNeighborhoodPhoneTableView)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        if isMovingFromParentViewController() {
            mapItem = nil
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch (indexPath.row) {
        case 0:
            let cell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "cell")
            cell.textLabel?.text = venue?.address
            cell.detailTextLabel?.text = venue?.neighborhood
            cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
            return cell
        case 1:
            let cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "cell")
            cell.textLabel?.text = venue?.phoneNumber ?? "Phone Number Not Found"
            cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
            return cell
        case 2:
            let cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "cell")
            cell.textLabel?.text = venue?.website ?? "Website Not Found"
            cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
            return cell
        case 3:
            let cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "cell")
            cell.textLabel?.text = "Text a Friend!"
            cell.textLabel?.font = UIFont.boldSystemFontOfSize(17.0)
            cell.textLabel?.textColor = kPurple
            cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
            return cell
        default:
            return UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "cell")
        }
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

        switch (indexPath.row) {
        case 0:
            let alertController = UIAlertController(title: "Open the Maps app to navigate to this venue?", message: nil, preferredStyle: .Alert)
            alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: { (action: UIAlertAction!) in
                print("Cancel")
            }))
            alertController.addAction(UIAlertAction(title: "Open in Maps", style: UIAlertActionStyle.Default, handler: { (action: UIAlertAction!) in
                dispatch_async(dispatch_get_main_queue()) {
                    [weak self] in
                    
                    if let tempVenueDetailsVC = self {
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
                        tempVenueDetailsVC.mapItem?.openInMapsWithLaunchOptions(launchOptions)
                        
                        FIRAnalytics.logEventWithName("navigated_to_venue", parameters: ["venue_name": self!.venue!.name!, "venue_neighborhood": self!.venue!.neighborhood!, "venue_food_type": self!.venue!.foodType!])
                        Amplitude.instance().logEvent("Opened Maps")
                    }
                }
            }))
            UIApplication.sharedApplication().keyWindow?.rootViewController?.presentViewController(alertController, animated: true, completion: nil)
        case 1:
            let formattedPhoneNumber = venue?.phoneNumber ?? "Phone Number Not Found"
            let stringArray = formattedPhoneNumber.componentsSeparatedByCharactersInSet(NSCharacterSet.decimalDigitCharacterSet().invertedSet)
            let phoneNumber = stringArray.joinWithSeparator("")
            if let url = NSURL(string: "tel://\(phoneNumber)") {
                UIApplication.sharedApplication().openURL(url)
                
                FIRAnalytics.logEventWithName("called_venue", parameters: ["venue_name": venue!.name!, "venue_neighborhood": venue!.neighborhood!, "venue_food_type": venue!.foodType!])
                Amplitude.instance().logEvent("Called Venue")
            }
        case 2:
            if venue?.website! != nil && venue?.website! != "Website Not Found" {
                let safariVC = SFSafariViewController(URL: NSURL(string: venue!.website!)!)
                safariVC.delegate = self
                self.presentViewController(safariVC, animated: true, completion: nil)
                
                FIRAnalytics.logEventWithName("viewed_venue_website", parameters: ["venue_name": venue!.name!, "venue_neighborhood": venue!.neighborhood!, "venue_food_type": venue!.foodType!])
                Amplitude.instance().logEvent("Viewed Venue Website")
            }
        case 3:
            let messageComposeVC = configuredMessageComposeViewController()
            if canSendText() {
                presentViewController(messageComposeVC, animated: true, completion: {
                    UIApplication.sharedApplication().statusBarStyle = .LightContent
                })
            } else {
                showSimpleAlertWithTitle("Sorry", message: "Your device is unable to send text messages", actionTitle: "OK", viewController: self)
            }
        default:
            return
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func safariViewControllerDidFinish(controller: SFSafariViewController) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: MapKit
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation {
            return nil
        }
        
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId)
        if pinView == nil {
            pinView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
            pinView!.image = UIImage(named: "Pin-Default")
        } else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    
    // MARK: SMS Invitations
    
    // A wrapper function to indicate whether or not a text message can be sent from the user's device
    func canSendText() -> Bool {
        return MFMessageComposeViewController.canSendText()
    }
    
    // Configures and returns a MFMessageComposeViewController instance
    func configuredMessageComposeViewController() -> MFMessageComposeViewController {
        let messageComposeVC = MFMessageComposeViewController()
        messageComposeVC.messageComposeDelegate = self
        messageComposeVC.navigationBar.tintColor = UIColor.whiteColor()
        messageComposeVC.navigationBar.titleTextAttributes = [NSFontAttributeName: UIFont.systemFontOfSize(22), NSForegroundColorAttributeName: UIColor.whiteColor()]
        messageComposeVC.body = "Check out \(venue!.name!), a new restaurant, with me on Tastemaker! Get the iOS app at getTastemaker.com"
        return messageComposeVC
    }
    
    // MFMessageComposeViewControllerDelegate callback - dismisses the view controller when the user is finished with it
    func messageComposeViewController(controller: MFMessageComposeViewController, didFinishWithResult result: MessageComposeResult) {
        switch result {
        case MessageComposeResultCancelled:
            controller.dismissViewControllerAnimated(true, completion: nil)
        case MessageComposeResultFailed:
            controller.dismissViewControllerAnimated(true, completion: nil)
        case MessageComposeResultSent:
            FIRAnalytics.setUserPropertyString("true", forName: "sent_sms_invite")
            FIRAnalytics.logEventWithName("sent_sms_invite", parameters: ["from": "venue_details", "venue_name": venue!.name!])
            controller.dismissViewControllerAnimated(true, completion: nil)
        default:
            break
        }
    }
}