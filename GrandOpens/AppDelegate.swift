//
//  AppDelegate.swift
//  GrandOpens
//
//  Created by Tony Morales on 6/7/15.
//  Copyright (c) 2015 Tony Morales. All rights reserved.
//

import UIKit
import CoreData
import Parse
import Bolts
import MBProgressHUD
import CoreLocation
//import ReachabilitySwift


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UITabBarControllerDelegate, CLLocationManagerDelegate {

    var window: UIWindow?
    var feedTableViewController: FeedTableViewController?
    var initialViewController: InitialViewController?
    var listViewController: ListViewController?
    var settingsViewController: SettingsViewController?
    
    let storyboard = UIStoryboard(name: "Main", bundle: nil)
    
    var tabBarController: GOTabBarController?
    var navController: UINavigationController?
    
    let locationManager = CLLocationManager()

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        // Optional Parse local datastore enabled - helpful comment
//        Parse.enableLocalDatastore()
        
        // Initialize Parse
        Parse.setApplicationId(valueForAPIKey("PARSE_APPLICATION_ID"), clientKey: valueForAPIKey("PARSE_CLIENT_KEY"))
        
        // Track statistics around application opens with Parse
        PFAnalytics.trackAppOpenedWithLaunchOptions(launchOptions)

        // Use Reachability to monitor connectivity
//        let reachability = try! Reachability.reachabilityForInternetConnection()
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reachabilityChanged:", name: ReachabilityChangedNotification, object: reachability)
//        try! reachability.startNotifier()
        
        self.initialViewController = storyboard.instantiateViewControllerWithIdentifier("InitialViewController") as? InitialViewController
        
        self.navController = UINavigationController(rootViewController: self.initialViewController!)
        self.navController!.navigationBarHidden = true
        
        // Set up Grand Open's global UIAppearance
        self.setupAppearance()
        
        // CoreLocation shit for region monitoring
        locationManager.delegate = self
        
        self.window!.rootViewController = self.navController
        self.window!.makeKeyAndVisible()
        
        UIApplication.sharedApplication().cancelAllLocalNotifications()
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
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
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    
    // MARK: AppDelegate

    func presentTabBarController() {
        self.tabBarController = GOTabBarController()
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
        
        for CLRegion in self.locationManager.monitoredRegions {
            self.locationManager.stopMonitoringForRegion(CLRegion)
        }
        
        locationManager.startMonitoringSignificantLocationChanges()
        print("monitoring")
    
        navController!.setViewControllers([initialViewController!, tabBarController!], animated: false)
    }
    
    func logOut() {
        // Clear cache
        GOCache.sharedCache.clear()
        
        // Clear NSUserDefaults
        NSUserDefaults.standardUserDefaults().synchronize()
        
        // Unsubscribe from push notifications by removing the user association from the current installation
        PFInstallation.currentInstallation().removeObjectForKey(kGOInstallationKey)
        PFInstallation.currentInstallation().saveInBackground()
        
        // Clear all caches
        PFQuery.clearAllCachedResults()
        
        // Log out
        PFUser.logOut()
        
        // Clear out cached data, view controllers, etc.
        navController!.popToRootViewControllerAnimated(false)
        
        self.feedTableViewController = nil
        self.listViewController = nil
    }
    
    
    // MARK: - ()
    
    // Set up appearance parameters to achieve Grand Open's custom look and feel
    func setupAppearance() {
        UIApplication.sharedApplication().statusBarStyle = UIStatusBarStyle.LightContent
        
        UINavigationBar.appearance().tintColor = UIColor.whiteColor()
        UINavigationBar.appearance().barTintColor = kBlue
        UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor()]
    }
    
//    func reachabilityChanged(note: NSNotification) {
//        let reachability = note.object as! Reachability
//        
//        if reachability.isReachable() {
//            if reachability.isReachableViaWiFi() {
//                print("reachable via wifi - appdelegate")
//            } else {
//                print("reachable via cellular - appdelegate")
//            }
//        } else {
//            print("not reachable - appdelegate")
//        }
//    }

    
    // MARK: CoreLocation
    
    // MARK: CLLocationManagerDelegate
    
    func regionFromVenue(venue: PFObject) -> CLCircularRegion {

        let venueLocation = venue.objectForKey(kVenueLocation) as? PFGeoPoint
        let venueLocation2D = venueLocation?.locationCoordinate2D()
        let region = CLCircularRegion(center: venueLocation2D!, radius: 40.0, identifier: venue.objectId!)
        region.notifyOnEntry = true
        return region
    }
    
    func startMonitoringVenueVisits(venue: PFObject) {
        
        // I'll need to come back and fix this shit so people know that either their devices don't support visit tracking OR more importantly a lot of GO functionality is lost until they grant location permission
//        if !CLLocationManager.isMonitoringAvailableForClass(CLCircularRegion) {
//            showSimpleAlertWithTitle("Error", message: "Visit tracking is not supported on this device!", viewController: self)
//            return
//        }
//        
//        if CLLocationManager.authorizationStatus() != .AuthorizedAlways {
//            showSimpleAlertWithTitle("Warning", message: "Your ability to vote, comment, and track visits will be unlocked once you grant Grand Opens permission to access the device location", viewController: self)
//        }
        
        let region = regionFromVenue(venue)
        locationManager.startMonitoringForRegion(region)
    }
    
    func stopMonitoringVenueVisits(venue: PFObject) {
        for region in locationManager.monitoredRegions {
            if let circularRegion = region as? CLCircularRegion {
                if circularRegion.identifier == venue.objectId! {
                    locationManager.stopMonitoringForRegion(circularRegion)
                }
            }
        }
    }
    
    // TO-DO: come back and fix this shit up so the users are informed of what went wrong
    
    func locationManager(manager: CLLocationManager, monitoringDidFailForRegion region: CLRegion?, withError error: NSError) {
        print("Monitoring failed for region with identifier: \(region?.identifier)")
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("Location Manager failed with the following error: \(error)")
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("location updated")
        
        let location = locations.last as CLLocation?
        let locationAsPFGeoPoint = PFGeoPoint(location: location)
        
        var today = NSDate()
        let calendar = NSCalendar.autoupdatingCurrentCalendar()
        calendar.timeZone = NSTimeZone.localTimeZone()
        today = calendar.startOfDayForDate(NSCalendar.currentCalendar().dateByAddingUnit(.Day, value: 1, toDate: today, options: NSCalendarOptions())!)
        let standardOpeningDateCoverage = calendar.startOfDayForDate(NSCalendar.currentCalendar().dateByAddingUnit(.Day, value: -(kStandardDaysOfOpeningsCovered), toDate: today, options: NSCalendarOptions())!)
        
        let queryNearbyVenues = PFQuery(className: kVenueClassKey)
        queryNearbyVenues.whereKey(kVenueLocation, nearGeoPoint: locationAsPFGeoPoint, withinMiles: 50.0)
        queryNearbyVenues.whereKey(kVenueOpeningDate, greaterThanOrEqualTo: standardOpeningDateCoverage)
        queryNearbyVenues.whereKey(kVenueOpeningDate, lessThan: today)
        queryNearbyVenues.limit = 20
        queryNearbyVenues.findObjectsInBackgroundWithBlock { (venues, error) in
            if error == nil {
                for venue in venues! {
                    self.startMonitoringVenueVisits(venue)
                }
            }
        }
    }
    
    func handleRegionEvent(region: CLRegion!) {
        
        let venue = PFQuery(className: kVenueClassKey)
        venue.getObjectInBackgroundWithId(region.identifier) { (venue: PFObject?, error: NSError?) -> Void in
            if error == nil && venue != nil {
                let visitActivity = PFObject(className: kVenueActivityClassKey)
                visitActivity.setObject(kVenueActivityTypeVisit, forKey: kVenueActivityTypeKey)
                visitActivity.setObject(PFUser.currentUser()!, forKey: kVenueActivityByUserKey)
                visitActivity.setObject(venue!, forKey: kVenueActivityToVenueKey)
                let visitACL = PFACL(user: PFUser.currentUser()!)
                visitActivity.ACL = visitACL
                visitActivity.saveInBackground()
            }
        }
        
        print("Geofence triggered!")
    }
    
    func locationManager(manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if region is CLCircularRegion {
            handleRegionEvent(region)
        }
    }
    
//    func locationManager(manager: CLLocationManager, didExitRegion region: CLRegion) {
//        if region is CLCircularRegion {
//            handleRegionEvent(region)
//        }
//    }
}

