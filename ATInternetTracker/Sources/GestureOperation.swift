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
    /// The screen event to be sent
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
    
    func sendGesture(gesture: Gesture) {
        timerTotalDuration = timerTotalDuration + timerDuration
        
        if timerTotalDuration > 5 || gesture.isReady {
            gesture.isReady = true
            ATInternet.sharedInstance.defaultTracker.dispatcher.dispatch([gesture])
        }
    }
    
    /**
     Function that is called when the operation runs
     */
    override func main() {
        autoreleasepool {
            
            let tracker = ATInternet.sharedInstance.defaultTracker
            
            var hasDelegate = false
            
            if let viewController = gestureEvent.viewController {
                if viewController.conformsToProtocol(IAutoTracker) {
                    if viewController.respondsToSelector(#selector(IAutoTracker.gestureWasDetected(_:))) {
                        hasDelegate = true
                    }
                }
            }
            
            if(tracker.enableLiveTagging) {
                NSThread.sleepForTimeInterval(0.2)
                
                if !self.cancelled {
                    UIApplicationContext.sharedInstance.previousEventSent = gestureEvent
                    ATInternet.sharedInstance.defaultTracker.socketSender!.sendMessage(gestureEvent.description)
                    
                }
            } else {
                // We pause thread in order to be able to cancel it
                NSThread.sleepForTimeInterval(0.2)
                
                if !self.cancelled {
                    
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
                    
                    if hasDelegate {
                        gestureEvent.viewController!.performSelector(#selector(IAutoTracker.gestureWasDetected(_:)), withObject: gesture)
                        
                        if gesture.isReady {
                            tracker.dispatcher.dispatch([gesture])
                        } else {
                            while(!gesture.isReady) {
                                NSThread.sleepForTimeInterval(timerDuration)
                                
                                sendGesture(gesture)
                            }
                        }
                    } else {
                        // User didn't implement delegate, no other data will be appended to screen, we send it
                        tracker.dispatcher.dispatch([gesture])
                    }
                }
            }
        }
    }
}
