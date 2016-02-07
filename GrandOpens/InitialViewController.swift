//
//  InitialViewController.swift
//  GrandOpens
//
//  Created by Tony Morales on 7/23/15.
//  Copyright (c) 2015 Tony Morales. All rights reserved.
//

import UIKit
import Parse
//import Onboard
import CoreLocation
import Firebase

class InitialViewController: UIViewController {

//    private var _presentedLoginViewController: Bool = false
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if DataService.dataService.BASE_REF.authData != nil {
            //observeAuthEventWithBlock({
//            authData in
            
            // this if clause added since deleting the app and reinstalling resulted in persisted Firebase auth but deleted NSUserDefaults, causing crashes
            if NSUserDefaults.standardUserDefaults().objectForKey("uid") == nil || NSUserDefaults.standardUserDefaults().objectForKey("username") ==  nil {
                DataService.dataService.BASE_REF.unauth()
                self.performSegueWithIdentifier("toLogin", sender: self)
            }
            
//            if authData != nil {
                let launchedBefore = NSUserDefaults.standardUserDefaults().boolForKey("LaunchedBefore")
//                var onboardingVC = OnboardingViewController()
                if !launchedBefore {
//                    let firstOnboardingPage = OnboardingContentViewController(title: "Let's get set up", body: "To discover the newest places around tap \"OK\" to share your location and get notifications", image: UIImage(named: "Permission.png"), buttonText: "OK") { () -> Void in
//                        self.locationManager.requestAlwaysAuthorization()
//                        let settings = UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil)
//                        UIApplication.sharedApplication().registerUserNotificationSettings(settings)
//                        self.dismissViewControllerAnimated(true, completion: nil)
//                        (UIApplication.sharedApplication().delegate as! AppDelegate).presentTabBarController()
//                    }
//                    onboardingVC = OnboardingViewController(backgroundImage: UIImage(named: "onboarding_bg.png"), contents: [firstOnboardingPage])
//                    onboardingVC.shouldMaskBackground = false
//                    onboardingVC.shouldFadeTransitions = true
//                    onboardingVC.titleFontSize = 20
//                    onboardingVC.bodyFontSize = 16
//                    onboardingVC.topPadding = 150
//                    onboardingVC.underIconPadding = -340
//                    onboardingVC.fontName = UIFont.systemFontOfSize(UIFont.systemFontSize()).familyName
//                    onboardingVC.hidePageControl = true
//                    self.presentViewController(onboardingVC, animated: false, completion: nil)
                    
                    self.view.backgroundColor = kPurple
                    
                    let permissioningTitle = UILabel(frame: CGRectMake(0, 0, UIScreen.mainScreen().bounds.width - 20, 40))
                    permissioningTitle.center = CGPointMake(UIScreen.mainScreen().bounds.width/2, UIScreen.mainScreen().bounds.height/6)
                    permissioningTitle.text = "Let's get set up"
                    permissioningTitle.font = UIFont.systemFontOfSize(22.0)
                    permissioningTitle.textColor = UIColor.whiteColor()
                    permissioningTitle.textAlignment = .Center
                    self.view.addSubview(permissioningTitle)
                    
                    let permissioningDetails = UILabel(frame: CGRectMake(0,0, UIScreen.mainScreen().bounds.width - 30, 80))
                    permissioningDetails.center = CGPointMake(UIScreen.mainScreen().bounds.width/2, UIScreen.mainScreen().bounds.height * 3 / 10)
                    permissioningDetails.text = "To discover the newest places around tap \"OK\" to share your location and get notifications"
                    permissioningDetails.font = UIFont.systemFontOfSize(17.0)
                    permissioningDetails.textColor = UIColor.whiteColor()
                    permissioningDetails.textAlignment = .Center
                    permissioningDetails.numberOfLines = 0
                    permissioningDetails.lineBreakMode = .ByWordWrapping
                    self.view.addSubview(permissioningDetails)
                    
                    let permissioningImage = UIImageView(image: UIImage(named: "Permission.png"))
                    permissioningImage.frame = CGRectMake(0, 0, UIScreen.mainScreen().bounds.width - 60, 200)
                    permissioningImage.center = CGPointMake(UIScreen.mainScreen().bounds.width/2, UIScreen.mainScreen().bounds.height/2)
                    self.view.addSubview(permissioningImage)
                    
                    let permissioningButton = UIButton(frame: CGRectMake(0, 0, UIScreen.mainScreen().bounds.width - 60, 35))
                    permissioningButton.center = CGPointMake(UIScreen.mainScreen().bounds.width/2, UIScreen.mainScreen().bounds.height * 4 / 5)
                    permissioningButton.setTitle("OK", forState: .Normal)
                    permissioningButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
                    permissioningButton.backgroundColor = UIColor.clearColor()
                    permissioningButton.layer.borderWidth = 2.0
                    permissioningButton.layer.borderColor = UIColor(white: 1.0, alpha: 0.4).CGColor
                    permissioningButton.layer.cornerRadius = 5.0
                    permissioningButton.titleLabel?.font = UIFont.systemFontOfSize(22.0)
                    permissioningButton.addTarget(self, action: "didTapPermissioningButton:", forControlEvents: .TouchUpInside)
                    self.view.addSubview(permissioningButton)
                    
                    NSUserDefaults.standardUserDefaults().setBool(true, forKey: "LaunchedBefore")
                } else {
                    // Present Grand Opens UI
                    (UIApplication.sharedApplication().delegate as! AppDelegate).presentTabBarController()
                }
            } else {
                self.performSegueWithIdentifier("toLogin", sender: self)
            }
//        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func didTapPermissioningButton(sender: AnyObject) {
        self.locationManager.requestAlwaysAuthorization()
        let settings = UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil)
        UIApplication.sharedApplication().registerUserNotificationSettings(settings)
//        self.dismissViewControllerAnimated(true, completion: nil)
        (UIApplication.sharedApplication().delegate as! AppDelegate).presentTabBarController()
    }
    
    
    // MARK: InitialViewController
//    
//    func presentLoginViewController(animated: Bool) {
//        if _presentedLoginViewController {
//            return
//        }
//        
//        _presentedLoginViewController = true
//        
////        var storyboard = UIStoryboard(name: "Main", bundle: nil)
//        
//        self.performSegueWithIdentifier("toLogin", sender: self)
////        var loginViewController = LoginViewController()
////        loginViewController.delegate = self
////        presentViewController(loginViewController, animated: animated, completion: nil)
//    }
//    
//    
//    // MARK: LoginViewControllerDelegate
//    
//    func loginViewControllerDidLogUserIn(loginViewController: LoginViewController) {
//        if _presentedLoginViewController {
//            _presentedLoginViewController = false
//            self.dismissViewControllerAnimated(true, completion: nil)
//        }
//    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
