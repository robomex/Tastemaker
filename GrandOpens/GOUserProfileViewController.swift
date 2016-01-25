//
//  GOUserProfileViewController.swift
//  GrandOpens
//
//  Created by Tony Morales on 1/20/16.
//  Copyright © 2016 Tony Morales. All rights reserved.
//

import UIKit
import ParseUI
import Parse

class GOUserProfileViewController: ListViewController {

    var user: PFUser?
    private var headerView: UIView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if user?.objectForKey(kUserDisplayNameKey) == nil || (user?.objectForKey(kUserDisplayNameKey))! as! String == "" {
            self.title = "A No-Namer"
        } else {
            self.title = user?.objectForKey(kUserDisplayNameKey) as? String
        }
        
        self.headerView = UIView(frame: CGRectMake(0.0, 0.0, self.tableView.bounds.size.width, 222.0))
        // Should be clear, this will be the container for our avatar, counts, and whatevz later
        self.headerView!.backgroundColor = UIColor.clearColor()
        
        let texturedBackgroundView: UIView = UIView(frame: self.view.bounds)
        texturedBackgroundView.backgroundColor = UIColor.whiteColor()
        self.tableView.backgroundView = texturedBackgroundView
        
        let profilePictureBackgroundView = UIView(frame: CGRectMake(94.0, 38.0, 132.0, 132.0))
        profilePictureBackgroundView.backgroundColor = UIColor.lightGrayColor()
        profilePictureBackgroundView.alpha = 0.0
        var layer: CALayer = profilePictureBackgroundView.layer
        layer.cornerRadius = 66.0
        layer.masksToBounds = true
        self.headerView!.addSubview(profilePictureBackgroundView)
        
        let profilePictureImageView: PFImageView = PFImageView(frame: CGRectMake(94.0, 38.0, 132.0, 132.0))
        self.headerView!.addSubview(profilePictureImageView)
        profilePictureImageView.contentMode = UIViewContentMode.ScaleAspectFill
        layer = profilePictureImageView.layer
        layer.cornerRadius = 66.0
        layer.masksToBounds = true
        profilePictureImageView.alpha = 0.0
        
        if GOUtility.userHasProfilePicture(self.user!) {
            let imageFile: PFFile! = self.user!.objectForKey(kUserProfilePicKey) as! PFFile
            profilePictureImageView.file = imageFile
            profilePictureImageView.loadInBackground { (image, error) in
                if error == nil {
                    UIView.animateWithDuration(0.2, animations: {
                        profilePictureBackgroundView.alpha = 1.0
                        profilePictureImageView.alpha = 1.0
                    })
                    
                    let backgroundImageView = UIImageView(image: image!) // .applyDarkEffect() is throwing an error
                    backgroundImageView.frame = self.tableView.backgroundView!.bounds
                    backgroundImageView.alpha = 0.0
                    backgroundImageView.contentMode = UIViewContentMode.ScaleAspectFill
                    let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .ExtraLight))
                    visualEffectView.frame = backgroundImageView.bounds
                    backgroundImageView.addSubview(visualEffectView)
                    self.tableView.backgroundView!.addSubview(backgroundImageView)
                    
                    UIView.animateWithDuration(0.2, animations: {
                        backgroundImageView.alpha = 1.0
                    })
                }
            }
        } else {
            profilePictureImageView.image = GOUtility.defaultProfilePicture()
            UIView.animateWithDuration(0.2, animations: {
                profilePictureBackgroundView.alpha = 1.0
                profilePictureImageView.alpha = 1.0
            })
            
            let backgroundImageView = UIImageView(image: GOUtility.defaultProfilePicture()!)
            backgroundImageView.frame = self.tableView.backgroundView!.bounds
            backgroundImageView.alpha = 0.0
            backgroundImageView.contentMode = UIViewContentMode.ScaleAspectFill
            let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .ExtraLight))
            visualEffectView.frame = backgroundImageView.bounds
            backgroundImageView.addSubview(visualEffectView)
            self.tableView.backgroundView!.addSubview(backgroundImageView)
            
            UIView.animateWithDuration(0.2, animations: {
                backgroundImageView.alpha = 1.0
            })
        }
        
        if self.user!.objectId != PFUser.currentUser()!.objectId {
            let loadingActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
            loadingActivityIndicatorView.startAnimating()
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: loadingActivityIndicatorView)
            
            // check if the currentUser is muting this user
            let queryIsMuting = PFQuery(className: kUserActivityClassKey)
            queryIsMuting.whereKey(kUserActivityTypeKey, equalTo: kUserActivityTypeMute)
            queryIsMuting.whereKey(kUserActivityToUserKey, equalTo: self.user!)
            queryIsMuting.whereKey(kUserActivityByUserKey, equalTo: PFUser.currentUser()!)
            queryIsMuting.cachePolicy = PFCachePolicy.CacheThenNetwork
            queryIsMuting.countObjectsInBackgroundWithBlock { (number, error) in
                if error != nil && error!.code != PFErrorCode.ErrorCacheMiss.rawValue {
                    print("Couldn't determine mute relationship: \(error)")
                    self.navigationItem.rightBarButtonItem = nil
                } else {
                    if number == 0 {
                        self.configureMuteButton()
                    } else {
                        self.configureUnmuteButton()
                    }
                }
            }
        }
        
        // Set a blank text back button here to prevent ellipses from showing as title during nav animation
        if (navigationController != nil) {
            let backButton = UIBarButtonItem(title: " ", style: .Plain, target: nil, action: nil)
            self.navigationController!.navigationBar.topItem!.backBarButtonItem = backButton
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.tabBarController!.tabBar.hidden = true
    }
    
    
    // MARK:- PFQueryTableViewController
    
    override func objectsDidLoad(error: NSError?) {
        super.objectsDidLoad(error)
        
        self.tableView.tableHeaderView = headerView!
    }
    
    override func queryForTable() -> PFQuery {
        let userSavedVenues = PFQuery(className: kVenueActivityClassKey)
        userSavedVenues.cachePolicy = PFCachePolicy.NetworkOnly
        userSavedVenues.whereKey(kVenueActivityByUserKey, equalTo: user!)
        userSavedVenues.whereKey(kVenueActivityTypeKey, equalTo: kVenueActivityTypeSave)
        userSavedVenues.orderByAscending("createdAt")
        userSavedVenues.includeKey(kVenueActivityToVenueKey)
        
        return userSavedVenues
    }
    
    
    // MARK:- TableViewController
    
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.text = user!.objectForKey(kUserDisplayNameKey) as? String ?? "A No-Namer"
        if header.textLabel?.text == "" {
            header.textLabel?.text = "A No-Namer"
        }
        header.textLabel?.font = UIFont.systemFontOfSize(16)
        header.textLabel?.textColor = UIColor.darkGrayColor()
        header.textLabel?.text = header.textLabel!.text! + "'s Saved Venues"
    }
    
   override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30.0
    }
    
    
    // MARK:- ()
    
    func muteButtonAction(sender: AnyObject) {
        let loadingActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
        loadingActivityIndicatorView.startAnimating()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: loadingActivityIndicatorView)
        
        self.configureUnmuteButton()
        
        GOUtility.muteUserInBackground(self.user!, block: { (succeeded, error) in
            if error != nil {
                self.configureMuteButton()
            }
        })
    }
    
    func unmuteButtonAction(sender: AnyObject) {
        let loadingActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
        loadingActivityIndicatorView.startAnimating()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: loadingActivityIndicatorView)
        
        self.configureMuteButton()
        
        GOUtility.unmuteUserInBackground(self.user!)
    }
    
    func configureMuteButton() {
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Mute", style: UIBarButtonItemStyle.Plain, target: self, action: "muteButtonAction:")
        GOCache.sharedCache.setMuteStatus(false, userId: self.user!.objectId!)
    }
    
    func configureUnmuteButton() {
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Unmute", style: UIBarButtonItemStyle.Plain, target: self, action: "unmuteButtonAction:")
        GOCache.sharedCache.setMuteStatus(true, userId: self.user!.objectId!)
    }
}