//
//  VenueViewController.swift
//  GrandOpens
//
//  Created by Tony Morales on 8/11/15.
//  Copyright (c) 2015 Tony Morales. All rights reserved.
//

import UIKit
import ReachabilitySwift
import Firebase
import Amplitude_iOS
import PagingMenuController

class VenueViewController: UIViewController, PagingMenuControllerDelegate {

    var venueID: String!
    var venue: Venue?
    
    private let uid: String = NSUserDefaults.standardUserDefaults().objectForKey("uid") as! String
    
    private var userActivitiesSaveHandle = UInt?()
    private var userActivitiesSaveRef: Firebase?
    private var venueActivitiesSaverRef: Firebase?
    
    private var userActivitiesSilenceHandle = UInt?()
    private var userActivitiesSilenceRef: Firebase?
    
    private var onlineStatusRef: Firebase?
    private var seenNotificationRef: Firebase?
    
    private var saveButton = UIBarButtonItem()
    private var silenceButton = UIBarButtonItem()
    
    let chatVC = VenueChatViewController()
    let detailsVC = VenueDetailsViewController()
    
    var banned: Bool?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        view.backgroundColor = UIColor.whiteColor()
        
        // Remove Navigation Controller shadow image to seamlessly blend with PagingMenuController section
        for parent in self.navigationController!.navigationBar.subviews {
            for childView in parent.subviews {
                if (childView is UIImageView) {
                    childView.removeFromSuperview()
                }
            }
        }
        
        navigationController!.navigationBar.titleTextAttributes = [NSFontAttributeName: UIFont.systemFontOfSize(22), NSForegroundColorAttributeName: UIColor.whiteColor()]
        
        chatVC.venue = venue
        detailsVC.venue = venue
        chatVC.title = "Chat"
        detailsVC.title = "Details"
        
        let viewControllers = [chatVC, detailsVC]
        
        let options = PagingMenuOptions()
        options.menuItemMargin = 5
        options.backgroundColor = kBlue
        options.selectedBackgroundColor = kBlue
        options.textColor = UIColor.whiteColor()
        options.selectedTextColor = UIColor.whiteColor()
        options.menuHeight = 30
        options.animationDuration = 0.3
        options.menuDisplayMode = .SegmentedControl
        options.menuItemMode = .Underline(height: 3, color: kPurple, horizontalPadding: 5, verticalPadding: 5)
        options.menuDisplayMode = .Standard(widthMode: .Flexible, centerItem: true, scrollingMode: .ScrollEnabled)
        options.font = UIFont.systemFontOfSize(17)
        options.selectedFont = UIFont.systemFontOfSize(17)
        
        let pagingMenuController = PagingMenuController(viewControllers: viewControllers, options: options)
        pagingMenuController.delegate = self
        
        self.addChildViewController(pagingMenuController)
        self.view.addSubview(pagingMenuController.view)
        pagingMenuController.didMoveToParentViewController(self)
        
        // Save/unsave and silence/unsilence setup, check if currentUser saved/silenced this venue
        
        let loadingActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.White)
        loadingActivityIndicatorView.startAnimating()
        self.navigationItem.setRightBarButtonItems([UIBarButtonItem(customView: loadingActivityIndicatorView), UIBarButtonItem(customView: loadingActivityIndicatorView)], animated: true)

        // Set a blank text back button here to prevent ellipses from showing as title during nav animation
        if (navigationController != nil) {
            let backButton = UIBarButtonItem(title: " ", style: .Plain, target: nil, action: nil)
            self.navigationController!.navigationBar.topItem!.backBarButtonItem = backButton
        }

        // Hide the chat inputToolbar if banned
        if self.banned != nil {
            chatVC.inputToolbar?.hidden = true
        }
        
        // Set notification to "seen" when app enters foreground from background
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(VenueViewController.appDidEnterForeground(_:)), name: UIApplicationWillEnterForegroundNotification, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if self.isMovingToParentViewController() {
            userActivitiesSaveRef = DataService.dataService.USER_ACTIVITIES_REF.childByAppendingPath("\(uid)/saves/\(venueID)")
            venueActivitiesSaverRef = DataService.dataService.VENUE_ACTIVITIES_REF.childByAppendingPath("\(venueID)/savers/\(uid)")
            userActivitiesSaveHandle = userActivitiesSaveRef!.observeEventType(FEventType.Value, withBlock: {
                snapshot in
                
                // Nested if statements for unwrapping
                if snapshot.exists() {
                    if snapshot.value.objectForKey("saved") as! Bool == true {
                        self.configureUnsaveButton()
                    } else {
                        self.configureSaveButton()
                    }
                } else {
                    self.configureSaveButton()
                }
            })
            
            userActivitiesSilenceRef = DataService.dataService.USER_ACTIVITIES_REF.childByAppendingPath("\(uid)/silences/\(venueID)")
            userActivitiesSilenceHandle = userActivitiesSilenceRef!.observeEventType(.Value, withBlock: {
                snapshot in
                
                if snapshot.exists() {
                    if snapshot.value.objectForKey("silenced") as! Bool == true {
                        self.configureUnsilenceButton()
                    } else {
                        self.configureSilenceButton()
                    }
                } else {
                    self.configureSilenceButton()
                }
            })
        }
        
        seenNotificationRef = DataService.dataService.BASE_REF.childByAppendingPath("notifications/\(uid)/\(venueID)")
        seenNotificationRef!.queryOrderedByChild("date").queryLimitedToLast(1).observeSingleEventOfType(.Value, withBlock: {
            snapshot in
            
            if snapshot.exists() {
                let enumerator = snapshot.children
                while let seenNotifications = enumerator.nextObject() as? FDataSnapshot {
                    self.seenNotificationRef?.childByAppendingPath("\(seenNotifications.key)/seen").setValue(true)
                }
            }
        })
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        onlineStatusRef = DataService.dataService.BASE_REF.childByAppendingPath("onlineStatuses/\(uid)")
        onlineStatusRef?.setValue(["\(self.venueID)": true])
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        if self.isMovingFromParentViewController() {
            userActivitiesSaveRef!.removeObserverWithHandle(userActivitiesSaveHandle!)
            userActivitiesSilenceRef!.removeObserverWithHandle(userActivitiesSilenceHandle!)
            chatVC.messageListener!.stop((chatVC.venue?.objectId)!)
            DataService.dataService.USER_ACTIVITIES_REF.childByAppendingPath("\(chatVC.uid)/visits/\(chatVC.venue?.objectId)").removeObserverWithHandle(chatVC.visitRefHandle)
            print("venueVC did disappear")
        }
    
        onlineStatusRef!.removeValue()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: Save actions
    
    func saveButtonAction(sender: AnyObject) {
   
        self.configureUnsaveButton()
        
        userActivitiesSaveRef?.updateChildValues(["saved": true, "updatedOn": dateFormatter().stringFromDate(NSDate())])
        venueActivitiesSaverRef?.childByAutoId().updateChildValues(["saved": true, "date": dateFormatter().stringFromDate(NSDate())])
        
        Amplitude.instance().logEvent("Saved Venue", withEventProperties: ["Venue Name": (venue?.name)!, "Venue Neighborhood": (venue?.neighborhood)!, "Venue Food Type": (venue?.foodType)!])
        Amplitude.instance().identify(AMPIdentify().add("Saves", value: 1).append("Saves-Venues", value: (venue?.name)!))
    }
    
    func unsaveButtonAction(sender: AnyObject) {

        self.configureSaveButton()
        
        userActivitiesSaveRef?.updateChildValues(["saved": false, "updatedOn": dateFormatter().stringFromDate(NSDate())])
        venueActivitiesSaverRef?.childByAutoId().updateChildValues(["saved": false, "date": dateFormatter().stringFromDate(NSDate())])
        
        Amplitude.instance().logEvent("Unsaved Venue", withEventProperties: ["Venue Name": (venue?.name)!, "Venue Neighborhood": (venue?.neighborhood)!, "Venue Food Type": (venue?.foodType)!])
    }
    
    func configureSaveButton() {
        self.saveButton = UIBarButtonItem(title: "Save", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(VenueViewController.saveButtonAction(_:)))
        self.navigationItem.setRightBarButtonItems([self.saveButton, self.silenceButton], animated: false)
    }
    
    func configureUnsaveButton() {
        self.saveButton = UIBarButtonItem(title: "Unsave", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(VenueViewController.unsaveButtonAction(_:)))
        self.navigationItem.setRightBarButtonItems([self.saveButton, self.silenceButton], animated: false)
    }
    
    
    // MARK: Silence actions
    
    func silenceButtonAction(sender: AnyObject) {
        
        self.configureUnsilenceButton()
        userActivitiesSilenceRef?.updateChildValues(["silenced": true, "updatedOn": dateFormatter().stringFromDate(NSDate())])
        
        // ADD AMPLITUDE TRACKING
    }
    
    func unsilenceButtonAction(sender: AnyObject) {

        self.configureSilenceButton()
        userActivitiesSilenceRef?.updateChildValues(["silenced": false, "updatedOn": dateFormatter().stringFromDate(NSDate())])
        
        // ADD AMPLITUDE TRACKING
    }
    
    func configureSilenceButton() {
        self.silenceButton = UIBarButtonItem(image: UIImage(named: "Notifications.png"), style: .Plain, target: self, action: #selector(VenueViewController.silenceButtonAction(_:)))
        self.navigationItem.setRightBarButtonItems([self.saveButton, self.silenceButton], animated: false)
    }
    
    func configureUnsilenceButton() {
        self.silenceButton = UIBarButtonItem(image: UIImage(named: "Notifications-Silenced.png"), style: .Plain, target: self, action: #selector(VenueViewController.unsilenceButtonAction(_:)))
        self.navigationItem.setRightBarButtonItems([self.saveButton, self.silenceButton], animated: false)
    }
    
    
    // MARK: PagingMenuController
    
    func willMoveToPageMenuController(menuController: UIViewController, previousMenuController: UIViewController) {
        if previousMenuController == chatVC {
            chatVC.inputToolbar.contentView.textView.resignFirstResponder()
        }
    }
    
    
    // MARK: Observer for flagging new messages as seen upon app entering foreground
    
    func appDidEnterForeground(notification: NSNotification) {
        seenNotificationRef!.queryOrderedByChild("date").queryLimitedToLast(1).observeSingleEventOfType(.Value, withBlock: {
            snapshot in
            
            if snapshot.exists() {
                let enumerator = snapshot.children
                while let seenNotifications = enumerator.nextObject() as? FDataSnapshot {
                    self.seenNotificationRef?.childByAppendingPath("\(seenNotifications.key)/seen").setValue(true)
                }
            }
        })
    }
}