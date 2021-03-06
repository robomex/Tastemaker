//
//  InitialViewController.swift
//  Tastemaker
//
//  Created by Tony Morales on 7/23/15.
//  Copyright (c) 2015 Tony Morales. All rights reserved.
//

import UIKit
import CoreLocation
import Firebase
import PermissionScope
import Amplitude_iOS

class InitialViewController: UIViewController {

    let pscope = PermissionScope()
    var authHandle = FIRAuthStateDidChangeListenerHandle?()
    // Had to add userLoggedIn flag since addAuthStateDidChangeListener was firing twice as of May 26
    var userLoggedIn: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        pscope.addPermission(NotificationsPermission(notificationCategories: nil), message: "Allow to know when someone replies to you + be the first to hear news")
        pscope.addPermission(LocationAlwaysPermission(), message: "Enable to find the newest places around + unlock voting for places you've been")
        pscope.headerLabel.text = "Let's get set up"
        pscope.bodyLabel.text = "Tastemaker works best with the following permissions"
        pscope.permissionButtonBorderColor = kBlue
        pscope.permissionButtonTextColor = kBlue
        pscope.closeButtonTextColor = UIColor.clearColor()
        pscope.authorizedButtonColor = kBlue
        pscope.unauthorizedButtonColor = kRed
        pscope.closeButton.titleLabel?.text = "X"
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        authHandle = FIRAuth.auth()!.addAuthStateDidChangeListener() {
            (auth, user) in
            
            if user != nil {
                if NSUserDefaults.standardUserDefaults().objectForKey("uid") == nil || NSUserDefaults.standardUserDefaults().objectForKey("nickname") ==  nil {
                    
                    // Clear NSUserDefaults
                    let appDomain = NSBundle.mainBundle().bundleIdentifier!
                    NSUserDefaults.standardUserDefaults().removePersistentDomainForName(appDomain)
                    
                    self.userLoggedIn = false
                    try! FIRAuth.auth()!.signOut()
                    Amplitude.instance().setUserId(nil)
                }
                
                // This check added in case the account is deleted in the database, they will be logged out
                if NSUserDefaults.standardUserDefaults().objectForKey("uid") != nil {
                    
                    Amplitude.instance().setUserId(NSUserDefaults.standardUserDefaults().objectForKey("uid") as! String)
                    
                    DataService.dataService.USERS_PUBLIC_REF.child(NSUserDefaults.standardUserDefaults().objectForKey("uid") as! String).observeSingleEventOfType(.Value, withBlock: {
                        snapshot in
                        
                        if !snapshot.exists() {
                            // Clear NSUserDefaults
                            let appDomain = NSBundle.mainBundle().bundleIdentifier!
                            NSUserDefaults.standardUserDefaults().removePersistentDomainForName(appDomain)
                            
                            self.userLoggedIn = false
                            try! FIRAuth.auth()!.signOut()
                            Amplitude.instance().setUserId(nil)
                        }
                    })
                }
                
                let launchedBefore = NSUserDefaults.standardUserDefaults().boolForKey("LaunchedBefore")
                if !launchedBefore {
                    
                    self.view.backgroundColor = UIColor.whiteColor()
                    
                    let permissioningTitle = UILabel(frame: CGRectMake(0, 0, UIScreen.mainScreen().bounds.width - 20, 40))
                    permissioningTitle.center = CGPointMake(UIScreen.mainScreen().bounds.width/2, UIScreen.mainScreen().bounds.height/6)
                    permissioningTitle.text = "Welcome to Tastemaker"
                    permissioningTitle.font = UIFont.systemFontOfSize(22.0)
                    permissioningTitle.textColor = UIColor.whiteColor()
                    permissioningTitle.textAlignment = .Center
                    self.view.addSubview(permissioningTitle)
                    
                    let permissioningDetails = UILabel(frame: CGRectMake(0,0, UIScreen.mainScreen().bounds.width - 30, 80))
                    permissioningDetails.center = CGPointMake(UIScreen.mainScreen().bounds.width/2, UIScreen.mainScreen().bounds.height * 3 / 10)
                    permissioningDetails.text = "To discover the newest places around tap \"Allow\" to set up notifications and location settings"
                    permissioningDetails.font = UIFont.systemFontOfSize(17.0)
                    permissioningDetails.textColor = UIColor.whiteColor()
                    permissioningDetails.textAlignment = .Center
                    permissioningDetails.numberOfLines = 0
                    permissioningDetails.lineBreakMode = .ByWordWrapping
                    self.view.addSubview(permissioningDetails)
                    
                    let permissioningImage = UIImageView(image: UIImage(named: "Permission.png"))
                    permissioningImage.frame = CGRectMake(0, 0, UIScreen.mainScreen().bounds.width - 60, 200)
                    permissioningImage.center = CGPointMake(UIScreen.mainScreen().bounds.width/2, UIScreen.mainScreen().bounds.height/2)
                    permissioningImage.contentMode = UIViewContentMode.ScaleAspectFill
                    self.view.addSubview(permissioningImage)
                    
                    let permissioningButton = UIButton(frame: CGRectMake(0, 0, UIScreen.mainScreen().bounds.width - 60, 200))
                    permissioningButton.center = CGPointMake(UIScreen.mainScreen().bounds.width/2, UIScreen.mainScreen().bounds.height/2)
                    permissioningButton.backgroundColor = UIColor.clearColor()
                    permissioningButton.addTarget(self, action: #selector(InitialViewController.didTapPermissioningButton(_:)), forControlEvents: .TouchUpInside)
                    self.view.addSubview(permissioningButton)
                    
                    UIView.animateWithDuration(0.5, animations: {
                        self.view.backgroundColor = kPurple
                    })
                } else {
                    
                    if !self.userLoggedIn {
                        // Present Tastemaker UI
                        (UIApplication.sharedApplication().delegate as! AppDelegate).presentTabBarController()
                        self.userLoggedIn = true
                    }
                }
            } else {
                // Clear NSUserDefaults
                let appDomain = NSBundle.mainBundle().bundleIdentifier!
                NSUserDefaults.standardUserDefaults().removePersistentDomainForName(appDomain)
                Amplitude.instance().setUserId(nil)
                
                self.performSegueWithIdentifier("toLogin", sender: self)
            }
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        for view in self.view.subviews {
            view.removeFromSuperview()
        }
        self.view.backgroundColor = UIColor.whiteColor()
        
        FIRAuth.auth()!.removeAuthStateDidChangeListener(authHandle!)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func didTapPermissioningButton(sender: AnyObject) {
        
        pscope.show({
            finished, results in
            
            print("got results \(results)")
            if results[0].status != .Unknown && results[1].status != .Unknown {
                
                if results[0].status == .Authorized {
                    UIApplication.sharedApplication().registerForRemoteNotifications()
                    
                    FIRAnalytics.logEventWithName("permissioned", parameters: ["from": "login", "type": "notification", "status": "authorized"])
                    FIRAnalytics.setUserPropertyString("authorized", forName: "notification_permission")
                    Amplitude.instance().logEvent("Initial Notification Permission", withEventProperties: ["Status": "Authorized"])
                    Amplitude.instance().identify(AMPIdentify().set("Notification Permission", value: "Authorized"))
                } else if results[0].status == .Unauthorized {
                    FIRAnalytics.logEventWithName("permissioned", parameters: ["from": "login", "type": "notification", "status": "unauthorized"])
                    FIRAnalytics.setUserPropertyString("unauthorized", forName: "notification_permission")
                    Amplitude.instance().logEvent("Initial Notification Permission", withEventProperties: ["Status": "Unauthorized"])
                    Amplitude.instance().identify(AMPIdentify().set("Notification Permission", value: "Unauthorized"))
                } else if results[0].status == .Disabled {
                    FIRAnalytics.logEventWithName("permissioned", parameters: ["from": "login", "type": "notification", "status": "disabled"])
                    FIRAnalytics.setUserPropertyString("disabled", forName: "notification_permission")
                    Amplitude.instance().logEvent("Initial Notification Permission", withEventProperties: ["Status": "Disabled"])
                    Amplitude.instance().identify(AMPIdentify().set("Notification Permission", value: "Disabled"))
                }
                
                if results[1].status == .Authorized {
                    FIRAnalytics.logEventWithName("permissioned", parameters: ["from": "login", "type": "location", "status": "authorized"])
                    FIRAnalytics.setUserPropertyString("authorized", forName: "location_permission")
                    Amplitude.instance().logEvent("Initial Location Permission", withEventProperties: ["Status": "Authorized"])
                    Amplitude.instance().identify(AMPIdentify().set("Location Permission", value: "Authorized"))
                } else if results[1].status == .Unauthorized {
                    FIRAnalytics.logEventWithName("permissioned", parameters: ["from": "login", "type": "location", "status": "unauthorized"])
                    FIRAnalytics.setUserPropertyString("unauthorized", forName: "location_permission")
                    Amplitude.instance().logEvent("Initial Location Permission", withEventProperties: ["Status": "Unauthorized"])
                    Amplitude.instance().identify(AMPIdentify().set("Location Permission", value: "Unauthorized"))
                } else if results[1].status == .Disabled {
                    FIRAnalytics.logEventWithName("permissioned", parameters: ["from": "login", "type": "location", "status": "disabled"])
                    FIRAnalytics.setUserPropertyString("disabled", forName: "location_permission")
                    Amplitude.instance().logEvent("Initial Location Permission", withEventProperties: ["Status": "Disabled"])
                    Amplitude.instance().identify(AMPIdentify().set("Location Permission", value: "Disabled"))
                }
                
                self.pscope.hide()
                (UIApplication.sharedApplication().delegate as! AppDelegate).presentTabBarController()
                NSUserDefaults.standardUserDefaults().setBool(true, forKey: "LaunchedBefore")
            }
        }, cancelled: {
            results in
                
            self.pscope.hide()
            (UIApplication.sharedApplication().delegate as! AppDelegate).presentTabBarController()
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "LaunchedBefore")
        })
    }
}