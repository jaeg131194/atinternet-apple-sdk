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
    
    func delay(delay:Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure)
    }
    
    func sendScreen(screen: Screen) {
        timerTotalDuration = timerTotalDuration + timerDuration
        
        if timerTotalDuration > 5 || screen.isReady {
            screen.isReady = true
            screen.sendView()
        }
    }
    
    /**
     function called when the operation runs
     */
    override func main() {
        autoreleasepool {
            
            let tracker = ATInternet.sharedInstance.defaultTracker
            
            var hasDelegate = false
            
            if let viewController = screenEvent.viewController {
                if viewController.conformsToProtocol(IAutoTracker) {
                    if viewController.respondsToSelector(#selector(IAutoTracker.screenWasDetected(_:))) {
                        hasDelegate = true
                    }
                }
            }
            
            //TODO: sendBuffer
            screenEvent.triggeredBy = UIApplicationContext.sharedInstance.previousEventSent
            
            if(tracker.enableLiveTagging) {
                // Wait a little in order to make this operation cancellable
                NSThread.sleepForTimeInterval(0.2)
                if !self.cancelled {
                    ATInternet.sharedInstance.defaultTracker.socketSender!.sendMessage(screenEvent.description)
                }
            } else {
                NSThread.sleepForTimeInterval(0.2)
                if !self.cancelled {
                    
                    let screen = tracker.screens.add(screenEvent.screen)
                    
                    if  hasDelegate {
                        screenEvent.viewController!.performSelector(#selector(IAutoTracker.screenWasDetected(_:)), withObject: screen)

                        if screen.isReady {
                            screen.sendView()
                        } else {
                            while(!screen.isReady) {
                                NSThread.sleepForTimeInterval(timerDuration)
                                
                                sendScreen(screen)
                            }
                        }
                    } else {
                        // User didn't implement delegate, no other data will be appended to screen, we send it
                        screen.sendView()
                    }
                }
            }
        }
    }
}