//
//  LoginViewController.swift
//  Tastemaker
//
//  Created by Tony Morales on 7/23/15.
//  Copyright (c) 2015 Tony Morales. All rights reserved.
//

import UIKit
import TTTAttributedLabel
import SafariServices
import Firebase
import Amplitude_iOS
import FBSDKCoreKit
import FBSDKLoginKit

class LoginViewController: UIViewController, TTTAttributedLabelDelegate, SFSafariViewControllerDelegate, UITextFieldDelegate, UIGestureRecognizerDelegate, FBSDKLoginButtonDelegate {
    
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var signupButton: UIButton!
    @IBOutlet weak var emailResetButton: UIButton!
    @IBOutlet weak var toggleSignupButton: UIButton!
    @IBOutlet weak var toggleEmailResetButton: UIButton!
    
    @IBOutlet weak var headlineLabel: UILabel!
    @IBOutlet weak var disclaimerLabel: TTTAttributedLabel!
    @IBOutlet weak var orLabel: UILabel!

    @IBOutlet weak var emailTextField: TextField!
    @IBOutlet weak var passwordTextField: TextField!
    @IBOutlet weak var nicknameTextField: TextField!
    
    let fbLoginButton = FBSDKLoginButton()
    
    // Onboarding code for testing
    var gradient: CAGradientLayer?
    var toColors: AnyObject?
    var fromColors: AnyObject?
    var animationLoop: Bool = false
    
    // for tracking keyboard
    private var keyboardShown: Bool?
    
    private var loginShown: Bool = false
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
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(LoginViewController.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(LoginViewController.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
        
        // look for taps
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(LoginViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        tap.delegate = self
        
        self.fbLoginButton.delegate = self
        fbLoginButton.readPermissions = ["public_profile", "email"]
        fbLoginButton.center.x = self.view.center.x
        fbLoginButton.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(fbLoginButton)
        
        let fbLoginButtonBottomConstraint = NSLayoutConstraint(item: fbLoginButton, attribute: NSLayoutAttribute.TopMargin, relatedBy: NSLayoutRelation.Equal, toItem: orLabel, attribute: NSLayoutAttribute.BottomMargin, multiplier: 1, constant: 29)
        let fbLoginButtonLeadingConstraint = NSLayoutConstraint(item: fbLoginButton, attribute: NSLayoutAttribute.Leading, relatedBy: NSLayoutRelation.Equal, toItem: view, attribute: .LeadingMargin, multiplier: 1, constant: 30)
        let fbLoginButtonTrailingConstraint = NSLayoutConstraint(item: fbLoginButton, attribute: NSLayoutAttribute.Trailing, relatedBy: .Equal, toItem: view, attribute: .TrailingMargin, multiplier: 1, constant: -30)
        NSLayoutConstraint.activateConstraints([fbLoginButtonBottomConstraint, fbLoginButtonLeadingConstraint, fbLoginButtonTrailingConstraint])
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
        emailTextField.addTarget(self, action: #selector(LoginViewController.textFieldDidChange(_:)), forControlEvents: .EditingChanged)
        emailTextField.delegate = self
        
        passwordTextField.layer.cornerRadius = textFieldCornerRadius
        passwordTextField.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.4)
        passwordTextField.attributedPlaceholder = NSAttributedString(string: "password (6+ characters)", attributes: [NSForegroundColorAttributeName: UIColor.whiteColor().colorWithAlphaComponent(0.7)])
        passwordTextField.textColor = UIColor.whiteColor()
        passwordTextField.tintColor = UIColor.whiteColor()
        passwordTextField.addTarget(self, action: #selector(LoginViewController.textFieldDidChange(_:)), forControlEvents: .EditingChanged)
        passwordTextField.returnKeyType = .Done
        passwordTextField.delegate = self
        
        nicknameTextField.layer.cornerRadius = textFieldCornerRadius
        nicknameTextField.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.4)
        nicknameTextField.attributedPlaceholder = NSAttributedString(string: "nickname", attributes: [NSForegroundColorAttributeName: UIColor.whiteColor().colorWithAlphaComponent(0.7)])
        nicknameTextField.textColor = UIColor.whiteColor()
        nicknameTextField.tintColor = UIColor.whiteColor()
        nicknameTextField.addTarget(self, action: #selector(LoginViewController.textFieldDidChange(_:)), forControlEvents: .EditingChanged)
        nicknameTextField.delegate = self

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
        loginButton.hidden = true
        
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
        
        let toggleSignupButtonBorderAlpha: CGFloat = 0.4
        toggleSignupButton.enabled = true
        toggleSignupButton.setTitle("Already have an account? Log In!", forState: .Normal)
        toggleSignupButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        toggleSignupButton.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.2)
        toggleSignupButton.layer.borderWidth = 2.0
        toggleSignupButton.layer.borderColor = UIColor(white: 1.0, alpha: toggleSignupButtonBorderAlpha).CGColor
        toggleSignupButton.layer.cornerRadius = 0
        toggleSignupButton.titleLabel?.font = UIFont.systemFontOfSize(17.0)
        
        headlineLabel.text = "find the newest restaurants,\nchat about what was good"
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
        toggleEmailResetButton.hidden = true
        
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
        
        orLabel.text = "or"
        orLabel.textColor = UIColor.whiteColor().colorWithAlphaComponent(0.4)
        orLabel.font = UIFont.systemFontOfSize(17.0)
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
            return newLength <= 40
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
                        
                        let user = ["provider": authData.provider!, "email": email, "nickname": nickname, "createdOn": dateFormatter().stringFromDate(NSDate()), "updatedOn": dateFormatter().stringFromDate(NSDate()), "notificationPeriod": "eight hours"]
                        let publicUser = ["nickname": nickname]
                        DataService.dataService.createNewPrivateAccount(authData.uid, user: user)
                        DataService.dataService.createNewPublicAccount(authData.uid, publicUser: publicUser)
                        
                        // Store the uid for future access
                        NSUserDefaults.standardUserDefaults().setValue(result["uid"], forKey: "uid")
                        NSUserDefaults.standardUserDefaults().setValue(nickname, forKey: "nickname")
                        NSUserDefaults.standardUserDefaults().setBool(false, forKey: "HasSeenInstructions")
                        NSUserDefaults.standardUserDefaults().setBool(false, forKey: "LaunchedBefore")
                        NSUserDefaults.standardUserDefaults().setBool(false, forKey: "HasSeenSilenceInstructions")
                        NSUserDefaults.standardUserDefaults().setBool(false, forKey: "HasSeenChatInstructions")
                        
                        Amplitude.instance().setUserId(NSUserDefaults.standardUserDefaults().objectForKey("uid") as! String)
                        Amplitude.instance().logEvent("Signed Up")
                        
                        // Enter the app
                        self.navigationController?.popToRootViewControllerAnimated(true)
                    })
                }
            })
        }
    }
    
    
    // MARK: didTapToggleSignupButton

    @IBAction func didTapToggleSignupButton(sender: UIButton) {
        if loginShown {
            loginButton.hidden = true
            toggleEmailResetButton.hidden = true
            passwordTextField.returnKeyType = .Next
            passwordTextField.attributedPlaceholder = NSAttributedString(string: "password (6+ characters)", attributes: [NSForegroundColorAttributeName: UIColor.whiteColor().colorWithAlphaComponent(0.7)])
            nicknameTextField.hidden = false
            signupButton.hidden = false
            toggleSignupButton.setTitle("Already have an account? Log In!", forState: .Normal)
            textFieldDidChange(nicknameTextField)
            toggleEmailResetButton.hidden = true
            disclaimerLabel.hidden = false
            loginShown = false
        } else {
            loginButton.hidden = false
            toggleEmailResetButton.hidden = false
            passwordTextField.returnKeyType = .Done
            passwordTextField.attributedPlaceholder = NSAttributedString(string: "password", attributes: [NSForegroundColorAttributeName: UIColor.whiteColor().colorWithAlphaComponent(0.7)])
            nicknameTextField.hidden = true
            signupButton.hidden = true
            toggleSignupButton.setTitle("New to Tastemaker? Sign Up!", forState: .Normal)
            textFieldDidChange(passwordTextField)
            toggleEmailResetButton.hidden = false
            disclaimerLabel.hidden = true
            loginShown = true
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
            toggleEmailResetButton.setTitle("Want to log in with your email?", forState: .Normal)
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
    
    
    // MARK: FB Login Button
    
    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {
        if error != nil {
            print("Error encountered during Facebook login")
        } else if result.isCancelled {
            print("Facebook login was cancelled")
        } else {
            
            let accessToken = FBSDKAccessToken.currentAccessToken().tokenString
            
            DataService.dataService.BASE_REF.authWithOAuthProvider("facebook", token: accessToken, withCompletionBlock: { error, authData in
                
                if error != nil {
                    print("Firebase authentication of Facebook token failed: \(error)")
                } else {
                    
                    let separator = " "
                    let displayName = authData.providerData["displayName"] as! String
                    let elements = displayName.componentsSeparatedByString(separator)
                    var nickname = elements[0]
                    if nickname.characters.count > 20 {
                        nickname = String(nickname.characters.prefix(20))
                    }
                    
                    DataService.dataService.USERS_PRIVATE_REF.childByAppendingPath(authData.uid).observeSingleEventOfType(.Value, withBlock: {
                        snapshot in
                        
                        var user = ["provider": authData.provider!, "nickname": nickname, "updatedOn": dateFormatter().stringFromDate(NSDate()), "facebookId": authData.providerData["id"] as! String]
                        let publicUser = ["nickname": nickname]
                        if authData.providerData["email"] != nil {
                            user["email"] = authData.providerData["email"] as? String
                        }
                        if authData.providerData["profileImageURL"] != nil {
                            user["profileImageURL"] = authData.providerData["profileImageURL"] as? String
                        }
                        
                        if snapshot.exists() {
                            DataService.dataService.USERS_PRIVATE_REF.childByAppendingPath(authData.uid).updateChildValues(user)
                            DataService.dataService.USERS_PUBLIC_REF.childByAppendingPath(authData.uid).updateChildValues(publicUser)
                            NSUserDefaults.standardUserDefaults().setValue(authData.uid, forKey: "uid")
                            NSUserDefaults.standardUserDefaults().setValue(nickname, forKey: "nickname")
                            
                            Amplitude.instance().setUserId(NSUserDefaults.standardUserDefaults().objectForKey("uid") as! String)
                            Amplitude.instance().logEvent("Logged In Via Facebook")
                            
                            self.navigationController?.popToRootViewControllerAnimated(true)
                        } else {
                            user["createdOn"] = dateFormatter().stringFromDate(NSDate())
                            user["notificationPeriod"] = "eight hours"
                            DataService.dataService.createNewPrivateAccount(authData.uid, user: user)
                            DataService.dataService.createNewPublicAccount(authData.uid, publicUser: publicUser)
                            
                            NSUserDefaults.standardUserDefaults().setValue(authData.uid, forKey: "uid")
                            NSUserDefaults.standardUserDefaults().setValue(nickname, forKey: "nickname")
                            NSUserDefaults.standardUserDefaults().setBool(false, forKey: "HasSeenInstructions")
                            NSUserDefaults.standardUserDefaults().setBool(false, forKey: "LaunchedBefore")
                            NSUserDefaults.standardUserDefaults().setBool(false, forKey: "HasSeenSilenceInstructions")
                            NSUserDefaults.standardUserDefaults().setBool(false, forKey: "HasSeenChatInstructions")
                            
                            Amplitude.instance().setUserId(NSUserDefaults.standardUserDefaults().objectForKey("uid") as! String)
                            Amplitude.instance().logEvent("Signed Up Via Facebook")
                            
                            self.navigationController?.popToRootViewControllerAnimated(true)
                        }
                    })
                }
            })
        }
    }
    
    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
        print("User logged out using the Facebook button")
    }
}