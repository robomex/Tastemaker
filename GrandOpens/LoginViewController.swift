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

class LoginViewController: UIViewController {
    
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var sendCodeButton: UIButton!
    
    @IBOutlet weak var questionLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    
    var phoneNumber: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        step1()
        sendCodeButton.layer.cornerRadius = 3
        
        self.editing = true
    }
    
    func step1() {
        phoneNumber = ""
        textField.placeholder = NSLocalizedString("numberDefault", comment: "555-333-6726")
        questionLabel.text = NSLocalizedString("enterPhone", comment: "Please enter your phone number to log in.")
        subtitleLabel.text = NSLocalizedString("enterPhoneExtra", comment: "This example is limited to 10-digit US number.")
        sendCodeButton.enabled = true
    }
    
    func step2() {
        phoneNumber = textField.text!
        textField.text = ""
        textField.placeholder = "1234"
        questionLabel.text = NSLocalizedString("enterCode", comment: "Enter the 4-digit confirmation code:")
        subtitleLabel.text = NSLocalizedString("enterCodeExtra", comment: "It was sent in an SMS message to +1" + phoneNumber) + phoneNumber
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
                    showAlert("Phone Login", message: NSLocalizedString("warningPhone", comment: "You must enter a 10-digit US phone number including area code."))
                    return step1()
            }
            
            self.editing = false
            let params = ["phoneNumber" : textFieldText, "language" : preferredLanguage]
            PFCloud.callFunctionInBackground("sendCode", withParameters: params) { response, error in
                self.editing = true
                if let error = error {
                    var description = error.description
                    if description.characters.count == 0 {
                        description = NSLocalizedString("warningGeneral", comment: "Something went wrong. Please try again.") // "There was a problem with the service.\nTry again later."
                    } else if let message = error.userInfo["error"] as? String {
                        description = message
                    }
                    self.showAlert("Login Error", message: description)
                    return self.step1()
                }
                return self.step2()
            }
        } else {
            if textFieldText.characters.count == 4, let code = Int(textFieldText) {
                return doLogin(phoneNumber, code: code)
            }
            
            showAlert("Code Entry", message: NSLocalizedString("warningCodeLength", comment: "You must enter the 4 digit code texted to your phone number."))
        }
    }
    
    func doLogin(phoneNumber: String, code: Int) {
        self.editing = false
        let params = ["phoneNumber": phoneNumber, "codeEntry": code] as [NSObject:AnyObject]
        PFCloud.callFunctionInBackground("logIn", withParameters: params) { response, error in
            if let description = error?.description {
                self.editing = true
                return self.showAlert("Login Error", message: description)
            }
            if let token = response as? String {
                PFUser.becomeInBackground(token) { user, error in
                    if let _ = error {
                        self.showAlert("Login Error", message: NSLocalizedString("warningGeneral", comment: "Something happened while trying to log in.\nPlease try again."))
                        self.editing = true
                        return self.step1()
                    }
                    return self.dismissViewControllerAnimated(true, completion: nil)
                }
            } else {
                self.editing = true
                self.showAlert("Login Error", message: NSLocalizedString("warningGeneral", comment: "Something went wrong.  Please try again."))
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
    
    func showAlert(title: String, message: String) {
        return UIAlertView(title: title, message: message, delegate: nil, cancelButtonTitle: NSLocalizedString("alertOK", comment: "OK")).show()
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .Default
    }
}

extension LoginViewController : UITextFieldDelegate {
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.didTapSendCodeButton()
        
        return true
    }
}
