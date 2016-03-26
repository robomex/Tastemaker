//
//  SettingsViewController.swift
//  GrandOpens
//
//  Created by Tony Morales on 7/23/15.
//  Copyright (c) 2015 Tony Morales. All rights reserved.
//

import UIKit
import SafariServices
import SCLAlertView_Objective_C
import Firebase
import Amplitude_iOS

class SettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, SFSafariViewControllerDelegate {
    
    var nickname: String? = NSUserDefaults.standardUserDefaults().objectForKey("nickname") as? String ?? ""
    var updatedNickname: String?
    var authHandle = UInt()
    var userHandle = UInt()
    var notificationPeriod = String()
    var settingsTableView: UITableView!
    
    var settingsHeadings = ["My Account", "Additional Information", ""]
    var myAccountRows = ["Nickname", "Muted Users", "Notification Period"]
    var additionalInformationRows = ["Privacy Policy", "Terms of Service"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Settings"
        settingsTableView = UITableView(frame: CGRectZero, style: UITableViewStyle.Grouped)
        settingsTableView.frame = CGRectMake(0, 0, UIScreen.mainScreen().bounds.width, UIScreen.mainScreen().bounds.height)
        settingsTableView.dataSource = self
        settingsTableView.delegate = self
        settingsTableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "settingsCell")
        settingsTableView.separatorStyle = UITableViewCellSeparatorStyle.SingleLine
        self.view.addSubview(settingsTableView)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController!.navigationBar.translucent = false
        
        self.navigationController!.navigationBar.titleTextAttributes = [NSFontAttributeName: UIFont.systemFontOfSize(26), NSForegroundColorAttributeName: UIColor.whiteColor()]
        self.navigationController!.view.backgroundColor = UIColor.whiteColor()
        self.tabBarController?.tabBar.hidden = false

        authHandle = DataService.dataService.BASE_REF.observeAuthEventWithBlock({
            authData in
            
            if authData == nil {
                (UIApplication.sharedApplication().delegate as! AppDelegate).navController?.popToRootViewControllerAnimated(true)
            }
        })
        
        userHandle = DataService.dataService.CURRENT_USER_PRIVATE_REF.childByAppendingPath("notificationPeriod").observeEventType(.Value, withBlock: {
            snapshot in
            
            if snapshot.exists() {
                self.notificationPeriod = snapshot.value as! String
                self.settingsTableView.reloadData()
            }
        })
        
        let tracker = GAI.sharedInstance().defaultTracker
        tracker.set(kGAIScreenName, value: "SettingsViewController")
        let builder = GAIDictionaryBuilder.createScreenView()
        tracker.send(builder.build() as [NSObject: AnyObject])
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        DataService.dataService.BASE_REF.removeAuthEventObserverWithHandle(authHandle)
        DataService.dataService.CURRENT_USER_PRIVATE_REF.childByAppendingPath("notificationPeriod").removeObserverWithHandle(self.userHandle)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    // TableView
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 3
        case 1:
            return 2
        case 2:
            return 1
        default:
            return 0
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
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
            cell.textLabel?.text = additionalInformationRows[indexPath.row]
            cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
        case 2:
            cell.textLabel?.text = "Log Out"
        default:
            cell.textLabel?.text = ""
        }
        return cell
    }

    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return settingsHeadings[section]
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
                let vc = GOMutedUsersViewController()
                navigationController?.pushViewController(vc, animated: true)
            } else if indexPath.row == 2 {
                let notificationPeriodMenu = UIAlertController(title: nil, message: "After you post to a venue's chat, receive notifications about new chats", preferredStyle: .ActionSheet)
                let fifteenMinutesAction = UIAlertAction(title: "For 15 Minutes", style: .Default, handler: {
                    (alert: UIAlertAction!) -> Void in
                    DataService.dataService.CURRENT_USER_PRIVATE_REF.childByAppendingPath("notificationPeriod").setValue("fifteen minutes")
                })
                notificationPeriodMenu.addAction(fifteenMinutesAction)
                let oneHourAction = UIAlertAction(title: "For 1 Hour", style: .Default, handler: {
                    (alert: UIAlertAction!) -> Void in
                    DataService.dataService.CURRENT_USER_PRIVATE_REF.childByAppendingPath("notificationPeriod").setValue("one hour")
                })
                notificationPeriodMenu.addAction(oneHourAction)
                let eightHoursAction = UIAlertAction(title: "For 8 Hours", style: .Default, handler: {
                    (alert: UIAlertAction!) -> Void in
                    DataService.dataService.CURRENT_USER_PRIVATE_REF.childByAppendingPath("notificationPeriod").setValue("eight hours")
                })
                notificationPeriodMenu.addAction(eightHoursAction)
                let oneDayAction = UIAlertAction(title: "For 1 Day", style: .Default, handler: {
                    (alert: UIAlertAction!) -> Void in
                    DataService.dataService.CURRENT_USER_PRIVATE_REF.childByAppendingPath("notificationPeriod").setValue("one day")
                })
                notificationPeriodMenu.addAction(oneDayAction)
                let threeDaysAction = UIAlertAction(title: "For 3 Days", style: .Default, handler: {
                    (alert: UIAlertAction!) -> Void in
                    DataService.dataService.CURRENT_USER_PRIVATE_REF.childByAppendingPath("notificationPeriod").setValue("three days")
                })
                notificationPeriodMenu.addAction(threeDaysAction)
                let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
                notificationPeriodMenu.addAction(cancelAction)
                self.presentViewController(notificationPeriodMenu, animated: true, completion: nil)
            }
        } else if indexPath.section == 1 {
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
        } else if indexPath.section == 2 && indexPath.row == 0 {
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