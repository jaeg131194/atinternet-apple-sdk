//
//  RotationOperation.swift
//  SmartTracker
//
//  Created by Théo Damaville on 05/11/2015.
//  Copyright © 2015 AT Internet. All rights reserved.
//

import UIKit
import Foundation

/// Class for sending gesture event to the socket server
class DeviceRotationOperation: NSOperation {
    
    /// The screen event to be sent
    var rotationEvent: DeviceRotationEvent
    
    /// timer to handle the timeout
    var timerTotalDuration: NSTimeInterval = 0
    
    /// after timeout, the hit is sent
    let TIMEOUT_OPERATION: NSTimeInterval = 5
    
    var timerDuration: NSTimeInterval = 0.2
    
    /**
     RotationOperation init
     
     - parameter rotationEvent: rotationEvent
     
     - returns: RotationOperation
     */
    init(rotationEvent: DeviceRotationEvent) {
        self.rotationEvent = rotationEvent
    }
    
    override func main() {
        autoreleasepool {
            let tracker = ATInternet.sharedInstance.defaultTracker
            
            NSThread.sleepForTimeInterval(0.2)
            if self.cancelled {
                return
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
    func sendGestureHit(tracker: AutoTracker) {
        let gesture = tracker.gestures.add()
        gesture.name = rotationEvent.methodName
        
        gesture.screen = rotationEvent.currentScreen
        gesture.type = rotationEvent.eventType
        gesture.customObjects.add(["deviceOrientation":tracker.orientation!.rawValue, "interfaceOrientation":UIApplication.sharedApplication().statusBarOrientation.rawValue])
        
        handleDelegate(gesture)
        tracker.dispatcher.dispatch([gesture])
    }
    
    /**
     Manage the delegate interaction: send the gesture to the uiviewcontroller or wait for timeout
     
     - parameter gesture: the gesture
     */
    func handleDelegate(gesture: Gesture) {
        if hasDelegate() {
            self.rotationEvent.viewController!.performSelector(#selector(IAutoTracker.gestureWasDetected(_:)), withObject: gesture)
            
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
        
        if let viewController = self.rotationEvent.viewController {
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
}
