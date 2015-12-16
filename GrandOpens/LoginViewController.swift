//
//  LoginViewController.swift
//  GrandOpens
//
//  Created by Tony Morales on 7/23/15.
//  Copyright (c) 2015 Tony Morales. All rights reserved.
//

import UIKit
import Parse
import Bolts
import TTTAttributedLabel
import SafariServices

class LoginViewController: UIViewController, TTTAttributedLabelDelegate, SFSafariViewControllerDelegate {
    
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var sendCodeButton: UIButton!
    
    @IBOutlet weak var welcomeLabel: UILabel!
    @IBOutlet weak var questionLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var disclaimerLabel: TTTAttributedLabel!

    
    var phoneNumber: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        step1()
        sendCodeButton.layer.cornerRadius = 3
        
        self.editing = true
    }
    
    func step1() {
        phoneNumber = ""
        textField.placeholder = "555-649-2568"
        questionLabel.text = "Enter your 10-digit US phone number to log in."
        subtitleLabel.text = "Grand Opens will send an SMS to your number to verify your account (standard SMS rates may apply)."
        sendCodeButton.setTitle("Continue", forState: UIControlState.Normal)
//        sendCodeButton.setTitle("Let's Go!", forState: UIControlState.Selected)
        let disclaimerText: NSString = "By tapping Continue you agree to our Terms of Service and confirm you have read our Privacy Policy."
        disclaimerLabel.delegate = self
        disclaimerLabel.text = disclaimerText as String
        let termsOfServiceRange: NSRange = disclaimerText.rangeOfString("Terms of Service")
        disclaimerLabel.addLinkToURL(NSURL(string: kTermsOfServiceURL)!, withRange: termsOfServiceRange)
        let privacyPolicyRange: NSRange = disclaimerText.rangeOfString("Privacy Policy")
        disclaimerLabel.addLinkToURL(NSURL(string: kPrivacyPolicyURL)!, withRange: privacyPolicyRange)
        sendCodeButton.enabled = true
    }
    
    func step2() {
        phoneNumber = textField.text!
        textField.text = ""
        textField.placeholder = "1234"
        questionLabel.text = "Enter your 4-digit confirmation code"
        subtitleLabel.text = "It was sent in an SMS message to +1" + phoneNumber
        disclaimerLabel.text = ""
        sendCodeButton.setTitle("Log In", forState: UIControlState.Normal)
        sendCodeButton.enabled = true
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        textField.becomeFirstResponder()
    }
    
    @IBAction func didTapSendCodeButton() {
        let preferredLanguage = NSBundle.mainBundle().preferredLocalizations[0]
        
        let textFieldText = textField.text ?? ""
        
        if phoneNumber == "" {
            if (preferredLanguage == "en" && textFieldText.characters.count != 10)
                || (preferredLanguage == "ja" && textFieldText.characters.count != 11) {
                    showSimpleAlertWithTitle("Invalid Phone Number", message: "You must enter a 10-digit US phone number including area code.", actionTitle: "OK", viewController: self)
                    return step1()
            }
            
            self.editing = false
            let params = ["phoneNumber" : textFieldText, "language" : preferredLanguage]
            PFCloud.callFunctionInBackground("sendCode", withParameters: params) { response, error in
                self.editing = true
                if let error = error {
                    var description = error.description
                    if description.characters.count == 0 {
                        description = "Something went wrong. Please try again." // "There was a problem with the service.\nTry again later."
                    } else if let message = error.userInfo["error"] as? String {
                        description = message
                    }
                    showSimpleAlertWithTitle("Login Error", message: description, actionTitle: "OK", viewController: self)
                    return self.step1()
                }
                return self.step2()
            }
        } else {
            if textFieldText.characters.count == 4, let code = Int(textFieldText) {
                return doLogin(phoneNumber, code: code)
            }
            showSimpleAlertWithTitle("Invalid Code Length", message: "You must enter the 4 digit code texted to your phone number.", actionTitle: "OK", viewController: self)
        }
    }
    
    func doLogin(phoneNumber: String, code: Int) {
        self.editing = false
        let params = ["phoneNumber": phoneNumber, "codeEntry": code] as [NSObject:AnyObject]
        PFCloud.callFunctionInBackground("logIn", withParameters: params) { response, error in
            if let description = error?.description {
                self.editing = true
                showSimpleAlertWithTitle("Login Error", message: description, actionTitle: "OK", viewController: self)
                return self.step1()
            }
            if let token = response as? String {
                PFUser.becomeInBackground(token) { user, error in
                    if let _ = error {
                        showSimpleAlertWithTitle("Login Error", message: "Something happened while trying to log in. Please try again.", actionTitle: "OK", viewController: self)
                        self.editing = true
                        return self.step1()
                    }
                    return (UIApplication.sharedApplication().delegate as! AppDelegate).presentTabBarController() //self.dismissViewControllerAnimated(true, completion: nil)
                }
            } else {
                self.editing = true
                showSimpleAlertWithTitle("Login Error", message: "Something went wrong, please try again.", actionTitle: "OK", viewController: self)
                return self.step1()
            }
        }
    }
    
    override func setEditing(editing: Bool, animated: Bool) {
        sendCodeButton.enabled = editing
        textField.enabled = editing
        if editing {
            textField.becomeFirstResponder()
        }
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .Default
    }
    
    // TTTAttributedLabelDelegate
    func attributedLabel(label: TTTAttributedLabel!, didSelectLinkWithURL url: NSURL!) {
//        UIApplication.sharedApplication().openURL(url)
        let safariVC = SFSafariViewController(URL: url)
        safariVC.delegate = self
        self.presentViewController(safariVC, animated: true, completion: nil)
    }
    
    // SFSafariViewControllerDelegate
    func safariViewControllerDidFinish(controller: SFSafariViewController) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
}

extension LoginViewController : UITextFieldDelegate {
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.didTapSendCodeButton()
        
        return true
    }
}
