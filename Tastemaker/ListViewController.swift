//
//  ListViewController.swift
//  Tastemaker
//
//  Created by Tony Morales on 6/9/15.
//  Copyright (c) 2015 Tony Morales. All rights reserved.
//

import UIKit
import DZNEmptyDataSet
import Firebase
import Amplitude_iOS

class ListViewController: FeedTableViewController, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    // MARK: Initialization
    
    private var saveListHandle: FIRDatabaseHandle?
    private var listVenues = [Venue]()
    var loading: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "My List"
        
        self.tableView.emptyDataSetSource = self
        self.tableView.emptyDataSetDelegate = self
        self.tableView.tableFooterView = UIView()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.tableView.separatorStyle = UITableViewCellSeparatorStyle.SingleLine
        
        if self.isMovingToParentViewController() {
            self.tableView.alpha = 0.0
            
            saveListHandle = DataService.dataService.USER_ACTIVITIES_REF.child("\(super.uid)/saves").observeEventType(FIRDataEventType.Value, withBlock: {
                snapshot in
                
                if !snapshot.exists() {
                    self.loading = false
                    self.listVenues = []
                    self.tableView.alpha = 1.0
                    self.tableView.reloadData()
                }
                
                let enumerator = snapshot.children
                self.listVenues = []
                while let data = enumerator.nextObject() as? FIRDataSnapshot {
                    DataService.dataService.VENUES_REF.child("\(data.key)").observeSingleEventOfType(FIRDataEventType.Value, withBlock: {
                        snap in
                        
                        self.listVenues.insert(snapshotToVenue(snap), atIndex: 0)
                        self.loading = false
                        self.tableView.reloadData()
                    })
                }
            })
        }
    }
    
    func listLogoutCleanup() {
        DataService.dataService.CURRENT_USER_PRIVATE_REF.child("banned").removeObserverWithHandle(bannedHandle!)
        DataService.dataService.USER_ACTIVITIES_REF.child("\(super.uid)/saves").removeObserverWithHandle(saveListHandle!)
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.listVenues.count
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        super.venues = self.listVenues
        let venueCell = super.tableView(self.tableView, cellForRowAtIndexPath: indexPath) as! VenueCellView
        return venueCell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let vc = VenueViewController()
        
        let venue = self.listVenues[indexPath.row]
        vc.venue = venue
        vc.venueID = venue.objectId
        if self.banned != nil {
            vc.banned = self.banned
        }
        
        let venueName: String = venue.name!
        vc.title = venueName
        vc.hidesBottomBarWhenPushed = true
        navigationController!.view.backgroundColor = UIColor.whiteColor()
        navigationController?.pushViewController(vc, animated: true)
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        FIRAnalytics.logEventWithName("viewed_venue", parameters: ["from": "my_list", "from_format": "list", "venue_name": venue.name!, "venue_neighborhood": venue.neighborhood!, "venue_food_type": venue.foodType!])
        Amplitude.instance().logEvent("Viewed Venue From My List", withEventProperties: ["Venue Name": venue.name!, "Venue Neighborhood": venue.neighborhood!, "Venue Food Type": venue.foodType!])
    }
    
    override func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        let vc = VenueViewController()
        
        let venueAnnotation = view.annotation as! VenueAnnotation
        let venue = venueAnnotation.venue
        vc.venue = venue
        vc.venueID = venue.objectId
        if banned != nil {
            vc.banned = banned
        }
        
        let venueName: String = venue.name!
        vc.title = venueName
        vc.hidesBottomBarWhenPushed = true
        navigationController!.view.backgroundColor = UIColor.whiteColor()
        navigationController?.pushViewController(vc, animated: true)
        
        FIRAnalytics.logEventWithName("viewed_venue", parameters: ["from": "my_list", "from_format": "map", "venue_name": venue.name!, "venue_neighborhood": venue.neighborhood!, "venue_food_type": venue.foodType!])
        Amplitude.instance().logEvent("Viewed Venue From My List Map", withEventProperties: ["Venue Name": venue.name!, "Venue Neighborhood": venue.neighborhood!, "Venue Food Type": venue.foodType!])
    }
    
    
    // MARK: ()
    
    
    // MARK: DZNEmptyDataSet
    
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        if loading {
            return nil
        } else {
            let title = "/.-("
            let attributes = [NSFontAttributeName: UIFont.systemFontOfSize(50.0)]
            return NSAttributedString(string: title, attributes: attributes)
        }
    }
    
    func descriptionForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        if loading {
            return nil
        } else {
            let description = "\nYou haven't saved any venues yet.\n\nIf a new place catches your eye, hit 'Save' in the venue's chat screen!\n\nYou can save up to five venues here."
            let attributes = [NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleBody)]
            return NSAttributedString(string: description, attributes: attributes)
        }
    }
}
