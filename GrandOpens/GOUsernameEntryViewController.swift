//
//  GOUsernameEntryViewController.swift
//  GrandOpens
//
//  Created by Tony Morales on 12/10/15.
//  Copyright © 2015 Tony Morales. All rights reserved.
//

import UIKit
import Parse

class GOUsernameEntryViewController: UIViewController, UITextFieldDelegate {

    var user: PFUser? = PFUser.currentUser()
    var usernameTextField: TextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Username explanation label
        let usernameExplanationLabel = UILabel(frame: CGRectMake(0, 0, UIScreen.mainScreen().bounds.width - 30, 40))
        usernameExplanationLabel.center = CGPointMake(UIScreen.mainScreen().bounds.width/2, 93)
        usernameExplanationLabel.textAlignment = NSTextAlignment.Center
        usernameExplanationLabel.font = UIFont.systemFontOfSize(14)
        usernameExplanationLabel.numberOfLines = 0
        usernameExplanationLabel.text = "Your username is how you appear on Grand Opens, pick one so friends and others can recognize you"
        usernameExplanationLabel.lineBreakMode = NSLineBreakMode.ByWordWrapping
        self.view.addSubview(usernameExplanationLabel)
        
        // Username entry field
        usernameTextField = TextField(frame: CGRectMake(0, 125, UIScreen.mainScreen().bounds.width, 40))
        usernameTextField.placeholder = "Joey Joe Joe Jr. S."
        usernameTextField.font = UIFont.systemFontOfSize(18)
        usernameTextField.borderStyle = UITextBorderStyle.None
        usernameTextField.autocorrectionType = UITextAutocorrectionType.No
        usernameTextField.keyboardType = UIKeyboardType.Default
        usernameTextField.returnKeyType = UIReturnKeyType.Done
        usernameTextField.clearButtonMode = UITextFieldViewMode.WhileEditing
        usernameTextField.contentVerticalAlignment = UIControlContentVerticalAlignment.Center
        usernameTextField.backgroundColor = UIColor.whiteColor()
        usernameTextField.text = user!["name"] as? String
        usernameTextField.delegate = self
        self.view.addSubview(usernameTextField)
        
        // Save button
        let saveButton = UIButton(frame: CGRect(x: 40, y: 175, width: UIScreen.mainScreen().bounds.width - 80, height: 40))
        saveButton.backgroundColor = UIColor(red: 0x9b/255, green: 0x59/255, blue: 0xb6/255, alpha: 1.0)
        saveButton.setTitle("Save", forState: .Normal)
        saveButton.titleLabel?.font = UIFont.boldSystemFontOfSize(18.0)
        saveButton.addTarget(self, action: "didTapSaveButton:", forControlEvents: .TouchUpInside)
        saveButton.layer.cornerRadius = 5
        self.view.addSubview(saveButton)
        
        self.view.backgroundColor = UIColor(red: 239.0/255.0, green: 239.0/255.0, blue: 244.0/255.0, alpha: 1.0)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func didTapSaveButton(sender: AnyObject) {
        let username: String? = usernameTextField.text
        if username != "" {
            user!["name"] = username
        }
        user!.saveEventually()
        
        if (self.navigationController != nil) {
            self.navigationController?.popViewControllerAnimated(true)
        } else {
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let destinationVC = segue.destinationViewController as? UINavigationController {
            let targetController = destinationVC.topViewController as? SettingsViewController
            targetController!.title = "Settings"
        }
    }

    // UITextFieldDelegate
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        guard let text = usernameTextField.text else {return true}
        
        let newLength = text.utf16.count + string.utf16.count - range.length
        return newLength <= 20
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}