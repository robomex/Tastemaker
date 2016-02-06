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
import Firebase
//import SCLAlertView
import SCLAlertView_Objective_C
//import TTTAttributedLabel
//import SafariServices

class VenueViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {

    var venueID: String!
    var venue: Venue?
    var segmentedControl: UISegmentedControl!
    
    private let uid: String = NSUserDefaults.standardUserDefaults().objectForKey("uid") as! String
    
    private var userActivitiesSaveHandle = UInt?()
//    private var authRefHandle = UInt?()
    private var userActivitiesSaveRef: Firebase?
    private var venueActivitiesSaverRef: Firebase?
    
//    private var signupLabel: TTTAttributedLabel!
    
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
        
//        let queryIsSaved = PFQuery(className: kVenueActivityClassKey)
//        queryIsSaved.whereKey(kVenueActivityTypeKey, equalTo: kVenueActivityTypeSave)
//        queryIsSaved.whereKey(kVenueActivityToVenueKey, equalTo: self.venue!)
//        queryIsSaved.whereKey(kVenueActivityByUserKey, equalTo: PFUser.currentUser()!)
//        queryIsSaved.cachePolicy = PFCachePolicy.CacheThenNetwork
//        queryIsSaved.countObjectsInBackgroundWithBlock { (number, error) in
//            if error != nil && error!.code != PFErrorCode.ErrorCacheMiss.rawValue {
//                print("Couldn't determine save relationship: \(error)")
//                self.navigationItem.rightBarButtonItem = nil
//            } else {
//                if number == 0 {
//                    self.configureSaveButton()
//                } else {
//                    self.configureUnsaveButton()
//                }
//                
//            }
//            
//        }
        
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
//        if PFUser.currentUser()!.objectForKey("banned") as? Bool == true {
//            chatVC.inputToolbar?.hidden = true
//        }
        
        // Reachability checks
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reachabilityChanged:", name: ReachabilityChangedNotification, object: reachability)
        try! reachability.startNotifier()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: ReachabilityChangedNotification, object: reachability)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        userActivitiesSaveRef = DataService.dataService.USER_ACTIVITIES_REF.childByAppendingPath("\(uid)/saves/\(venueID)")
        venueActivitiesSaverRef = DataService.dataService.VENUE_ACTIVITIES_REF.childByAppendingPath("\(venueID)/savers/\(uid)")
        userActivitiesSaveHandle = userActivitiesSaveRef!.observeEventType(FEventType.Value, withBlock: {
            snapshot in
            
            if snapshot.exists() {
                self.configureUnsaveButton()
            } else {
                self.configureSaveButton()
            }
        })
        
//        authRefHandle = DataService.dataService.BASE_REF.observeAuthEventWithBlock({
//            authData in
//            
//            if authData == nil {
//                self.presentLogin()
//            }
//        })
        
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
//        DataService.dataService.BASE_REF.removeAuthEventObserverWithHandle(authRefHandle!)
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
    
    
    // MARK: Account and login
    
    func presentLogin() {
        let alert = SCLAlertView()
        let emailTextField = alert.addTextField("Email")
        let passwordTextField = alert.addTextField("Password")
        let usernameTextField = alert.addTextField("Choose a username")
        
        emailTextField.autocorrectionType = .No
        emailTextField.keyboardType = .EmailAddress
        passwordTextField.autocorrectionType = .No
        passwordTextField.secureTextEntry = true
        passwordTextField.keyboardType = .Default
        usernameTextField.autocorrectionType = .No
        usernameTextField.keyboardType = .Default
        
        alert.addButton("Create Account", validationBlock: {
            let email = emailTextField.text
            let password = passwordTextField.text
            let username = usernameTextField.text
            
            if email == "" {
                showSimpleAlertWithTitle("Whoops!", message: "You forgot to enter your email", actionTitle: "OK", viewController: self)
                emailTextField.becomeFirstResponder()
                return false
            } else if !self.isValidEmail(email!) {
                showSimpleAlertWithTitle("Whoops!", message: "Please enter a valid email address", actionTitle: "OK", viewController: self)
                emailTextField.becomeFirstResponder()
                return false
            }

            let regex = try! NSRegularExpression(pattern: ".*[^A-Za-z0-9].*", options: NSRegularExpressionOptions())
            if password?.characters.count < 6 {
                showSimpleAlertWithTitle("Whoops!", message: "Choose a password at least 6 characters long", actionTitle: "OK", viewController: self)
                // The below line is causing the error 'Snapshotting a view that has not been rendered results in an empty snapshot'
                passwordTextField.becomeFirstResponder()
                return false
            } else if regex.firstMatchInString(password!, options: NSMatchingOptions(), range: NSMakeRange(0, (password?.characters.count)!)) != nil {
                showSimpleAlertWithTitle("Whoops!", message: "Choose a password without special characters", actionTitle: "OK", viewController: self)
                passwordTextField.becomeFirstResponder()
                return false
            }
            
            if username == "" {
                showSimpleAlertWithTitle("Whoops!", message: "Choose a username first", actionTitle: "OK", viewController: self)
                usernameTextField.becomeFirstResponder()
                return false
            } else if username?.characters.count > 20 {
                showSimpleAlertWithTitle("Whoops!", message: "Choose a shorter username", actionTitle: "OK", viewController: self)
                usernameTextField.becomeFirstResponder()
                return false
            }
            
                return false
            }, actionBlock: {
                print("you registered")
        })
        alert.showAnimationType = SCLAlertViewShowAnimation.FadeIn
        alert.hideAnimationType = SCLAlertViewHideAnimation.FadeOut
        alert.backgroundType = SCLAlertViewBackground.Shadow
        alert.customViewColor = kPurple
        
//        let signupText: NSString = "By tapping Create Account you agree to our Terms of Service and confirm you have read our Privacy Policy"
//        signupLabel.delegate = self
//        signupLabel.text = signupText as String
//        let signupLabelLinkAttributes: [NSObject: AnyObject] = [
//            kCTForegroundColorAttributeName: kBlue,
//            NSUnderlineColorAttributeName: NSNumber(bool: false)
//        ]
//        signupLabel.linkAttributes = signupLabelLinkAttributes
//        signupLabel.inactiveLinkAttributes = nil
//        let termsOfServiceRange: NSRange = signupText.rangeOfString("Terms of Service")
//        signupLabel.addLinkToURL(NSURL(string: kTermsOfServiceURL)!, withRange: termsOfServiceRange)
//        let privacyPolicyRange: NSRange = signupText.rangeOfString("Privacy Policy")
//        signupLabel.addLinkToURL(NSURL(string: kPrivacyPolicyURL), withRange: privacyPolicyRange)
//        //
//        alert.attributedFormatBlock (String) {
//            var subtitle: NSMutableAttributedString = NSMutableAttributedString(string: value)
//            return subtitle
//        }
        alert.showEdit(self.view.window?.rootViewController, title: "Sign up to join the chat!", subTitle: "No pressure, you can change your username at any time", closeButtonTitle: "Cancel", duration: 0)
    }
    
    func isValidEmail(emailAddress: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}"
        let emailTest = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailTest.evaluateWithObject(emailAddress)
    }
    
    
    // MARK: Save actions
    
    func saveButtonAction(sender: AnyObject) {
        let loadingActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.White)
        loadingActivityIndicatorView.startAnimating()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: loadingActivityIndicatorView)
        
        self.configureUnsaveButton()
        
        userActivitiesSaveRef?.setValue(true)
        venueActivitiesSaverRef?.setValue(true)
//        GOUtility.saveVenueEventually(self.venue!, block: { (succeeded, error) in
//            if error != nil {
//                self.configureSaveButton()
//            }
//        })
    }
    
    func unsaveButtonAction(sender: AnyObject) {
        let loadingActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.White)
        loadingActivityIndicatorView.startAnimating()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: loadingActivityIndicatorView)
        
        self.configureSaveButton()
        
        userActivitiesSaveRef?.removeValue()
        venueActivitiesSaverRef?.removeValue()
//        GOUtility.unsaveVenueEventually(self.venue!)
    }
    
    func configureSaveButton() {
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: UIBarButtonItemStyle.Plain, target: self, action: Selector("saveButtonAction:"))
//        GOCache.sharedCache.setVenueIsSavedByCurrentUser(false, venue: self.venue!)
    }
    
    func configureUnsaveButton() {
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Unsave", style: UIBarButtonItemStyle.Plain, target: self, action: Selector("unsaveButtonAction:"))
//        GOCache.sharedCache.setVenueIsSavedByCurrentUser(true, venue: self.venue!)
    }
    
    
    // MARK: Reachability
    
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
                let announcement = Announcement(title: "Internet Connection Lost!", subtitle: "We'll refresh everything automatically when reconnected", image: nil, duration: 4.0, action: nil)
                ColorList.Shout.background = kRed
                ColorList.Shout.title = UIColor.whiteColor()
                ColorList.Shout.subtitle = UIColor.whiteColor()
                Shout(announcement, to: self)
            }
        }
    }
}