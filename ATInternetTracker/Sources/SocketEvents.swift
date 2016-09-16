//
//  SmartSocketEvents.swift
//  SmartTracker
//
//  Created by Théo Damaville on 24/02/2016.
//  Copyright © 2016 AT Internet. All rights reserved.
//

import Foundation
import UIKit

/// Factory making a different class in charge of handling different events
class SocketEventFactory {
    class func create(_ eventName: String, liveManager: LiveNetworkManager, messageData: JSON?) -> SocketEvent {
        switch eventName {
        // triggered after viewDidAppear
        case SmartSocketEvent.Screenshot.rawValue:
            return SEScreenshot(liveManager: liveManager, messageData: messageData)
        // interface requesting a live session
        case SmartSocketEvent.InterfaceAskedForLive.rawValue:
            return SEInterfaceAskedForLive(liveManager: liveManager, messageData: messageData)
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

/// Handle all the incoming messages from the websocket
class SocketEvent {
    let liveManager: LiveNetworkManager
    let messageData: JSON?
    
    init(liveManager: LiveNetworkManager, messageData: JSON? = nil) {
        self.liveManager = liveManager
        self.messageData = messageData
    }
    
    func process() {}
    
    /// delay
    ///
    /// - parameter delay:   a delay before executing the closure
    /// - parameter closure: a closure to execute after a delay
    func delay(_ delay:Double, closure:@escaping ()->()) {
        DispatchQueue.main.asyncAfter(
            deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
    }
}

/// Wait a bit then send a screenshot with screen information and suggested events
class SEScreenshot: SocketEvent {
    func makeJSONArray(_ values: [Any]) -> [Any] {
        if let events = values as? [GestureEvent] {
            return events.map( {$0.description.toJSONObject()!} )
        }
        return []
    }
    
    
    override func process() {
        delay(0.5) {
            var controls: [Any] = []
            if let currentViewController = UIViewControllerContext.sharedInstance.currentViewController {
                controls = self.makeJSONArray(currentViewController.getControls())
            }
            
            var toIgnore = [UIView]()
            if let toolbar = self.liveManager.toolbar?.toolbar {
                toIgnore.append(toolbar)
            }
            if let popup = self.liveManager.currentPopupDisplayed {
                toIgnore.append(popup)
            }
            
            var base64 = UIApplication.shared
                .keyWindow?
                .screenshot(toIgnore)?
                .toBase64()!
                .replacingOccurrences(of: "\n", with: "")
                .replacingOccurrences(of: "\r", with: "")
            
            assert(base64 != nil)
            let screen = Screen()
            if self.messageData != nil && self.messageData!["screen"]["className"].string != nil && self.messageData!["screen"]["className"].string! != screen.className {
                base64 = "R0lGODlhAQABAIAAAP///wAAACwAAAAAAQABAAACAkQBADs="  // 1x1 white pixel
                screen.className = self.messageData!["screen"]["className"].string!
                controls = []
            }
            let screenshotEvent = ScreenshotEvent(screen: screen,
                                                  screenshot: base64,
                                                  suggestedEvents: controls)
            
            self.liveManager.sender?.sendMessage(screenshotEvent.description)
        }
    }
}
    
/// The BO is asking for a live - display a popup to the user
class SEInterfaceAskedForLive: SocketEvent {
    override func process() {
        let currentVersion = TechnicalContext.applicationVersion.isEmpty ? "" : TechnicalContext.applicationVersion
        if self.messageData != nil && self.messageData!["version"].string != nil && self.messageData!["version"].string != currentVersion {
            liveManager.sender?.sendMessageForce(DeviceVersion().description)
            return
        }
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
            var toIgnore = [UIView]()
            if let toolbar = self.liveManager.toolbar?.toolbar {
                toIgnore.append(toolbar)
            }
            if let popup = self.liveManager.currentPopupDisplayed {
                toIgnore.append(popup)
            }
            let base64 = UIApplication.shared
                .keyWindow?
                .screenshot(toIgnore)?
                .toBase64()!
                .replacingOccurrences(of: "\n", with: "")
                .replacingOccurrences(of: "\r", with: "")
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
