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

class LoginViewController: UIViewController, TTTAttributedLabelDelegate, SFSafariViewControllerDelegate, UITextFieldDelegate, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var signupButton: UIButton!
    @IBOutlet weak var toggleSignupButton: UIButton!
    
    @IBOutlet weak var headlineLabel: UILabel!
    @IBOutlet weak var subtitleLabel: TTTAttributedLabel!
    @IBOutlet weak var disclaimerLabel: TTTAttributedLabel!

    @IBOutlet weak var emailTextField: TextField!
    @IBOutlet weak var passwordTextField: TextField!
    @IBOutlet weak var usernameTextField: TextField!
    
    // Onboarding code for testing
    var gradient: CAGradientLayer?
    var toColors: AnyObject?
    var fromColors: AnyObject?
    var animationLoop: Bool = false
    
    // for tracking keyboard
    private var keyboardShown: Bool?
    private var signupShown: Bool?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        step1()
        
        self.editing = true
        
        self.gradient = CAGradientLayer()
        self.gradient?.frame = self.view.bounds
        self.gradient?.colors = [kBlue.CGColor, kBlue.CGColor, kPurple.CGColor]
        self.view.layer.insertSublayer(self.gradient!, atIndex: 0)
        self.toColors = [UIColor.whiteColor().CGColor, kRed.CGColor, kRed.CGColor]
        animateBackgroundGradient()
        
        // UITextField's nextField setup
        self.emailTextField.nextField = self.passwordTextField
        self.passwordTextField.nextField = self.usernameTextField
        
        // move view with keyboard
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillShow:"), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillHide:"), name: UIKeyboardWillHideNotification, object: nil)
        
        // look for taps
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
        view.addGestureRecognizer(tap)
        tap.delegate = self
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // Track keyboard for moving the view up and down
    
    func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue() {
            if !(keyboardShown ?? false) {
                self.view.frame.origin.y -= keyboardSize.height/2
            }
        }
        keyboardShown = true
    }
    
    func keyboardWillHide(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue() {
            self.view.frame.origin.y += keyboardSize.height/2
        }
        keyboardShown = false
    }
    
    // Watch for taps to dismiss the keyboard
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        if touch.view!.isKindOfClass(TTTAttributedLabel) {
            return false
        } else {
            return true
        }
    }
    
    func step1() {
        let textFieldCornerRadius:CGFloat = 5
        
        emailTextField.layer.cornerRadius = textFieldCornerRadius
        emailTextField.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.4)
        emailTextField.attributedPlaceholder = NSAttributedString(string: "email", attributes: [NSForegroundColorAttributeName: UIColor.whiteColor().colorWithAlphaComponent(0.7)])
        emailTextField.textColor = UIColor.whiteColor()
        emailTextField.tintColor = UIColor.whiteColor()
        emailTextField.addTarget(self, action: "textFieldDidChange:", forControlEvents: .EditingChanged)
        emailTextField.delegate = self
        
        passwordTextField.layer.cornerRadius = textFieldCornerRadius
        passwordTextField.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.4)
        passwordTextField.attributedPlaceholder = NSAttributedString(string: "password", attributes: [NSForegroundColorAttributeName: UIColor.whiteColor().colorWithAlphaComponent(0.7)])
        passwordTextField.textColor = UIColor.whiteColor()
        passwordTextField.tintColor = UIColor.whiteColor()
        passwordTextField.addTarget(self, action: "textFieldDidChange:", forControlEvents: .EditingChanged)
        passwordTextField.returnKeyType = .Done
        passwordTextField.delegate = self
        
        usernameTextField.layer.cornerRadius = textFieldCornerRadius
        usernameTextField.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.4)
        usernameTextField.attributedPlaceholder = NSAttributedString(string: "nickname", attributes: [NSForegroundColorAttributeName: UIColor.whiteColor().colorWithAlphaComponent(0.7)])
        usernameTextField.textColor = UIColor.whiteColor()
        usernameTextField.tintColor = UIColor.whiteColor()
        usernameTextField.addTarget(self, action: "textFieldDidChange:", forControlEvents: .EditingChanged)
        usernameTextField.delegate = self
        usernameTextField.hidden = true

        let loginButtonBorderAlpha: CGFloat = 0.4
        loginButton.enabled = false
        loginButton.setTitle("Log In", forState: .Normal)
        loginButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        loginButton.setTitleColor(UIColor.whiteColor().colorWithAlphaComponent(0.2), forState: .Disabled)
        loginButton.backgroundColor = UIColor.clearColor()
        loginButton.layer.borderWidth = 2.0
        loginButton.layer.borderColor = UIColor(white: 1.0, alpha: loginButtonBorderAlpha).CGColor
        loginButton.layer.cornerRadius = textFieldCornerRadius
        loginButton.titleLabel?.font = UIFont.systemFontOfSize(22.0)
        
        let signupButtonBorderAlpha: CGFloat = 0.4
        signupButton.enabled = false
        signupButton.setTitle("Sign Up", forState: .Normal)
        signupButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        signupButton.setTitleColor(UIColor.whiteColor().colorWithAlphaComponent(0.2), forState: .Disabled)
        signupButton.backgroundColor = UIColor.clearColor()
        signupButton.layer.borderWidth = 2.0
        signupButton.layer.borderColor = UIColor(white: 1.0, alpha: signupButtonBorderAlpha).CGColor
        signupButton.layer.cornerRadius = textFieldCornerRadius
        signupButton.titleLabel?.font = UIFont.systemFontOfSize(22.0)
        signupButton.hidden = true
        
        let toggleSignupButtonBorderAlpha: CGFloat = 0.4
        toggleSignupButton.enabled = true
        toggleSignupButton.setTitle("Don't have an account? Sign Up!", forState: .Normal)
        toggleSignupButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        toggleSignupButton.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.2)
        toggleSignupButton.layer.borderWidth = 2.0
        toggleSignupButton.layer.borderColor = UIColor(white: 1.0, alpha: toggleSignupButtonBorderAlpha).CGColor
        toggleSignupButton.layer.cornerRadius = 0
        toggleSignupButton.titleLabel?.font = UIFont.systemFontOfSize(17.0)
        
        headlineLabel.text = "discover and chat about the newest places"
        headlineLabel.font = UIFont.systemFontOfSize(17.0)
        
        let emailResetText: NSString = "Forgot your password?"
        subtitleLabel.delegate = self
        subtitleLabel.text = emailResetText as String
        let emailResetLabelLinkAttributes: [NSObject: AnyObject] = [
            kCTForegroundColorAttributeName: UIColor.whiteColor().colorWithAlphaComponent(0.4),
            NSUnderlineStyleAttributeName: NSNumber(bool: false)
        ]
        subtitleLabel.linkAttributes = emailResetLabelLinkAttributes
        subtitleLabel.inactiveLinkAttributes = nil
        let emailResetRange: NSRange = emailResetText.rangeOfString("Forgot your password?")
        subtitleLabel.addLinkToURL(NSURL(string: kResetEmailURL)!, withRange: emailResetRange)
        
        let disclaimerText: NSString = "By signing up you agree to our Terms & Privacy Policy."
        disclaimerLabel.delegate = self
        disclaimerLabel.text = disclaimerText as String
        let disclaimerLabelLinkAttributes: [NSObject: AnyObject] = [
            NSFontAttributeName: UIFont.boldSystemFontOfSize(12.0),
            NSUnderlineStyleAttributeName: NSNumber(bool: false)
        ]
        let disclaimerLabelActiveLinkAttributes: [NSObject: AnyObject] = [
            NSFontAttributeName: UIFont.boldSystemFontOfSize(12.0),
            NSUnderlineStyleAttributeName: NSNumber(bool: false),
            kCTForegroundColorAttributeName: kRed
        ]
        disclaimerLabel.linkAttributes = disclaimerLabelLinkAttributes
        disclaimerLabel.activeLinkAttributes = disclaimerLabelActiveLinkAttributes
        disclaimerLabel.inactiveLinkAttributes = nil
        let termsOfServiceRange: NSRange = disclaimerText.rangeOfString("Terms")
        disclaimerLabel.addLinkToURL(NSURL(string: kTermsOfServiceURL)!, withRange: termsOfServiceRange)
        let privacyPolicyRange: NSRange = disclaimerText.rangeOfString("Privacy Policy")
        disclaimerLabel.addLinkToURL(NSURL(string: kPrivacyPolicyURL)!, withRange: privacyPolicyRange)
        disclaimerLabel.hidden = true
    }
    
    // UITextField functions
    
    func textFieldDidChange(sender: UITextField) {
        if passwordTextField.text?.stringByTrimmingCharactersInSet(.whitespaceCharacterSet()).characters.count == 0 || emailTextField.text?.stringByTrimmingCharactersInSet(.whitespaceCharacterSet()).characters.count == 0 || (!usernameTextField.hidden && usernameTextField.text?.stringByTrimmingCharactersInSet(.whitespaceCharacterSet()).characters.count == 0) {
            loginButton.enabled = false
            signupButton.enabled = false
        } else {
            loginButton.enabled = true
            signupButton.enabled = true
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == emailTextField {
            textField.nextField?.becomeFirstResponder()
        } else if textField == passwordTextField && usernameTextField.hidden {
            textField.resignFirstResponder()
            self.didTapLoginButton(textField)
        } else if textField == passwordTextField && !usernameTextField.hidden {
            textField.nextField?.becomeFirstResponder()
        } else if textField == usernameTextField {
            textField.resignFirstResponder()
            self.didTapSignupButton(textField)
        }
        return true
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else {return true}
        
        if textField == usernameTextField {
            let newLength = text.utf16.count + string.utf16.count - range.length
            return newLength <= 20
        } else if textField == emailTextField {
            let newLength = text.utf16.count + string.utf16.count - range.length
            return newLength <= 30
        } else if textField == passwordTextField {
            let newLength = text.utf16.count + string.utf16.count - range.length
            return newLength <= 20
        } else {
            return true
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    @IBAction func didTapLoginButton(sender: AnyObject) {

        print("here we gooooo")
    }
    
    // Showing SCLAlertViews in the below function causes issues with the functions watching for keyboard movement
    // Unable to use .becomeFirstResponder for offending field as that causes issues with the keyboard movement functions
    
    @IBAction func didTapSignupButton(sender: AnyObject) {
        let email = emailTextField.text
        let password = passwordTextField.text
        let username = usernameTextField.text
        
        if email == "" {
            showSimpleAlertWithTitle("Whoops!", message: "Please enter your email address", actionTitle: "OK", viewController: self)
//            emailTextField.becomeFirstResponder()
            return
        } else if !self.isValidEmail(email!) {
            showSimpleAlertWithTitle("Whoops!", message: "Please enter a valid email address", actionTitle: "OK", viewController: self)
//            emailTextField.becomeFirstResponder()
            return
        }
        
        let regex = try! NSRegularExpression(pattern: ".*[^A-Za-z0-9].*", options: NSRegularExpressionOptions())
        if password?.characters.count < 6 {
            showSimpleAlertWithTitle("Whoops!", message: "Choose a password at least 6 characters long", actionTitle: "OK", viewController: self)
            // The below line is causing the error 'Snapshotting a view that has not been rendered results in an empty snapshot'
//            passwordTextField.becomeFirstResponder()
            return
        } else if regex.firstMatchInString(password!, options: NSMatchingOptions(), range: NSMakeRange(0, (password?.characters.count)!)) != nil {
            showSimpleAlertWithTitle("Whoops!", message: "Choose a password without special characters", actionTitle: "OK", viewController: self)
//            passwordTextField.becomeFirstResponder()
            return
        }
        
        if username == "" {
            showSimpleAlertWithTitle("Whoops!", message: "Please enter your nickname", actionTitle: "OK", viewController: self)
//            usernameTextField.becomeFirstResponder()
            return
        } else if username?.characters.count > 20 {
            showSimpleAlertWithTitle("Whoops!", message: "Choose a shorter nickname", actionTitle: "OK", viewController: self)
//            usernameTextField.becomeFirstResponder()
            return
        }
    
    }

    @IBAction func didTapToggleSignupButton(sender: UIButton) {
        if signupShown ?? true {
            loginButton.hidden = true
            subtitleLabel.hidden = true
            passwordTextField.returnKeyType = .Next
            passwordTextField.attributedPlaceholder = NSAttributedString(string: "password (6+ characters)", attributes: [NSForegroundColorAttributeName: UIColor.whiteColor().colorWithAlphaComponent(0.7)])
            usernameTextField.hidden = false
            signupButton.hidden = false
            signupShown = false
            toggleSignupButton.setTitle("Have an account? Log In!", forState: .Normal)
            // not an issue to just pass in UITextField like this?
            textFieldDidChange(usernameTextField)
            disclaimerLabel.hidden = false
        } else {
            loginButton.hidden = false
            subtitleLabel.hidden = false
            passwordTextField.returnKeyType = .Done
            passwordTextField.attributedPlaceholder = NSAttributedString(string: "password", attributes: [NSForegroundColorAttributeName: UIColor.whiteColor().colorWithAlphaComponent(0.7)])
            usernameTextField.hidden = true
            signupButton.hidden = true
            signupShown = true
            toggleSignupButton.setTitle("Don't have an account? Sign Up!", forState: .Normal)
            textFieldDidChange(passwordTextField)
            disclaimerLabel.hidden = true
        }
    }
    
    // Email validation
    
    func isValidEmail(emailAddress: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}"
        let emailTest = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailTest.evaluateWithObject(emailAddress)
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