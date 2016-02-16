//
//  ChatMessage.swift
//  GrandOpens
//
//  Created by Tony Morales on 7/23/15.
//  Copyright (c) 2015 Tony Morales. All rights reserved.
//

import Foundation
import Parse
import Firebase

struct ChatMessage {
    let message: String
    let senderID: String
    let senderName: String
    let date: NSDate
    let visitStatus: String
}

class MessageListener {
    var currentHandle: UInt?
    
    init (venueID: String, startDate: NSDate, callback: (ChatMessage) -> ()) {
        let handle = ref.childByAppendingPath(venueID).queryOrderedByChild("date").queryStartingAtValue(dateFormatter().stringFromDate(startDate)).observeEventType(FEventType.ChildAdded, withBlock: {
            snapshot in
            let message = snapshotToChatMessage(snapshot)
            callback(message)
        })
        self.currentHandle = handle
    }
    func stop() {
        if let handle = currentHandle {
            ref.removeObserverWithHandle(handle)
            currentHandle = nil
        }
    }
}

private let ref = Firebase(url: "https://grandopens.firebaseio.com/messages")
//private let dateFormat = "yyyyMMddHHmmss"
//
//private func dateFormatter() -> NSDateFormatter {
//    let dateFormatter = NSDateFormatter()
//    dateFormatter.dateFormat = dateFormat
//    return dateFormatter
//}

func saveChatMessage(venueID: String, message: ChatMessage) {
    ref.childByAppendingPath(venueID).childByAutoId().updateChildValues(["date": dateFormatter().stringFromDate(message.date), "message": message.message, "sender": message.senderID, "senderName": message.senderName, "visitStatus": message.visitStatus])
}

private func snapshotToChatMessage(snapshot: FDataSnapshot) -> ChatMessage {
    let date = dateFormatter().dateFromString(snapshot.value["date"] as! String)
    let sender = snapshot.value["sender"] as? String
    let text = snapshot.value["message"] as? String
    let senderName = snapshot.value["senderName"] as? String
    let visitStatus = snapshot.value["visitStatus"] as? String
    return ChatMessage(message: text!, senderID: sender!, senderName: senderName!, date: date!, visitStatus: visitStatus!)
}

func fetchMessages(venueID: String, callback: ([ChatMessage]) -> ()) {
    ref.childByAppendingPath(venueID).queryOrderedByChild("date").queryLimitedToLast(15).observeSingleEventOfType(FEventType.Value, withBlock: {
        snapshot in
        
        var messages = Array<ChatMessage>()
        let enumerator = snapshot.children
        
        while let data = enumerator.nextObject() as? FDataSnapshot {
            messages.append(snapshotToChatMessage(data))
        }
        callback(messages)
    })
}

func fetchEarlierMessages(venueID: String, firstMessageTime: String, callback: ([ChatMessage]) -> ()) {
    ref.childByAppendingPath(venueID).queryOrderedByChild("date").queryEndingAtValue(firstMessageTime).queryLimitedToLast(13).observeSingleEventOfType(FEventType.Value, withBlock: {
        snapshot in
        
        var messages = Array<ChatMessage>()
        let enumerator = snapshot.children
        
        while let data = enumerator.nextObject() as? FDataSnapshot {
            messages.insert(snapshotToChatMessage(data), atIndex: 0)
        }
        messages.removeAtIndex(0)
        callback(messages)
    })
}