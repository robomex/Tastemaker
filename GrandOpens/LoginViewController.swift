//
//  LoginViewController.swift
//  GrandOpens
//
//  Created by Tony Morales on 7/23/15.
//  Copyright (c) 2015 Tony Morales. All rights reserved.
//

import UIKit
import TTTAttributedLabel
import SafariServices
import Firebase
import Amplitude_iOS
import Batch

class LoginViewController: UIViewController, TTTAttributedLabelDelegate, SFSafariViewControllerDelegate, UITextFieldDelegate, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var signupButton: UIButton!
    @IBOutlet weak var emailResetButton: UIButton!
    @IBOutlet weak var toggleSignupButton: UIButton!
    @IBOutlet weak var toggleEmailResetButton: UIButton!
    
    @IBOutlet weak var headlineLabel: UILabel!
    @IBOutlet weak var disclaimerLabel: TTTAttributedLabel!

    @IBOutlet weak var emailTextField: TextField!
    @IBOutlet weak var passwordTextField: TextField!
    @IBOutlet weak var nicknameTextField: TextField!
    
    // Onboarding code for testing
    var gradient: CAGradientLayer?
    var toColors: AnyObject?
    var fromColors: AnyObject?
    var animationLoop: Bool = false
    
    // for tracking keyboard
    private var keyboardShown: Bool?
    
    private var signupShown: Bool?
    private var emailResetShown: Bool?
    
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
        self.passwordTextField.nextField = self.nicknameTextField
        
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
        
        nicknameTextField.layer.cornerRadius = textFieldCornerRadius
        nicknameTextField.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.4)
        nicknameTextField.attributedPlaceholder = NSAttributedString(string: "nickname", attributes: [NSForegroundColorAttributeName: UIColor.whiteColor().colorWithAlphaComponent(0.7)])
        nicknameTextField.textColor = UIColor.whiteColor()
        nicknameTextField.tintColor = UIColor.whiteColor()
        nicknameTextField.addTarget(self, action: "textFieldDidChange:", forControlEvents: .EditingChanged)
        nicknameTextField.delegate = self
        nicknameTextField.hidden = true

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
        
        headlineLabel.text = "discover and chat about \nthe newest places"
        headlineLabel.font = UIFont.systemFontOfSize(17.0)
        
        emailResetButton.enabled = false
        emailResetButton.setTitle("Reset Password", forState: .Normal)
        emailResetButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        emailResetButton.setTitleColor(UIColor.whiteColor().colorWithAlphaComponent(0.2), forState: .Disabled)
        emailResetButton.backgroundColor = UIColor.clearColor()
        emailResetButton.layer.borderWidth = 2.0
        emailResetButton.layer.borderColor = UIColor(white: 1.0, alpha: loginButtonBorderAlpha).CGColor
        emailResetButton.layer.cornerRadius = textFieldCornerRadius
        emailResetButton.titleLabel?.font = UIFont.systemFontOfSize(22.0)
        emailResetButton.hidden = true
        
        toggleEmailResetButton.enabled = true
        toggleEmailResetButton.setTitle("Forgot your password?", forState: .Normal)
        toggleEmailResetButton.setTitleColor(UIColor.whiteColor().colorWithAlphaComponent(0.4), forState: .Normal)
        toggleEmailResetButton.backgroundColor = UIColor.clearColor()
        toggleEmailResetButton.layer.borderColor = UIColor.clearColor().CGColor
        toggleEmailResetButton.titleLabel?.font = UIFont.systemFontOfSize(12.0)
        
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
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        let tracker = GAI.sharedInstance().defaultTracker
        tracker.set(kGAIScreenName, value: "LoginViewController")
        let builder = GAIDictionaryBuilder.createScreenView()
        tracker.send(builder.build() as [NSObject: AnyObject])
    }
    
    
    // MARK: UITextField functions
    
    func textFieldDidChange(sender: UITextField) {
        if (!passwordTextField.hidden && passwordTextField.text?.stringByTrimmingCharactersInSet(.whitespaceCharacterSet()).characters.count == 0) || emailTextField.text?.stringByTrimmingCharactersInSet(.whitespaceCharacterSet()).characters.count == 0 || (!nicknameTextField.hidden && nicknameTextField.text?.stringByTrimmingCharactersInSet(.whitespaceCharacterSet()).characters.count == 0) {
            loginButton.enabled = false
            signupButton.enabled = false
            emailResetButton.enabled = false
        } else {
            loginButton.enabled = true
            signupButton.enabled = true
            emailResetButton.enabled = true
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == emailTextField && passwordTextField.hidden {
            textField.resignFirstResponder()
            self.didTapEmailResetButton(textField)
        } else if textField == emailTextField && !passwordTextField.hidden {
            textField.nextField?.becomeFirstResponder()
        } else if textField == passwordTextField && nicknameTextField.hidden {
            textField.resignFirstResponder()
            self.didTapLoginButton(textField)
        } else if textField == passwordTextField && !nicknameTextField.hidden {
            textField.nextField?.becomeFirstResponder()
        } else if textField == nicknameTextField {
            textField.resignFirstResponder()
            self.didTapSignupButton(textField)
        }
        return true
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else {return true}
        
        if textField == nicknameTextField {
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
    
    
    // MARK: didTapLoginButton
    
    @IBAction func didTapLoginButton(sender: AnyObject) {
        let email = emailTextField.text!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) ?? ""
        let password = passwordTextField.text
        
        if email == "" {
            showSimpleAlertWithTitle("Whoops!", message: "Please enter your email address", actionTitle: "OK", viewController: self)
            return
        } else if !self.isValidEmail(email) {
            showSimpleAlertWithTitle("Whoops!", message: "Please enter a valid email address", actionTitle: "OK", viewController: self)
            return
        }
        
        let regex = try! NSRegularExpression(pattern: ".*[^A-Za-z0-9].*", options: NSRegularExpressionOptions())
        if password?.characters.count < 6 {
            showSimpleAlertWithTitle("Whoops!", message: "Passwords are at least 6 characters long", actionTitle: "OK", viewController: self)
            return
        } else if regex.firstMatchInString(password!, options: NSMatchingOptions(), range: NSMakeRange(0, (password?.characters.count)!)) != nil {
            showSimpleAlertWithTitle("Whoops!", message: "Passwords cannot contain special characters", actionTitle: "OK", viewController: self)
            return
        } else if password != nil {
            var trimmedPassword = password!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            trimmedPassword = trimmedPassword.stringByReplacingOccurrencesOfString(" ", withString: "")
            if password != trimmedPassword {
                showSimpleAlertWithTitle("Whoops!", message: "Passwords cannot contain spaces", actionTitle: "OK", viewController: self)
                return
            }
        }
        
        if email != "" && password != "" {
            DataService.dataService.BASE_REF.authUser(email, password: password, withCompletionBlock: {
                error, authData in
                
                if error != nil {
                    showSimpleAlertWithTitle("Whoops!", message: "Please check your login email and password", actionTitle: "OK", viewController: self)
                } else {
                    NSUserDefaults.standardUserDefaults().setValue(authData.uid, forKey: "uid")
                    
                    Amplitude.instance().setUserId(NSUserDefaults.standardUserDefaults().objectForKey("uid") as! String)
                    
                    let editor = BatchUser.editor()
                    editor.setIdentifier((NSUserDefaults.standardUserDefaults().objectForKey("uid") as! String))
                    editor.save()
                    
                    DataService.dataService.CURRENT_USER_PRIVATE_REF.observeSingleEventOfType(FEventType.Value, withBlock: {
                        snapshot in
                        
                        NSUserDefaults.standardUserDefaults().setValue(snapshot.value["nickname"], forKey: "nickname")
                        
                        Amplitude.instance().logEvent("Logged In")
                        
                        self.navigationController?.popToRootViewControllerAnimated(true)
                    })
                }
            })
        }
    }
    
    
    // MARK: didTapSignupButton
    
    // Showing SCLAlertViews in the below function causes issues with the functions watching for keyboard movement
    // Unable to use .becomeFirstResponder for offending field as that causes issues with the keyboard movement functions
    
    @IBAction func didTapSignupButton(sender: AnyObject) {
        let email = emailTextField.text!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) ?? ""
        let password = passwordTextField.text
        var nickname = nicknameTextField.text!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) ?? ""
        nickname = nickname.stringByReplacingOccurrencesOfString(" ", withString: "")
        
        if email == "" {
            showSimpleAlertWithTitle("Whoops!", message: "Please enter your email address", actionTitle: "OK", viewController: self)
            return
        } else if !self.isValidEmail(email) {
            showSimpleAlertWithTitle("Whoops!", message: "Please enter a valid email address", actionTitle: "OK", viewController: self)
            return
        }
        
        let regex = try! NSRegularExpression(pattern: ".*[^A-Za-z0-9].*", options: NSRegularExpressionOptions())
        if password?.characters.count < 6 {
            showSimpleAlertWithTitle("Whoops!", message: "Choose a password at least 6 characters long", actionTitle: "OK", viewController: self)
            return
        } else if regex.firstMatchInString(password!, options: NSMatchingOptions(), range: NSMakeRange(0, (password?.characters.count)!)) != nil {
            showSimpleAlertWithTitle("Whoops!", message: "Choose a password without special characters", actionTitle: "OK", viewController: self)
            return
        } else if password != nil {
            var trimmedPassword = password!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            trimmedPassword = trimmedPassword.stringByReplacingOccurrencesOfString(" ", withString: "")
            if password != trimmedPassword {
                showSimpleAlertWithTitle("Whoops!", message: "Passwords cannot contain spaces", actionTitle: "OK", viewController: self)
                return
            }
        }
        
        if nickname == "" {
            showSimpleAlertWithTitle("Whoops!", message: "Please enter your nickname", actionTitle: "OK", viewController: self)
            return
        } else if nickname.characters.count > 20 {
            showSimpleAlertWithTitle("Whoops!", message: "Choose a shorter nickname", actionTitle: "OK", viewController: self)
            return
        }
        
        if email != "" && password != "" && nickname != "" {
            DataService.dataService.BASE_REF.createUser(email, password: password, withValueCompletionBlock: {
                error, result in
                
                if error != nil {
                    showSimpleAlertWithTitle("Whoops!", message: "We were unable to create your account, please try again", actionTitle: "OK", viewController: self)
                } else {
                    DataService.dataService.BASE_REF.authUser(email, password: password, withCompletionBlock: {
                        err, authData in
                        
                        let user = ["provider": authData.provider!, "email": email, "nickname": nickname, "createdOn": dateFormatter().stringFromDate(NSDate()), "updatedOn": dateFormatter().stringFromDate(NSDate())]
                        let publicUser = ["nickname": nickname]
                        DataService.dataService.createNewPrivateAccount(authData.uid, user: user)
                        DataService.dataService.createNewPublicAccount(authData.uid, publicUser: publicUser)
                        
                        Amplitude.instance().setUserId(NSUserDefaults.standardUserDefaults().objectForKey("uid") as! String)
                        Amplitude.instance().logEvent("Signed Up")
                        
                        let editor = BatchUser.editor()
                        editor.setIdentifier((NSUserDefaults.standardUserDefaults().objectForKey("uid") as! String))
                        editor.save()
                        
                        // Enter the app
                        self.navigationController?.popToRootViewControllerAnimated(true)
                    })
                    
                    // Store the uid for future access
                    NSUserDefaults.standardUserDefaults().setValue(result["uid"], forKey: "uid")
                    NSUserDefaults.standardUserDefaults().setValue(nickname, forKey: "nickname")
                    NSUserDefaults.standardUserDefaults().setBool(false, forKey: "HasSeenInstructions")
                    NSUserDefaults.standardUserDefaults().setBool(false, forKey: "LaunchedBefore")
                }
            })
        }
    }
    
    
    // MARK: didTapToggleSignupButton

    @IBAction func didTapToggleSignupButton(sender: UIButton) {
        if signupShown ?? true {
            loginButton.hidden = true
            toggleEmailResetButton.hidden = true
            passwordTextField.returnKeyType = .Next
            passwordTextField.attributedPlaceholder = NSAttributedString(string: "password (6+ characters)", attributes: [NSForegroundColorAttributeName: UIColor.whiteColor().colorWithAlphaComponent(0.7)])
            nicknameTextField.hidden = false
            signupButton.hidden = false
            toggleSignupButton.setTitle("Have an account? Log In!", forState: .Normal)
            textFieldDidChange(nicknameTextField)
            disclaimerLabel.hidden = false
            signupShown = false
        } else {
            loginButton.hidden = false
            toggleEmailResetButton.hidden = false
            passwordTextField.returnKeyType = .Done
            passwordTextField.attributedPlaceholder = NSAttributedString(string: "password", attributes: [NSForegroundColorAttributeName: UIColor.whiteColor().colorWithAlphaComponent(0.7)])
            nicknameTextField.hidden = true
            signupButton.hidden = true
            toggleSignupButton.setTitle("Don't have an account? Sign Up!", forState: .Normal)
            textFieldDidChange(passwordTextField)
            disclaimerLabel.hidden = true
            signupShown = true
        }
    }
    
    
    // MARK: Email reset
    
    @IBAction func didTapToggleEmailResetButton(sender: AnyObject) {
        if emailResetShown ?? true {
            loginButton.hidden = true
            emailTextField.returnKeyType = .Done
            toggleSignupButton.hidden = true
            passwordTextField.hidden = true
            emailResetButton.hidden = false
            toggleEmailResetButton.setTitle("Want to log in?", forState: .Normal)
            textFieldDidChange(emailTextField)
            emailResetShown = false
        } else {
            loginButton.hidden = false
            emailTextField.returnKeyType = .Next
            toggleSignupButton.hidden = false
            passwordTextField.hidden = false
            textFieldDidChange(passwordTextField)
            emailResetButton.hidden = true
            toggleEmailResetButton.setTitle("Forgot your password?", forState: .Normal)
            emailResetShown = true
        }
    }
    
    @IBAction func didTapEmailResetButton(sender: AnyObject) {
        let email = emailTextField.text!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) ?? ""
        
        if email == "" {
            showSimpleAlertWithTitle("Whoops!", message: "Please enter your email address", actionTitle: "OK", viewController: self)
            return
        } else if !self.isValidEmail(email) {
            showSimpleAlertWithTitle("Whoops!", message: "Please enter a valid email address", actionTitle: "OK", viewController: self)
            return
        }
        
        if email != "" {
            DataService.dataService.BASE_REF.resetPasswordForUser(email, withCompletionBlock: {
                error in
                
                if error != nil {
                    showSimpleAlertWithTitle("Whoops!", message: "We ran into an error trying to reset your password", actionTitle: "OK", viewController: self)
                } else {
                    Amplitude.instance().logEvent("Reset Password")
                    showSimpleAlertWithTitle("Sent!", message: "Check the email we just sent for details about resetting your password", actionTitle: "OK", viewController: self)
                }
            })
        }
    }
    
    
    // MARK: Email validation
    
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
        
        if url == NSURL(string: kTermsOfServiceURL) {
            Amplitude.instance().logEvent("Viewed Terms", withEventProperties: ["Viewed From": "Sign Up"])
        } else if url == NSURL(string: kPrivacyPolicyURL) {
            Amplitude.instance().logEvent("Viewed Privacy", withEventProperties: ["Viewed From": "Sign Up"])
        }
    }
    
    // SFSafariViewControllerDelegate
    func safariViewControllerDidFinish(controller: SFSafariViewController) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    // MARK: Animation
    
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