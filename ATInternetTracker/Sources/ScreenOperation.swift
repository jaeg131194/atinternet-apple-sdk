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
class ScreenOperation: Operation {
    
    /// The screen event to be sent
    var screenEvent: ScreenEvent
    
    var timerDuration: TimeInterval = 0.2
    
    /// Timer to handle the timeout
    var timerTotalDuration: TimeInterval = 0
    
    /// after timeout, the hit is sent
    let TIMEOUT_OPERATION: TimeInterval = 5
    
    /**
     ScreenOperation init
     
     - parameter screenEvent: ScreenEvent
     
     - returns: ScreenOperation
     */
    init(screenEvent: ScreenEvent) {
        self.screenEvent = screenEvent
    }
    
    func handleTimer(_ screen: Screen) {
        Thread.sleep(forTimeInterval: timerDuration)
        timerTotalDuration = timerTotalDuration + timerDuration
        
        if timerTotalDuration > TIMEOUT_OPERATION {
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
            Thread.sleep(forTimeInterval: 0.2)
            
            if self.isCancelled {
                return
            }
            
            if(tracker.enableLiveTagging) {
                tracker.socketSender!.sendMessage(screenEvent.description)
            }
            
            if (tracker.enableAutoTracking) {
                if !sendScreenHit(tracker) {
                    print("hit ignored")
                }
            }
        }
    }
    
    /**
     Send a Screen hit
     
     - parameter tracker: AutoTracker
     */
    func sendScreenHit(_ tracker: AutoTracker) -> Bool {
        let screen = tracker.screens.add(screenEvent.screen)
        let shouldSend = mapConfiguration(screen)
        if shouldSend {
            handleDelegate(screen)
            screen.sendView()
        }
        return shouldSend
    }
    
    /**
     Map the screen with custom information to add
     
     - parameter screen: the screen
     */
    func mapConfiguration(_ screen: Screen) -> Bool {
        waitForConfigurationLoaded()
        
        if let mapping = Configuration.smartSDKMapping {
            if let shouldIgnore = mapping["configuration"]["screens"][screen.className]["ignoreElement"].bool {
                if shouldIgnore {
                    return false
                }
            }
            if let mappedName = mapping["configuration"]["screens"][screen.className]["title"].string {
                screen.name = mappedName
            }
        }
        return true
    }
    
    /**
     Wait for the configuration to be loaded
     */
    func waitForConfigurationLoaded() {
        while(!AutoTracker.isConfigurationLoaded) {
            Thread.sleep(forTimeInterval: 0.2)
        }
    }
    
    /**
     Wait for the screen to be ready or until timeout
     
     - parameter screen: the screen
     */
    func handleDelegate(_ screen: Screen) {
        if hasDelegate() {
            screenEvent.viewController!.perform(#selector(IAutoTracker.screenWasDetected(_:)), with: screen)
            if screen.isReady {
                return
            } else {
                while(!screen.isReady) {
                    handleTimer(screen)
                }
            }
        }
    }
    
    /**
     Do the viewcontroller has a AutoTracker Delegate ?
     
     - returns: yes if so
     */
    func hasDelegate() -> Bool {
        var hasDelegate = false
        if let viewController = screenEvent.viewController {
            if viewController.conforms(to: IAutoTracker.self) {
                if viewController.responds(to: #selector(IAutoTracker.screenWasDetected(_:))) {
                    hasDelegate = true
                }
            }
        }
        return hasDelegate
    }
    
}
