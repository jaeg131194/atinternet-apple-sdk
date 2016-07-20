//
//  SmartSocketEvents.swift
//  SmartTracker
//
//  Created by Théo Damaville on 24/02/2016.
//  Copyright © 2016 AT Internet. All rights reserved.
//

import Foundation
import UIKit

class SocketEventFactory {
    class func create(eventName: String, liveManager: LiveNetworkManager) -> SocketEvent {
        switch eventName {
        // triggered after viewDidAppear
        case SmartSocketEvent.Screenshot.rawValue:
            return SEScreenshot(liveManager: liveManager)
        // interface requesting a live session
        case SmartSocketEvent.InterfaceAskedForLive.rawValue:
            return SEInterfaceAskedForLive(liveManager: liveManager)
        // device decline live (loop from self due to the dispatch broadcast)
        case SmartSocketEvent.InterfaceRefusedLive.rawValue:
            return SEInterfaceRefusedLive(liveManager: liveManager)
        // device ready to go live
        case SmartSocketEvent.InterfaceAcceptedLive.rawValue:
            return SEInterfaceAcceptedLive(liveManager: liveManager)
        // interface request a screenshot from current view
        case SmartSocketEvent.InterfaceAskedForScreenshot.rawValue:
            return SEInterfaceAskedForScreenshot(liveManager: liveManager)
        // interface ends live sessions
        case SmartSocketEvent.InterfaceStoppedLive.rawValue:
            return SEInterfaceStoppedLive(liveManager: liveManager)
        case SmartSocketEvent.InterfaceAbortedLiveRequest.rawValue:
            return SEInterfaceAbortedLiveRequest(liveManager: liveManager)
        default:
            return SocketEvent(liveManager: liveManager)
        }
    }
}

class SocketEvent {
    let liveManager: LiveNetworkManager
    
    init(liveManager: LiveNetworkManager) {
        self.liveManager = liveManager
    }
    
    func process() {
        print("not handled")
    }
    
    func delay(delay:Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure)
    }
}

/// Wait a bit then send a screenshot with screen information and suggested events
class SEScreenshot: SocketEvent {
    func makeJSONArray(values: [AnyObject]) -> [AnyObject] {
        if let events = values as? [GestureEvent] {
            return events.map( {$0.description.toJSONObject()!} )
        }
        return []
    }
    
    override func process() {
        delay(0.5) {
            let start = NSDate()
            var controls: [AnyObject] = []
            if let currentViewController = UIViewControllerContext.sharedInstance.currentViewController {
                controls = self.makeJSONArray(currentViewController.getControls())
            }
            
            UIView.animateWithDuration(0.01, animations: {
                self.liveManager.toolbar?.toolbar.alpha = 0
                }, completion: { (Bool) in
                    //self.liveManager.setToolbarHidden(true)
                    let base64 = UIApplication.sharedApplication()
                        .keyWindow?.screenshot()?
                        .toBase64()!
                        .stringByReplacingOccurrencesOfString("\n", withString: "")
                        .stringByReplacingOccurrencesOfString("\r", withString: "")
                    
                    assert(base64 != nil)
                    UIView.animateWithDuration(0.01, animations: {
                        //self.liveManager.setToolbarHidden(false)
                        self.liveManager.toolbar?.toolbar.alpha = 1
                        }, completion: { (Bool) in
                            let screenshotEvent = ScreenshotEvent(screen: Screen(),
                                                                  screenshot: base64,
                                                                  suggestedEvents: controls)
                            
                            self.liveManager.sender?.sendMessage(screenshotEvent.description)
                    })
            })
            
            //print(NSDate().timeIntervalSinceDate(start))
            
        }
    }
}
    
/// The BO is asking for a live - display a popup to the user
class SEInterfaceAskedForLive: SocketEvent {
    override func process() {
        self.liveManager.interfaceAskedForLive()
    }
}

/// Live Tagging canceled
class SEInterfaceRefusedLive: SocketEvent {
    override func process() {
        self.liveManager.interfaceRefusedLive()
    }
}

/// Live Tagging started
class SEInterfaceAcceptedLive: SocketEvent {
    override func process() {
        self.liveManager.interfaceAcceptedLive()
    }
}

/// BO is requesting a screenshot
class SEInterfaceAskedForScreenshot: SocketEvent {
    override func process() {
        if self.liveManager.networkStatus == .Connected {
            self.liveManager.setToolbarHidden(true)
            let base64 = UIApplication.sharedApplication()
                .keyWindow?.screenshot()?
                .toBase64()!
                .stringByReplacingOccurrencesOfString("\n", withString: "")
                .stringByReplacingOccurrencesOfString("\r", withString: "")
            self.liveManager.setToolbarHidden(false)
            let currentScreen = Screen()
            self.liveManager.sender?.sendMessage(ScreenshotUpdated(screenshot: base64, screen: currentScreen).description)
        }
    }
}

/// Live tagging is canceled
class SEInterfaceStoppedLive: SocketEvent {
    override func process() {
        self.liveManager.interfaceStoppedLive()
    }
}

class SEInterfaceAbortedLiveRequest: SocketEvent {
    override func process() {
        self.liveManager.interfaceAbortedLiveRequest()
    }
}
