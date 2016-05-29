//
//  SettingsViewController.swift
//  Tastemaker
//
//  Created by Tony Morales on 7/23/15.
//  Copyright (c) 2015 Tony Morales. All rights reserved.
//

import UIKit
import SafariServices
import SCLAlertView_Objective_C
import Firebase
import Amplitude_iOS
import PermissionScope
import MessageUI

class SettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, SFSafariViewControllerDelegate, MFMessageComposeViewControllerDelegate {
    
    var nickname: String? = NSUserDefaults.standardUserDefaults().objectForKey("nickname") as? String ?? ""
    var updatedNickname: String?
    var authHandle = FIRAuthStateDidChangeListenerHandle?()
    var userHandle = FIRDatabaseHandle()
    var notificationPeriod = String()
    var settingsTableView: UITableView!
    private var usesPassword: Bool?
    private var newPassword: String?
    private var newPasswordReentry: String?
    private var needToFixPermissions: Bool?
    let pscope = PermissionScope()
    
    var settingsHeadings = ["My Account", "Permissions", "Additional Information", ""]
    var myAccountRows = ["Nickname", "Muted Users", "Notification Period", "Text a Friend!", "Change Password"]
    var additionalInformationRows = ["Privacy Policy", "Terms of Service"]
    var fixPermissionsRows = ["Update Permissions"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Settings"
        settingsTableView = UITableView(frame: CGRectZero, style: UITableViewStyle.Grouped)
        settingsTableView.frame = CGRectMake(0, 0, UIScreen.mainScreen().bounds.width, UIScreen.mainScreen().bounds.height)
        settingsTableView.dataSource = self
        settingsTableView.delegate = self
        settingsTableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "settingsCell")
        settingsTableView.separatorStyle = UITableViewCellSeparatorStyle.SingleLine

        let tabBarHeight = self.tabBarController?.tabBar.bounds.height
        edgesForExtendedLayout = UIRectEdge.All
        settingsTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: tabBarHeight!, right: 0)
        self.view.addSubview(settingsTableView)
        
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
        
        self.navigationController!.navigationBar.translucent = false
        
        self.navigationController!.navigationBar.titleTextAttributes = [NSFontAttributeName: UIFont.systemFontOfSize(22), NSForegroundColorAttributeName: UIColor.whiteColor()]
        self.navigationController!.view.backgroundColor = UIColor.whiteColor()
        self.tabBarController?.tabBar.hidden = false

        if isMovingToParentViewController() {
            
            authHandle = FIRAuth.auth()!.addAuthStateDidChangeListener() {
                [weak self] (auth, user) in
                
                if let throwawaySettingsVC = self {
                    if user != nil {
                        for profile in (user?.providerData)! {
                            let providerId = profile.providerID
                            if providerId == "password" {
                                throwawaySettingsVC.usesPassword = true
                                throwawaySettingsVC.settingsTableView.reloadData()
                            }
                        }
                    } else {
                        DataService.dataService.CURRENT_USER_PRIVATE_REF.child("notificationPeriod").removeObserverWithHandle(throwawaySettingsVC.userHandle)
                        FIRAuth.auth()!.removeAuthStateDidChangeListener(throwawaySettingsVC.authHandle!)
                        
                        (UIApplication.sharedApplication().delegate as! AppDelegate).navController?.popToRootViewControllerAnimated(true)
                    }
                }
            }
            
            userHandle = DataService.dataService.CURRENT_USER_PRIVATE_REF.child("notificationPeriod").observeEventType(.Value, withBlock: {
                snapshot in
                
                if snapshot.exists() {
                    self.notificationPeriod = snapshot.value as! String
                    self.settingsTableView.reloadData()
                }
            })
        }
        
        if PermissionScope().statusLocationAlways() == .Unauthorized || PermissionScope().statusLocationAlways() == .Unknown || PermissionScope().statusNotifications() == .Unauthorized || PermissionScope().statusNotifications() == .Unknown {
            needToFixPermissions = true
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        if isMovingFromParentViewController() {
            
            DataService.dataService.CURRENT_USER_PRIVATE_REF.child("notificationPeriod").removeObserverWithHandle(self.userHandle)
            FIRAuth.auth()!.removeAuthStateDidChangeListener(authHandle!)
        }
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    // TableView
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            if (usesPassword != nil) && usesPassword! {
                return 5
            } else {
                return 4
            }
        case 1:
            if (needToFixPermissions != nil) && needToFixPermissions! {
                return 1
            } else {
                return 2
            }
        case 2:
            if (needToFixPermissions != nil) && needToFixPermissions! {
                return 2
            } else {
                return 1
            }
        case 3:
            if (needToFixPermissions != nil) && needToFixPermissions! {
                return 1
            } else {
                return 0
            }
        default:
            return 0
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if (needToFixPermissions != nil) && needToFixPermissions! {
            return 4
        } else {
            return 3
        }
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.Value1, reuseIdentifier: "settingsCell")
        switch (indexPath.section) {
        case 0:
            cell.textLabel?.text = myAccountRows[indexPath.row]
            switch (indexPath.row) {
            case 0:
                cell.detailTextLabel?.text = nickname
                cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
            case 2:
                switch (self.notificationPeriod) {
                case "fifteen minutes":
                    cell.detailTextLabel?.text = "15 Minutes"
                case "one hour":
                    cell.detailTextLabel?.text = "1 Hour"
                case "eight hours":
                    cell.detailTextLabel?.text = "8 Hours"
                case "one day":
                    cell.detailTextLabel?.text = "1 Day"
                case "three days":
                    cell.detailTextLabel?.text = "3 Days"
                default:
                    cell.detailTextLabel?.text = ""
                }
                cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
            case 3:
                cell.textLabel?.textColor = kPurple
                cell.textLabel?.font = UIFont.boldSystemFontOfSize(17.0)
                cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
            default:
                cell.detailTextLabel?.text = ""
                cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
            }
        case 1:
            cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
            if (needToFixPermissions != nil) && needToFixPermissions! {
                cell.textLabel?.text = fixPermissionsRows[indexPath.row]
                cell.textLabel?.textColor = kRed
            } else {
                cell.textLabel?.text = additionalInformationRows[indexPath.row]
            }
        case 2:
            if (needToFixPermissions != nil) && needToFixPermissions! {
                cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
                cell.textLabel?.text = additionalInformationRows[indexPath.row]
            } else {
                cell.textLabel?.text = "Log Out"
            }
        case 3:
            if (needToFixPermissions != nil) && needToFixPermissions! {
                cell.textLabel?.text = "Log Out"
            }
        default:
            cell.textLabel?.text = ""
        }
        return cell
    }

    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if (needToFixPermissions != nil) && needToFixPermissions! {
            return settingsHeadings[section]
        } else {
            switch section {
            case 0:
                return settingsHeadings[0]
            case 1:
                return settingsHeadings[2]
            case 2:
                return settingsHeadings[3]
            default:
                return ""
            }
        }
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40.0
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                let nicknameAlert = SCLAlertView()
                let nicknameTextField = nicknameAlert.addTextField("Nickname")
                nicknameTextField.text = nickname
                nicknameTextField.autocorrectionType = .No
                nicknameTextField.autocapitalizationType = .None
                nicknameTextField.keyboardType = .Default
                nicknameAlert.addButton("Save Nickname", validationBlock: {
                    self.updatedNickname = nicknameTextField.text!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) ?? ""
                    self.updatedNickname = self.updatedNickname!.stringByReplacingOccurrencesOfString(" ", withString: "")
                    
                    if self.updatedNickname == "" {
                        showSimpleAlertWithTitle("Please enter a nickname", message: "", actionTitle: "OK", viewController: self)
                        nicknameTextField.becomeFirstResponder()
                        return false
                    } else if self.updatedNickname!.characters.count > 20 {
                        showSimpleAlertWithTitle("Please enter a shorter nickname", message: "", actionTitle: "OK", viewController: self)
                        nicknameTextField.becomeFirstResponder()
                        return false
                    }
                    return true
                    }, actionBlock: {
                        DataService.dataService.CURRENT_USER_PRIVATE_REF.updateChildValues(["nickname": self.updatedNickname!, "updatedOn": dateFormatter().stringFromDate(NSDate())])
                        DataService.dataService.CURRENT_USER_PUBLIC_REF.updateChildValues(["nickname": self.updatedNickname!])
                        NSUserDefaults.standardUserDefaults().setValue(nicknameTextField.text, forKey: "nickname")
                        
                        self.nickname = self.updatedNickname
                        self.settingsTableView.reloadData()
                        
                        FIRAnalytics.logEventWithName("changed_nickname", parameters: ["from": "settings"])
                        Amplitude.instance().logEvent("Changed Nickname")
                })
                nicknameAlert.showAnimationType = .SlideInToCenter
                nicknameAlert.hideAnimationType = .FadeOut
                nicknameAlert.customViewColor = kPurple
                nicknameAlert.backgroundType = .Blur
                nicknameAlert.shouldDismissOnTapOutside = true
                nicknameAlert.showEdit(self.view.window?.rootViewController, title: nil, subTitle: "No pressure, you can change your nickname at any time", closeButtonTitle: "Cancel", duration: 0)
                // becomeFirstResponder causes keyboard issues
//                nicknameTextField.becomeFirstResponder()
            } else if indexPath.row == 1 {
                let vc = MutedUsersViewController()
                navigationController?.pushViewController(vc, animated: true)
            } else if indexPath.row == 2 {
                let notificationPeriodMenu = UIAlertController(title: nil, message: "After you post to a venue's chat, receive notifications about new chats", preferredStyle: .ActionSheet)
                let fifteenMinutesAction = UIAlertAction(title: "For 15 Minutes", style: .Default, handler: {
                    (alert: UIAlertAction!) -> Void in
                    DataService.dataService.CURRENT_USER_PRIVATE_REF.child("notificationPeriod").setValue("fifteen minutes")
                    FIRAnalytics.logEventWithName("changed_notification_period", parameters: ["to": "fifteen_minutes"])
                    Amplitude.instance().logEvent("Changed Notification Period", withEventProperties: ["Setting": "15 Minutes"])
                })
                notificationPeriodMenu.addAction(fifteenMinutesAction)
                let oneHourAction = UIAlertAction(title: "For 1 Hour", style: .Default, handler: {
                    (alert: UIAlertAction!) -> Void in
                    DataService.dataService.CURRENT_USER_PRIVATE_REF.child("notificationPeriod").setValue("one hour")
                    FIRAnalytics.logEventWithName("changed_notification_period", parameters: ["to": "one_hour"])
                    Amplitude.instance().logEvent("Changed Notification Period", withEventProperties: ["Setting": "1 Hour"])
                })
                notificationPeriodMenu.addAction(oneHourAction)
                let eightHoursAction = UIAlertAction(title: "For 8 Hours", style: .Default, handler: {
                    (alert: UIAlertAction!) -> Void in
                    DataService.dataService.CURRENT_USER_PRIVATE_REF.child("notificationPeriod").setValue("eight hours")
                    FIRAnalytics.logEventWithName("changed_notification_period", parameters: ["to": "eight_hours"])
                    Amplitude.instance().logEvent("Changed Notification Period", withEventProperties: ["Setting": "8 Hours"])
                })
                notificationPeriodMenu.addAction(eightHoursAction)
                let oneDayAction = UIAlertAction(title: "For 1 Day", style: .Default, handler: {
                    (alert: UIAlertAction!) -> Void in
                    DataService.dataService.CURRENT_USER_PRIVATE_REF.child("notificationPeriod").setValue("one day")
                    FIRAnalytics.logEventWithName("changed_notification_period", parameters: ["to": "one_day"])
                    Amplitude.instance().logEvent("Changed Notification Period", withEventProperties: ["Setting": "1 Day"])
                })
                notificationPeriodMenu.addAction(oneDayAction)
                let threeDaysAction = UIAlertAction(title: "For 3 Days", style: .Default, handler: {
                    (alert: UIAlertAction!) -> Void in
                    DataService.dataService.CURRENT_USER_PRIVATE_REF.child("notificationPeriod").setValue("three days")
                    FIRAnalytics.logEventWithName("changed_notification_period", parameters: ["to": "three_days"])
                    Amplitude.instance().logEvent("Changed Notification Period", withEventProperties: ["Setting": "3 Days"])
                })
                notificationPeriodMenu.addAction(threeDaysAction)
                let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
                notificationPeriodMenu.addAction(cancelAction)
                self.presentViewController(notificationPeriodMenu, animated: true, completion: nil)
            } else if indexPath.row == 3 {
                let messageComposeVC = configuredMessageComposeViewController()
                if canSendText() {
                    presentViewController(messageComposeVC, animated: true, completion: {
                        UIApplication.sharedApplication().statusBarStyle = .LightContent
                    })
                } else {
                    showSimpleAlertWithTitle("Sorry", message: "Your device is unable to send text messages", actionTitle: "OK", viewController: self)
                }
            } else if indexPath.row == 4 {
                let changePasswordAlert = SCLAlertView()
                let newPasswordTextField = changePasswordAlert.addTextField("New Password")
                let newPasswordReentryTextField = changePasswordAlert.addTextField("Re-enter New Password")
                newPasswordTextField.autocorrectionType = .No
                newPasswordReentryTextField.autocorrectionType = .No
                newPasswordTextField.autocapitalizationType = .None
                newPasswordReentryTextField.autocapitalizationType = .None
                newPasswordTextField.keyboardType = .Default
                newPasswordReentryTextField.keyboardType = .Default
                newPasswordTextField.secureTextEntry = true
                newPasswordReentryTextField.secureTextEntry = true
                
                changePasswordAlert.addButton("Change Password", validationBlock: {
                    self.newPassword = newPasswordTextField.text!
                    self.newPasswordReentry = newPasswordReentryTextField.text!
                    
                    let regex = try! NSRegularExpression(pattern: ".*[^A-Za-z0-9].*", options: NSRegularExpressionOptions())
                    if self.newPassword! == "" {
                        showSimpleAlertWithTitle("Please enter a new password", message: "", actionTitle: "OK", viewController: self)
                        newPasswordTextField.becomeFirstResponder()
                        return false
                    } else if self.newPassword!.characters.count < 6 {
                        showSimpleAlertWithTitle("Choose a new password at least 6 characters long", message: "", actionTitle: "OK", viewController: self)
                        newPasswordTextField.becomeFirstResponder()
                        return false
                    } else if regex.firstMatchInString(self.newPassword!, options: NSMatchingOptions(), range: NSMakeRange(0, (self.newPassword?.characters.count)!)) != nil {
                        showSimpleAlertWithTitle("Choose a password without special characters", message: "", actionTitle: "OK", viewController: self)
                        newPasswordTextField.becomeFirstResponder()
                        return false
                    } else if self.newPassword! != self.newPasswordReentry! {
                        showSimpleAlertWithTitle("Your new password doesn't match", message: "", actionTitle: "OK", viewController: self)
                        newPasswordTextField.becomeFirstResponder()
                        return false
                    } else if self.newPassword != nil {
                        var trimmedPassword = self.newPassword!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                        trimmedPassword = trimmedPassword.stringByReplacingOccurrencesOfString(" ", withString: "")
                        if self.newPassword! != trimmedPassword {
                            showSimpleAlertWithTitle("Passwords cannot contain spaces", message: "", actionTitle: "OK", viewController: self)
                            newPasswordTextField.becomeFirstResponder()
                            return false
                        }
                    }
                    return true
                    }, actionBlock: {
                        
                        let user = FIRAuth.auth()?.currentUser
                        user?.updatePassword(self.newPassword!) { error in
                            if let error = error {
                                showSimpleAlertWithTitle("We were unable to change your password right now", message: "", actionTitle: "OK", viewController: self)
                                print(error)
                            } else {
                                showSimpleAlertWithTitle("You successfully changed your password", message: "", actionTitle: "OK", viewController: self)
                                DataService.dataService.CURRENT_USER_PRIVATE_REF.updateChildValues(["updatedOn": dateFormatter().stringFromDate(NSDate())])
                                FIRAnalytics.logEventWithName("changed_password", parameters: ["from": "settings"])
                                Amplitude.instance().logEvent("Changed Password")
                            }
                        }
                })
                changePasswordAlert.showAnimationType = .SlideInToCenter
                changePasswordAlert.hideAnimationType = .FadeOut
                changePasswordAlert.customViewColor = kPurple
                changePasswordAlert.backgroundType = .Blur
                changePasswordAlert.shouldDismissOnTapOutside = true
                changePasswordAlert.showEdit(view.window?.rootViewController, title: nil, subTitle: "Choose a new password 6+ characters long ", closeButtonTitle: "Cancel", duration: 0)
            }
        } else if indexPath.section == 1 {
            if (needToFixPermissions != nil) && needToFixPermissions! {
                
                FIRAnalytics.logEventWithName("viewed_update_permissions", parameters: ["from": "settings"])
                Amplitude.instance().logEvent("Viewed Update Permissions")
                
                pscope.show({
                    finished, results in
                    
                    if results[0].status != .Unknown && results[1].status != .Unknown {
                        
                        if results[0].status == .Authorized {
                            UIApplication.sharedApplication().registerForRemoteNotifications()
                            
                            FIRAnalytics.logEventWithName("permissioned", parameters: ["from": "settings", "type": "notification", "status": "authorized"])
                            Amplitude.instance().logEvent("Subsequent Notification Permission", withEventProperties: ["Status": "Authorized"])
                            Amplitude.instance().identify(AMPIdentify().set("Notification Permission", value: "Authorized"))
                        } else if results[0].status == .Unauthorized {
                            FIRAnalytics.logEventWithName("permissioned", parameters: ["from": "settings", "type": "notification", "status": "unauthorized"])
                            Amplitude.instance().logEvent("Subsequent Notification Permission", withEventProperties: ["Status": "Unauthorized"])
                            Amplitude.instance().identify(AMPIdentify().set("Notification Permission", value: "Unauthorized"))
                        } else if results[0].status == .Disabled {
                            FIRAnalytics.logEventWithName("permissioned", parameters: ["from": "settings", "type": "notification", "status": "disabled"])
                            Amplitude.instance().logEvent("Subsequent Notification Permission", withEventProperties: ["Status": "Disabled"])
                            Amplitude.instance().identify(AMPIdentify().set("Notification Permission", value: "Disabled"))
                        }
                        
                        if results[1].status == .Authorized {
                            FIRAnalytics.logEventWithName("permissioned", parameters: ["from": "settings", "type": "location", "status": "authorized"])
                            Amplitude.instance().logEvent("Subsequent Location Permission", withEventProperties: ["Status": "Authorized"])
                            Amplitude.instance().identify(AMPIdentify().set("Location Permission", value: "Authorized"))
                        } else if results[1].status == .Unauthorized {
                            FIRAnalytics.logEventWithName("permissioned", parameters: ["from": "settings", "type": "location", "status": "unauthorized"])
                            Amplitude.instance().logEvent("Subsequent Location Permission", withEventProperties: ["Status": "Unauthorized"])
                            Amplitude.instance().identify(AMPIdentify().set("Location Permission", value: "Unauthorized"))
                        } else if results[1].status == .Disabled {
                            FIRAnalytics.logEventWithName("permissioned", parameters: ["from": "settings", "type": "location", "status": "disabled"])
                            Amplitude.instance().logEvent("Subsequent Location Permission", withEventProperties: ["Status": "Disabled"])
                            Amplitude.instance().identify(AMPIdentify().set("Location Permission", value: "Disabled"))
                        }
                        
                        self.pscope.hide()
                        if (PermissionScope().statusLocationAlways() != .Unauthorized && PermissionScope().statusLocationAlways() != .Unknown) && (PermissionScope().statusNotifications() != .Unauthorized && PermissionScope().statusNotifications() != .Unknown) {
                            self.needToFixPermissions = false
                        }
                        self.settingsTableView.reloadData()
                    }
                    }, cancelled: {
                        results in

                })
            } else {
                switch (indexPath.row) {
                case 0:
                    let safariVC = SFSafariViewController(URL: NSURL(string: kPrivacyPolicyURL)!)
                    safariVC.delegate = self
                    self.presentViewController(safariVC, animated: true, completion: nil)
                    
                    FIRAnalytics.logEventWithName("viewed_safari", parameters: ["from": "settings", "type": "privacy"])
                    Amplitude.instance().logEvent("Viewed Privacy", withEventProperties: ["Viewed From": "Settings"])
                case 1:
                    let safariVC = SFSafariViewController(URL: NSURL(string: kTermsOfServiceURL)!)
                    safariVC.delegate = self
                    self.presentViewController(safariVC, animated: true, completion: nil)
                    
                    FIRAnalytics.logEventWithName("viewed_safari", parameters: ["from": "settings", "type": "terms"])
                    Amplitude.instance().logEvent("Viewed Terms", withEventProperties: ["Viewed From": "Settings"])
                default:
                    return
                }
            }
        } else if indexPath.section == 2 {
            if (needToFixPermissions != nil) && needToFixPermissions! {
                switch (indexPath.row) {
                case 0:
                    let safariVC = SFSafariViewController(URL: NSURL(string: kPrivacyPolicyURL)!)
                    safariVC.delegate = self
                    self.presentViewController(safariVC, animated: true, completion: nil)
                    
                    FIRAnalytics.logEventWithName("viewed_safari", parameters: ["from": "settings", "type": "privacy"])
                    Amplitude.instance().logEvent("Viewed Privacy", withEventProperties: ["Viewed From": "Settings"])
                case 1:
                    let safariVC = SFSafariViewController(URL: NSURL(string: kTermsOfServiceURL)!)
                    safariVC.delegate = self
                    self.presentViewController(safariVC, animated: true, completion: nil)
                    
                    FIRAnalytics.logEventWithName("viewed_safari", parameters: ["from": "settings", "type": "terms"])
                    Amplitude.instance().logEvent("Viewed Terms", withEventProperties: ["Viewed From": "Settings"])
                default:
                    return
                }
            } else {
                let alertController = UIAlertController(title: "Are you sure?", message: nil, preferredStyle: .Alert)
                alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: { (action: UIAlertAction!) in
                    print("Cancel")
                }))
                alertController.addAction(UIAlertAction(title: "Log Out", style: UIAlertActionStyle.Default, handler: { (action: UIAlertAction!) in
                    
                    FIRAnalytics.logEventWithName("logged_out", parameters: ["from": "settings"])
                    Amplitude.instance().logEvent("Logged Out")
                    (UIApplication.sharedApplication().delegate as! AppDelegate).logOut()
                }))
                UIApplication.sharedApplication().keyWindow?.rootViewController?.presentViewController(alertController, animated: true, completion: nil)
            }
        } else if indexPath.section == 3 {
            let alertController = UIAlertController(title: "Are you sure?", message: nil, preferredStyle: .Alert)
            alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: { (action: UIAlertAction!) in
                print("Cancel")
            }))
            alertController.addAction(UIAlertAction(title: "Log Out", style: UIAlertActionStyle.Default, handler: { (action: UIAlertAction!) in
                
                FIRAnalytics.logEventWithName("logged_out", parameters: ["from": "settings"])
                Amplitude.instance().logEvent("Logged Out")
                (UIApplication.sharedApplication().delegate as! AppDelegate).logOut()
            }))
            UIApplication.sharedApplication().keyWindow?.rootViewController?.presentViewController(alertController, animated: true, completion: nil)
        }
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func safariViewControllerDidFinish(controller: SFSafariViewController) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    // MARK: SMS Invitations
    
    // A wrapper function to indicate whether or not a text message can be sent from the user's device
    func canSendText() -> Bool {
        return MFMessageComposeViewController.canSendText()
    }
    
    // Configures and returns a MFMessageComposeViewController instance
    func configuredMessageComposeViewController() -> MFMessageComposeViewController {
        let messageComposeVC = MFMessageComposeViewController()
        messageComposeVC.messageComposeDelegate = self
        messageComposeVC.navigationBar.tintColor = UIColor.whiteColor()
        messageComposeVC.navigationBar.titleTextAttributes = [NSFontAttributeName: UIFont.systemFontOfSize(22), NSForegroundColorAttributeName: UIColor.whiteColor()]
        messageComposeVC.body = "Check out the newest restaurants with me on Tastemaker! Get the iOS app at getTastemaker.com"
        return messageComposeVC
    }
    
    // MFMessageComposeViewControllerDelegate callback - dismisses the view controller when the user is finished with it
    func messageComposeViewController(controller: MFMessageComposeViewController, didFinishWithResult result: MessageComposeResult) {
        switch result {
        case MessageComposeResultCancelled:
            controller.dismissViewControllerAnimated(true, completion: nil)
        case MessageComposeResultFailed:
            controller.dismissViewControllerAnimated(true, completion: nil)
        case MessageComposeResultSent:
            FIRAnalytics.logEventWithName("sent_sms_invite", parameters: ["from": "settings"])
            controller.dismissViewControllerAnimated(true, completion: nil)
        default:
            break
        }
    }
}