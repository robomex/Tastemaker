//
//  VenueViewController.swift
//  Tastemaker
//
//  Created by Tony Morales on 8/11/15.
//  Copyright (c) 2015 Tony Morales. All rights reserved.
//

import UIKit
import ReachabilitySwift
import Firebase
import Amplitude_iOS
import PagingMenuController
import Instructions

class VenueViewController: UIViewController, PagingMenuControllerDelegate, CoachMarksControllerDataSource {

    var venueID: String!
    var venue: Venue?
    
    private let uid: String = NSUserDefaults.standardUserDefaults().objectForKey("uid") as! String
    
    private var userActivitiesSaveHandle = FIRDatabaseHandle?()
    private var userActivitiesSaveRef: FIRDatabaseReference?
    private var venueActivitiesSaverRef: FIRDatabaseReference?
    
    private var userActivitiesSilenceHandle = FIRDatabaseHandle?()
    private var userActivitiesSilenceRef: FIRDatabaseReference?
    
    private var onlineStatusRef: FIRDatabaseReference?
    private var seenNotificationRef: FIRDatabaseReference?
    
    private var saveButton = UIBarButtonItem()
    private var silenceButton = UIBarButtonItem()
    
    let chatVC = VenueChatViewController()
    let detailsVC = VenueDetailsViewController()
    
    var banned: Bool?
    
    let coachMarksController = CoachMarksController()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        view.backgroundColor = UIColor.whiteColor()
        
        // Remove Navigation Controller shadow image to seamlessly blend with PagingMenuController section
        for parent in navigationController!.navigationBar.subviews {
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
        
        addChildViewController(pagingMenuController)
        view.addSubview(pagingMenuController.view)
        pagingMenuController.didMoveToParentViewController(self)
        
        // Save/unsave and silence/unsilence setup, check if currentUser saved/silenced this venue
        
        let loadingActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.White)
        loadingActivityIndicatorView.startAnimating()
        navigationItem.setRightBarButtonItems([UIBarButtonItem(customView: loadingActivityIndicatorView), UIBarButtonItem(customView: loadingActivityIndicatorView)], animated: true)

        // Set a blank text back button here to prevent ellipses from showing as title during nav animation
        if (navigationController != nil) {
            let backButton = UIBarButtonItem(title: " ", style: .Plain, target: nil, action: nil)
            navigationController!.navigationBar.topItem!.backBarButtonItem = backButton
        }

        // Hide the chat inputToolbar if banned
        if banned != nil {
            chatVC.inputToolbar?.hidden = true
        }
        
        // Set notification to "seen" when app enters foreground from background
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(VenueViewController.appDidEnterForeground(_:)), name: UIApplicationWillEnterForegroundNotification, object: nil)
        
        coachMarksController.dataSource = self
        coachMarksController.overlayBackgroundColor = kGray.colorWithAlphaComponent(0.8)
        coachMarksController.allowOverlayTap = true
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if isMovingToParentViewController() {
            userActivitiesSaveRef = DataService.dataService.USER_ACTIVITIES_REF.child("\(uid)/saves")
            venueActivitiesSaverRef = DataService.dataService.VENUE_ACTIVITIES_REF.child("\(venueID)/savers/\(uid)")
            userActivitiesSaveHandle = userActivitiesSaveRef!.observeEventType(FIRDataEventType.Value, withBlock: {
                snapshot in
                
                let enumerator = snapshot.children
                var savedVenues = [String]()
                while let data = enumerator.nextObject() as? FIRDataSnapshot {
                    savedVenues.append(data.key)
                }
                if savedVenues.contains((self.venue?.objectId!)!) {
                    self.configureUnsaveButton()
                } else if snapshot.childrenCount >= 5 {
                    self.navigationItem.setRightBarButtonItems([self.silenceButton], animated: false)
                } else {
                    self.configureSaveButton()
                }
            })
            
            userActivitiesSilenceRef = DataService.dataService.USER_ACTIVITIES_REF.child("\(uid)/silences/\(venueID)")
            userActivitiesSilenceHandle = userActivitiesSilenceRef!.observeEventType(.Value, withBlock: {
                snapshot in
                
                if snapshot.exists() {
                    self.configureUnsilenceButton()
                } else {
                    self.configureSilenceButton()
                }
            })
        }
        
        seenNotificationRef = DataService.dataService.BASE_REF.child("notifications/\(uid)/\(venueID)")
        seenNotificationRef!.observeSingleEventOfType(.Value, withBlock: {
            snapshot in
            
            if snapshot.exists() {
                self.seenNotificationRef!.removeValue()
            }
        })
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        onlineStatusRef = DataService.dataService.BASE_REF.child("onlineStatuses/\(uid)")
        onlineStatusRef?.setValue(["\(venueID)": true])
        
        let hasSeenChatInstructions = NSUserDefaults.standardUserDefaults().boolForKey("HasSeenChatInstructions")
        if !hasSeenChatInstructions {
            coachMarksController.startOn(self)
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "HasSeenChatInstructions")
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        if isMovingFromParentViewController() {
            userActivitiesSaveRef!.removeObserverWithHandle(userActivitiesSaveHandle!)
            userActivitiesSilenceRef!.removeObserverWithHandle(userActivitiesSilenceHandle!)
        }
    
        onlineStatusRef!.removeValue()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: Save actions
    
    func saveButtonAction(sender: AnyObject) {
   
        configureUnsaveButton()
        
        userActivitiesSaveRef?.child(self.venue!.objectId!).setValue(dateFormatter().stringFromDate(NSDate()))
        venueActivitiesSaverRef?.setValue(dateFormatter().stringFromDate(NSDate()))
        
        Amplitude.instance().logEvent("Saved Venue", withEventProperties: ["Venue Name": (venue?.name)!, "Venue Neighborhood": (venue?.neighborhood)!, "Venue Food Type": (venue?.foodType)!])
        Amplitude.instance().identify(AMPIdentify().add("Saves", value: 1))
    }
    
    func unsaveButtonAction(sender: AnyObject) {

        configureSaveButton()
        
        userActivitiesSaveRef?.child(self.venue!.objectId!).removeValue()
        venueActivitiesSaverRef?.removeValue()
        
        Amplitude.instance().logEvent("Unsaved Venue", withEventProperties: ["Venue Name": (venue?.name)!, "Venue Neighborhood": (venue?.neighborhood)!, "Venue Food Type": (venue?.foodType)!])
    }
    
    func configureSaveButton() {
        saveButton = UIBarButtonItem(title: "Save", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(VenueViewController.saveButtonAction(_:)))
        navigationItem.setRightBarButtonItems([saveButton, silenceButton], animated: false)
    }
    
    func configureUnsaveButton() {
        saveButton = UIBarButtonItem(title: "Unsave", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(VenueViewController.unsaveButtonAction(_:)))
        navigationItem.setRightBarButtonItems([saveButton, silenceButton], animated: false)
    }
    
    
    // MARK: Silence actions
    
    func silenceButtonAction(sender: AnyObject) {
        
        userActivitiesSilenceRef?.setValue(dateFormatter().stringFromDate(NSDate()))
        configureUnsilenceButton()
        
        Amplitude.instance().logEvent("Silenced Venue", withEventProperties: ["Venue Name": (venue?.name)!])
    }
    
    func unsilenceButtonAction(sender: AnyObject) {

        userActivitiesSilenceRef?.removeValue()
        configureSilenceButton()
        
        Amplitude.instance().logEvent("Unsilenced Venue", withEventProperties: ["Venue Name": (venue?.name)!])
    }
    
    func configureSilenceButton() {
        silenceButton = UIBarButtonItem(image: UIImage(named: "Notifications.png"), style: .Plain, target: self, action: #selector(VenueViewController.silenceButtonAction(_:)))
        navigationItem.setRightBarButtonItems([saveButton, silenceButton], animated: false)
    }
    
    func configureUnsilenceButton() {
        silenceButton = UIBarButtonItem(image: UIImage(named: "Notifications-Silenced.png"), style: .Plain, target: self, action: #selector(VenueViewController.unsilenceButtonAction(_:)))
        navigationItem.setRightBarButtonItems([saveButton, silenceButton], animated: false)
    }
    
    
    // MARK: PagingMenuController
    
    func willMoveToPageMenuController(menuController: UIViewController, previousMenuController: UIViewController) {
        if previousMenuController == chatVC {
            chatVC.inputToolbar.contentView.textView.resignFirstResponder()
        }
    }
    
    
    // MARK: Observer for flagging new messages as seen upon app entering foreground
    
    func appDidEnterForeground(notification: NSNotification) {
        seenNotificationRef!.observeSingleEventOfType(.Value, withBlock: {
            snapshot in
            
            if snapshot.exists() {
                self.seenNotificationRef!.removeValue()
            }
        })
    }
    
    // MARK: CoachMarksControllerDataSource
    
    func numberOfCoachMarksForCoachMarksController(coachMarksController: CoachMarksController) -> Int {
        return 2
    }
    
    func coachMarksController(coachMarksController: CoachMarksController, coachMarksForIndex index: Int) -> CoachMark {
        switch(index) {
        case 0:
            var chatIntroCoachMark = coachMarksController.coachMarkForView(self.chatVC.view) { (frame: CGRect) -> UIBezierPath in
                
                return UIBezierPath(roundedRect: CGRectInset(frame, 35, 40), cornerRadius: 20)
            }
            chatIntroCoachMark.arrowOrientation = .Bottom
            return chatIntroCoachMark
        case 1:
            var saveCoachMark = coachMarksController.coachMarkForView(navigationItem.rightBarButtonItems![0].valueForKey("view") as? UIView)
            saveCoachMark.horizontalMargin = 5
            return saveCoachMark
        default:
            return coachMarksController.coachMarkForView()
        }
    }
    
    func coachMarksController(coachMarksController: CoachMarksController, coachMarkViewsForIndex index: Int, coachMark: CoachMark) -> (bodyView: CoachMarkBodyView, arrowView: CoachMarkArrowView?) {
        
        let coachViews = coachMarksController.defaultCoachViewsWithArrow(true, arrowOrientation: coachMark.arrowOrientation)
        
        switch(index) {
        case 0:
            coachViews.bodyView.hintLabel.text = "Each venue has its own chat to plan your visit or leave your review"
            coachViews.bodyView.nextLabel.text = "OK!"
            coachViews.bodyView.hintLabel.layoutManager.hyphenationFactor = 0.0
            coachViews.bodyView.hintLabel.textAlignment = .Left
        case 1:
            coachViews.bodyView.hintLabel.text = "Once you find a place you want to remember, hit the Save button to stash up to five venues to My List"
            coachViews.bodyView.nextLabel.text = "👍🏾"
            coachViews.bodyView.hintLabel.layoutManager.hyphenationFactor = 0.0
            coachViews.bodyView.hintLabel.textAlignment = .Left
        default:
            break
        }
        
        return (bodyView: coachViews.bodyView, arrowView: coachViews.arrowView)
    }
}