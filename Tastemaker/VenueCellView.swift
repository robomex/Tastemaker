//
//  VenueCellView.swift
//  Tastemaker
//
//  Created by Tony Morales on 9/19/15.
//  Copyright (c) 2015 Tony Morales. All rights reserved.
//

import Foundation
import UIKit

struct VenueCellButtons: OptionSetType {
    let rawValue: Int
    init(rawValue: Int) {self.rawValue = rawValue}
    
    static let None = VenueCellButtons(rawValue: 1 << 0)
    static let Vote = VenueCellButtons(rawValue: 1 << 1)
    
    static let Default: VenueCellButtons = [Vote]
}

class VenueCellView: UITableViewCell {
    
    // The bitmark which specifies the enabled interaction elements in the view
    var buttons: VenueCellButtons = .None
    
    
    // @name Accessing Interaction Elements
    
    // The Vote button
    var voteButton: UIButton?
    
    weak var delegate: VenueCellViewDelegate?
    
    var containerView: UIView?
    var venueNameLabel: UILabel?
    var venueNeighborhoodLabel: UILabel?
    var venueOpeningDateLabel: UILabel?
    var isFeatured: String?
    var triangle: TriangleView?
    
    
    // MARK: Initialization
    
    init(frame: CGRect, buttons otherButtons: VenueCellButtons) {
        super.init(style: UITableViewCellStyle.Default, reuseIdentifier: nil)
        self.frame = frame
        
        VenueCellView.validateButtons(otherButtons)
        buttons = otherButtons
        
        self.clipsToBounds = false
        self.backgroundColor = UIColor.whiteColor()
        
        // Translucent portion
        self.containerView = UIView(frame: CGRectMake(0.0, 0.0, self.bounds.size.width, self.bounds.size.height))
        self.containerView!.clipsToBounds = false
        self.addSubview(self.containerView!)
        self.containerView!.backgroundColor = UIColor.whiteColor()
        
        if self.buttons.contains(VenueCellButtons.Vote) {
            // Vote button
            voteButton = UIButton(type: UIButtonType.Custom)
            triangle = TriangleView(frame: CGRectMake(18, 24, 16, 12))
            self.triangle!.alpha = 0.1
            self.triangle!.backgroundColor = UIColor.clearColor()
            containerView!.addSubview(self.triangle!)
            containerView!.addSubview(self.voteButton!)
            self.voteButton!.frame = CGRectMake(6, 18, 40, 40)
            self.voteButton!.backgroundColor = UIColor.clearColor()
            self.voteButton!.setTitle("", forState: UIControlState.Normal)
            self.voteButton!.setTitleColor(kGray, forState: UIControlState.Normal)
            self.voteButton!.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Selected)
            self.voteButton!.titleLabel!.font = UIFont.systemFontOfSize(14.0)
            self.voteButton!.titleLabel!.minimumScaleFactor = 0.8
            self.voteButton!.titleLabel!.adjustsFontSizeToFitWidth = true
            self.voteButton!.adjustsImageWhenHighlighted = false
            self.voteButton!.titleEdgeInsets = UIEdgeInsetsMake(14.0, 0.0, 0.0, 0.0)

            self.voteButton!.selected = false
        }
        
        // Venue name label
        self.venueNameLabel = UILabel(frame: CGRectMake(54.0, 15.0, containerView!.bounds.size.width - 54.0, 26.0))
        containerView!.addSubview(self.venueNameLabel!)
        self.venueNameLabel!.textColor = UIColor.blackColor()
        self.venueNameLabel!.font = UIFont.systemFontOfSize(22.0)
        self.venueNameLabel!.backgroundColor = UIColor.clearColor()
        
        // Venue neighborhood label
        self.venueNeighborhoodLabel = UILabel(frame: CGRectMake(54.0, 42.0, containerView!.bounds.size.width - 54.0, 18.0))
        containerView!.addSubview(self.venueNeighborhoodLabel!)
        self.venueNeighborhoodLabel!.textColor = UIColor.blackColor()
        self.venueNeighborhoodLabel!.font = UIFont.systemFontOfSize(14.0)
        self.venueNeighborhoodLabel!.backgroundColor = UIColor.clearColor()
        
        // Venue opening date label
        self.venueOpeningDateLabel = UILabel(frame: CGRectMake(containerView!.bounds.size.width - 70, 42, 50, 18))
        containerView!.addSubview(self.venueOpeningDateLabel!)
        self.venueOpeningDateLabel!.textColor = UIColor.blackColor()
        self.venueOpeningDateLabel!.font = UIFont.systemFontOfSize(14)
        self.venueOpeningDateLabel!.backgroundColor = UIColor.clearColor()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: VenueCellView
    
    var venue: Venue? {
        didSet{
            
            if self.buttons.contains(VenueCellButtons.Vote) {
                self.voteButton!.addTarget(self, action: #selector(VenueCellView.didTapVoteButtonAction(_:)), forControlEvents: UIControlEvents.TouchUpInside)
            }
            
            let venueName: String? = venue?.name
            self.venueNameLabel!.text = venueName
            
            let venueNeighborhood: String? = venue?.neighborhood
            self.venueNeighborhoodLabel!.text = venueNeighborhood
            
            let venueOpeningDate: String? = venue?.openingDate
            let truncatedOpeningDateFormatter = NSDateFormatter()
            truncatedOpeningDateFormatter.dateFormat = "yyyy-MM-dd"
            let date = truncatedOpeningDateFormatter.dateFromString(venueOpeningDate!)
            truncatedOpeningDateFormatter.dateFormat = "MMM d"
            let venueOpeningDateString = truncatedOpeningDateFormatter.stringFromDate(date!)
            
            if venueName != "Chicago Chat" {
                self.venueOpeningDateLabel!.text = venueOpeningDateString
            } else {
                self.venueOpeningDateLabel!.text = ""
            }
            
            let featured: String? = venue?.foodType
            self.isFeatured = featured
            
            self.setNeedsDisplay()
        }
    }
    
    func shouldEnableVoteButton(enable: Bool) {
        if enable {
            self.voteButton!.addTarget(self, action: #selector(VenueCellView.didTapVoteButtonAction(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        } else {
            self.voteButton!.removeTarget(self, action: #selector(VenueCellView.didTapVoteButtonAction(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        }
    }
    
    func setVisitStatus(visited: Bool) {
        self.voteButton!.enabled = visited
        if visited || venueNameLabel!.text == "Chicago Chat" {
            self.voteButton!.enabled = true
            self.containerView?.backgroundColor = kBlue.colorWithAlphaComponent(0.2)
        }
        if self.isFeatured != nil && venueNameLabel!.text != "Chicago Chat" {
            if self.isFeatured! == "Featured" {
                // During initial implementation of "Specials", i.e. featured's, the vote button was enabled, however if both the featured placement and the potential normal placement will coexist in the same list, don't want to automatically enable voting for everyone - instead of just visitors - as that will artificially inflate the vote numbers
                //                self.voteButton!.enabled = true
                self.containerView?.backgroundColor = kRed.colorWithAlphaComponent(0.2)
            }
        }
    }
    
    
    // MARK: ()
    
    static func validateButtons(buttons: VenueCellButtons) {
        if buttons == VenueCellButtons.None {
            fatalError("Buttons must be set before initializing VenueCellView")
        }
    }
    
    func didTapVoteButtonAction(button: UIButton) {
        if delegate != nil {
            delegate!.venueCellView!(self, didTapVoteButton: button, venueId: (venue?.objectId)!)
        }
    }
}

/*  The protocol defines methods a delegate of VenueCellView should implement.
    All methods of the protocol are optional.
*/

@objc protocol VenueCellViewDelegate: class {
    
    /*
        Sent to the delegate when the vote button is tapped
    */
    optional func venueCellView(venueCellView: VenueCellView, didTapVoteButton button: UIButton, venueId: String)
}