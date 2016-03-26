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
        
        self.tabBar.tintColor = kBlue
        self.tabBar.barTintColor = UIColor.whiteColor()
        
        self.navController = UINavigationController()
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    
    // MARK: UITabBarController
    
    override func setViewControllers(viewControllers: [UIViewController]?, animated: Bool) {
        super.setViewControllers(viewControllers, animated: animated)
    }
}