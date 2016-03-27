//
//  GOUserProfileViewController.swift
//  GrandOpens
//
//  Created by Tony Morales on 1/20/16.
//  Copyright © 2016 Tony Morales. All rights reserved.
//

import UIKit
import Firebase
import DZNEmptyDataSet
import Amplitude_iOS

class GOUserProfileViewController: FeedTableViewController, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {

    var userId = String()
    var userNickname = String()
    private var userActivitiesMuteHandle = UInt?()
    private var userActivitiesMuteRef: Firebase?
    private var usersSavedListRef: Firebase?
    private var usersSavedListHandle = UInt?()
    private var usersSavedListVenues = [Venue]()
    private var loading: Bool = true
    
    private var headerView: UIView?
    let profilePicWidth: CGFloat = 132
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = userNickname
        self.tableView.emptyDataSetDelegate = self
        self.tableView.emptyDataSetSource = self
        
        DataService.dataService.USERS_PUBLIC_REF.childByAppendingPath(userId).observeSingleEventOfType(FEventType.Value, withBlock: {
            snapshot in
            
            if snapshot.exists() {
                if let nickname = snapshot.value.objectForKey("nickname") as? String {
                    
                    self.userNickname = nickname
                    self.title = nickname
                }
            }
        })
        
        self.headerView = UIView(frame: CGRectMake(0.0, 0.0, self.tableView.bounds.size.width, 222.0))
        // Should be clear, this will be the container for our avatar, counts, and whatevz later
        self.headerView!.backgroundColor = UIColor.clearColor()
        
        let texturedBackgroundView: UIView = UIView(frame: self.view.bounds)
        texturedBackgroundView.backgroundColor = UIColor.whiteColor()
        self.tableView.backgroundView = texturedBackgroundView
        
        let profilePictureBackgroundView = UIView(frame: CGRectMake(UIScreen.mainScreen().bounds.width/2 - profilePicWidth/2, 38.0, profilePicWidth, profilePicWidth))
        profilePictureBackgroundView.backgroundColor = UIColor.lightGrayColor()
        profilePictureBackgroundView.alpha = 0.0
        let layer: CALayer = profilePictureBackgroundView.layer
        layer.cornerRadius = 66.0
        layer.masksToBounds = true
        self.headerView!.addSubview(profilePictureBackgroundView)
        
//        let profilePictureImageView: PFImageView = PFImageView(frame: CGRectMake(UIScreen.mainScreen().bounds.width/2 - profilePicWidth/2, 38.0, profilePicWidth, profilePicWidth))
//        self.headerView!.addSubview(profilePictureImageView)
//        profilePictureImageView.contentMode = UIViewContentMode.ScaleAspectFill
//        layer = profilePictureImageView.layer
//        layer.cornerRadius = 66.0
//        layer.masksToBounds = true
//        profilePictureImageView.alpha = 0.0
        
//        if GOUtility.userHasProfilePicture(self.user!) {
//            let imageFile: PFFile! = self.user!.objectForKey(kUserProfilePicKey) as! PFFile
//            profilePictureImageView.file = imageFile
//            profilePictureImageView.loadInBackground { (image, error) in
//                if error == nil {
//                    UIView.animateWithDuration(0.2, animations: {
//                        profilePictureBackgroundView.alpha = 1.0
//                        profilePictureImageView.alpha = 1.0
//                    })
//                    
//                    let backgroundImageView = UIImageView(image: image!) // .applyDarkEffect() is throwing an error
//                    backgroundImageView.frame = self.tableView.backgroundView!.bounds
//                    backgroundImageView.alpha = 0.0
//                    backgroundImageView.contentMode = UIViewContentMode.ScaleAspectFill
//                    let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .ExtraLight))
//                    visualEffectView.frame = backgroundImageView.bounds
//                    backgroundImageView.addSubview(visualEffectView)
//                    self.tableView.backgroundView!.addSubview(backgroundImageView)
//                    
//                    UIView.animateWithDuration(0.2, animations: {
//                        backgroundImageView.alpha = 1.0
//                    })
//                }
//            }
//        } else {
//            profilePictureImageView.image = GOUtility.defaultProfilePicture()
//            UIView.animateWithDuration(0.2, animations: {
//                profilePictureBackgroundView.alpha = 1.0
//                profilePictureImageView.alpha = 1.0
//            })
//            
//            let backgroundImageView = UIImageView(image: GOUtility.defaultProfilePicture()!)
//            backgroundImageView.frame = self.tableView.backgroundView!.bounds
//            backgroundImageView.alpha = 0.0
//            backgroundImageView.contentMode = UIViewContentMode.ScaleAspectFill
//            let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .ExtraLight))
//            visualEffectView.frame = backgroundImageView.bounds
//            backgroundImageView.addSubview(visualEffectView)
//            self.tableView.backgroundView!.addSubview(backgroundImageView)
//            
//            UIView.animateWithDuration(0.2, animations: {
//                backgroundImageView.alpha = 1.0
//            })
//        }
//        
//        if self.user!.objectId != PFUser.currentUser()!.objectId {
//            let loadingActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
//            loadingActivityIndicatorView.startAnimating()
//            self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: loadingActivityIndicatorView)
//            
//            // check if the currentUser is muting this user
//            let queryIsMuting = PFQuery(className: kUserActivityClassKey)
//            queryIsMuting.whereKey(kUserActivityTypeKey, equalTo: kUserActivityTypeMute)
//            queryIsMuting.whereKey(kUserActivityToUserKey, equalTo: self.user!)
//            queryIsMuting.whereKey(kUserActivityByUserKey, equalTo: PFUser.currentUser()!)
//            queryIsMuting.cachePolicy = PFCachePolicy.CacheThenNetwork
//            queryIsMuting.countObjectsInBackgroundWithBlock { (number, error) in
//                if error != nil && error!.code != PFErrorCode.ErrorCacheMiss.rawValue {
//                    print("Couldn't determine mute relationship: \(error)")
//                    self.navigationItem.rightBarButtonItem = nil
//                } else {
//                    if number == 0 {
//                        self.configureMuteButton()
//                    } else {
//                        self.configureUnmuteButton()
//                    }
//                }
//            }
//        }
        
        // Mute and unmute setup, check if this user is muted
        let loadingActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.White)
        loadingActivityIndicatorView.startAnimating()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: loadingActivityIndicatorView)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.tableView.alpha = 1.0
        self.tabBarController!.tabBar.hidden = true
        
        userActivitiesMuteRef = DataService.dataService.USER_ACTIVITIES_REF.childByAppendingPath("\(super.uid)/mutes/\(self.userId)")
        userActivitiesMuteHandle = userActivitiesMuteRef!.observeEventType(FEventType.Value, withBlock: {
            snapshot in
            
            if snapshot.exists() {
                self.configureUnmuteButton()
            } else if super.uid == self.userId {
                self.navigationItem.rightBarButtonItem = nil
            } else {
                self.configureMuteButton()
            }
        })
        
        usersSavedListRef = DataService.dataService.USER_ACTIVITIES_REF.childByAppendingPath("\(userId)/saves")
        usersSavedListHandle = usersSavedListRef?.queryOrderedByChild("saved").queryEqualToValue(true).observeEventType(FEventType.Value, withBlock: {
            snapshot in
            
            if !snapshot.exists() {
                self.loading = false
            }
            
            let enumerator = snapshot.children
            self.usersSavedListVenues = []
            self.tableView.reloadData()
            while let data = enumerator.nextObject() as? FDataSnapshot {
                DataService.dataService.VENUES_REF.childByAppendingPath("\(data.key)").observeSingleEventOfType(FEventType.Value, withBlock: {
                    snap in
                    
                    self.usersSavedListVenues.insert(snapshotToVenue(snap), atIndex: 0)
                    self.tableView.reloadData()
                    self.loading = false
                })
            }
        })
        
        // Set a blank text back button here to prevent ellipses from showing as title during nav animation
        self.navigationItem.leftBarButtonItem = nil
        if (navigationController != nil) {
            let backButton = UIBarButtonItem(title: " ", style: .Plain, target: nil, action: nil)
            self.navigationController!.navigationBar.topItem!.backBarButtonItem = backButton
        }
        
        let tracker = GAI.sharedInstance().defaultTracker
        tracker.set(kGAIScreenName, value: "UserProfileViewController")
        let builder = GAIDictionaryBuilder.createScreenView()
        tracker.send(builder.build() as [NSObject: AnyObject])
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.navigationItem.rightBarButtonItem = nil
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        userActivitiesMuteRef!.removeObserverWithHandle(userActivitiesMuteHandle!)
        usersSavedListRef?.removeObserverWithHandle(usersSavedListHandle!)
    }

    
    // MARK:- TableViewController
    
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.text = userNickname
        header.textLabel?.font = UIFont.systemFontOfSize(16)
        header.textLabel?.textColor = UIColor.darkGrayColor()
        header.textLabel?.text = header.textLabel!.text! + "'s Saved Venues"
    }
    
   override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30.0
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.usersSavedListVenues.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        super.venues = self.usersSavedListVenues
        let venueCell = super.tableView(self.tableView, cellForRowAtIndexPath: indexPath) as! GOVenueCellView
        venueCell.containerView?.alpha = 0.0
        return venueCell
    }
    
    
    // MARK:- ()
    
    func muteButtonAction(sender: AnyObject) {
        let loadingActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.White)
        loadingActivityIndicatorView.startAnimating()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: loadingActivityIndicatorView)
        
        self.configureUnmuteButton()
        
        userActivitiesMuteRef?.setValue(true)
        
        Amplitude.instance().logEvent("Muted User", withEventProperties: ["Muted User ID": self.userId, "Muted User Nickname": self.userNickname])
        Amplitude.instance().identify(AMPIdentify().add("Mutes", value: 1).append("Mutes-UserIDs", value: (self.userId)))
    }
    
    func unmuteButtonAction(sender: AnyObject) {
        let loadingActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.White)
        loadingActivityIndicatorView.startAnimating()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: loadingActivityIndicatorView)
        
        self.configureMuteButton()
        
        userActivitiesMuteRef?.removeValue()
        
        Amplitude.instance().logEvent("Unmuted User", withEventProperties: ["Unmuted User ID": self.userId, "Unmuted User Nickname": self.userNickname])
    }
    
    func configureMuteButton() {
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Mute", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(GOUserProfileViewController.muteButtonAction(_:)))
    }
    
    func configureUnmuteButton() {
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Unmute", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(GOUserProfileViewController.unmuteButtonAction(_:)))
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