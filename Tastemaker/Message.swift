//
//  ChatMessage.swift
//  Tastemaker
//
//  Created by Tony Morales on 7/23/15.
//  Copyright (c) 2015 Tony Morales. All rights reserved.
//

import Foundation
import Firebase

struct ChatMessage {
    let message: String
    let senderID: String
    let senderName: String
    let date: NSDate
    let visitStatus: String
}

class MessageListener {
    var currentHandle: FIRDatabaseHandle?
    
    init (venueID: String, startDate: NSDate, callback: (ChatMessage) -> ()) {
        let handle = DataService.dataService.MESSAGES_REF.child(venueID).queryOrderedByChild("date").queryStartingAtValue(dateFormatter().stringFromDate(startDate)).observeEventType(FIRDataEventType.ChildAdded, withBlock: {
            snapshot in
            let message = snapshotToChatMessage(snapshot)
            callback(message)
        })
        self.currentHandle = handle
    }
    
    func stop(venueID: String) {
        if let handle = currentHandle {
            DataService.dataService.MESSAGES_REF.child(venueID).removeObserverWithHandle(handle)
            currentHandle = nil
        }
    }
}

func saveChatMessage(venueID: String, message: ChatMessage) {
    DataService.dataService.MESSAGES_REF.child(venueID).childByAutoId().updateChildValues(["date": dateFormatter().stringFromDate(message.date), "message": message.message, "sender": message.senderID, "senderName": message.senderName, "visitStatus": message.visitStatus])
}

private func snapshotToChatMessage(snapshot: FIRDataSnapshot) -> ChatMessage {
    let date = dateFormatter().dateFromString(snapshot.value!.objectForKey("date") as! String)
    let sender = snapshot.value!.objectForKey("sender") as? String
    let text = snapshot.value!.objectForKey("message") as? String
    let senderName = snapshot.value!.objectForKey("senderName") as? String
    let visitStatus = snapshot.value!.objectForKey("visitStatus") as? String
    return ChatMessage(message: text!, senderID: sender!, senderName: senderName!, date: date!, visitStatus: visitStatus!)
}

func fetchMessages(venueID: String, callback: ([ChatMessage]) -> ()) {
    DataService.dataService.MESSAGES_REF.child(venueID).queryOrderedByChild("date").queryLimitedToLast(15).observeSingleEventOfType(FIRDataEventType.Value, withBlock: {
        snapshot in
        
        var messages = Array<ChatMessage>()
        let enumerator = snapshot.children
        
        while let data = enumerator.nextObject() as? FIRDataSnapshot {
            messages.append(snapshotToChatMessage(data))
        }
        callback(messages)
    })
}

func fetchEarlierMessages(venueID: String, firstMessageTime: String, callback: ([ChatMessage]) -> ()) {
    DataService.dataService.MESSAGES_REF.child(venueID).queryOrderedByChild("date").queryEndingAtValue(firstMessageTime).queryLimitedToLast(13).observeSingleEventOfType(FIRDataEventType.Value, withBlock: {
        snapshot in
        
        var messages = Array<ChatMessage>()
        let enumerator = snapshot.children
        
        while let data = enumerator.nextObject() as? FIRDataSnapshot {
            messages.insert(snapshotToChatMessage(data), atIndex: 0)
        }
        messages.removeAtIndex(0)
        callback(messages)
    })
}