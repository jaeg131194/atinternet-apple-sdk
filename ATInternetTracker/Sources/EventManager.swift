//
//  EventManager.swift
//  SmartTracker
//
//  Created by Théo Damaville on 05/11/2015.
//  Copyright © 2015 AT Internet. All rights reserved.
//

import Foundation
import UIKit

/// Class for managing an NSOperationQueue
/// The Queue is a serial background queue that manage ScreenEvents and pass it to the Sender
class EventManager {
    /// Singleton
    static let sharedInstance = EventManager()
    
    /// delegate for test purpose (and more ?)
    //var delegate: EventHandler?

    /// Queue for managing events
    lazy private var _eventQueue:NSOperationQueue = NSOperationQueue()
    
    private init() {
        _eventQueue.maxConcurrentOperationCount = 1
        _eventQueue.name = "at_eventQueue"
        _eventQueue.qualityOfService = NSQualityOfService.Background
    }
    
    /**
     addEvent : add an event to the queue
     
     - parameter event: An event to be added to queue to be sent to socket server
     */
    func addEvent(event: NSOperation) {
        _eventQueue.addOperation(event)
    }
    
    /**
     lastEvent : Get the last event in queue
     */
    func lastEvent() -> NSOperation? {
        return _eventQueue.operations.last
    }
    
    /**
     lastScreenEvent : Get the last screen event in queue
     */
    func lastScreenEvent() -> NSOperation? {
        for op in _eventQueue.operations.reverse() {
            if op is ScreenOperation {
                return op
            }
        }
        
        return nil
    }
    
    /**
     lastGestureEvent : Get the last gesture event in queue
     */
    func lastGestureEvent() -> NSOperation? {
        for op in _eventQueue.operations.reverse() {
            if op is GestureOperation {
                return op
            }
        }
        
        return nil
    }
    
    /**
     Only the screen event must be removed
     */
    func cancelLastScreenEvent() {
        let op = _eventQueue.operations.last
        if op is ScreenOperation {
            op?.cancel()
        }
    }
    
    /**
     cancelLastEvent : cancel the last event in queue
     */
    func cancelLastEvent() {
        _eventQueue.operations.last?.cancel()
    }
    
    /**
     For tests pupose (for now)
     */
    func cancelAllEvents() {
        _eventQueue.cancelAllOperations()
    }
}
