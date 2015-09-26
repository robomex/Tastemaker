//
//  GOTabBarController.swift
//  GrandOpens
//
//  Created by Tony Morales on 9/26/15.
//  Copyright © 2015 Tony Morales. All rights reserved.
//

import Foundation
import UIKit
import MobileCoreServices

class GOTabBarController: UITabBarController, UINavigationControllerDelegate {
    var navController: UINavigationController?
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tabBar.tintColor = UIColor(red: 254.0/255.0, green: 149.0/255.0, blue: 50.0/255.0, alpha: 1.0)
        self.tabBar.barTintColor = UIColor(red: 0.0/255.0, green: 0.0/255.0, blue: 0.0/255.0, alpha: 1.0)
        
        self.navController = UINavigationController()
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    
    // MARK: UITabBarController
    
    override func setViewControllers(viewControllers: [UIViewController]?, animated: Bool) {
        super.setViewControllers(viewControllers, animated: animated)
    }
    
    
    // MARK: 
}