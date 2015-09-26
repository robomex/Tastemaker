//
//  FeedTableViewController.swift
//  GrandOpens
//
//  Created by Tony Morales on 6/20/15.
//  Copyright (c) 2015 Tony Morales. All rights reserved.
//

import UIKit
import Parse
import ParseUI
//import Synchronized

class FeedTableViewController: UITableViewController, GOVenueCellViewDelegate {

    var venues: [Venue] = []
    
    
    // MARK: Initialization
    
    deinit {
        let defaultNotificationCenter = NSNotificationCenter.defaultCenter()
        defaultNotificationCenter.removeObserver(self, name: GOUtilityUserVotedUnvotedVenueCallbackFinishedNotification, object: nil)
        defaultNotificationCenter.removeObserver(self, name: GOUserVotedUnvotedVenueNotification, object: nil)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        UIApplication.sharedApplication().statusBarStyle = .LightContent
        
        // Register to be notified when a voted/unvoted callback finished
        let defaultNotificationCenter = NSNotificationCenter.defaultCenter()
        defaultNotificationCenter.addObserver(self, selector: Selector("userDidVoteOrUnvoteVenue:"), name: GOUtilityUserVotedUnvotedVenueCallbackFinishedNotification, object: nil)
        defaultNotificationCenter.addObserver(self, selector: Selector("userDidVoteOrUnvoteVenue:"), name: GOUserVotedUnvotedVenueNotification, object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let font = UIFont(name: "Muli", size: 26) {
            navigationController!.navigationBar.topItem!.title = "Chicago"
            navigationController!.navigationBar.titleTextAttributes = [NSFontAttributeName: font, NSForegroundColorAttributeName: UIColor.whiteColor()]
            navigationController!.view.backgroundColor = UIColor.whiteColor()
        }
        
        fetchVenues({
            venues in
            self.venues = venues
            self.tableView.reloadData()
        })
        
        self.tabBarController?.tabBar.hidden = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    // MARK: UITableViewDelegate
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.0
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.0
    }
    
    override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }
    
    
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return venues.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> PFTableViewCell {

        let CellIdentifier = "VenueCell"
        
        let index: Int = self.indexForObjectAtIndexPath(indexPath)
        
        var venueCell: GOVenueCellView? = self.tableView.dequeueReusableCellWithIdentifier(CellIdentifier) as? GOVenueCellView
        if venueCell == nil {
            venueCell = GOVenueCellView(frame: CGRectMake(0.0, 0.0, self.view.bounds.size.width, 76.0), buttons: GOVenueCellButtons.Default)
            venueCell!.delegate = self
            venueCell!.selectionStyle = UITableViewCellSelectionStyle.None
        }
        
        let venue: Venue? = venues[indexPath.row]
        venueCell!.venue = venue
        venueCell!.tag = index
        venueCell!.voteButton!.tag = index
        
        let attributesForVenue = GOCache.sharedCache.attributesForVenue(venue!)
        
        if attributesForVenue != nil {
            venueCell!.setVoteStatus(GOCache.sharedCache.isVenueVotedByCurrentUser(venue!))
            venueCell!.voteButton!.setTitle(GOCache.sharedCache.voteCountForVenue(venue!).description, forState: UIControlState.Normal)
            
            if venueCell!.voteButton!.alpha < 1.0 {
                UIView.animateWithDuration(0.200, animations: {
                    venueCell!.voteButton!.alpha = 1.0
                })
            }
        } else {
//  ADD SYNCHRONIZE SHIT COCOAPOD HERE
//            venueCell!.voteButton!.alpha = 0.0
//            
//            synchronized(self) {
//                // Check if we can update the cache
//                let outstandingSectionHeaderQueryStatus: Int? = self.outstandingSectionHeaderQueries[index] as? Int
//                
//            }
        }
        
        return venueCell!
        

//        let cell = tableView.dequeueReusableCellWithIdentifier("VenueCell", forIndexPath: indexPath) as! VenueCell
//
//        let venueInfo = venues[indexPath.row]
//        cell.venueName.text = venueInfo.name
//        cell.venueNeighborhood.text = venueInfo.neighborhood
//        cell.voteButton.venueId = venueInfo.id
//        
//        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let vc = VenueViewController(transitionStyle: .Scroll, navigationOrientation: .Horizontal, options: nil)
        
        let venue = venues[indexPath.row]
        vc.venue = venue
        vc.venueID = venue.id
        vc.title = venue.name
        navigationItem.title = ""
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    @IBAction func voteButtonPressed(sender: VoteButton) {
        saveVenueVote(sender.venueId!)
    }
    
    
    // MARK: GOVenueCellViewDelegate
    
    func venueCellView(venueCellView: GOVenueCellView, didTapVoteButton button: UIButton, venue: PFObject) {
        venueCellView.shouldEnableVoteButton(false)
        
        let voted: Bool = !button.selected
        venueCellView.setVoteStatus(voted)
        
        let originalButtonTitle = button.titleLabel!.text
        
        var voteCount: Int = Int(button.titleLabel!.text!)!
        if (voted) {
            voteCount++
            GOCache.sharedCache.incrementVoteCountForVenue(venue)
        } else {
            if voteCount > 0 {
                voteCount--
            }
            GOCache.sharedCache.decrementVoteCountForVenue(venue)
        }
        
        GOCache.sharedCache.setVenueIsVotedByCurrentUser(venue, voted: voted)
        
        button.setTitle(String(voteCount), forState: UIControlState.Normal)
        
        if voted {
            GOUtility.voteVenueInBackground(venue, block: { (succeeded, error) in
                let actualVenueCellView: GOVenueCellView? = self.tableView(self.tableView, viewForHeaderInSection: button.tag) as? GOVenueCellView
                actualVenueCellView?.shouldEnableVoteButton(true)
                actualVenueCellView?.setVoteStatus(succeeded)
                
                if !succeeded {
                    actualVenueCellView?.voteButton!.setTitle(originalButtonTitle, forState: UIControlState.Normal)
                }
            })
        } else {
            GOUtility.unvoteVenueInBackground(venue, block: { (succeeded, error) in
                let actualVenueCellView: GOVenueCellView? = self.tableView(self.tableView, viewForHeaderInSection: button.tag) as? GOVenueCellView
                actualVenueCellView?.shouldEnableVoteButton(false)
                actualVenueCellView?.setVoteStatus(!succeeded)
                
                if !succeeded{
                    actualVenueCellView?.voteButton!.setTitle(originalButtonTitle, forState: UIControlState.Normal)
                }
            })
        }
    }
    
    
    // MARK: ()
    
    func userDidVoteOrUnvoteVenue(note: NSNotification) {
        self.tableView.beginUpdates()
        self.tableView.endUpdates()
    }
    
    func indexForObjectAtIndexPath(indexPath: NSIndexPath) -> Int {
        return indexPath.row
    }
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        

    }
    */
}
