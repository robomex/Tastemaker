//
//  VenueChatViewController.swift
//  GrandOpens
//
//  Created by Tony Morales on 7/21/15.
//  Copyright (c) 2015 Tony Morales. All rights reserved.
//

import Foundation
import JSQMessagesViewController
import DZNEmptyDataSet
import SCLAlertView_Objective_C
import Firebase
import Amplitude_iOS

class VenueChatViewController: JSQMessagesViewController, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    var messages: [JSQMessage] = []
    var visitStatuses: [String] = []
    var venue: Venue?
    var messageListener: MessageListener?
    var avatars = Dictionary<String, JSQMessagesAvatarImage>()
    let uid: String = NSUserDefaults.standardUserDefaults().objectForKey("uid") as! String
    var mutedUsers = [String: String]()
    var mutedRefHandle = UInt()
    var visitRefHandle = UInt()
    
    var visitStatus = "noVisits"
    var currentMessageSendTime = NSDate()
    var lastMessageSendTime = NSDate()
    var secondToLastMessageSendTime = NSDate()
    
    // Used for grabbing avatars via containedIn PFQuery
    var userIdList = [String]()
    
    // Indexed with messages and used for pushing GOUserProfile
//    var users = Dictionary<String, PFUser>()
    
    let outgoingBubble = JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImageWithColor(kBlue)
    let outgoingVisitedBubble = JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImageWithColor(kPurple)
    let outgoingThereNowBubble = JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImageWithColor(kRed)
    let incomingBubble = JSQMessagesBubbleImageFactory().incomingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleLightGrayColor())
    let incomingVisitedBubble = JSQMessagesBubbleImageFactory().incomingMessagesBubbleImageWithColor(kPurple)
    let incomingThereNowBubble = JSQMessagesBubbleImageFactory().incomingMessagesBubbleImageWithColor(kRed)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.senderId = uid
        self.collectionView?.loadEarlierMessagesHeaderTextColor = UIColor.clearColor()
        self.showLoadEarlierMessagesHeader = true
        
        self.senderDisplayName = NSUserDefaults.standardUserDefaults().objectForKey("nickname") as! String

        self.inputToolbar?.contentView!.leftBarButtonItem = nil
        self.edgesForExtendedLayout = UIRectEdge.None
        self.navigationController!.navigationBar.translucent = false
        self.inputToolbar?.contentView?.textView?.resignFirstResponder()

        // Items for Report function
        JSQMessagesCollectionViewCell.registerMenuAction(Selector("reportMessage:"))
        UIMenuController.sharedMenuController().menuItems = [UIMenuItem.init(title: "Report", action: Selector("reportMessage:"))]
        
        self.collectionView?.emptyDataSetSource = self
        self.collectionView?.emptyDataSetDelegate = self
        

    }
    
    override func viewWillAppear(animated: Bool) {
        
        // BEFORE moving removeObservers to viewWillDisappear and setting 4x arrays/dicts (visitStatuses, userIdList, mutedUsers, messages) to nil in viewWillDisappear, previous problems were: Need to keep this in viewDidLoad to prevent the messages from loading multiple times, when moved to viewDidAppear and setting messages to empty, there was an 'array index out of range' error
        DataService.dataService.USER_ACTIVITIES_REF.childByAppendingPath("\(uid)/mutes").observeSingleEventOfType(FEventType.Value, withBlock: {
            snapshot in
            
            let enumerator = snapshot.children
            while let data = enumerator.nextObject() as? FDataSnapshot {
                self.mutedUsers[data.key] = "muted"
            }
            
            if let id = self.venue?.objectId {
                fetchMessages(id, callback: {
                    messages in
                    
                    for m in messages {
                        if self.mutedUsers[m.senderID] == nil {
                            self.messages.append(JSQMessage(senderId: m.senderID, senderDisplayName: m.senderName, date: m.date, text: m.message))
                            self.visitStatuses.append(m.visitStatus)
                            self.userIdList.append(m.senderID)
                        }
                    }
                    self.finishReceivingMessageAnimated(false)
                    self.userIdList = Array(Set(self.userIdList))
                    
                    if self.messages.count > 0 {
                        self.collectionView?.loadEarlierMessagesHeaderTextColor = kBlue
                    }
                })
            }
        })
        
        // BEFORE moving removeObservers to viewWillDisappear and setting 4x arrays/dicts (visitStatuses, userIdList, mutedUsers, messages) to nil in viewWillDisappear, previous problems were: putting this in viewWillAppear causes multiple messages on outgoing message, maybe since it's placed in a PageVC?
        if let id = venue?.objectId {
            messageListener = MessageListener(venueID: id, startDate: NSDate(), callback: {
                message in
                if self.mutedUsers[message.senderID] == nil {
                    self.messages.append(JSQMessage(senderId: message.senderID, senderDisplayName: message.senderName, date: message.date, text: message.message))
                    self.visitStatuses.append(message.visitStatus)
                    self.userIdList.append(message.senderID)
                }
                self.finishReceivingMessage()
                self.userIdList = Array(Set(self.userIdList))
            })
        }
        
        mutedRefHandle = DataService.dataService.USER_ACTIVITIES_REF.childByAppendingPath("\(uid)/mutes").observeEventType(FEventType.Value, withBlock: {
            snapshot in
            
            let enumerator = snapshot.children
            while let data = enumerator.nextObject() as? FDataSnapshot {
                self.mutedUsers[data.key] = "muted"
            }
        })
        
        visitRefHandle = DataService.dataService.USER_ACTIVITIES_REF.childByAppendingPath("\(uid)/visits/\(venue?.objectId!)").queryLimitedToLast(1).observeEventType(FEventType.Value, withBlock: {
            snapshot in

            if snapshot.exists() {
                self.visitStatus = "visited"

                let enumerator = snapshot.children
                while let data = enumerator.nextObject() as? FDataSnapshot {
                    if let date = dateFormatter().dateFromString(data.value["startedAt"] as! String) {
                        if date.timeIntervalSinceNow > (-3*60*60) {
                            self.visitStatus = "thereNow"
                        } else {
                            self.visitStatus = "visited"
                        }
                    }
                }
            } else {
                self.visitStatus = "noVisits"
            }
        })
        
        let tracker = GAI.sharedInstance().defaultTracker
        tracker.set(kGAIScreenName, value: "VenueChatViewController")
        let builder = GAIDictionaryBuilder.createScreenView()
        tracker.send(builder.build() as [NSObject: AnyObject])
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(true)
        self.inputToolbar?.contentView?.textView?.resignFirstResponder()
        
        messageListener?.stop((venue?.objectId)!)
        DataService.dataService.USER_ACTIVITIES_REF.childByAppendingPath("\(uid)/mutes").removeObserverWithHandle(mutedRefHandle)
        DataService.dataService.USER_ACTIVITIES_REF.childByAppendingPath("\(uid)/visits/\(venue?.objectId!)").removeObserverWithHandle(visitRefHandle)
        
        self.messages = []
        self.visitStatuses = []
        self.mutedUsers = [:]
        self.userIdList = []
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(true)

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
        let visitData = self.visitStatuses[indexPath.row]
        if data.senderId == uid {
            switch visitData {
                case "thereNow": return outgoingThereNowBubble
                case "visited": return outgoingVisitedBubble
                default: return outgoingBubble
            }
        } else {
            switch visitData {
                case "thereNow": return incomingThereNowBubble
                case "visited": return incomingVisitedBubble
                default: return incomingBubble
            }
        }
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAtIndexPath: indexPath) as! JSQMessagesCollectionViewCell
        
        let message = messages[indexPath.item]
        let visitData = self.visitStatuses[indexPath.row]
        if message.senderId != uid && visitData == "noVisits" {
            cell.textView?.textColor = UIColor.blackColor()
        } else {
            cell.textView?.textColor = UIColor.whiteColor()
        }
        
        // The below two lines were originally for formatting of links within messages, I will have to consider how to handle links 
//        let attributes: [NSObject: AnyObject] = [NSForegroundColorAttributeName: cell.textView?.textColor, NSUnderlineStyleAttributeName: 1]
//        cell.textView?.linkTextAttributes = attributes
        
        return cell
    }
    
    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: NSDate!) {
        
        self.secondToLastMessageSendTime = self.lastMessageSendTime
        self.lastMessageSendTime = self.currentMessageSendTime
        self.currentMessageSendTime = NSDate()
        if self.secondToLastMessageSendTime.timeIntervalSinceNow > -5 {
            showThrottleAlert()
            return
        }
        
        let messageVisitStatus = visitStatus
        let chatMessage = ChatMessage(message: text, senderID: senderId, senderName: senderDisplayName, date: date, visitStatus: messageVisitStatus)
        if let id = venue?.objectId {
            saveChatMessage(id, message: chatMessage)
        }
        
        Amplitude.instance().logEvent("Chat", withEventProperties: ["Venue Name": venue!.name!, "Venue Neighborhood": venue!.neighborhood!, "Venue Food Type": venue!.foodType!])
        Amplitude.instance().identify(AMPIdentify().add("Chats", value: 1))
        
        finishSendingMessage()
    }
    
    // MARK: View nicknames above bubbles
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
        let message = messages[indexPath.item]
        
        // Sent by current user, skip
        if message.senderId == uid {
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
        if message.senderId == uid {
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

    // MARK: Timestamps
    
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
    
    // MARK: Avatars
    
    func setupAvatarImage(id: String, name: String, incoming: Bool) {
        
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
//            let query = PFUser.query()
//            query?.whereKey("objectId", containedIn: userIdList)
//            query?.selectKeys([kUserDisplayNameKey, kUserProfilePicKey, kUserProfilePicSmallKey])
//            query?.findObjectsInBackgroundWithBlock { (objects, error) -> Void in
//                if error == nil {
//                    for object in objects! {
//                        if let thumbnail = object[kUserProfilePicSmallKey] as? PFFile {
//                            thumbnail.getDataInBackgroundWithBlock({ (imageData: NSData?, error: NSError?) -> Void in
//                                if (error == nil) && message.senderId == object.objectId {
//                                    self.avatars[message.senderId] = JSQMessagesAvatarImageFactory.avatarImageWithImage(UIImage(data: imageData!), diameter: 30)
//                                    self.collectionView?.reloadData()
//                                }
//                            })
//                        }
//                        if message.senderId == object.objectId {
//                            self.users[message.senderId] = object as? PFUser
//                        }
//                    }
//                }
//            }
            self.setupAvatarImage(message.senderId, name: message.senderDisplayName, incoming: true)
            return avatars[message.senderId]
        } else {
            return avatars[message.senderId]
        }
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, didTapAvatarImageView avatarImageView: UIImageView!, atIndexPath indexPath: NSIndexPath!) {
        let message = self.messages[indexPath.item]
        let vc = GOUserProfileViewController(style: UITableViewStyle.Plain)
        vc.userId = message.senderId
        vc.userNickname = message.senderDisplayName
        navigationController?.pushViewController(vc, animated: true)
    }
    
    
    // MARK: Report button
    
    override func collectionView(collectionView: UICollectionView, shouldShowMenuForItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        
        return super.collectionView(collectionView, shouldShowMenuForItemAtIndexPath: indexPath)
    }
    
    override func collectionView(collectionView: UICollectionView, canPerformAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
        
        let message = self.messages[indexPath.row]
        if action == Selector("reportMessage:") && message.senderId == self.uid {
            return false
        } else if action == Selector("reportMessage:") {
            return true
        }
        
        return super.collectionView(collectionView, canPerformAction: action, forItemAtIndexPath: indexPath, withSender: sender)
    }
    
    override func collectionView(collectionView: UICollectionView, performAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {
        
        if action == Selector("reportMessage:") {
            
            let message = messages[indexPath.row]
            DataService.dataService.USER_ACTIVITIES_REF.childByAppendingPath("\(uid)/reports").childByAutoId().updateChildValues(["date": dateFormatter().stringFromDate(NSDate()), "reportedMessage": message.text, "reportedUser": message.senderId, "reportedNickname": message.senderDisplayName])
            
            Amplitude.instance().logEvent("Reported Message", withEventProperties: ["Reported User ID": message.senderId, "Reported User Nickname": message.senderDisplayName, "Reported Message": message.text])
            Amplitude.instance().identify(AMPIdentify().add("Reports", value: 1).append("Reported-UserIDs", value: (message.senderId)))
        }
        
        super.collectionView(collectionView, performAction: action, forItemAtIndexPath: indexPath, withSender: sender)
    }
    
    
    // MARK: Load earlier header
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, header headerView: JSQMessagesLoadEarlierHeaderView!, didTapLoadEarlierMessagesButton sender: UIButton!) {
        
        if self.messages.count == 0 {
            return
        }
        
        let firstMessageTime = dateFormatter().stringFromDate(messages[0].date)
        let oldBottomOffset = (self.collectionView?.contentSize.height)! - (self.collectionView?.contentOffset.y)!
        
        fetchEarlierMessages((venue?.objectId)!, firstMessageTime: firstMessageTime, callback: {
            messages in
            
            for m in messages {
                if self.mutedUsers[m.senderID] == nil { //!GOCache.sharedCache.isUserMutedByCurrentUser(m.senderID) {
                    self.messages.insert(JSQMessage(senderId: m.senderID, senderDisplayName: m.senderName, date: m.date, text: m.message), atIndex: 0)
                    self.visitStatuses.insert(m.visitStatus, atIndex: 0)
                    self.userIdList.append(m.senderID)
                }
            }
            self.userIdList = Array(Set(self.userIdList))
            self.finishReceivingMessageAnimated(false)
            self.collectionView?.layoutIfNeeded()
            
            if dateFormatter().stringFromDate(self.messages[0].date) == firstMessageTime {
                self.collectionView?.loadEarlierMessagesHeaderTextColor = UIColor.clearColor()
            } else if messages.count < 12 {
                self.collectionView?.contentOffset = CGPointMake(0, (self.collectionView?.contentSize.height)! - oldBottomOffset - kJSQMessagesCollectionViewCellLabelHeightDefault)
                return
            }
            
            self.collectionView?.contentOffset = CGPointMake(0, (self.collectionView?.contentSize.height)! - oldBottomOffset)
        })
    }
    
    
    // MARK:-
    
    func showThrottleAlert() {
        let messageThrottleAlert = SCLAlertView()
        // Adding a timer is causing SCLAlertView console printouts "unknown action type for button"
//        messageThrottleAlert.addTimerToButtonIndex(0, reverse: true)
        messageThrottleAlert.showAnimationType = .SlideInToCenter
        messageThrottleAlert.hideAnimationType = .FadeOut
        messageThrottleAlert.customViewColor = kPurple
        messageThrottleAlert.backgroundType = .Blur
        messageThrottleAlert.shouldDismissOnTapOutside = true
        messageThrottleAlert.showInfo(self.view.window?.rootViewController, title: "Whoa there", subTitle: "There's no rush, please wait a moment before sending a new message", closeButtonTitle: "Dismiss", duration: 5.0)
    }
    
    
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