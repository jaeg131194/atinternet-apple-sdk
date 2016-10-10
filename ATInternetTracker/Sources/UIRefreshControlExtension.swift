//
//  File.swift
//  SmartTracker
//
//  Created by Théo Damaville on 29/01/2016.
//  Copyright © 2016 AT Internet. All rights reserved.
//

import Foundation
import UIKit

extension UIRefreshControl {
    /**
     *  Singleton
     */
    struct Static {
        static var token: String = UUID().uuidString
    }
    
    
    /**
     Initialize: called once at the runtime
     in swift you have to init the swizzling from this method
     */
    public class func at_swizzle() {
        if self !== UIRefreshControl.self {
            return
        }
        
        DispatchQueue.once(token: Static.token) {
            // Get the "- (id)initWithFrame:" method.
            let original = class_getInstanceMethod(self, #selector(UIRefreshControl.init as () -> UIRefreshControl))
            // Get the "- (id)swizzled_initWithFrame:" method.
            let swizzle = class_getInstanceMethod(self, #selector(UIRefreshControl.at_init))
            // Swap their implementations.
            method_exchangeImplementations(original, swizzle)
            do {
                try self.jr_swizzleMethod(#selector(UIRefreshControl.beginRefreshing), withMethod: #selector(UIRefreshControl.at_beginRefreshing))
                try self.jr_swizzleMethod(#selector(UIView.init(frame:)), withMethod: #selector(UIRefreshControl.at_initWithFrame(_:)))
            } catch {
                NSException(name: NSExceptionName(rawValue: "SwizzleException"), reason: "Impossible to find method to swizzle", userInfo: nil).raise()
            }
        }
    }

    
    /**
 */
    public class func at_unswizzle() {
        if self !== UIRefreshControl.self {
            return
        }
        
        DispatchQueue.once(token: Static.token) {
            // Get the "- (id)initWithFrame:" method.
            let original = class_getInstanceMethod(self, #selector(UIRefreshControl.init as () -> UIRefreshControl))
            // Get the "- (id)swizzled_initWithFrame:" method.
            let swizzle = class_getInstanceMethod(self, #selector(UIRefreshControl.at_init))
            // Swap their implementations.
            method_exchangeImplementations(swizzle, original)
            do {
                try self.jr_swizzleMethod(#selector(UIRefreshControl.at_beginRefreshing), withMethod: #selector(UIRefreshControl.beginRefreshing))
                try self.jr_swizzleMethod(#selector(UIRefreshControl.at_initWithFrame(_:)), withMethod: #selector(UIView.init(frame:)))
            } catch {
                NSException(name: NSExceptionName(rawValue: "SwizzleException"), reason: "Impossible to find method to swizzle", userInfo: nil).raise()
            }
        }
    }
    
    func at_init() -> Any {
        self.addTarget(self, action: #selector(UIRefreshControl.at_refresh), for: UIControlEvents.valueChanged)
        return self.at_init()
    }
    
    func at_refresh () {
        let lastOperation = EventManager.sharedInstance.lastEvent() as? GestureOperation
        
        if let operation = lastOperation {
            if operation.gestureEvent.eventType == Gesture.GestureEventType.scroll  {
                let gesture = operation.gestureEvent as! ScrollEvent
                operation.cancel()
                gesture.view.className = self.classLabel
                gesture.view.path = self.path
                gesture.view.position = -1
                gesture.direction = "down"
                gesture.eventType = Gesture.GestureEventType.refresh
                
                if let screenshot = self.screenshot() {
                    if let b64 = screenshot.toBase64() {
                        gesture.view.screenshot = b64.replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "\r", with: "")
                    }
                }
                
                let (_,mehodName,_,_) = UIApplication.shared.getTouchedViewInfo(self)
                if let method = mehodName {
                    gesture.methodName = method
                }
                EventManager.sharedInstance.addEvent(GestureOperation(gestureEvent: gesture))
            }
        }
        else {
            let (_,methodName,_,_) = UIApplication.shared.getTouchedViewInfo(self)
            let selfView = View(view: self)
            let currentScreen = Screen()
            let refreshEvent = RefreshEvent(method: methodName, view: selfView, currentScreen: currentScreen)
            EventManager.sharedInstance.addEvent(GestureOperation(gestureEvent: refreshEvent))
        }
    }
    
    func at_initWithFrame(_ frame: CGRect) {
        self.at_initWithFrame(frame)
    }
    
    func at_beginRefreshing() {
        self.at_beginRefreshing()
    }    
}
