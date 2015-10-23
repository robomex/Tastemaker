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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UITabBarControllerDelegate, CLLocationManagerDelegate {

    var window: UIWindow?
    var networkStatus: Reachability.NetworkStatus?
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
        
        // THIS SHIT IS CRASHING - fix this shit later
        //self.monitorReachability()
        
        self.initialViewController = storyboard.instantiateViewControllerWithIdentifier("InitialViewController") as? InitialViewController
        
        self.navController = UINavigationController(rootViewController: self.initialViewController!)
        self.navController!.navigationBarHidden = true
        
        // Set up Grand Open's global UIAppearance
        self.setupAppearance()
        
        // CoreLocation shit for region monitoring
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.startMonitoringSignificantLocationChanges()
        print("monitoring")
        
        self.window!.rootViewController = self.navController
        self.window!.makeKeyAndVisible()
        
        let settings = UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil)
        application.registerUserNotificationSettings(settings)
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
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }
    
    
    // MARK: AppDelegate
    
    func isParseReachable() -> Bool {
        return self.networkStatus != .NotReachable
    }

    func presentTabBarController() {
        self.tabBarController = GOTabBarController()
        self.feedTableViewController = FeedTableViewController(style: UITableViewStyle.Plain)
        self.listViewController = ListViewController(style: UITableViewStyle.Plain)
        self.settingsViewController = storyboard.instantiateViewControllerWithIdentifier("SettingsViewController") as? SettingsViewController
        
        let feedNavigationController: UINavigationController = UINavigationController(rootViewController: self.feedTableViewController!)
        let listNavigationController: UINavigationController = UINavigationController(rootViewController: self.listViewController!)
        let settingsNavigationController: UINavigationController = UINavigationController(rootViewController: self.settingsViewController!)
        
        let feedTabBarItem: UITabBarItem = UITabBarItem(title: "Home", image: UIImage(named: "Home.png")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysOriginal), selectedImage: UIImage(named: "Home.png")?.imageWithRenderingMode(UIImageRenderingMode.AlwaysOriginal))
        feedTabBarItem.setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.redColor(), NSFontAttributeName: UIFont.boldSystemFontOfSize(13)], forState: UIControlState.Selected)
        feedTabBarItem.setTitleTextAttributes([NSForegroundColorAttributeName: UIColor(red: 114.0/255.0, green: 114.0/255.0, blue: 14.0/255.0, alpha: 1.0), NSFontAttributeName: UIFont.boldSystemFontOfSize(13)], forState: UIControlState.Normal)
        
        let listTabBarItem: UITabBarItem = UITabBarItem(title: "List", image: UIImage(named: "Lists.png")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysOriginal), selectedImage: UIImage(named: "Lists.png")?.imageWithRenderingMode(UIImageRenderingMode.AlwaysOriginal))
        listTabBarItem.setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.whiteColor(), NSFontAttributeName: UIFont.boldSystemFontOfSize(13)], forState: UIControlState.Selected)
        listTabBarItem.setTitleTextAttributes([NSForegroundColorAttributeName: UIColor(red: 114.0/255.0, green: 114.0/255.0, blue: 14.0/255.0, alpha: 1.0), NSFontAttributeName: UIFont.boldSystemFontOfSize(13)], forState: UIControlState.Normal)
        
        let settingsTabBarItem: UITabBarItem = UITabBarItem(title: "Settings", image: UIImage(named: "Settings.png")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysOriginal), selectedImage: UIImage(named: "Settings.png")?.imageWithRenderingMode(UIImageRenderingMode.AlwaysOriginal))
        settingsTabBarItem.setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.whiteColor(), NSFontAttributeName: UIFont.boldSystemFontOfSize(13)], forState: UIControlState.Selected)
        settingsTabBarItem.setTitleTextAttributes([NSForegroundColorAttributeName: UIColor(red: 114.0/255.0, green: 255.0/255.0, blue: 14.0/255.0, alpha: 1.0), NSFontAttributeName: UIFont.boldSystemFontOfSize(13)], forState: UIControlState.Normal)
        
        feedNavigationController.tabBarItem = feedTabBarItem
        listNavigationController.tabBarItem = listTabBarItem
        settingsNavigationController.tabBarItem = settingsTabBarItem
        
        tabBarController!.delegate = self
        tabBarController!.viewControllers = [feedNavigationController, listNavigationController, settingsNavigationController]
    
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
        UINavigationBar.appearance().barTintColor = UIColor(red: 34.0/255.0, green: 167.0/255.0, blue: 240.0/255.0, alpha: 1.0)
        UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor()]
    }
    
    func monitorReachability() {
        guard let reachability = Reachability(hostname: "api.parse.com") else {
            return
        }
        
        reachability.whenReachable = { (reach: Reachability) in
            self.networkStatus = reach.currentReachabilityStatus
            if self.isParseReachable() && PFUser.currentUser() != nil && self.feedTableViewController!.objects!.count == 0 {
                // Refresh home on network restoration. Takes care of freshly installed app that failed to loan the home list under bad network conditions.
                // In this case, they'd see an empty list placeholder (once I add one) and have no way of refreshing the list
                self.feedTableViewController!.loadObjects()
            }
        }
        
        reachability.whenUnreachable = { (reach: Reachability) in
            self.networkStatus = reach.currentReachabilityStatus
        }
        
        reachability.startNotifier()
    }
    
    
    // MARK: CoreLocation
    
    // MARK: CLLocationManagerDelegate
    
    // The below will be used when/if MapViews are added to GO, this prevents the user location from being attempted to be displayed when permission may not have yet been requested
    //    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
    //        mapView.showsUserLocation = (status == .AuthorizedAlways)
    //    }
    
    func regionFromVenue(venue: PFObject) -> CLCircularRegion {
        let region = CLCircularRegion(center: venue.valueForKey(kVenueLocation) as! CLLocationCoordinate2D, radius: 40.0, identifier: venue.objectId!)
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
        
        let queryNearbyVenues = PFQuery(className: kVenueClassKey)
        queryNearbyVenues.whereKey(kVenueLocation, nearGeoPoint: locationAsPFGeoPoint, withinMiles: 50.0)
        queryNearbyVenues.limit = 20
        queryNearbyVenues.findObjectsInBackgroundWithBlock { (venues, error) in
            if error == nil {
                for venue in venues as! [PFObject] {
                    self.startMonitoringVenueVisits(venue)
                }
            }
        }
    }
    
    func handleRegionEvent(region: CLRegion!) {
        
        let venue = PFQuery(className: kVenueClassKey)
        venue.getObjectInBackgroundWithId(region.identifier) { (venue: PFObject?, error: NSError?) -> Void in
            if error == nil && venue != nil {
                let visitActivity = PFObject(className: kActivityClassKey)
                visitActivity.setObject(kActivityTypeVisit, forKey: kActivityTypeKey)
                visitActivity.setObject(PFUser.currentUser()!, forKey: kActivityByUserKey)
                visitActivity.setObject(venue!, forKey: kActivityToObjectKey)
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
    
    
    

    // MARK: - Core Data stack

    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.GrandOpens.GrandOpens" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1] 
    }()

    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("GrandOpens", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()

    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("GrandOpens.sqlite")
        var error: NSError? = nil
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
        } catch var error1 as NSError {
            error = error1
            coordinator = nil
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            dict[NSUnderlyingErrorKey] = error
            error = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(error), \(error!.userInfo)")
            abort()
        } catch {
            fatalError()
        }
        
        return coordinator
    }()

    lazy var managedObjectContext: NSManagedObjectContext? = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        if coordinator == nil {
            return nil
        }
        var managedObjectContext = NSManagedObjectContext()
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        if let moc = self.managedObjectContext {
            var error: NSError? = nil
            if moc.hasChanges {
                do {
                    try moc.save()
                } catch let error1 as NSError {
                    error = error1
                    // Replace this implementation with code to handle the error appropriately.
                    // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    NSLog("Unresolved error \(error), \(error!.userInfo)")
                    abort()
                }
            }
        }
    }

}

