//
//  VenueViewController.swift
//  GrandOpens
//
//  Created by Tony Morales on 8/11/15.
//  Copyright (c) 2015 Tony Morales. All rights reserved.
//

import UIKit
import Parse
import ReachabilitySwift
import Firebase
import SCLAlertView_Objective_C

class VenueViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {

    var venueID: String!
    var venue: Venue?
    var segmentedControl: UISegmentedControl!
    
    private let uid: String = NSUserDefaults.standardUserDefaults().objectForKey("uid") as! String
    
    private var userActivitiesSaveHandle = UInt?()
    private var userActivitiesSaveRef: Firebase?
    private var venueActivitiesSaverRef: Firebase?
    
    let chatVC = VenueChatViewController()
    let detailsVC = VenueDetailsViewController()
    
    var banned: Bool?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        view.backgroundColor = UIColor.whiteColor()
        dataSource = self
        delegate = self
        chatVC.venueID = venue?.objectId
        detailsVC.venue = venue
        setViewControllers([chatVC], direction: UIPageViewControllerNavigationDirection.Forward, animated: true, completion: nil)
        
        let segmentedControlWidth = 140 as CGFloat
        let screenWidth = self.view.frame.size.width
        segmentedControl = UISegmentedControl(items: ["Chat", "Details"])
        segmentedControl.frame = CGRectMake((screenWidth / 2) - (segmentedControlWidth / 2), 10, segmentedControlWidth, 25)
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: "venueSegmentedControlAction:", forControlEvents: .ValueChanged)
        segmentedControl.backgroundColor = UIColor.whiteColor()
        segmentedControl.tintColor = kPurple
        segmentedControl.layer.cornerRadius = 5
        self.view.addSubview(segmentedControl)
        
        // Save and unsave setup, check if currentUser saved this venue
        
        let loadingActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.White)
        loadingActivityIndicatorView.startAnimating()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: loadingActivityIndicatorView)
        
        // Set a blank text back button here to prevent ellipses from showing as title during nav animation
        if (navigationController != nil) {
            let backButton = UIBarButtonItem(title: " ", style: .Plain, target: nil, action: nil)
            self.navigationController!.navigationBar.topItem!.backBarButtonItem = backButton
        }
        
        // Hide the chat inputToolbar unless they've visited the venue
//        if !GOCache.sharedCache.isVenueVisitedByCurrentUser(self.venue!) && venue!.objectForKey(kVenueName) as! String != "Chicago Chat" {
//            chatVC.inputToolbar?.hidden = true
//        }

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
                if snapshot.value["saved"] as! Bool == true {
                    self.configureUnsaveButton()
                } else {
                    self.configureSaveButton()
                }
            } else {
                self.configureSaveButton()
            }
        })
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        userActivitiesSaveRef!.removeObserverWithHandle(userActivitiesSaveHandle!)
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
        
        switch viewController {
        case detailsVC: return chatVC
        default: return nil
        }
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        
        switch viewController {
        case chatVC: return detailsVC
        default: return nil
        }
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
        let loadingActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.White)
        loadingActivityIndicatorView.startAnimating()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: loadingActivityIndicatorView)
        
        self.configureUnsaveButton()
        
        userActivitiesSaveRef?.updateChildValues(["saved": true, "updatedOn": dateFormatter().stringFromDate(NSDate())])
        venueActivitiesSaverRef?.childByAutoId().updateChildValues(["saved": true, "date": dateFormatter().stringFromDate(NSDate())])
    }
    
    func unsaveButtonAction(sender: AnyObject) {
        let loadingActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.White)
        loadingActivityIndicatorView.startAnimating()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: loadingActivityIndicatorView)
        
        self.configureSaveButton()
        
        userActivitiesSaveRef?.updateChildValues(["saved": false, "updatedOn": dateFormatter().stringFromDate(NSDate())])
        venueActivitiesSaverRef?.childByAutoId().updateChildValues(["saved": false, "date": dateFormatter().stringFromDate(NSDate())])
    }
    
    func configureSaveButton() {
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: UIBarButtonItemStyle.Plain, target: self, action: Selector("saveButtonAction:"))
    }
    
    func configureUnsaveButton() {
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Unsave", style: UIBarButtonItemStyle.Plain, target: self, action: Selector("unsaveButtonAction:"))
    }
}