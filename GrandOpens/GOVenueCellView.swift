//
//  GOVenueCellView.swift
//  GrandOpens
//
//  Created by Tony Morales on 9/19/15.
//  Copyright (c) 2015 Tony Morales. All rights reserved.
//

import Foundation
import UIKit
import ParseUI
import Parse

struct GOVenueCellButtons: OptionSetType {
    let rawValue: Int
    init(rawValue: Int) {self.rawValue = rawValue}
    
    static let None = GOVenueCellButtons(rawValue: 1 << 0)
    static let Vote = GOVenueCellButtons(rawValue: 1 << 1)
    
    static let Default: GOVenueCellButtons = [Vote]
}

class GOVenueCellView: PFTableViewCell {
    
    // The bitmark which specifies the enabled interaction elements in the view
    var buttons: GOVenueCellButtons = .None
    
    
    // @name Accessing Interaction Elements
    
    // The Vote button
    var voteButton: UIButton?
    
    var delegate: GOVenueCellViewDelegate?
    
    var containerView: UIView?
    
    
    // MARK: Initialization
    
    init(frame: CGRect, buttons otherButtons: GOVenueCellButtons) {
        super.init(style: UITableViewCellStyle.Default, reuseIdentifier: nil)
        self.frame = frame
        
        GOVenueCellView.validateButtons(otherButtons)
        buttons = otherButtons
        
        self.clipsToBounds = false
        self.backgroundColor = UIColor.clearColor()
        
        // translucent portion
        self.containerView = UIView(frame: CGRectMake(0.0, 0.0, self.bounds.size.width, self.bounds.size.height))
        self.containerView!.clipsToBounds = false
        self.addSubview(self.containerView!)
        self.containerView!.backgroundColor = UIColor.whiteColor()
        
        if self.buttons.contains(GOVenueCellButtons.Vote) {
            // Vote button
            voteButton = UIButton(type: UIButtonType.Custom)
            containerView!.addSubview(self.voteButton!)
            self.voteButton!.frame = CGRectMake(10, 30, 30, 30)
            self.voteButton!.backgroundColor = UIColor.clearColor()
            self.voteButton!.setTitle("", forState: UIControlState.Normal)
            self.voteButton!.setTitleColor(UIColor(red: 155.0/255.0, green: 89.0/255.0, blue: 182.0/255.0, alpha: 1.0), forState: UIControlState.Normal)
            self.voteButton!.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Selected)
            self.voteButton!.titleEdgeInsets = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0)
            self.voteButton!.titleLabel!.font = UIFont.systemFontOfSize(12.0)
            self.voteButton!.titleLabel!.minimumScaleFactor = 0.8
            self.voteButton!.titleLabel!.adjustsFontSizeToFitWidth = true
            self.voteButton!.adjustsImageWhenHighlighted = false
            self.voteButton!.adjustsImageWhenDisabled = false
            self.voteButton!.setBackgroundImage(UIImage(named: "Vote.png"), forState: UIControlState.Normal)
            self.voteButton!.setBackgroundImage(UIImage(named: "Vote.png"), forState: UIControlState.Selected)
            self.voteButton!.selected = false
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: GOVenueCellView
    
    var venue: PFObject? {
        didSet{
            var constrainWidth: CGFloat = containerView!.bounds.size.width
            
            if self.buttons.contains(GOVenueCellButtons.Vote) {
                constrainWidth = self.voteButton!.frame.origin.x
                self.voteButton!.addTarget(self, action: Selector("didTapVoteButtonAction:"), forControlEvents: UIControlEvents.TouchUpInside)
            }
            
            self.setNeedsDisplay()
        }
    }
    
    func setVoteStatus(voted: Bool) {
        self.voteButton!.selected = voted
        
        // FIXME: both are the same???
        if (voted) {
            self.voteButton!.titleEdgeInsets = UIEdgeInsetsMake(-3.0, 0.0, 0.0, 0.0)
        } else {
            self.voteButton!.titleEdgeInsets = UIEdgeInsetsMake(-3.0, 0.0, 0.0, 0.0)
        }
    }
    
    func shouldEnableVoteButton(enable: Bool) {
        if enable {
            self.voteButton!.removeTarget(self, action: Selector("didTapVoteButtonAction:"), forControlEvents: UIControlEvents.TouchUpInside)
        } else {
            self.voteButton!.addTarget(self, action: Selector("didTapVoteButtonAction:"), forControlEvents: UIControlEvents.TouchUpInside)
        }
    }
    
    
    // MARK: ()
    
    static func validateButtons(buttons: GOVenueCellButtons) {
        if buttons == GOVenueCellButtons.None {
            fatalError("Buttons must be set before initializing GOVenueCellView")
        }
    }
    
    func didTapVoteButtonAction(button: UIButton) {
        if delegate != nil && delegate!.respondsToSelector(Selector("venueCellView:didTapVoteButton:venue:")) {
            delegate!.venueCellView!(self, didTapVoteButton: button, venue: self.venue!)
        }
    }
}

/*  The protocol defines methods a delegate of GOVenueCellView should implement.
    All methods of the protocol are optional.
*/

@objc protocol GOVenueCellViewDelegate: NSObjectProtocol {
    
    /*
        Sent to the delegate when the vote button is tapped
        @param venue the PFObject for the venue that is being voted or unvoted
    */
    optional func venueCellView(venueCellView: GOVenueCellView, didTapVoteButton button: UIButton, venue: PFObject)
}