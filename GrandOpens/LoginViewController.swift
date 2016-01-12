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

    // Onboarding code for testing
    var gradient: CAGradientLayer?
    var toColors: AnyObject?
    var fromColors: AnyObject?
//    var initialVC: InitialViewController?
//    let storyboard = UIStoryboard(name: "main", bundle: nil)
    
    var phoneNumber: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        step1()
        sendCodeButton.layer.cornerRadius = 3
        
        self.editing = true
        
        self.gradient = CAGradientLayer()
        self.gradient?.frame = self.view.bounds
        self.gradient?.colors = [kBlue.CGColor, UIColor.whiteColor().CGColor, UIColor.whiteColor().CGColor]
        self.view.layer.insertSublayer(self.gradient!, atIndex: 0)
        self.toColors = [UIColor.whiteColor().CGColor, UIColor.whiteColor().CGColor, kRed.CGColor]
        animateBackgroundGradient()
    }
    
    func step1() {
        phoneNumber = ""
        textField.placeholder = "(555) 649-2568"
        questionLabel.text = "Enter your 10-digit US phone number to discover and chat about the newest places around."
        subtitleLabel.text = "We will send you an SMS to verify your account (standard SMS rates may apply)."
        sendCodeButton.setTitle("Log In", forState: UIControlState.Normal)
        sendCodeButton.backgroundColor = kPurple
//        sendCodeButton.setTitle("Let's Go!", forState: UIControlState.Selected)
        let disclaimerText: NSString = "By tapping Log In you agree to our Terms of Service and confirm you have read our Privacy Policy."
        disclaimerLabel.delegate = self
        disclaimerLabel.text = disclaimerText as String
        let disclaimerLabelLinkAttributes: [NSObject: AnyObject] = [
            kCTForegroundColorAttributeName: kBlue,
            NSUnderlineStyleAttributeName: NSNumber(bool: false)
        ]
        disclaimerLabel.linkAttributes = disclaimerLabelLinkAttributes
        disclaimerLabel.inactiveLinkAttributes = nil
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
        questionLabel.text = "Enter your 4-digit confirmation code."
        subtitleLabel.text = "It was sent in an SMS message to +1 " + phoneNumber + "."
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
            
            // Deformat the phone number by removing parentheses and dashes for saving and processing
            let stringArray = textFieldText.componentsSeparatedByCharactersInSet(NSCharacterSet.decimalDigitCharacterSet().invertedSet)
            let unformattedPhoneNumber = stringArray.joinWithSeparator("")
            if (preferredLanguage == "en" && unformattedPhoneNumber.characters.count != 10)
                || (preferredLanguage == "ja" && unformattedPhoneNumber.characters.count != 11) {
                    showSimpleAlertWithTitle("Invalid Phone Number", message: "You must enter a 10-digit US phone number including area code.", actionTitle: "OK", viewController: self)
                    return step1()
            }
            
            self.editing = false
            let params = ["phoneNumber" : unformattedPhoneNumber, "language" : preferredLanguage]
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
                    self.navigationController?.popToRootViewControllerAnimated(true)

//                    self.initialVC = super.storyboard!.instantiateViewControllerWithIdentifier("InitialViewController") as? InitialViewController
//                    return self.presentViewController(self.initialVC!, animated: true, completion: nil)//(UIApplication.sharedApplication().delegate as! AppDelegate).presentTabBarController() //self.dismissViewControllerAnimated(true, completion: nil)
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
        let safariVC = SFSafariViewController(URL: url)
        safariVC.delegate = self
        self.presentViewController(safariVC, animated: true, completion: nil)
    }
    
    // SFSafariViewControllerDelegate
    func safariViewControllerDidFinish(controller: SFSafariViewController) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // Phone number formatting
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        if textField == textField && phoneNumber == "" {
            let newString = (textField.text! as NSString).stringByReplacingCharactersInRange(range, withString: string)
            let components = newString.componentsSeparatedByCharactersInSet(NSCharacterSet.decimalDigitCharacterSet().invertedSet)
            
            let decimalString = components.joinWithSeparator("") as NSString
            let length = decimalString.length
            let hasLeadingOne = length > 0 && decimalString.characterAtIndex(0) == (1 as unichar)
            
            if length == 0 || (length > 10 && !hasLeadingOne) || length > 11 {
                let newLength = (textField.text! as NSString).length + (string as NSString).length - range.length as Int
                return (newLength > 10) ? false : true
            }
            var index = 0 as Int
            let formattedString = NSMutableString()
            
            if hasLeadingOne {
                formattedString.appendString("1")
                index += 1
            }
            if (length - index) > 3 {
                let areaCode = decimalString.substringWithRange(NSMakeRange(index, 3))
                formattedString.appendFormat("(%@) ", areaCode)
                index += 3
            }
            if (length - index) > 3 {
                let prefix = decimalString.substringWithRange(NSMakeRange(index, 3))
                formattedString.appendFormat("%@-", prefix)
                index += 3
            }
            
            let remainder = decimalString.substringFromIndex(index)
            formattedString.appendString(remainder)
            textField.text = formattedString as String
            return false
        } else {
            return true
        }
    }
    
    // Onboarding code for testing
    func animateBackgroundGradient() {
        self.fromColors = self.gradient?.colors
        self.gradient!.colors = self.toColors! as! [AnyObject]
        
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
        self.toColors = self.fromColors
        self.fromColors = self.gradient?.colors
        animateBackgroundGradient()
    }
}

extension LoginViewController : UITextFieldDelegate {
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.didTapSendCodeButton()
        
        return true
    }
}
