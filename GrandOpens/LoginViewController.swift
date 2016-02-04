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

class LoginViewController: UIViewController, TTTAttributedLabelDelegate, SFSafariViewControllerDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var continueButton: UIButton!
    
    @IBOutlet weak var headlineLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var disclaimerLabel: TTTAttributedLabel!

    @IBOutlet weak var emailTextField: TextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    // Onboarding code for testing
    var gradient: CAGradientLayer?
    var toColors: AnyObject?
    var fromColors: AnyObject?
    var animationLoop: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        step1()
        
        self.editing = true
        
        self.gradient = CAGradientLayer()
        self.gradient?.frame = self.view.bounds
        self.gradient?.colors = [kBlue.CGColor, kBlue.CGColor, UIColor.whiteColor().CGColor]
        self.view.layer.insertSublayer(self.gradient!, atIndex: 0)
        self.toColors = [UIColor.whiteColor().CGColor, kRed.CGColor, kRed.CGColor]
        animateBackgroundGradient()
        
        // UITextField's nextField setup
        self.emailTextField.nextField = self.passwordTextField
    }
    
    func step1() {
        emailTextField.layer.cornerRadius = 5
        emailTextField.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.4)
        emailTextField.attributedPlaceholder = NSAttributedString(string: "email", attributes: [NSForegroundColorAttributeName: UIColor.whiteColor().colorWithAlphaComponent(0.7)])
        emailTextField.textColor = UIColor.whiteColor()
        emailTextField.tintColor = UIColor.whiteColor()
        emailTextField.addTarget(self, action: "textFieldDidChange:", forControlEvents: UIControlEvents.EditingChanged)
        emailTextField.delegate = self
        
        passwordTextField.layer.cornerRadius = 5
        passwordTextField.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.4)
        passwordTextField.attributedPlaceholder = NSAttributedString(string: "password", attributes: [NSForegroundColorAttributeName: UIColor.whiteColor().colorWithAlphaComponent(0.7)])
        passwordTextField.textColor = UIColor.whiteColor()
        passwordTextField.tintColor = UIColor.whiteColor()
        passwordTextField.addTarget(self, action: "textFieldDidChange:", forControlEvents: UIControlEvents.EditingChanged)
        passwordTextField.delegate = self
        
        headlineLabel.text = "discover and chat about the newest places"
        subtitleLabel.text = "No pressure! You can change your username at any time"
        
        let continueButtonBorderAlpha: CGFloat = 0.4
        let continueButtonCornerRadius: CGFloat = 5.0
        continueButton.enabled = false
        continueButton.setTitle("Continue", forState: UIControlState.Normal)
        continueButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        continueButton.setTitleColor(UIColor.whiteColor().colorWithAlphaComponent(0.2), forState: .Disabled)
        continueButton.backgroundColor = UIColor.clearColor()
        continueButton.layer.borderWidth = 2.0
        continueButton.layer.borderColor = UIColor(white: 1.0, alpha: continueButtonBorderAlpha).CGColor
        continueButton.layer.cornerRadius = continueButtonCornerRadius
        
        let disclaimerText: NSString = "By signing up you agree to our Terms & Privacy Policy."
        disclaimerLabel.delegate = self
        disclaimerLabel.text = disclaimerText as String
        let disclaimerLabelLinkAttributes: [NSObject: AnyObject] = [
            kCTForegroundColorAttributeName: kBlue,
            NSUnderlineStyleAttributeName: NSNumber(bool: false)
        ]
        disclaimerLabel.linkAttributes = disclaimerLabelLinkAttributes
        disclaimerLabel.inactiveLinkAttributes = nil
        let termsOfServiceRange: NSRange = disclaimerText.rangeOfString("Terms")
        disclaimerLabel.addLinkToURL(NSURL(string: kTermsOfServiceURL)!, withRange: termsOfServiceRange)
        let privacyPolicyRange: NSRange = disclaimerText.rangeOfString("Privacy Policy")
        disclaimerLabel.addLinkToURL(NSURL(string: kPrivacyPolicyURL)!, withRange: privacyPolicyRange)
    }
    
    func textFieldDidChange(sender: UITextField) {
        if passwordTextField.text?.stringByTrimmingCharactersInSet(.whitespaceCharacterSet()).characters.count == 0 || emailTextField.text?.stringByTrimmingCharactersInSet(.whitespaceCharacterSet()).characters.count == 0 {
            continueButton.enabled = false
        } else {
            continueButton.enabled = true
        }
//        sender.text = sender.text?.stringByTrimmingCharactersInSet(.whitespaceCharacterSet())
//        guard
//            let email = emailTextField.text where !email.isEmpty,
//            let password = passwordTextField.text where !password.isEmpty
//            else {return}
//        continueButton.enabled = true
//
//        if emailTextField.text?.characters.count > 0 && passwordTextField.text?.characters.count > 0 {
//            continueButton.enabled = true
//        } else {
//            continueButton.enabled = false
//        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == emailTextField {
            textField.nextField?.becomeFirstResponder()
        } else if textField == passwordTextField {
            textField.resignFirstResponder()
            self.didTapContinueButton()
        }
        return true
    }
    
    func step2() {
        headlineLabel.text = "Enter your 4-digit confirmation code."
        subtitleLabel.text = "It was sent in an SMS message to +1 "
        disclaimerLabel.text = ""
        continueButton.setTitle("Log In", forState: UIControlState.Normal)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        

    }
    
    @IBAction func didTapContinueButton() {

        print("here we gooooo")
//        
//        if phoneNumber == "" {
//            
//            // Deformat the phone number by removing parentheses and dashes for saving and processing
//            let stringArray = textFieldText.componentsSeparatedByCharactersInSet(NSCharacterSet.decimalDigitCharacterSet().invertedSet)
//            let unformattedPhoneNumber = stringArray.joinWithSeparator("")
//            if (preferredLanguage == "en" && unformattedPhoneNumber.characters.count != 10)
//                || (preferredLanguage == "ja" && unformattedPhoneNumber.characters.count != 11) {
//                    showSimpleAlertWithTitle("Invalid Phone Number", message: "You must enter a 10-digit US phone number including area code.", actionTitle: "OK", viewController: self)
//                    return step1()
//            }
//            
//            self.editing = false
//            let params = ["phoneNumber" : unformattedPhoneNumber, "language" : preferredLanguage]
//            PFCloud.callFunctionInBackground("sendCode", withParameters: params) { response, error in
//                self.editing = true
//                if let error = error {
//                    var description = error.description
//                    if description.characters.count == 0 {
//                        description = "Something went wrong. Please try again." // "There was a problem with the service.\nTry again later."
//                    } else if let message = error.userInfo["error"] as? String {
//                        description = message
//                    }
//                    showSimpleAlertWithTitle("Login Error", message: description, actionTitle: "OK", viewController: self)
//                    return self.step1()
//                }
//                return self.step2()
//            }
//        } else {
//            if textFieldText.characters.count == 4, let code = Int(textFieldText) {
//                return doLogin(phoneNumber, code: code)
//            }
//            showSimpleAlertWithTitle("Invalid Code Length", message: "You must enter the 4 digit code texted to your phone number.", actionTitle: "OK", viewController: self)
//        }
    }
    
//    func doLogin(phoneNumber: String, code: Int) {
//        self.editing = false
//        let params = ["phoneNumber": phoneNumber, "codeEntry": code] as [NSObject:AnyObject]
//        PFCloud.callFunctionInBackground("logIn", withParameters: params) { response, error in
//            if let description = error?.description {
//                self.editing = true
//                showSimpleAlertWithTitle("Login Error", message: description, actionTitle: "OK", viewController: self)
//                return self.step1()
//            }
//            if let token = response as? String {
//                PFUser.becomeInBackground(token) { user, error in
//                    if let _ = error {
//                        showSimpleAlertWithTitle("Login Error", message: "Something happened while trying to log in. Please try again.", actionTitle: "OK", viewController: self)
//                        self.editing = true
//                        return self.step1()
//                    }
//                    self.navigationController?.popToRootViewControllerAnimated(true)
//                }
//            } else {
//                self.editing = true
//                showSimpleAlertWithTitle("Login Error", message: "Something went wrong, please try again.", actionTitle: "OK", viewController: self)
//                return self.step1()
//            }
//        }
//    }
    
//    override func setEditing(editing: Bool, animated: Bool) {
//        continueButton.enabled = editing
//        textField.enabled = editing
//        if editing {
//            textField.becomeFirstResponder()
//        }
//    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .Default
    }
    
    // TTTAttributedLabelDelegate
    func attributedLabel(label: TTTAttributedLabel!, didSelectLinkWithURL url: NSURL!) {
        let safariVC = SFSafariViewController(URL: url)
        safariVC.delegate = self
        self.presentViewController(safariVC, animated: true, completion: nil)
    }
    
    // SFSafariViewControllerDelegate
    func safariViewControllerDidFinish(controller: SFSafariViewController) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // Phone number formatting
//    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
//        if textField == textField && phoneNumber == "" {
//            let newString = (textField.text! as NSString).stringByReplacingCharactersInRange(range, withString: string)
//            let components = newString.componentsSeparatedByCharactersInSet(NSCharacterSet.decimalDigitCharacterSet().invertedSet)
//            
//            let decimalString = components.joinWithSeparator("") as NSString
//            let length = decimalString.length
//            let hasLeadingOne = length > 0 && decimalString.characterAtIndex(0) == (1 as unichar)
//            
//            if length == 0 || (length > 10 && !hasLeadingOne) || length > 11 {
//                let newLength = (textField.text! as NSString).length + (string as NSString).length - range.length as Int
//                return (newLength > 10) ? false : true
//            }
//            var index = 0 as Int
//            let formattedString = NSMutableString()
//            
//            if hasLeadingOne {
//                formattedString.appendString("1")
//                index += 1
//            }
//            if (length - index) > 3 {
//                let areaCode = decimalString.substringWithRange(NSMakeRange(index, 3))
//                formattedString.appendFormat("(%@) ", areaCode)
//                index += 3
//            }
//            if (length - index) > 3 {
//                let prefix = decimalString.substringWithRange(NSMakeRange(index, 3))
//                formattedString.appendFormat("%@-", prefix)
//                index += 3
//            }
//            
//            let remainder = decimalString.substringFromIndex(index)
//            formattedString.appendString(remainder)
//            textField.text = formattedString as String
//            return false
//        } else {
//            return true
//        }
//    }
    
    // Onboarding code for testing
    func animateBackgroundGradient() {
        self.fromColors = self.gradient?.colors
        self.gradient!.colors = self.toColors! as? [AnyObject]
        
        let animation: CABasicAnimation = CABasicAnimation(keyPath: "colors")
        animation.fromValue = fromColors
        animation.toValue = toColors
        animation.duration = 17.00
        animation.removedOnCompletion = true
        animation.fillMode = kCAFillModeForwards
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        animation.delegate = self
        
        self.gradient?.addAnimation(animation, forKey: "animateGradient")
    }
    
    override func animationDidStop(anim: CAAnimation, finished flag: Bool) {
        if !animationLoop {
            self.toColors = self.fromColors
            self.fromColors = self.gradient?.colors
            animateBackgroundGradient()
            animationLoop = true
        }
    }
}