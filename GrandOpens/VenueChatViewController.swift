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

class VenueChatViewController: JSQMessagesViewController {
    
    var messages: [JSQMessage] = []
    
    var venueID: String?
    
    var messageListener: MessageListener?
    
    let outgoingBubble = JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImageWithColor(UIColor(red: 34.0/255.0, green: 167.0/255.0, blue: 240.0/255.0, alpha: 1.0))
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
                    self.messages.append(JSQMessage(senderId: m.senderID, senderDisplayName: m.senderID, date: m.date, text: m.message))
                }
                self.finishReceivingMessage()
            })
        }
        
        self.senderId = currentUser()!.id
        self.senderDisplayName = currentUser()!.name
        
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()

        automaticallyScrollsToMostRecentMessage = true
                
//        self.inputToolbar.loadToolbarContentView()
//        self.inputToolbar.contentView.rightBarButtonItem = JSQMessagesToolbarButtonFactory.defaultSendButtonItem()
    }
    
    override func viewWillAppear(animated: Bool) {
        
        if let id = venueID {
            messageListener = MessageListener(venueID: id, startDate: NSDate(), callback: {
                message in
                self.messages.append(JSQMessage(senderId: message.senderID, senderDisplayName: message.senderID, date: message.date, text: message.message))
                self.finishReceivingMessage()
            })
        }
        
    }
    
    override func viewDidAppear(animated: Bool) {
//        collectionView?.collectionViewLayout.springinessEnabled = true
//        self.inputToolbar.contentView.textView.becomeFirstResponder()
    }
    
    override func viewWillDisappear(animated: Bool) {
        
        messageListener?.stop()
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
        
        return cell
    }
    
    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: NSDate!) {
        let m = JSQMessage(senderId: senderId, senderDisplayName: senderDisplayName, date: date, text: text)
        self.messages.append(m)
        
        if let id = venueID {
            saveMessage(id, message: Message(message: text, senderID: senderId, date: date))
        }
        
        finishSendingMessage()
    }
}