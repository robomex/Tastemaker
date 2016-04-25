//
//  ListViewController.swift
//  GrandOpens
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
    
    private var saveListHandle: UInt?
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
            
            saveListHandle = DataService.dataService.USER_ACTIVITIES_REF.childByAppendingPath("\(super.uid)/saves").queryOrderedByChild("saved").queryEqualToValue(true).observeEventType(FEventType.Value, withBlock: {
                snapshot in
                
                if !snapshot.exists() {
                    self.loading = false
                    self.listVenues = []
                    self.tableView.alpha = 1.0
                    self.tableView.reloadData()
                }
                
                let enumerator = snapshot.children
                self.listVenues = []
                while let data = enumerator.nextObject() as? FDataSnapshot {
                    DataService.dataService.VENUES_REF.childByAppendingPath("\(data.key)").observeSingleEventOfType(FEventType.Value, withBlock: {
                        snap in
                        
                        self.listVenues.insert(snapshotToVenue(snap), atIndex: 0)
                        self.tableView.reloadData()
                        
                        for venue in self.listVenues {
                            DataService.dataService.USER_ACTIVITIES_REF.childByAppendingPath("\(self.uid)/visits/\(venue.objectId!)").observeSingleEventOfType(.Value, withBlock: {
                                snapshot in
                                
                                if snapshot.exists() {
                                    self.visits[venue.objectId!] = true
                                }
                                self.loading = false
                                self.tableView.reloadData()
                            })
                        }
                    })
                }
            })
        }

        let tracker = GAI.sharedInstance().defaultTracker
        tracker.set(kGAIScreenName, value: "UserListViewController")
        let builder = GAIDictionaryBuilder.createScreenView()
        tracker.send(builder.build() as [NSObject: AnyObject])
    }
    
    func listLogoutCleanup() {
        DataService.dataService.CURRENT_USER_PRIVATE_REF.childByAppendingPath("banned").removeObserverWithHandle(bannedHandle!)
        DataService.dataService.USER_ACTIVITIES_REF.childByAppendingPath("\(super.uid)/saves").removeObserverWithHandle(saveListHandle!)
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
        let venueCell = super.tableView(self.tableView, cellForRowAtIndexPath: indexPath) as! GOVenueCellView
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
        
        Amplitude.instance().logEvent("Viewed Venue From My List", withEventProperties: ["Venue Name": venue.name!, "Venue Neighborhood": venue.neighborhood!, "Venue Food Type": venue.foodType!])
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
            let description = "You haven't saved any venues yet. \nIf a new place catches your eye, save it and it'll pop up here!"
            let attributes = [NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleBody)]
            return NSAttributedString(string: description, attributes: attributes)
        }
    }
}
