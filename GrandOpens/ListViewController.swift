//
//  ListViewController.swift
//  GrandOpens
//
//  Created by Tony Morales on 6/9/15.
//  Copyright (c) 2015 Tony Morales. All rights reserved.
//

import UIKit
import ParseUI
import Parse
import DZNEmptyDataSet
import Firebase

class ListViewController: FeedTableViewController, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    // MARK: Initialization
    
    private let ref = Firebase(url: "https://grandopens.firebaseio.com")
    private var saveListHandle: UInt?
    private var listVenues = [Venue]()
    
    deinit {
        let defaultNotificationCenter = NSNotificationCenter.defaultCenter()
        defaultNotificationCenter.removeObserver(self, name: GOUtilityUserSavedUnsavedVenueNotification, object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let defaultNotificationCenter = NSNotificationCenter.defaultCenter()
        defaultNotificationCenter.addObserver(self, selector: "userDidSaveOrUnsaveVenue:", name: GOUtilityUserSavedUnsavedVenueNotification, object: nil)
        self.title = "My List"
        
        self.tableView.emptyDataSetSource = self
        self.tableView.emptyDataSetDelegate = self
        self.tableView.tableFooterView = UIView()
        
        // This is supposed to be in viewWillAppear, however the empty state always flashes when placed there, troubleshoot later
        listVenues = []
        saveListHandle = ref.childByAppendingPath("userActivities/\(super.uid)/saves").observeEventType(FEventType.Value, withBlock: {
            snapshot in
            let enumerator = snapshot.children
            self.listVenues = []
            while let data = enumerator.nextObject() as? FDataSnapshot {
                self.ref.childByAppendingPath("venues/\(data.key)").observeSingleEventOfType(FEventType.Value, withBlock: {
                    snap in
             
                    self.listVenues.insert(snapshotToVenue(snap), atIndex: 0)
                    self.tableView.reloadData()
                })
            }
        })
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.tabBarController?.tabBar.hidden = false
        self.tableView.separatorStyle = UITableViewCellSeparatorStyle.SingleLine
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        ref.removeObserverWithHandle(saveListHandle!)
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
        let venueCell = super.tableView(self.tableView, cellForRowAtIndexPath: indexPath)
        return venueCell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let vc = VenueViewController(transitionStyle: .Scroll, navigationOrientation: .Horizontal, options: nil)
        
        let venue = self.listVenues[indexPath.row]
        vc.venue = venue
        vc.venueID = venue.objectId
        
        let venueName: String = venue.name!
        vc.title = venueName
        vc.hidesBottomBarWhenPushed = true
        navigationController!.view.backgroundColor = UIColor.whiteColor()
        navigationController?.pushViewController(vc, animated: true)
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    
    // MARK: ()
    
    @objc func userDidSaveOrUnsaveVenue(note: NSNotification) {
        //        self.loadObjects()
    }
    
    
    // MARK: DZNEmptyDataSet
    
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let title = "/.-("
        let attributes = [NSFontAttributeName: UIFont.systemFontOfSize(50.0)]
        return NSAttributedString(string: title, attributes: attributes)
    }
    
    func descriptionForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let description = "You haven't saved any venues yet. \nIf a new place catches your eye, save it and it'll pop up here!"
        let attributes = [NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleBody)]
        return NSAttributedString(string: description, attributes: attributes)
    }
    
    
    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
    }
    */
    
}
