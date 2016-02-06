//
//  InitialViewController.swift
//  GrandOpens
//
//  Created by Tony Morales on 7/23/15.
//  Copyright (c) 2015 Tony Morales. All rights reserved.
//

import UIKit
import Parse
import Onboard
import CoreLocation
import Firebase

class InitialViewController: UIViewController {

//    private var _presentedLoginViewController: Bool = false
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        DataService.dataService.BASE_REF.observeAuthEventWithBlock({
            authData in
            
            if authData != nil {
                let launchedBefore = NSUserDefaults.standardUserDefaults().boolForKey("LaunchedBefore")
                if !launchedBefore {
                    let firstOnboardingPage = OnboardingContentViewController(title: "Let's get set up", body: "To discover the newest places around tap \"OK\" to share your location and get notifications", image: UIImage(named: "Permission.png"), buttonText: "OK") { () -> Void in
                        self.locationManager.requestAlwaysAuthorization()
                        let settings = UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil)
                        UIApplication.sharedApplication().registerUserNotificationSettings(settings)
                        self.dismissViewControllerAnimated(true, completion: nil)
                        (UIApplication.sharedApplication().delegate as! AppDelegate).presentTabBarController()
                    }
                    let onboardingVC = OnboardingViewController(backgroundImage: UIImage(named: "onboarding_bg.png"), contents: [firstOnboardingPage])
                    onboardingVC.shouldMaskBackground = false
                    onboardingVC.shouldFadeTransitions = true
                    onboardingVC.titleFontSize = 20
                    onboardingVC.bodyFontSize = 16
                    onboardingVC.topPadding = 150
                    onboardingVC.underIconPadding = -340
                    onboardingVC.fontName = UIFont.systemFontOfSize(UIFont.systemFontSize()).familyName
                    onboardingVC.hidePageControl = true
                    self.presentViewController(onboardingVC, animated: false, completion: nil)
                    NSUserDefaults.standardUserDefaults().setBool(true, forKey: "LaunchedBefore")
                } else {
                    // Present Grand Opens UI
                    (UIApplication.sharedApplication().delegate as! AppDelegate).presentTabBarController()
                }
            } else {
                self.performSegueWithIdentifier("toLogin", sender: self)
            }
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
