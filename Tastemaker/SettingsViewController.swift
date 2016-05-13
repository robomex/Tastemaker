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

class SettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, SFSafariViewControllerDelegate {
    
    var nickname: String? = NSUserDefaults.standardUserDefaults().objectForKey("nickname") as? String ?? ""
    var updatedNickname: String?
    var authHandle = UInt()
    var userHandle = UInt()
    var notificationPeriod = String()
    var settingsTableView: UITableView!
    private var usesPassword: Bool?
    private var oldPassword: String?
    private var newPassword: String?
    private var newPasswordReentry: String?
    private var email: String?
    private var needToFixPermissions: Bool?
    let pscope = PermissionScope()
    
    var settingsHeadings = ["My Account", "Permissions", "Additional Information", ""]
    var myAccountRows = ["Nickname", "Muted Users", "Notification Period", "Change Password"]
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

        authHandle = DataService.dataService.BASE_REF.observeAuthEventWithBlock({
            authData in
            
            if authData == nil {
                (UIApplication.sharedApplication().delegate as! AppDelegate).navController?.popToRootViewControllerAnimated(true)
            } else if authData.provider == "password" {
                self.usesPassword = true
                self.email = (authData.providerData["email"] as! String)
                self.settingsTableView.reloadData()
            }
        })
        
        userHandle = DataService.dataService.CURRENT_USER_PRIVATE_REF.childByAppendingPath("notificationPeriod").observeEventType(.Value, withBlock: {
            snapshot in
            
            if snapshot.exists() {
                self.notificationPeriod = snapshot.value as! String
                self.settingsTableView.reloadData()
            }
        })
        
        if PermissionScope().statusLocationAlways() == .Unauthorized || PermissionScope().statusNotifications() == .Unauthorized {
            needToFixPermissions = true
        }
        
        let tracker = GAI.sharedInstance().defaultTracker
        tracker.set(kGAIScreenName, value: "SettingsViewController")
        let builder = GAIDictionaryBuilder.createScreenView()
        tracker.send(builder.build() as [NSObject: AnyObject])
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        DataService.dataService.CURRENT_USER_PRIVATE_REF.childByAppendingPath("notificationPeriod").removeObserverWithHandle(self.userHandle)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        DataService.dataService.BASE_REF.removeAuthEventObserverWithHandle(authHandle)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    // TableView
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            if (usesPassword != nil) && usesPassword! {
                return 4
            } else {
                return 3
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
                    DataService.dataService.CURRENT_USER_PRIVATE_REF.childByAppendingPath("notificationPeriod").setValue("fifteen minutes")
                    Amplitude.instance().logEvent("Changed Notification Period", withEventProperties: ["Setting": "15 Minutes"])
                })
                notificationPeriodMenu.addAction(fifteenMinutesAction)
                let oneHourAction = UIAlertAction(title: "For 1 Hour", style: .Default, handler: {
                    (alert: UIAlertAction!) -> Void in
                    DataService.dataService.CURRENT_USER_PRIVATE_REF.childByAppendingPath("notificationPeriod").setValue("one hour")
                    Amplitude.instance().logEvent("Changed Notification Period", withEventProperties: ["Setting": "1 Hour"])
                })
                notificationPeriodMenu.addAction(oneHourAction)
                let eightHoursAction = UIAlertAction(title: "For 8 Hours", style: .Default, handler: {
                    (alert: UIAlertAction!) -> Void in
                    DataService.dataService.CURRENT_USER_PRIVATE_REF.childByAppendingPath("notificationPeriod").setValue("eight hours")
                    Amplitude.instance().logEvent("Changed Notification Period", withEventProperties: ["Setting": "8 Hours"])
                })
                notificationPeriodMenu.addAction(eightHoursAction)
                let oneDayAction = UIAlertAction(title: "For 1 Day", style: .Default, handler: {
                    (alert: UIAlertAction!) -> Void in
                    DataService.dataService.CURRENT_USER_PRIVATE_REF.childByAppendingPath("notificationPeriod").setValue("one day")
                    Amplitude.instance().logEvent("Changed Notification Period", withEventProperties: ["Setting": "1 Day"])
                })
                notificationPeriodMenu.addAction(oneDayAction)
                let threeDaysAction = UIAlertAction(title: "For 3 Days", style: .Default, handler: {
                    (alert: UIAlertAction!) -> Void in
                    DataService.dataService.CURRENT_USER_PRIVATE_REF.childByAppendingPath("notificationPeriod").setValue("three days")
                    Amplitude.instance().logEvent("Changed Notification Period", withEventProperties: ["Setting": "3 Days"])
                })
                notificationPeriodMenu.addAction(threeDaysAction)
                let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
                notificationPeriodMenu.addAction(cancelAction)
                self.presentViewController(notificationPeriodMenu, animated: true, completion: nil)
            } else if indexPath.row == 3 {
                let changePasswordAlert = SCLAlertView()
                let oldPasswordTextField = changePasswordAlert.addTextField("Old Password")
                let newPasswordTextField = changePasswordAlert.addTextField("New Password")
                let newPasswordReentryTextField = changePasswordAlert.addTextField("Re-enter New Password")
                oldPasswordTextField.autocorrectionType = .No
                newPasswordTextField.autocorrectionType = .No
                newPasswordReentryTextField.autocorrectionType = .No
                oldPasswordTextField.autocapitalizationType = .None
                newPasswordTextField.autocapitalizationType = .None
                newPasswordReentryTextField.autocapitalizationType = .None
                oldPasswordTextField.keyboardType = .Default
                newPasswordTextField.keyboardType = .Default
                newPasswordReentryTextField.keyboardType = .Default
                oldPasswordTextField.secureTextEntry = true
                newPasswordTextField.secureTextEntry = true
                newPasswordReentryTextField.secureTextEntry = true
                
                changePasswordAlert.addButton("Change Password", validationBlock: {
                    self.oldPassword = oldPasswordTextField.text!
                    self.newPassword = newPasswordTextField.text!
                    self.newPasswordReentry = newPasswordReentryTextField.text!
                    
                    let regex = try! NSRegularExpression(pattern: ".*[^A-Za-z0-9].*", options: NSRegularExpressionOptions())
                    if self.oldPassword! == "" {
                        showSimpleAlertWithTitle("Please enter your old password", message: "", actionTitle: "OK", viewController: self)
                        oldPasswordTextField.becomeFirstResponder()
                        return false
                    } else if self.newPassword! == "" {
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
                        
                        DataService.dataService.BASE_REF.changePasswordForUser(self.email!, fromOld: self.oldPassword!, toNew: self.newPassword!, withCompletionBlock: {
                            error in
                            
                            if error != nil {
                                showSimpleAlertWithTitle("We were unable to change your password right now, you may have entered your old password incorrectly", message: "", actionTitle: "OK", viewController: self)
                                print(error)
                            } else {
                                showSimpleAlertWithTitle("You successfully changed your password", message: "", actionTitle: "OK", viewController: self)
                                DataService.dataService.CURRENT_USER_PRIVATE_REF.updateChildValues(["updatedOn": dateFormatter().stringFromDate(NSDate())])
                                Amplitude.instance().logEvent("Changed Password")
                            }
                        })
                })
                changePasswordAlert.showAnimationType = .SlideInToCenter
                changePasswordAlert.hideAnimationType = .FadeOut
                changePasswordAlert.customViewColor = kPurple
                changePasswordAlert.backgroundType = .Blur
                changePasswordAlert.shouldDismissOnTapOutside = true
                changePasswordAlert.showEdit(view.window?.rootViewController, title: nil, subTitle: "Enter your old password and choose a new password 6+ characters long ", closeButtonTitle: "Cancel", duration: 0)
            }
        } else if indexPath.section == 1 {
            if (needToFixPermissions != nil) && needToFixPermissions! {
                
                Amplitude.instance().logEvent("Viewed Update Permissions")
                
                pscope.show({
                    finished, results in
                    
                    if results[0].status != .Unknown && results[1].status != .Unknown {
                        
                        if results[0].status == .Authorized {
                            UIApplication.sharedApplication().registerForRemoteNotifications()
                            
                            Amplitude.instance().logEvent("Subsequent Notification Permission", withEventProperties: ["Status": "Authorized"])
                            Amplitude.instance().identify(AMPIdentify().set("Notification Permission", value: "Authorized"))
                        } else if results[0].status == .Unauthorized {
                            Amplitude.instance().logEvent("Subsequent Notification Permission", withEventProperties: ["Status": "Unauthorized"])
                            Amplitude.instance().identify(AMPIdentify().set("Notification Permission", value: "Unauthorized"))
                        } else if results[0].status == .Disabled {
                            Amplitude.instance().logEvent("Subsequent Notification Permission", withEventProperties: ["Status": "Disabled"])
                            Amplitude.instance().identify(AMPIdentify().set("Notification Permission", value: "Disabled"))
                        }
                        
                        if results[1].status == .Authorized {
                            Amplitude.instance().logEvent("Subsequent Location Permission", withEventProperties: ["Status": "Authorized"])
                            Amplitude.instance().identify(AMPIdentify().set("Location Permission", value: "Authorized"))
                        } else if results[1].status == .Unauthorized {
                            Amplitude.instance().logEvent("Subsequent Location Permission", withEventProperties: ["Status": "Unauthorized"])
                            Amplitude.instance().identify(AMPIdentify().set("Location Permission", value: "Unauthorized"))
                        } else if results[1].status == .Disabled {
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
                    
                    Amplitude.instance().logEvent("Viewed Privacy", withEventProperties: ["Viewed From": "Settings"])
                case 1:
                    let safariVC = SFSafariViewController(URL: NSURL(string: kTermsOfServiceURL)!)
                    safariVC.delegate = self
                    self.presentViewController(safariVC, animated: true, completion: nil)
                    
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
                    
                    Amplitude.instance().logEvent("Viewed Privacy", withEventProperties: ["Viewed From": "Settings"])
                case 1:
                    let safariVC = SFSafariViewController(URL: NSURL(string: kTermsOfServiceURL)!)
                    safariVC.delegate = self
                    self.presentViewController(safariVC, animated: true, completion: nil)
                    
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
}