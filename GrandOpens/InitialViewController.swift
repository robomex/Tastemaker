//
//  InitialViewController.swift
//  GrandOpens
//
//  Created by Tony Morales on 7/23/15.
//  Copyright (c) 2015 Tony Morales. All rights reserved.
//

import UIKit
import CoreLocation
import Firebase

class InitialViewController: UIViewController {

    let locationManager = CLLocationManager()
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if DataService.dataService.BASE_REF.authData != nil {
        
            // This if clause added since deleting the app and reinstalling resulted in persisted Firebase auth but deleted NSUserDefaults, causing crashes
            if NSUserDefaults.standardUserDefaults().objectForKey("uid") == nil || NSUserDefaults.standardUserDefaults().objectForKey("nickname") ==  nil {
                DataService.dataService.BASE_REF.unauth()
                self.navigationController?.popToRootViewControllerAnimated(true)
                
                // want to pop to prevent navigating to login on top of already present vc
//                self.performSegueWithIdentifier("toLogin", sender: self)
            }
            
            // This check added in case the account is deleted in the database, they will be logged out
            DataService.dataService.USERS_PUBLIC_REF.childByAppendingPath(NSUserDefaults.standardUserDefaults().objectForKey("uid") as! String).observeSingleEventOfType(.Value, withBlock: {
                snapshot in
                
                if !snapshot.exists() {
                    DataService.dataService.BASE_REF.unauth()
                    self.navigationController?.popToRootViewControllerAnimated(true)
                    
                    // want to pop to prevent navigating to login on top of already present vc
//                    self.performSegueWithIdentifier("toLogin", sender: self)
                }
            })
            
            let launchedBefore = NSUserDefaults.standardUserDefaults().boolForKey("LaunchedBefore")
            if !launchedBefore {

                self.view.backgroundColor = UIColor.whiteColor()
                
                let permissioningTitle = UILabel(frame: CGRectMake(0, 0, UIScreen.mainScreen().bounds.width - 20, 40))
                permissioningTitle.center = CGPointMake(UIScreen.mainScreen().bounds.width/2, UIScreen.mainScreen().bounds.height/6)
                permissioningTitle.text = "Let's get set up"
                permissioningTitle.font = UIFont.systemFontOfSize(22.0)
                permissioningTitle.textColor = UIColor.whiteColor()
                permissioningTitle.textAlignment = .Center
                self.view.addSubview(permissioningTitle)
                
                let permissioningDetails = UILabel(frame: CGRectMake(0,0, UIScreen.mainScreen().bounds.width - 30, 80))
                permissioningDetails.center = CGPointMake(UIScreen.mainScreen().bounds.width/2, UIScreen.mainScreen().bounds.height * 3 / 10)
                permissioningDetails.text = "To discover the newest places around you tap \"Allow\" to get notifications and share your location"
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
                permissioningButton.addTarget(self, action: "didTapPermissioningButton:", forControlEvents: .TouchUpInside)
                self.view.addSubview(permissioningButton)
                
                UIView.animateWithDuration(0.5, animations: {
                    self.view.backgroundColor = kPurple
                })
                
                NSUserDefaults.standardUserDefaults().setBool(true, forKey: "LaunchedBefore")
            } else {
                // Present Grand Opens UI
                (UIApplication.sharedApplication().delegate as! AppDelegate).presentTabBarController()
            }
        } else {
            self.performSegueWithIdentifier("toLogin", sender: self)
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        for view in self.view.subviews {
            view.removeFromSuperview()
        }
        self.view.backgroundColor = UIColor.whiteColor()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func didTapPermissioningButton(sender: AnyObject) {
        self.locationManager.requestAlwaysAuthorization()
        let settings = UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil)
        UIApplication.sharedApplication().registerUserNotificationSettings(settings)
        (UIApplication.sharedApplication().delegate as! AppDelegate).presentTabBarController()
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
