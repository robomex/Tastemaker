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

class VenueViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {

    var venueID: String!
    var venue: Venue?
    var segmentedControl: UISegmentedControl!
    
    private let uid: String = NSUserDefaults.standardUserDefaults().objectForKey("uid") as! String
    
    private var userActivitiesSaveHandle = UInt?()
    private var userActivitiesSaveRef: Firebase?
    private var venueActivitiesSaverRef: Firebase?
    
    private var userActivitiesSilenceHandle = UInt?()
    private var userActivitiesSilenceRef: Firebase?
    
    private var onlineStatusHandle = UInt?()
    private var onlineStatusRef: Firebase?
    
    private var seenNotificationRef: Firebase?
    
    private var saveButton = UIBarButtonItem()
    private var silenceButton = UIBarButtonItem()
    
    let chatVC = VenueChatViewController()
    let detailsVC = VenueDetailsViewController()
    var orderedViewControllers = [UIViewController]()
    
    var banned: Bool?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        view.backgroundColor = UIColor.whiteColor()
        dataSource = self
        delegate = self
        chatVC.venue = venue
        detailsVC.venue = venue
        orderedViewControllers = [self.chatVC, self.detailsVC]
        setViewControllers([chatVC], direction: UIPageViewControllerNavigationDirection.Forward, animated: true, completion: nil)
        
        let segmentedControlWidth = 140 as CGFloat
        let screenWidth = self.view.frame.size.width
        segmentedControl = UISegmentedControl(items: ["Chat", "Details"])
        segmentedControl.frame = CGRectMake((screenWidth / 2) - (segmentedControlWidth / 2), 10, segmentedControlWidth, 25)
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(VenueViewController.venueSegmentedControlAction(_:)), forControlEvents: .ValueChanged)
        segmentedControl.backgroundColor = UIColor.whiteColor()
        segmentedControl.tintColor = kPurple
        segmentedControl.layer.cornerRadius = 5
        self.view.addSubview(segmentedControl)
        
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
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        userActivitiesSaveRef = DataService.dataService.USER_ACTIVITIES_REF.childByAppendingPath("\(uid)/saves/\(venueID)")
        venueActivitiesSaverRef = DataService.dataService.VENUE_ACTIVITIES_REF.childByAppendingPath("\(venueID)/savers/\(uid)")
        userActivitiesSaveHandle = userActivitiesSaveRef!.observeEventType(FEventType.Value, withBlock: {
            snapshot in
            
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
        
        seenNotificationRef = DataService.dataService.BASE_REF.childByAppendingPath("notifications/\(uid)/\(venueID)")
        seenNotificationRef!.queryOrderedByChild("date").queryLimitedToLast(1).observeSingleEventOfType(FEventType.Value, withBlock: {
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
        
        userActivitiesSaveRef!.removeObserverWithHandle(userActivitiesSaveHandle!)
        userActivitiesSilenceRef!.removeObserverWithHandle(userActivitiesSilenceHandle!)

        onlineStatusRef!.removeValue()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func venueSegmentedControlAction(sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            setViewControllers([chatVC], direction: UIPageViewControllerNavigationDirection.Reverse, animated: true, completion: nil)
        case 1:
            setViewControllers([detailsVC], direction: UIPageViewControllerNavigationDirection.Forward, animated: true, completion: nil)
        default:
            return
        }
    }
    
    
    // MARK: UIPageViewControllerDataSource
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {

        guard let viewControllerIndex = orderedViewControllers.indexOf(viewController) else {
            return nil
        }
        
        let previousIndex = viewControllerIndex - 1
        
        guard previousIndex >= 0 else {
            return nil
        }
        
        guard orderedViewControllers.count > previousIndex else {
            return nil
        }
        
        return orderedViewControllers[previousIndex]
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        
        guard let viewControllerIndex = orderedViewControllers.indexOf(viewController) else {
            return nil
        }
        
        let nextIndex = viewControllerIndex + 1
        
        guard orderedViewControllers.count != nextIndex else {
            return nil
        }
        
        guard orderedViewControllers.count > nextIndex else {
            return nil
        }
        
        return orderedViewControllers[nextIndex]
    }
    
    
    // MARK: UIPageViewControllerDelegate
    
    func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        
        if (!completed) {
            return
        }
        
        if segmentedControl.selectedSegmentIndex == 0 {
            segmentedControl.selectedSegmentIndex = 1
        } else if segmentedControl.selectedSegmentIndex == 1 {
            segmentedControl.selectedSegmentIndex = 0
        }
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
}