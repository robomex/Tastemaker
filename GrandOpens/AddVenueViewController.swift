//
//  AddVenueViewController.swift
//  GrandOpens
//
//  Created by Tony Morales on 2/10/16.
//  Copyright © 2016 Tony Morales. All rights reserved.
//

import UIKit
import Firebase
import GeoFire

class AddVenueViewController: UIViewController, UIGestureRecognizerDelegate, UITextFieldDelegate {

    @IBOutlet weak var nameTextField: TextField!
    @IBOutlet weak var openingDateTextField: TextField!
    @IBOutlet weak var addressTextField: TextField!
    @IBOutlet weak var neighborhoodTextField: TextField!
    @IBOutlet weak var phoneNumberTextField: TextField!
    @IBOutlet weak var foodTypeTextField: TextField!
    @IBOutlet weak var descriptionTextField: TextField!
    @IBOutlet weak var createButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.editing = true
        self.nameTextField.nextField = self.openingDateTextField
        self.openingDateTextField.nextField = self.addressTextField
        self.addressTextField.nextField = self.neighborhoodTextField
        self.neighborhoodTextField.nextField = self.phoneNumberTextField
        self.phoneNumberTextField.nextField = self.foodTypeTextField
        self.foodTypeTextField.nextField = self.descriptionTextField
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
        view.addGestureRecognizer(tap)
        tap.delegate = self
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == descriptionTextField {
            textField.resignFirstResponder()
            self.didTapCreateButton(textField)
        } else {
            textField.nextField?.becomeFirstResponder()
        }
        return true
    }

    @IBAction func didTapCreateButton(sender: AnyObject) {
        let name = nameTextField.text
        let openingDate = openingDateTextField.text
        let address = addressTextField.text
        let neighborhood = neighborhoodTextField.text
        let phoneNumber = phoneNumberTextField.text
        let foodType = foodTypeTextField.text
        let description = descriptionTextField.text
        
//        DataService.dataService.VENUES_REF.childByAutoId().setValue(["name": name, "openingDate": openingDate, "address": address, "neighborhood": neighborhood, "phoneNumber": phoneNumber, "foodType": foodType, "description": description])
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
