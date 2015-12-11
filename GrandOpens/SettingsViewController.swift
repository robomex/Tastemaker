//
//  SettingsViewController.swift
//  GrandOpens
//
//  Created by Tony Morales on 7/23/15.
//  Copyright (c) 2015 Tony Morales. All rights reserved.
//

import UIKit
import Parse

class SettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    
    var usernameLabel: UILabel!
    var nameTextField: UITextField!
    var saveSettingsButton: UIButton!
    
    var user: PFUser? = PFUser.currentUser()
    
    var settingsHeadings = ["My Account", "Additional Information"]
    var myAccountRows = ["Username", "Phone Number"]
    var additionalInformationRows = ["Privacy Policy", "Terms of Service"]
    
    override func viewDidLoad() {
        super.viewDidLoad()

//        nameTextField.delegate = self
//        saveSettingsButton.layer.cornerRadius = 3
//        if let user = self.user {
//            usernameLabel.text = user.username
//            if let name = user["name"] as? String {
//                nameTextField.text = name
//            }
//        } else {
//            dismissViewControllerAnimated(true, completion: nil)
//        }
        
        let settingsTableView = UITableView(frame: CGRectZero, style: UITableViewStyle.Grouped)
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
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    @IBAction func didTapLogOut(sender: AnyObject) {
        PFUser.logOutInBackgroundWithBlock { error in
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    @IBAction func didTapSaveSettings(sender: AnyObject) {
        if let user = self.user {
            if nameTextField.text != "" {
                user["name"] = nameTextField.text
            }
            user.saveEventually()
        } else {
            dismissViewControllerAnimated(true, completion: nil)
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
        return 2
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
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
                cell.detailTextLabel?.text = phoneNumber!.substringWithRange(Range<String.Index>(start: (phoneNumber?.startIndex)!, end: (phoneNumber?.endIndex.advancedBy(-7))!)) + "-" + phoneNumber!.substringWithRange(Range<String.Index>(start: (phoneNumber?.startIndex.advancedBy(3))!, end: (phoneNumber?.endIndex.advancedBy(-4))!)) + "-" + phoneNumber!.substringWithRange(Range<String.Index>(start: (phoneNumber?.startIndex.advancedBy(6))!, end: (phoneNumber?.endIndex)!))
            default:
                cell.detailTextLabel?.text = ""
            }
        case 1:
            cell.textLabel?.text = additionalInformationRows[indexPath.row]
            cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
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
            
        }
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
//    
//    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
//        let backItem = UIBarButtonItem()
//        backItem.title = " "
//        navigationItem.backBarButtonItem = backItem
//    }
}


// Extension from AnyPhone code
//
//extension SettingsViewController : UITextFieldDelegate {
//    func textFieldShouldReturn(textField: UITextField) -> Bool {
//        nameTextField.resignFirstResponder()
//        return true
//    }
//}