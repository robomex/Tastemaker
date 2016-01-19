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
//    var userIDs = [String]()
    var avatars = Dictionary<String, JSQMessagesAvatarImage>()
    let outgoingBubble = JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImageWithColor(kBlue)
    let incomingBubble = JSQMessagesBubbleImageFactory().incomingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleLightGrayColor())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
//        collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSizeZero
//        collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero
        
        if let id = venueID {
            fetchMessages(id, callback: {
                messages in
                
                for m in messages {
                    self.messages.append(JSQMessage(senderId: m.senderID, senderDisplayName: m.senderName, date: m.date, text: m.message))
//                    self.userIDs.append(m.senderID)
                }
                self.finishReceivingMessage()
            })
        }
        
        self.senderId = currentUser()!.id
            
        if PFUser.currentUser()?.objectForKey(kUserDisplayNameKey) as? String == "" {
            self.senderDisplayName = "A No-Name Person"
        } else {
            self.senderDisplayName = PFUser.currentUser()?.objectForKey(kUserDisplayNameKey) as? String
        }

        self.inputToolbar?.contentView!.leftBarButtonItem = nil
        self.edgesForExtendedLayout = UIRectEdge.None
        self.navigationController!.navigationBar.translucent = false
        self.inputToolbar?.contentView?.textView?.resignFirstResponder()

        self.collectionView?.emptyDataSetSource = self
        self.collectionView?.emptyDataSetDelegate = self
        
        if let id = venueID {
            messageListener = MessageListener(venueID: id, startDate: NSDate(), callback: {
                message in
                self.messages.append(JSQMessage(senderId: message.senderID, senderDisplayName: message.senderName, date: message.date, text: message.message))
//                let user: PFUser = PFQuery.getUserObjectWithId(message.senderID)!
//                self.userIDs.append(message.senderID)
                self.finishReceivingMessage()
            })
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        
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
            saveChatMessage(id, message: ChatMessage(message: text, senderID: senderId, senderName: senderDisplayName, date: date))
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

    // Timestamps
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForCellTopLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
        if indexPath.item % 3 == 0 {
            let message = self.messages[indexPath.item]
            return JSQMessagesTimestampFormatter.sharedFormatter().attributedTimestampForDate(message.date)
        }
        return nil
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellTopLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        if indexPath.item % 3 == 0 {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        }
        return 0
    }
    
    // Avatars
    
    func setupAvatarImage(id: String, name: String,
        //imageURL: String?, 
        incoming: Bool) {
        
//        if let PFObject.
//        if let stringURL = imageURL {
//            if let url = NSURL(string: stringURL) {
//                if let data = NSData(contentsOfURL: url) {
//                    let image = UIImage(data: data)
//                    let diameter = incoming ? UInt((collectionView?.collectionViewLayout.incomingAvatarViewSize.width)!) : UInt((collectionView?.collectionViewLayout.outgoingAvatarViewSize.width)!)
//                    let avatarImage = JSQMessagesAvatarImageFactory.avatarImageWithImage(image, diameter: diameter)
//                    avatars[name] = avatarImage
//                    return
//                }
//            }
//        }
//        if let user = PFQuery.getUserObjectWithId(name) {
//            if let avatar = user.objectForKey("picture") {
//                avatar.getDataInBackgroundWithBlock({ (data, error) -> Void in
//                    if let data = data where error == nil {
//                        let image = UIImage(data: data)
//                        let diameter = incoming ? UInt((self.collectionView?.collectionViewLayout.incomingAvatarViewSize.width)!) : UInt((self.collectionView?.collectionViewLayout.outgoingAvatarViewSize.width)!)
//                        let avatarImage = JSQMessagesAvatarImageFactory.avatarImageWithImage(image, diameter: diameter)
//                        self.avatars[name] = avatarImage
//                        return
//                    }
//                    
//                    // If at some point we failed to get the image (e.g. broken URL), default to avatarColor
//                    self.setupAvatarColor(name, incoming: incoming)
//                })
//            }
//        }
//        let user = PFQuery.getUserObjectWithId(name)
//        pfUserToUser(user!).getPhoto({
//            image in
//            let image = image
//            let diameter = incoming ? UInt((self.collectionView?.collectionViewLayout.incomingAvatarViewSize.width)!) : UInt((self.collectionView?.collectionViewLayout.outgoingAvatarViewSize.width)!)
//            let avatarImage = JSQMessagesAvatarImageFactory.avatarImageWithImage(image, diameter: diameter)
//            self.avatars[name] = avatarImage
//            return
//        })
            
        // If at some point we failed to get the image (e.g. broken URL), default to avatarColor
        self.setupAvatarColor(id, name: name, incoming: incoming)
    }
    
    func setupAvatarColor(id: String, var name: String, incoming: Bool) {
        let diameter = incoming ? UInt((collectionView?.collectionViewLayout.incomingAvatarViewSize.width)!) : UInt((collectionView?.collectionViewLayout.outgoingAvatarViewSize.width)!)
        
        let rgbValue = id.hash
        let r = CGFloat(Float((rgbValue & 0xFF0000) >> 16)/255.0)
        let g = CGFloat(Float((rgbValue & 0xFF00) >> 8)/255.0)
        let b = CGFloat(Float(rgbValue & 0xFF)/255.0)
        let color = UIColor(red: r, green: g, blue: b, alpha: 0.5)
        
        if name == "" {
            name = "?"
        }
        
        let initials: String? = name.substringToIndex(name.startIndex.advancedBy(1))
        let userImage = JSQMessagesAvatarImageFactory.avatarImageWithUserInitials(initials, backgroundColor: color, textColor: UIColor.whiteColor(), font: UIFont.systemFontOfSize(13), diameter: diameter)
        
        avatars[id] = userImage
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageAvatarImageDataSource! {
        let message = self.messages[indexPath.item]
        if avatars[message.senderId] == nil {
            let query = PFUser.query()
            query?.whereKey("objectId", equalTo: message.senderId)
            query?.selectKeys(["picture"])
            query?.findObjectsInBackgroundWithBlock { (objects: [AnyObject]?, error: NSError?) -> Void in
                if error == nil {
                    for object in objects! {
                        if let thumbnail = object["picture"] as? PFFile {
                            thumbnail.getDataInBackgroundWithBlock({ (imageData: NSData?, error: NSError?) -> Void in
                                if (error == nil) {
                                    self.avatars[message.senderId] = JSQMessagesAvatarImageFactory.avatarImageWithImage(UIImage(data: imageData!), diameter: 30)
                                    self.collectionView?.reloadData()
                                }
                            })
                        }
                    }
                }
            }
            self.setupAvatarImage(message.senderId, name: message.senderDisplayName, incoming: true)
            return avatars[message.senderId]
        } else {
            return avatars[message.senderId]
        }
    }

//    override func collectionView(collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageAvatarImageDataSource! {
//        let message = self.messages[indexPath.item]
//        if avatars[message.senderId] == nil {
//            if let user = PFQuery.getUserObjectWithId(message.senderId) {
//                if let avatar = user.objectForKey("picture") {
//                    avatar.getDataInBackgroundWithBlock({ (imageData: NSData?, error: NSError?) -> Void in
//                        if error == nil {
//                            self.avatars[message.senderId] = JSQMessagesAvatarImageFactory.avatarImageWithImage(UIImage(data: imageData!), diameter: 30)
//                            self.collectionView?.reloadData()
//                        }
//                    })
//                }
//            }
//            self.setupAvatarImage(message.senderId, name: message.senderDisplayName, incoming: true)
//            return avatars[message.senderId]
//        } else {
//            return avatars[message.senderId]
//        }
//    }
    
//        let message = self.messages[indexPath.item]
//        let user = self.users[indexPath.item]
//        if avatars[message.senderId] == nil {
//            let thumbnailFile = user["picture"] as? PFFile
//            thumbnailFile?.getDataInBackgroundWithBlock({ (imageData: NSData?, error: NSError?) -> Void in
//                if error == nil {
//                    self.avatars[message.senderId] = JSQMessagesAvatarImageFactory.avatarImageWithImage(UIImage(data: imageData!), diameter: 30)
//                    self.collectionView?.reloadData()
//                } //else {
////                    self.setupAvatarImage(message.senderId, name: message.senderDisplayName,
////                        //imageURL: message.imageURL(),
////                        incoming: true)
////                }
//            
//            })
//            self.setupAvatarImage(message.senderId, name: message.senderDisplayName,
//                //imageURL: message.imageURL(),
//                incoming: true)
//            return avatars[message.senderId]
//        } else {
//            return avatars[message.senderId]
//        }
//    }
    
    
    // MARK: DZNEmptyDataSet
    
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let title = ":-x"
        let attributes = [NSFontAttributeName: UIFont.systemFontOfSize(50.0)]
        return NSAttributedString(string: title, attributes: attributes)
    }
    
    func descriptionForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let description = "It's quiet around here. \nGo check this place out \nand be first to join the chat!"
        let attributes = [NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleBody)]
        return NSAttributedString(string: description, attributes: attributes)
    }
}