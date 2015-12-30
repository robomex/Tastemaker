//
//  VenueViewController.swift
//  GrandOpens
//
//  Created by Tony Morales on 8/11/15.
//  Copyright (c) 2015 Tony Morales. All rights reserved.
//

import UIKit
import Parse

class VenueViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {

    var venueID: String?
    var venue: PFObject?
    var segmentedControl: UISegmentedControl!
    
    let chatVC = VenueChatViewController()
    let detailsVC = VenueDetailsViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        view.backgroundColor = UIColor.whiteColor()
        dataSource = self
        delegate = self
        chatVC.venueID = venue?.objectId
        detailsVC.venue = venue
        setViewControllers([chatVC], direction: UIPageViewControllerNavigationDirection.Forward, animated: true, completion: nil)
        
        let frame = UIScreen.mainScreen().bounds
        segmentedControl = UISegmentedControl(items: ["Chat", "Details"])
        segmentedControl.frame = CGRectMake(frame.minX + 100, frame.minY + 70, frame.width - 200, frame.height * 0.04)
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
        
        let queryIsSaved = PFQuery(className: kActivityClassKey)
        queryIsSaved.whereKey(kActivityTypeKey, equalTo: kActivityTypeSave)
        queryIsSaved.whereKey(kActivityToObjectKey, equalTo: self.venue!)
        queryIsSaved.whereKey(kActivityByUserKey, equalTo: PFUser.currentUser()!)
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
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func goToNextVC() {
        let nextVC = pageViewController(self, viewControllerAfterViewController: viewControllers![0])!
        setViewControllers([nextVC], direction: UIPageViewControllerNavigationDirection.Forward, animated: true, completion: nil)
    }
    
    func goToPreviousVC() {
        let previousVC = pageViewController(self, viewControllerBeforeViewController: viewControllers![0])!
        setViewControllers([previousVC], direction: UIPageViewControllerNavigationDirection.Reverse, animated: true, completion: nil)
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
}