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

class ListViewController: FeedTableViewController, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    // MARK: Initialization
    
    private var saveListHandle: UInt?
    private var listVenues = [Venue]()
    private var loading: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "My List"
        
        self.tableView.emptyDataSetSource = self
        self.tableView.emptyDataSetDelegate = self
        self.tableView.tableFooterView = UIView()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
//        print(self.)
//        self.navigationController!.navigationBar.translucent = false
//        self.tableView.alpha = 0.0
//        navigationController!.navigationBar.titleTextAttributes = [NSFontAttributeName: UIFont.systemFontOfSize(26), NSForegroundColorAttributeName: UIColor.whiteColor()]
        self.tabBarController?.tabBar.hidden = false
        self.tableView.separatorStyle = UITableViewCellSeparatorStyle.SingleLine
        
        if self.listVenues.isEmpty {
            saveListHandle = DataService.dataService.USER_ACTIVITIES_REF.childByAppendingPath("\(super.uid)/saves").queryOrderedByChild("saved").queryEqualToValue(true).observeEventType(FEventType.Value, withBlock: {
                snapshot in
                
                if !snapshot.exists() {
                    self.loading = false
                    self.tableView.alpha = 1.0
                }
                
                let enumerator = snapshot.children
                self.listVenues = []
                while let data = enumerator.nextObject() as? FDataSnapshot {
                    DataService.dataService.VENUES_REF.childByAppendingPath("\(data.key)").observeSingleEventOfType(FEventType.Value, withBlock: {
                        snap in
                        
                        self.listVenues.insert(snapshotToVenue(snap), atIndex: 0)
                        self.tableView.reloadData()
                        self.loading = false
                    })
                }
            })
        }
            
        let tracker = GAI.sharedInstance().defaultTracker
        tracker.set(kGAIScreenName, value: "UserListViewController")
        let builder = GAIDictionaryBuilder.createScreenView()
        tracker.send(builder.build() as [NSObject: AnyObject])
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
//        DataService.dataService.USER_ACTIVITIES_REF.childByAppendingPath("\(super.uid)/saves").removeObserverWithHandle(saveListHandle!)
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
    
    
    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
    }
    */
    
}
