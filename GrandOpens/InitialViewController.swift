//
//  InitialViewController.swift
//  GrandOpens
//
//  Created by Tony Morales on 7/23/15.
//  Copyright (c) 2015 Tony Morales. All rights reserved.
//

import UIKit
import Parse

class InitialViewController: UIViewController, LoginViewControllerDelegate {

    private var _presentedLoginViewController: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if PFUser.currentUser() == nil {
            presentLoginViewController(false)
            return
        }
        
        // Present Grand Opens UI
        (UIApplication.sharedApplication().delegate as! AppDelegate).presentTabBarController()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: InitialViewController
    
    func presentLoginViewController(animated: Bool) {
        if _presentedLoginViewController {
            return
        }
        
        _presentedLoginViewController = true
        
//        var storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        self.performSegueWithIdentifier("toLogin", sender: self)
//        var loginViewController = LoginViewController()
//        loginViewController.delegate = self
//        presentViewController(loginViewController, animated: animated, completion: nil)
    }
    
    
    // MARK: LoginViewControllerDelegate
    
    func loginViewControllerDidLogUserIn(loginViewController: LoginViewController) {
        if _presentedLoginViewController {
            _presentedLoginViewController = false
            self.dismissViewControllerAnimated(true, completion: nil)
        }
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
