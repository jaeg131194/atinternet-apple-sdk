//
//  EventOperation.swift
//  SmartTracker
//
//  Created by Théo Damaville on 05/11/2015.
//  Copyright © 2015 AT Internet. All rights reserved.
//

import UIKit
import Foundation

/// Class for sending screen event to socket server
class ScreenOperation: NSOperation {
    
    /// The screen event to be sent
    var screenEvent: ScreenEvent
    
    var timerDuration: NSTimeInterval = 0.2
    
    var timerTotalDuration: NSTimeInterval = 0
    
    /**
     ScreenOperation init
     
     - parameter screenEvent: ScreenEvent
     
     - returns: ScreenOperation
     */
    init(screenEvent: ScreenEvent) {
        self.screenEvent = screenEvent
    }
    
    /*func delay(delay:Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure)
    }*/
    
    func handleTimer(screen: Screen) {
        NSThread.sleepForTimeInterval(timerDuration)
        timerTotalDuration = timerTotalDuration + timerDuration
        
        if timerTotalDuration > 5 {
            screen.isReady = true
        }
    }

    /**
     function called when the operation runs
     */
    override func main() {
        autoreleasepool {
            let tracker = ATInternet.sharedInstance.defaultTracker
            
            //TODO: sendBuffer
            screenEvent.triggeredBy = UIApplicationContext.sharedInstance.previousEventSent
            
            // Wait a little in order to make this operation cancellable
            NSThread.sleepForTimeInterval(0.2)
            
            if self.cancelled {
                return
            }
            
            if(tracker.enableLiveTagging) {
                tracker.socketSender!.sendMessage(screenEvent.description)
            }
            if (tracker.enableAutoTracking) {
                sendScreenHit(tracker)
            }
        }
    }
    
    func sendScreenHit(tracker: AutoTracker) {
        let screen = tracker.screens.add(screenEvent.screen)
        mapConfiguration(screen)
        handleDelegate(screen)
        screen.sendView()
    }
    
    func mapConfiguration(screen: Screen) {
        waitForConfigurationLoaded()
        
        if let mapping = Configuration.smartSDKMapping {
            if let mappedName = mapping["configuration"]["screens"][screen.className]["title"].string {
                screen.name = mappedName
            }
        }
    }
    
    func waitForConfigurationLoaded() {
        while(!AutoTracker.isConfigurationLoaded) {
            NSThread.sleepForTimeInterval(0.2)
        }
    }
    
    func handleDelegate(screen: Screen) {
        if hasDelegate() {
            screenEvent.viewController!.performSelector(#selector(IAutoTracker.screenWasDetected(_:)), withObject: screen)
            if screen.isReady {
                return
            } else {
                while(!screen.isReady) {
                    handleTimer(screen)
                }
            }
        }
    }
    
    func hasDelegate() -> Bool {
        var hasDelegate = false
        if let viewController = screenEvent.viewController {
            if viewController.conformsToProtocol(IAutoTracker) {
                if viewController.respondsToSelector(#selector(IAutoTracker.screenWasDetected(_:))) {
                    hasDelegate = true
                }
            }
        }
        return hasDelegate
    }
    
}
