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
import Whisper

class VenueViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {

    var venueID: String?
    var venue: PFObject?
    var segmentedControl: UISegmentedControl!
    
    let chatVC = VenueChatViewController()
    let detailsVC = VenueDetailsViewController()
    let reachability = try! Reachability.reachabilityForInternetConnection()
    
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
        
        let queryIsSaved = PFQuery(className: kVenueActivityClassKey)
        queryIsSaved.whereKey(kVenueActivityTypeKey, equalTo: kVenueActivityTypeSave)
        queryIsSaved.whereKey(kVenueActivityToVenueKey, equalTo: self.venue!)
        queryIsSaved.whereKey(kVenueActivityByUserKey, equalTo: PFUser.currentUser()!)
        queryIsSaved.cachePolicy = PFCachePolicy.CacheThenNetwork
        queryIsSaved.countObjectsInBackgroundWithBlock { (number, error) in
            if error != nil && error!.code != PFErrorCode.ErrorCacheMiss.rawValue {
                print("Couldn't determine save relationship: \(error)")
                self.navigationItem.rightBarButtonItem = nil
            } else {
                if number == 0 {
                    self.configureSaveButton()
                } else {
                    self.configureUnsaveButton()
                }
                
            }
            
        }
        
        // Set a blank text back button here to prevent ellipses from showing as title during nav animation
        if (navigationController != nil) {
            let backButton = UIBarButtonItem(title: " ", style: .Plain, target: nil, action: nil)
            self.navigationController!.navigationBar.topItem!.backBarButtonItem = backButton
        }
        
        // Hide the chat inputToolbar unless they've visited the venue
        if !GOCache.sharedCache.isVenueVistedByCurrentUser(self.venue!) && venue!.objectForKey(kVenueName) as! String != "Chicago Chat" {
            chatVC.inputToolbar?.hidden = true
        }

        // Hide the chat inputToolbar if banned
        let user = PFUser.currentUser()
        user?.fetchInBackgroundWithBlock { (object, error) -> Void in
            let banned = object!.objectForKey("banned") as! Bool
            if banned == true {
                self.chatVC.inputToolbar?.hidden = true
            }
        }
        
        // Reachability checks
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reachabilityChanged:", name: ReachabilityChangedNotification, object: reachability)
        try! reachability.startNotifier()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: ReachabilityChangedNotification, object: reachability)
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
    
    
    // MARK: ()
    
    func saveButtonAction(sender: AnyObject) {
        let loadingActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.White)
        loadingActivityIndicatorView.startAnimating()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: loadingActivityIndicatorView)
        
        self.configureUnsaveButton()
        
        GOUtility.saveVenueEventually(self.venue!, block: { (succeeded, error) in
            if error != nil {
                self.configureSaveButton()
            }
        })
    }
    
    func unsaveButtonAction(sender: AnyObject) {
        let loadingActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.White)
        loadingActivityIndicatorView.startAnimating()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: loadingActivityIndicatorView)
        
        self.configureSaveButton()
        
        GOUtility.unsaveVenueEventually(self.venue!)
    }
    
    func configureSaveButton() {
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: UIBarButtonItemStyle.Plain, target: self, action: Selector("saveButtonAction:"))
        GOCache.sharedCache.setVenueIsSavedByCurrentUser(false, venue: self.venue!)
    }
    
    func configureUnsaveButton() {
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Unsave", style: UIBarButtonItemStyle.Plain, target: self, action: Selector("unsaveButtonAction:"))
        GOCache.sharedCache.setVenueIsSavedByCurrentUser(true, venue: self.venue!)
    }
    
    func reachabilityChanged(note: NSNotification) {
        let reachability = note.object as! Reachability
        
        dispatch_async(dispatch_get_main_queue()) {
            if reachability.isReachable() {
                if reachability.isReachableViaWiFi() {
                    print("reachable via wifi - venueVC")
                } else {
                    print("reachable via cellular - venueVC")
                }
            } else {
                let announcement = Announcement(title: "Internet Connection Lost!", subtitle: "Try again in a bit", image: nil, duration: 4.0, action: nil)
                ColorList.Shout.background = kRed
                ColorList.Shout.title = UIColor.whiteColor()
                ColorList.Shout.subtitle = UIColor.whiteColor()
                Shout(announcement, to: self)
            }
        }
    }
}