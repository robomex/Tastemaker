//
//  SettingsViewController.swift
//  GrandOpens
//
//  Created by Tony Morales on 7/23/15.
//  Copyright (c) 2015 Tony Morales. All rights reserved.
//

import UIKit
import Parse
import SafariServices

class SettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, SFSafariViewControllerDelegate {
    
    var usernameLabel: UILabel!
    var nameTextField: UITextField!
    var saveSettingsButton: UIButton!
    
    var user: PFUser? = PFUser.currentUser()
    
    var settingsTableView: UITableView!
    
    var settingsHeadings = ["My Account", "Additional Information", ""]
    var myAccountRows = ["Username", "Phone Number"]
    var additionalInformationRows = ["Privacy Policy", "Terms of Service"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        settingsTableView = UITableView(frame: CGRectZero, style: UITableViewStyle.Grouped)
        settingsTableView.frame = CGRectMake(0, 0, UIScreen.mainScreen().bounds.width, UIScreen.mainScreen().bounds.height)
        settingsTableView.dataSource = self
        settingsTableView.delegate = self
        settingsTableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "settingsCell")
        settingsTableView.separatorStyle = UITableViewCellSeparatorStyle.SingleLine
        self.view.addSubview(settingsTableView)
    }
    
    override func viewWillAppear(animated: Bool) {
        self.navigationController!.navigationBar.topItem!.title = "Settings"
        self.navigationController!.navigationBar.titleTextAttributes = [NSFontAttributeName: UIFont.systemFontOfSize(26), NSForegroundColorAttributeName: UIColor.whiteColor()]
        self.navigationController!.view.backgroundColor = UIColor.whiteColor()
        self.tabBarController?.tabBar.hidden = false
        self.settingsTableView.reloadData()
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    @IBAction func didTapLogOut(sender: AnyObject) {
        PFUser.logOutInBackgroundWithBlock { error in
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    func checkSetting(user: PFUser, settingName : String) -> Bool {
        if let value = user[settingName] as? Bool {
            return value
        }
        return false
    }
    
    // TableView
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 2 {
            return 1
        } else {
            return 2
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
                cell.detailTextLabel?.text = user!["name"] as? String
                cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
            case 1:
                let phoneNumber = user?.username
                cell.detailTextLabel?.text = "(" + phoneNumber!.substringWithRange(Range<String.Index>(start: (phoneNumber?.startIndex)!, end: (phoneNumber?.endIndex.advancedBy(-7))!)) + ") " + phoneNumber!.substringWithRange(Range<String.Index>(start: (phoneNumber?.startIndex.advancedBy(3))!, end: (phoneNumber?.endIndex.advancedBy(-4))!)) + "-" + phoneNumber!.substringWithRange(Range<String.Index>(start: (phoneNumber?.startIndex.advancedBy(6))!, end: (phoneNumber?.endIndex)!))
            default:
                cell.detailTextLabel?.text = ""
            }
        case 1:
            cell.textLabel?.text = additionalInformationRows[indexPath.row]
            cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
        case 2:
            cell.textLabel?.text = "Log Out"
        default:
            cell.textLabel?.text = "Oh shit something broke"
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
        
        if indexPath.section == 0 && indexPath.row == 0 {
            let vc = GOUsernameEntryViewController()
            vc.user = user
            vc.title = "Username"
            navigationItem.title = " "
            navigationController!.view.backgroundColor = UIColor.whiteColor()
            navigationController?.pushViewController(vc, animated: true)
        } else if indexPath.section == 1 {
            switch (indexPath.row) {
            case 0:
                let safariVC = SFSafariViewController(URL: NSURL(string: kPrivacyPolicyURL)!)
                safariVC.delegate = self
                self.presentViewController(safariVC, animated: true, completion: nil)
            case 1:
                let safariVC = SFSafariViewController(URL: NSURL(string: kTermsOfServiceURL)!)
                safariVC.delegate = self
                self.presentViewController(safariVC, animated: true, completion: nil)
            default:
                return
            }
        } else if indexPath.section == 2 && indexPath.row == 0 {
            let alertController = UIAlertController(title: "Are you sure?", message: nil, preferredStyle: .Alert)
            alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: { (action: UIAlertAction!) in
                print("Cancel")
            }))
            alertController.addAction(UIAlertAction(title: "Log Out", style: UIAlertActionStyle.Default, handler: { (action: UIAlertAction!) in
                PFUser.logOutInBackgroundWithBlock { error in
                    (UIApplication.sharedApplication().delegate as! AppDelegate).logOut()
                }
            }))
            UIApplication.sharedApplication().keyWindow?.rootViewController?.presentViewController(alertController, animated: true, completion: nil)
        }
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func safariViewControllerDidFinish(controller: SFSafariViewController) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
//    
//    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
//        let backItem = UIBarButtonItem()
//        backItem.title = " "
//        navigationItem.backBarButtonItem = backItem
//    }
}