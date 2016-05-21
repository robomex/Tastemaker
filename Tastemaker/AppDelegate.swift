//
//  AppDelegate.swift
//  Tastemaker
//
//  Created by Tony Morales on 6/7/15.
//  Copyright (c) 2015 Tony Morales. All rights reserved.
//

import UIKit
import CoreLocation
import Firebase
import Amplitude_iOS
import SwiftyDrop
import FBSDKCoreKit
import FBSDKLoginKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UITabBarControllerDelegate, CLLocationManagerDelegate {

    var window: UIWindow?
    var feedTableViewController: FeedTableViewController?
    var initialViewController: InitialViewController?
    var listViewController: ListViewController?
    var settingsViewController: SettingsViewController?
    
    let storyboard = UIStoryboard(name: "Main", bundle: nil)
    
    var tabBarController: TabBarController?
    var navController: UINavigationController?
    
    let locationManager = CLLocationManager()

    override init() {
        super.init()
        
        // Persistence is causing issues with not loading the latest messages/hitting the cache and ignoring the latest messages called by observeSingleEventOfType queries
//        Firebase.defaultConfig().persistenceEnabled = true
    }
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        self.initialViewController = storyboard.instantiateViewControllerWithIdentifier("InitialViewController") as? InitialViewController
        
        self.navController = UINavigationController(rootViewController: self.initialViewController!)
        self.navController!.navigationBarHidden = true
        
        // Set up Tastemaker's global UIAppearance
        self.setupAppearance()
        
        // CoreLocation for visit monitoring
        locationManager.delegate = self
        
        self.window!.rootViewController = self.navController
        self.window!.makeKeyAndVisible()
        
        // Amplitude initialization
        Amplitude.instance().initializeApiKey("6d506a59d008bdec71b5b5a9ec4af932")
        
        // Update/register device's push token
        if NSUserDefaults.standardUserDefaults().objectForKey("uid") as? String != nil {
            registerForPushNotifications(application)
        }
        
        if NSUserDefaults.standardUserDefaults().objectForKey("uid") as? String != nil {
            let uid = NSUserDefaults.standardUserDefaults().objectForKey("uid") as! String
            
            DataService.dataService.BASE_REF.childByAppendingPath("onlineStatuses/\(uid)/").removeValue()
        }
        
        return FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    
    // MARK: Push
    
    func registerForPushNotifications(application: UIApplication) {
        let notificationSettings = UIUserNotificationSettings(forTypes: [.Badge, .Sound, .Alert], categories: nil)
        application.registerUserNotificationSettings(notificationSettings)
    }
    
    func application(application: UIApplication, didRegisterUserNotificationSettings notificationSettings: UIUserNotificationSettings) {
        
        if NSUserDefaults.standardUserDefaults().objectForKey("uid") as? String != nil {
            let uid = NSUserDefaults.standardUserDefaults().objectForKey("uid") as! String
            
            if notificationSettings.types != .None {
                application.registerForRemoteNotifications()
            } else if notificationSettings.types == .None {
                DataService.dataService.BASE_REF.childByAppendingPath("devices/\(uid)").removeValue()
            }
        }
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        
        if NSUserDefaults.standardUserDefaults().objectForKey("uid") as? String != nil {
            let uid = NSUserDefaults.standardUserDefaults().objectForKey("uid") as! String

            DataService.dataService.BASE_REF.childByAppendingPath("devices/\(uid)").updateChildValues(["token": deviceToken.hexString, "updatedOn": dateFormatter().stringFromDate(NSDate())])
        }
    }
    
    // Use to respond to notifications when app is running in the foreground, not background
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {

    }

    // Use to respond to notifications when app is running in the foreground OR background
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        
        let state = application.applicationState
        if state == UIApplicationState.Inactive || state == UIApplicationState.Background {
            if let venue = userInfo["venue"] {
                
                DataService.dataService.VENUES_REF.childByAppendingPath(venue as! String).observeSingleEventOfType(.Value, withBlock: {
                    snapshot in

                    let targetVenue = snapshotToVenue(snapshot)
                    let vc = VenueViewController()
                    vc.venue = targetVenue
                    vc.venueID = targetVenue.objectId
                    // NEED TO ADD IN BANNED CHECK OR MOVE BANNED CHECK TO CHATVC
                    let venueName: String = targetVenue.name!
                    vc.title = venueName
                    vc.hidesBottomBarWhenPushed = true
                    let backButton = UIBarButtonItem(title: " ", style: .Plain, target: nil, action: nil)
                    
                    self.feedTableViewController?.navigationController?.popToRootViewControllerAnimated(false)
                    self.feedTableViewController?.navigationController?.navigationBar.topItem?.backBarButtonItem = backButton
                    self.feedTableViewController?.navigationController?.pushViewController(vc, animated: false)
                    
                    Amplitude.instance().logEvent("Launch From Push", withEventProperties: ["Venue Name": targetVenue.name!])
                })
            }
        } else if state == UIApplicationState.Active {
            let aps = userInfo["aps"] as! [String: AnyObject]
            if let message = aps["alert"] {
                Drop.down(message as! String, state: .Color(kPurple), duration: 5.0) {
                    
                    if let venue = userInfo["venue"] {
                        
                        DataService.dataService.VENUES_REF.childByAppendingPath(venue as! String).observeSingleEventOfType(.Value, withBlock: {
                            snapshot in
                            
                            let targetVenue = snapshotToVenue(snapshot)
                            let vc = VenueViewController()
                            vc.venue = targetVenue
                            vc.venueID = targetVenue.objectId
                            // NEED TO ADD IN BANNED CHECK OR MOVE BANNED CHECK TO CHATVC
                            let venueName: String = targetVenue.name!
                            vc.title = venueName
                            vc.hidesBottomBarWhenPushed = true
                            let backButton = UIBarButtonItem(title: " ", style: .Plain, target: nil, action: nil)
                            
                            self.tabBarController?.selectedIndex = 0
                            self.feedTableViewController?.navigationController?.popToRootViewControllerAnimated(false)

                            self.feedTableViewController?.navigationController?.navigationBar.topItem?.backBarButtonItem = backButton
                            self.feedTableViewController?.navigationController?.pushViewController(vc, animated: true)
                            
                            Amplitude.instance().logEvent("Launch From In-App Push", withEventProperties: ["Venue Name": targetVenue.name!])
                        })
                    }
                }
            }
        }
        completionHandler(.NoData)
    }
    
    
    // MARK: App state changes, i.e. inactive, background, etc.
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        
        
        if NSUserDefaults.standardUserDefaults().objectForKey("uid") as? String != nil {
            let uid = NSUserDefaults.standardUserDefaults().objectForKey("uid") as! String
            
            let onlineStatusRef = DataService.dataService.BASE_REF.childByAppendingPath("onlineStatuses/\(uid)/")
            onlineStatusRef.observeSingleEventOfType(.Value, withBlock: {
                snapshot in

                if snapshot.exists() {
                    let enumerator = snapshot.children
                    while let venueOnlineStatuses = enumerator.nextObject() as? FDataSnapshot {
                        onlineStatusRef.childByAppendingPath("\(venueOnlineStatuses.key)").setValue(false)
                    }
                }
            })
        }
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        if NSUserDefaults.standardUserDefaults().objectForKey("uid") as? String != nil {
            let uid = NSUserDefaults.standardUserDefaults().objectForKey("uid") as! String
            
            let onlineStatusRef = DataService.dataService.BASE_REF.childByAppendingPath("onlineStatuses/\(uid)/")
            onlineStatusRef.observeSingleEventOfType(.Value, withBlock: {
                snapshot in
                
                if snapshot.exists() {
                    let enumerator = snapshot.children
                    while let dormantVenueOnlineStatuses = enumerator.nextObject() as? FDataSnapshot {
                        onlineStatusRef.childByAppendingPath("\(dormantVenueOnlineStatuses.key)").setValue(true)
                    }
                }
            })
        }
        
        FBSDKAppEvents.activateApp()
    }
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation)
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    
    // MARK: AppDelegate

    func presentTabBarController() {
        self.tabBarController = TabBarController()
        self.feedTableViewController = FeedTableViewController(style: UITableViewStyle.Plain)
        self.listViewController = ListViewController(style: UITableViewStyle.Plain)
        self.settingsViewController = storyboard.instantiateViewControllerWithIdentifier("SettingsViewController") as? SettingsViewController
        
        let feedNavigationController: UINavigationController = UINavigationController(rootViewController: self.feedTableViewController!)
        let listNavigationController: UINavigationController = UINavigationController(rootViewController: self.listViewController!)
        let settingsNavigationController: UINavigationController = UINavigationController(rootViewController: self.settingsViewController!)
        
        let feedTabBarItem: UITabBarItem = UITabBarItem(title: "Home", image: UIImage(named: "Home.png"), selectedImage: UIImage(named: "Home.png"))
        feedTabBarItem.setTitleTextAttributes([NSForegroundColorAttributeName: kBlue, NSFontAttributeName: UIFont.systemFontOfSize(13)], forState: UIControlState.Selected)
        feedTabBarItem.setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.grayColor(), NSFontAttributeName: UIFont.systemFontOfSize(13)], forState: UIControlState.Normal)
        
        let listTabBarItem: UITabBarItem = UITabBarItem(title: "My List", image: UIImage(named: "Lists.png"), selectedImage: UIImage(named: "Lists.png"))
        listTabBarItem.setTitleTextAttributes([NSForegroundColorAttributeName: kBlue, NSFontAttributeName: UIFont.systemFontOfSize(13)], forState: UIControlState.Selected)
        listTabBarItem.setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.grayColor(), NSFontAttributeName: UIFont.systemFontOfSize(13)], forState: UIControlState.Normal)
        
        let settingsTabBarItem: UITabBarItem = UITabBarItem(title: "Settings", image: UIImage(named: "Settings.png"), selectedImage: UIImage(named: "Settings.png"))
        settingsTabBarItem.setTitleTextAttributes([NSForegroundColorAttributeName: kBlue, NSFontAttributeName: UIFont.systemFontOfSize(13)], forState: UIControlState.Selected)
        settingsTabBarItem.setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.grayColor(), NSFontAttributeName: UIFont.systemFontOfSize(13)], forState: UIControlState.Normal)
        
        feedNavigationController.tabBarItem = feedTabBarItem
        listNavigationController.tabBarItem = listTabBarItem
        settingsNavigationController.tabBarItem = settingsTabBarItem
        
        tabBarController!.delegate = self
        tabBarController!.viewControllers = [feedNavigationController, listNavigationController, settingsNavigationController]
        
        let locationAuthorizationStatus = CLLocationManager.authorizationStatus()
        if CLLocationManager.locationServicesEnabled() {
            
            switch locationAuthorizationStatus {
            case .AuthorizedAlways:
                locationManager.startMonitoringVisits()
                print("monitoring - always")
            case .AuthorizedWhenInUse:
                locationManager.startMonitoringVisits()
                print("monitoring - when in use")
            case .NotDetermined:
                locationManager.requestAlwaysAuthorization()
                print("Requested always authorization")
            case .Denied:
                print("authorization DENIED")
            default:
                print("other case, possibly restricted")
            }
        }
        
        navController!.setViewControllers([initialViewController!, tabBarController!], animated: true)
    }

    
    // MARK: Logout
    
    func logOut() {
        // Stop monitoring visits
        locationManager.stopMonitoringVisits()
        
        self.feedTableViewController?.feedTableLogoutCleanup()
        // Check whether listVC has been loaded, if so clean up listVC observers
        let isLoaded = !(self.listViewController?.loading)!
        if isLoaded {
            self.listViewController?.listLogoutCleanup()
        }
        
        // Delete device token so pushes aren't attempted for an old or logged out device
        if NSUserDefaults.standardUserDefaults().objectForKey("uid") as? String != nil {
            let uid = NSUserDefaults.standardUserDefaults().objectForKey("uid") as! String
            DataService.dataService.BASE_REF.childByAppendingPath("devices/\(uid)").removeValue()
        }
        
        // Log out of Facebook
        let loginManager = FBSDKLoginManager()
        loginManager.logOut()
        
        // Clear Amplitude userId
        Amplitude.instance().setUserId(nil)
        
        DataService.dataService.BASE_REF.unauth()
    }
    
    
    // MARK: - ()
    
    // Set up appearance parameters to achieve Tastemaker's custom look and feel
    func setupAppearance() {
        UIApplication.sharedApplication().statusBarStyle = UIStatusBarStyle.LightContent
        
        UINavigationBar.appearance().tintColor = UIColor.whiteColor()
        UINavigationBar.appearance().barTintColor = kBlue
        UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor()]
    }

    
    // MARK: CoreLocation
    
    // MARK: CLLocationManagerDelegate
    
    func locationManager(manager: CLLocationManager, didVisit visit: CLVisit) {
        
        let fetchedVenuesDictionary = NSUserDefaults.standardUserDefaults().objectForKey("venues") as! [[String:AnyObject]]
        var fetchedVenues = [Venue]()
        for venue in fetchedVenuesDictionary {
            fetchedVenues.append(deserializeVenue(venue))
        }
        let venueSort = VenueSorter()
        let sortedVenues = venueSort.sortVenuesByDistanceFromLocation(fetchedVenues, location: CLLocation(latitude: visit.coordinate.latitude, longitude: visit.coordinate.longitude)).prefix(3)
        
        if NSUserDefaults.standardUserDefaults().objectForKey("uid") as? String != nil {
            let uid = NSUserDefaults.standardUserDefaults().objectForKey("uid") as! String
            
            if visit.arrivalDate.isEqualToDate(NSDate.distantPast()) || visit.departureDate.isEqualToDate(NSDate.distantFuture()) {
                // don't have info on when this visit began, i.e. the user just installed, OR don't have info on when this visit ended, i.e. the user recently arrived at the place
                
                for venue in sortedVenues {
                    let visitDistanceFromVenue = CLLocation(latitude: visit.coordinate.latitude, longitude: visit.coordinate.longitude).distanceFromLocation(CLLocation(latitude: venue.latitude!, longitude: venue.longitude!))
                    if  visitDistanceFromVenue < 66 {
                        DataService.dataService.USER_ACTIVITIES_REF.childByAppendingPath("\(uid)/visits/\(venue.objectId!)").childByAutoId().updateChildValues(["startedAt": dateFormatter().stringFromDate(visit.arrivalDate), "distanceFromVenue": String(visitDistanceFromVenue)])
                        
                        Amplitude.instance().logEvent("Visited Venue", withEventProperties: ["Venue Name": venue.name!, "Venue Neighborhood": venue.neighborhood!, "Venue Food Type": venue.foodType!])
                        Amplitude.instance().identify(AMPIdentify().add("Visits", value: 1))
                    }
                }
            } else {
                // visit complete, has both start and end dates
                
                for venue in sortedVenues {
                    let visitDistanceFromVenue = CLLocation(latitude: visit.coordinate.latitude, longitude: visit.coordinate.longitude).distanceFromLocation(CLLocation(latitude: venue.latitude!, longitude: venue.longitude!))
                    if visitDistanceFromVenue < 66 {
                        DataService.dataService.VENUE_ACTIVITIES_REF.childByAppendingPath("\(venue.objectId!)/visitors/private/\(uid)").childByAutoId().updateChildValues(["endedAt": dateFormatter().stringFromDate(visit.departureDate), "startedAt": dateFormatter().stringFromDate(visit.arrivalDate), "distanceFromVenue": String(visitDistanceFromVenue)])
                        DataService.dataService.VENUE_ACTIVITIES_REF.childByAppendingPath("\(venue.objectId!)/visitors/public/\(uid)").setValue(true)
                    }
                }
            }
        }
    }

    // TO-DO: come back and fix this up so the users are informed of what went wrong
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("Location Manager failed with the following error: \(error)")
    }
}