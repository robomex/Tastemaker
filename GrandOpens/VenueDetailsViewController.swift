//
//  VenueDetailsViewController.swift
//  GrandOpens
//
//  Created by Tony Morales on 7/29/15.
//  Copyright (c) 2015 Tony Morales. All rights reserved.
//

import UIKit

class VenueDetailsViewController: UIViewController {

    var venue: Venue?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        var venueDetailsLabel = UILabel(frame: CGRectMake(0, 0, 300, 80))
        venueDetailsLabel.center = CGPointMake(UIScreen.mainScreen().bounds.width/2, 200)
        venueDetailsLabel.text = venue!.description + " " + venue!.foodType
        venueDetailsLabel.textAlignment = NSTextAlignment.Center
        venueDetailsLabel.font = UIFont(name: "Muli", size: 17)
        venueDetailsLabel.lineBreakMode = NSLineBreakMode.ByWordWrapping
        venueDetailsLabel.numberOfLines = 3
        self.view.addSubview(venueDetailsLabel)
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