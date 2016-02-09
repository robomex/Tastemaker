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
import SCLAlertView_Objective_C
import Firebase

class SettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, SFSafariViewControllerDelegate {
    
    var nicknameLabel: UILabel!
    
    var nickname: String = "" //NSUserDefaults.standardUserDefaults().valueForKey("username") as! String
    
    var settingsTableView: UITableView!
    
    var settingsHeadings = ["My Account", "Additional Information", ""]
    var myAccountRows = ["Nickname", "Muted Users"]
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
        
        self.navigationController!.navigationBar.translucent = false
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController!.navigationBar.titleTextAttributes = [NSFontAttributeName: UIFont.systemFontOfSize(26), NSForegroundColorAttributeName: UIColor.whiteColor()]
        self.navigationController!.view.backgroundColor = UIColor.whiteColor()
        self.tabBarController?.tabBar.hidden = false
//        self.settingsTableView.reloadData()
        
        DataService.dataService.CURRENT_USER_REF.observeSingleEventOfType(FEventType.Value, withBlock: {
            snapshot in
            
            self.nickname = snapshot.value["nickname"] as! String
            self.settingsTableView.reloadData()
        })
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    // TableView
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 2
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
//                let vc = GOUsernameEntryViewController()
//                vc.user = user
//                vc.title = "Username"
//                navigationController!.view.backgroundColor = UIColor.whiteColor()
//                navigationController?.pushViewController(vc, animated: true)
                let nicknameAlert = SCLAlertView()
                let nicknameTextField = nicknameAlert.addTextField("Nickname")
                nicknameTextField.text = nickname
                nicknameTextField.autocorrectionType = .No
                nicknameTextField.autocapitalizationType = .None
                nicknameTextField.keyboardType = .Default
                nicknameAlert.addButton("Save Nickname", validationBlock: {
                    let nickname = nicknameTextField.text
                    
                    if nickname == "" {
                        showSimpleAlertWithTitle("Please enter a nickname", message: "", actionTitle: "OK", viewController: self)
                        nicknameTextField.becomeFirstResponder()
                        return false
                    } else if nickname?.characters.count > 20 {
                        showSimpleAlertWithTitle("Please enter a shorter nickname", message: "", actionTitle: "OK", viewController: self)
                        nicknameTextField.becomeFirstResponder()
                        return false
                    }
                    return true
                    }, actionBlock: {
                        DataService.dataService.CURRENT_USER_REF.updateChildValues(["nickname": nicknameTextField.text!])
                        NSUserDefaults.standardUserDefaults().setValue(nicknameTextField.text, forKey: "nickname")
                        self.viewWillAppear(false)
                })
                nicknameAlert.showAnimationType = .SlideInToCenter
                nicknameAlert.hideAnimationType = .FadeOut
                nicknameAlert.customViewColor = kPurple
                nicknameAlert.backgroundType = .Blur
                nicknameAlert.shouldDismissOnTapOutside = true
                nicknameAlert.showEdit(self.view.window?.rootViewController, title: nil, subTitle: "No pressure, you can change your nickname at any time", closeButtonTitle: "Cancel", duration: 0)
//                nicknameTextField.becomeFirstResponder()
            } else if indexPath.row == 1 {
                let vc = GOMutedUsersViewController()
                navigationController?.pushViewController(vc, animated: true)
            }
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