//
//  UserProfileViewController.swift
//  Tastemaker
//
//  Created by Tony Morales on 1/20/16.
//  Copyright © 2016 Tony Morales. All rights reserved.
//

import UIKit
import Firebase
import DZNEmptyDataSet
import Amplitude_iOS
import JSQMessagesViewController

class UserProfileViewController: FeedTableViewController, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {

    var userId = String()
    var userNickname = String()
    private var userActivitiesMuteHandle = UInt?()
    private var usersSavedListHandle = UInt?()
    private var usersSavedListVenues = [Venue]()
    private var loading: Bool = true
    private var originalMessages: [JSQMessage] = []
    private var originalVisitStatuses: [String] = []
    private var originalUserIdList = [String]()
    private var isMuted = Bool()
    private var superUid = String()
    
    private var headerView: UIView?
    let profilePicWidth: CGFloat = 132
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.emptyDataSetDelegate = self
        tableView.emptyDataSetSource = self
        
        headerView = UIView(frame: CGRectMake(0.0, 0.0, tableView.bounds.size.width, 222.0))
        // Should be clear, this will be the container for our avatar, counts, and whatevz later
        headerView!.backgroundColor = UIColor.clearColor()
        
        let texturedBackgroundView: UIView = UIView(frame: view.bounds)
        texturedBackgroundView.backgroundColor = UIColor.whiteColor()
        tableView.backgroundView = texturedBackgroundView
        
        let profilePictureBackgroundView = UIView(frame: CGRectMake(UIScreen.mainScreen().bounds.width/2 - profilePicWidth/2, 38.0, profilePicWidth, profilePicWidth))
        profilePictureBackgroundView.backgroundColor = UIColor.lightGrayColor()
        profilePictureBackgroundView.alpha = 0.0
        let layer: CALayer = profilePictureBackgroundView.layer
        layer.cornerRadius = 66.0
        layer.masksToBounds = true
        headerView!.addSubview(profilePictureBackgroundView)
        
        let loadingActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.White)
        loadingActivityIndicatorView.startAnimating()
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: loadingActivityIndicatorView)
        
        superUid = super.uid
        
        if navigationController?.viewControllers[(navigationController?.viewControllers.count)! - 2] is VenueViewController {
            let venueVC = navigationController?.viewControllers[(navigationController?.viewControllers.count)! - 2] as! VenueViewController
            let chatVC = venueVC.chatVC
            originalMessages = chatVC.messages
            originalVisitStatuses = chatVC.visitStatuses
            originalUserIdList = chatVC.userIdList
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        tabBarController!.tabBar.hidden = true
        title = userNickname
        
        if isMovingToParentViewController() {
            
            userActivitiesMuteHandle = DataService.dataService.USER_ACTIVITIES_REF.childByAppendingPath("\(super.uid)/mutes/\(userId)").observeEventType(FEventType.Value, withBlock: {
                [weak self] snapshot in
                
                if let throwawayUserProfileVC = self {
                    if snapshot.exists() {
                        throwawayUserProfileVC.isMuted = true
                        throwawayUserProfileVC.configureUnmuteButton()
                    } else if throwawayUserProfileVC.superUid == throwawayUserProfileVC.userId {
                        throwawayUserProfileVC.navigationItem.rightBarButtonItem = nil
                    } else {
                        throwawayUserProfileVC.isMuted = false
                        throwawayUserProfileVC.configureMuteButton()
                    }
                }
            })
            
            usersSavedListHandle = DataService.dataService.USER_ACTIVITIES_REF.childByAppendingPath("\(userId)/saves").observeEventType(FEventType.Value, withBlock: {
                [weak self] snapshot in
                
                if let throwawayUserProfileVC = self {
                    if !snapshot.exists() {
                        throwawayUserProfileVC.loading = false
                        throwawayUserProfileVC.tableView.alpha = 1.0
                        throwawayUserProfileVC.tableView.reloadData()
                    }
                    
                    let enumerator = snapshot.children
                    throwawayUserProfileVC.usersSavedListVenues = []
                    while let data = enumerator.nextObject() as? FDataSnapshot {
                        DataService.dataService.VENUES_REF.childByAppendingPath("\(data.key)").observeSingleEventOfType(FEventType.Value, withBlock: {
                            snap in
                            
                            throwawayUserProfileVC.usersSavedListVenues.insert(snapshotToVenue(snap), atIndex: 0)
                            throwawayUserProfileVC.loading = false
                            throwawayUserProfileVC.tableView.reloadData()
                        })
                    }
                }
            })
        }

        // Set a blank text back button here to prevent ellipses from showing as title during nav animation
        navigationItem.leftBarButtonItem = nil
        if (navigationController != nil) {
            let backButton = UIBarButtonItem(title: " ", style: .Plain, target: nil, action: nil)
            navigationController!.navigationBar.topItem!.backBarButtonItem = backButton
        }
        
        if super.uid == userId {
            navigationItem.rightBarButtonItem = nil
        } else if isMuted {
            configureUnmuteButton()
        } else if !isMuted {
            configureMuteButton()
        }
        
        let tracker = GAI.sharedInstance().defaultTracker
        tracker.set(kGAIScreenName, value: "UserProfileViewController")
        let builder = GAIDictionaryBuilder.createScreenView()
        tracker.send(builder.build() as [NSObject: AnyObject])
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationItem.rightBarButtonItem = nil
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        if isMovingFromParentViewController() {
            visits.removeAll()
            usersSavedListVenues.removeAll()
            DataService.dataService.USER_ACTIVITIES_REF.childByAppendingPath("\(super.uid)/mutes/\(userId)").removeObserverWithHandle(userActivitiesMuteHandle!)
            DataService.dataService.USER_ACTIVITIES_REF.childByAppendingPath("\(userId)/saves").removeObserverWithHandle(usersSavedListHandle!)
            tableView.emptyDataSetSource = nil
            tableView.emptyDataSetDelegate = nil
        }
    }

    
    // MARK:- TableViewController
    
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.font = UIFont.systemFontOfSize(16)
        header.textLabel?.textColor = UIColor.darkGrayColor()
        header.textLabel?.text = userNickname + "'s Saved Venues"
    }
    
   override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30.0
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return usersSavedListVenues.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        super.venues = usersSavedListVenues
        let venueCell = super.tableView(tableView, cellForRowAtIndexPath: indexPath) as! VenueCellView
        
        if indexPath.row == (tableView.indexPathsForVisibleRows?.last?.row)! {
            UIView.animateWithDuration(0.1, animations: {
                tableView.alpha = 1.0
            })
        }
        return venueCell
    }
    
    
    // MARK:- ()
    
    func muteButtonAction(sender: AnyObject) {
        let loadingActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.White)
        loadingActivityIndicatorView.startAnimating()
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: loadingActivityIndicatorView)
        
        configureUnmuteButton()
        isMuted = true
        DataService.dataService.USER_ACTIVITIES_REF.childByAppendingPath("\(super.uid)/mutes/\(userId)").setValue(true)
        if navigationController?.viewControllers[(navigationController?.viewControllers.count)! - 2] is VenueViewController {
            let venueVC = navigationController?.viewControllers[(navigationController?.viewControllers.count)! - 2] as! VenueViewController
            let chatVC = venueVC.chatVC
            chatVC.mutedUsers[userId] = "muted"
            
            var filteredMessages: [JSQMessage] = []
            var filteredVisitStatuses: [String] = []
            var filteredUserIdList = [String]()
            for (index, message) in chatVC.messages.enumerate() {
                if chatVC.mutedUsers[message.senderId] == nil {
                    filteredMessages.append(originalMessages[index])
                    filteredVisitStatuses.append(originalVisitStatuses[index])
                    filteredUserIdList.append(message.senderId)
                }
            }
            filteredUserIdList = Array(Set(filteredUserIdList))
            chatVC.messages = filteredMessages
            chatVC.visitStatuses = filteredVisitStatuses
            chatVC.userIdList = filteredUserIdList
            chatVC.collectionView.reloadData()
        }
        
        Amplitude.instance().logEvent("Muted User", withEventProperties: ["Muted User ID": userId, "Muted User Nickname": userNickname])
        Amplitude.instance().identify(AMPIdentify().add("Mutes", value: 1))
    }
    
    func unmuteButtonAction(sender: AnyObject) {
        let loadingActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.White)
        loadingActivityIndicatorView.startAnimating()
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: loadingActivityIndicatorView)
        
        configureMuteButton()
        isMuted = false
        DataService.dataService.USER_ACTIVITIES_REF.childByAppendingPath("\(super.uid)/mutes/\(userId)").removeValue()
        if navigationController?.viewControllers[(navigationController?.viewControllers.count)! - 2] is VenueViewController {
            let venueVC = navigationController?.viewControllers[(navigationController?.viewControllers.count)! - 2] as! VenueViewController
            let chatVC = venueVC.chatVC
            chatVC.mutedUsers[userId] = nil
            chatVC.messages = originalMessages
            chatVC.visitStatuses = originalVisitStatuses
            chatVC.userIdList = originalUserIdList
        }
        
        Amplitude.instance().logEvent("Unmuted User", withEventProperties: ["Unmuted User ID": userId, "Unmuted User Nickname": userNickname])
        Amplitude.instance().identify(AMPIdentify().add("Mutes", value: -1))
    }
    
    func configureMuteButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Mute", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(UserProfileViewController.muteButtonAction(_:)))
    }
    
    func configureUnmuteButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Unmute", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(UserProfileViewController.unmuteButtonAction(_:)))
    }
    
    
    // MARK: DZNEmptyDataSet
    
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        if loading {
            return nil
        } else {
            let title = ":-|"
            let attributes = [NSFontAttributeName: UIFont.systemFontOfSize(50.0)]
            return NSAttributedString(string: title, attributes: attributes)
        }
    }
    
    func descriptionForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        if loading {
            return  nil
        } else {
            let description = "This person's list is empty. \nShoot them a recommendation of somewhere good!"
            let attributes = [NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleBody)]
            return NSAttributedString(string: description, attributes: attributes)
        }
    }
}