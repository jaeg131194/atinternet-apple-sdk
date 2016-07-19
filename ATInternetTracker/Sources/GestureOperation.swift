//
//  EventOperation.swift
//  SmartTracker
//
//  Created by Théo Damaville on 05/11/2015.
//  Copyright © 2015 AT Internet. All rights reserved.
//

import UIKit
import Foundation

/// Class for sending gesture event to the socket server
class GestureOperation: NSOperation {
    
    var gestureEvent: GestureEvent
    
    var timerDuration: NSTimeInterval = 0.2
    
    var timerTotalDuration: NSTimeInterval = 0
    
    /**
     GestureOperation init
     
     - parameter gestureEvent: gestureEvent
     
     - returns: GestureOperation
     */
    init(gestureEvent: GestureEvent) {
        self.gestureEvent = gestureEvent
    }
    
    /**
     Function that is called when the operation runs
     */
    override func main() {
        autoreleasepool {
            
            let tracker = ATInternet.sharedInstance.defaultTracker
            
            NSThread.sleepForTimeInterval(0.2)
            if self.cancelled {
                return
            }
            
            if tracker.enableLiveTagging {
                UIApplicationContext.sharedInstance.previousEventSent = gestureEvent
                ATInternet.sharedInstance.defaultTracker.socketSender!.sendMessage(gestureEvent.description)
            }
            
            if tracker.enableAutoTracking {
                sendGestureHit(tracker)
            }
        }
    }
    
    
    
    func sendGestureHit(tracker: AutoTracker) {
        let gesture = tracker.gestures.add()
        if let method = gestureEvent.methodName {
            gesture.name = method
            
            if method == "handleBack:" {
                gesture.action = .Navigate
            }
        }
        
        gesture.screen = gestureEvent.currentScreen
        gesture.type = gestureEvent.eventType
        gesture.view = gestureEvent.view
        
        // We pause thread in order to wait if next operation is a screen. If a screen operation is added after gesture operation, then it's a navigation event
        NSThread.sleepForTimeInterval(0.5)
        
        if let _ = EventManager.sharedInstance.lastScreenEvent() as? ScreenOperation  {
            gesture.action = .Navigate
        }
        
        mapConfiguration(gesture)
        handleDelegate(gesture)
        tracker.dispatcher.dispatch([gesture])
    }
    
    func handleDelegate(gesture: Gesture) {
        if hasDelegate() {
            gestureEvent.viewController!.performSelector(#selector(IAutoTracker.gestureWasDetected(_:)), withObject: gesture)
            
            if gesture.isReady {
                return
            }
            while(!gesture.isReady) {
                handleTimer(gesture)
            }
        }
    }
    
    func hasDelegate() -> Bool {
        var hasDelegate = false
        
        if let viewController = gestureEvent.viewController {
            if viewController.conformsToProtocol(IAutoTracker) {
                if viewController.respondsToSelector(#selector(IAutoTracker.gestureWasDetected(_:))) {
                    hasDelegate = true
                }
            }
        }
        return hasDelegate
    }
    
    func handleTimer(gesture: Gesture) {
        NSThread.sleepForTimeInterval(timerDuration)
        timerTotalDuration = timerTotalDuration + timerDuration
        if timerTotalDuration > 5 {
            gesture.isReady = true
        }
    }
    
    func mapConfiguration(gesture: Gesture) {
        waitForConfigurationLoaded()
        
        if let mapping = Configuration.smartSDKMapping {
            if gestureEvent.methodName == nil {
                gestureEvent.methodName = gestureEvent.defaultMethodName
            }
            assert(gestureEvent.methodName != nil)
            
            let eventKeyBase = Gesture.getEventTypeRawValue(gestureEvent.eventType.rawValue)+"."+gestureEvent.direction+"."+gestureEvent.methodName!
            let position = gesture.view != nil ? "."+String(gesture.view?.position) : ""
            let view = gesture.view != nil ? "."+gesture.view!.className : ""
            let screen = gesture.screen != nil ? "."+gesture.screen!.className : ""
            
            /* 9 strings generated */
            let one = eventKeyBase+position+view+screen
            let two = eventKeyBase+position+view
            let tree = eventKeyBase+position
            let four = eventKeyBase+position+screen
            let five = eventKeyBase
            let six = eventKeyBase+view
            let seven = eventKeyBase+screen
            let height = eventKeyBase+view+screen
            let events = [one, two, tree, four, five, six, seven, height]
            
            for aKey in events {
                if let mappedName = mapping["configuration"]["events"][aKey]["title"].string {
                    gesture.name = mappedName
                    break
                }
            }
        }
    }
    
    func waitForConfigurationLoaded() {
        while(!AutoTracker.isConfigurationLoaded) {
            NSThread.sleepForTimeInterval(0.2)
        }
    }
}
