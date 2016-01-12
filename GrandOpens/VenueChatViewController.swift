//
//  VenueChatViewController.swift
//  GrandOpens
//
//  Created by Tony Morales on 7/21/15.
//  Copyright (c) 2015 Tony Morales. All rights reserved.
//

import Foundation
import Parse
import JSQMessagesViewController
import DZNEmptyDataSet

class VenueChatViewController: JSQMessagesViewController, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    var messages: [JSQMessage] = []
    var venueID: String?
    var messageListener: MessageListener?
    
    let outgoingBubble = JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImageWithColor(kBlue)
    let incomingBubble = JSQMessagesBubbleImageFactory().incomingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleLightGrayColor())
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSizeZero
        collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero
        
        if let id = venueID {
            fetchMessages(id, callback: {
                messages in
                
                for m in messages {
                    self.messages.append(JSQMessage(senderId: m.senderID, senderDisplayName: m.senderName, date: m.date, text: m.message))
                }
                self.finishReceivingMessage()
            })
        }
        
        self.senderId = currentUser()!.id
        self.senderDisplayName = currentUser()!.name

        self.inputToolbar?.contentView!.leftBarButtonItem = nil
        self.edgesForExtendedLayout = UIRectEdge.None
        self.navigationController!.navigationBar.translucent = false
        
        self.inputToolbar?.contentView?.textView?.resignFirstResponder()
        
        self.collectionView?.emptyDataSetSource = self
        self.collectionView?.emptyDataSetDelegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        
        if let id = venueID {
            messageListener = MessageListener(venueID: id, startDate: NSDate(), callback: {
                message in
                self.messages.append(JSQMessage(senderId: message.senderID, senderDisplayName: message.senderName, date: message.date, text: message.message))
                self.finishReceivingMessage()
            })
        }
        
        self.automaticallyScrollsToMostRecentMessage = true
        self.scrollToBottomAnimated(true)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(true)
        messageListener?.stop()
        self.inputToolbar?.contentView?.textView?.resignFirstResponder()
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageData! {
        
        let data = self.messages[indexPath.row]
        return data
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageBubbleImageDataSource! {
        
        let data = self.messages[indexPath.row]
        if data.senderId == PFUser.currentUser()!.objectId {
            return outgoingBubble
        } else {
            return incomingBubble
        }
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAtIndexPath: indexPath) as! JSQMessagesCollectionViewCell
        
        let message = messages[indexPath.item]
        if message.senderId == PFUser.currentUser()!.objectId {
            cell.textView?.textColor = UIColor.whiteColor()
        } else {
            cell.textView?.textColor = UIColor.blackColor()
        }
        
        // The below two lines were originally for formatting of links within messages, I will have to consider how to handle links 
//        let attributes: [NSObject: AnyObject] = [NSForegroundColorAttributeName: cell.textView?.textColor, NSUnderlineStyleAttributeName: 1]
//        cell.textView?.linkTextAttributes = attributes
        
        return cell
    }
    
    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: NSDate!) {
        
        if let id = venueID {
            saveMessage(id, message: Message(message: text, senderID: senderId, senderName: senderDisplayName, date: date))
        }
        
        finishSendingMessage()
    }
    
    // View usernames above bubbles
    override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
        let message = messages[indexPath.item]
        
        // Sent by current user, skip
        if message.senderId == PFUser.currentUser()?.objectId {
            return nil
        }
        
        // Same as last sender, skip
        if indexPath.item > 0 {
            let previousMessage = messages[indexPath.item - 1]
            if previousMessage.senderId == message.senderId {
                return nil
            }
        }
        
        return NSAttributedString(string: message.senderDisplayName)
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        let message = messages[indexPath.item]
        // Sent by current user, skip
        if message.senderId == PFUser.currentUser()?.objectId {
            return CGFloat(0.0)
        }
        
        // Same as last sender, skip
        if indexPath.item > 0 {
            let previousMessage = messages[indexPath.item - 1]
            if previousMessage.senderId == message.senderId {
                return CGFloat(0.0)
            }
        }
        
        return kJSQMessagesCollectionViewCellLabelHeightDefault
    }
    
    
    // MARK: DZNEmptyDataSet
    
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let title = ":-x"
        let attributes = [NSFontAttributeName: UIFont.systemFontOfSize(50.0)]
        return NSAttributedString(string: title, attributes: attributes)
    }
    
    func descriptionForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let description = "It's quiet around here. \nGo check this place out and be first to join the chat!"
        let attributes = [NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleBody)]
        return NSAttributedString(string: description, attributes: attributes)
    }
}