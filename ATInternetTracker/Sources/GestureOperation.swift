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
    
    /// refresh the timer tick
    var timerDuration: NSTimeInterval = 0.2
    
    /// timer to handle the timeout
    var timerTotalDuration: NSTimeInterval = 0
    
    /// after timeout, the hit is sent
    let TIMEOUT_OPERATION: NSTimeInterval = 5
    
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
    
    /**
     Send a Gesture Hit
     
     - parameter tracker: AutoTracker
     */
    func sendGestureHit(tracker: AutoTracker) -> Bool {
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
        
        let shouldSendHit = mapConfiguration(gesture)
        if shouldSendHit {
            handleDelegate(gesture)
            tracker.dispatcher.dispatch([gesture])
        }
        return shouldSendHit
    }
    
    /**
     Manage the delegate interaction: send the gesture to the uiviewcontroller or wait for timeout
     
     - parameter gesture: the gesture
     */
    func handleDelegate(gesture: Gesture) {
        if hasDelegate() {
            self.gestureEvent.viewController!.performSelector(#selector(IAutoTracker.gestureWasDetected(_:)), withObject: gesture)
            
            if gesture.isReady {
                return
            }
            while(!gesture.isReady) {
                handleTimer(gesture)
            }
        }
    }
    
    /**
     Check if the current viewcontroller has implemented the AutoTracker delegate
     
     - returns: true if delegate implemented
     */
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
    
    /**
     Wait until the gesture is ready to be sent or TIMEOUT
     
     - parameter gesture: the gesture to be sent
     */
    func handleTimer(gesture: Gesture) {
        NSThread.sleepForTimeInterval(timerDuration)
        timerTotalDuration = timerTotalDuration + timerDuration
        if timerTotalDuration > TIMEOUT_OPERATION {
            gesture.isReady = true
        }
    }
    
    /**
     Map the gesture attributes if a LiveTagging configuration is given
     
     - parameter gesture: the gesture to map
     */
    func mapConfiguration(gesture: Gesture) -> Bool {
        waitForConfigurationLoaded()
        
        if let mapping = Configuration.smartSDKMapping {
            if gestureEvent.methodName == nil {
                gestureEvent.methodName = gestureEvent.defaultMethodName
            }
            assert(gestureEvent.methodName != nil)
            
            let eventKeyBase = Gesture.getEventTypeRawValue(gestureEvent.eventType.rawValue)+"."+gestureEvent.direction+"."+gestureEvent.methodName!
            let position = gesture.view != nil ? "."+String(gesture.view!.position) : ""
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
                if let shouldIgnore = mapping["configuration"]["events"][aKey]["ignoreElement"].bool {
                    if shouldIgnore {
                        return false
                    }
                }
                if let mappedName = mapping["configuration"]["events"][aKey]["title"].string {
                    gesture.name = mappedName
                    break
                }
            }
        }
        return true
    }
    
    /**
     Wait for the configuration
     */
    func waitForConfigurationLoaded() {
        while(!AutoTracker.isConfigurationLoaded) {
            NSThread.sleepForTimeInterval(0.2)
        }
    }
}
