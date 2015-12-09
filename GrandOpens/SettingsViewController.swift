//
//  SettingsViewController.swift
//  GrandOpens
//
//  Created by Tony Morales on 7/23/15.
//  Copyright (c) 2015 Tony Morales. All rights reserved.
//

import UIKit
import Parse

class SettingsViewController: UIViewController {
    
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var nameTextField: UITextField!
    
    @IBOutlet weak var saveSettingsButton: UIButton!
    
    var user: PFUser? = PFUser.currentUser()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        nameTextField.delegate = self
        saveSettingsButton.layer.cornerRadius = 3
        if let user = self.user {
            usernameLabel.text = user.username
            if let name = user["name"] as? String {
                nameTextField.text = name
            }
        } else {
            dismissViewControllerAnimated(true, completion: nil)
        }
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
}

extension SettingsViewController : UITextFieldDelegate {
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        nameTextField.resignFirstResponder()
        return true
    }
}