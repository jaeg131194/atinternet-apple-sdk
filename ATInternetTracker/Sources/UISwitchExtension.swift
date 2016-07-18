//
//  UISwitchExtension.swift
//  SmartTracker
//
//  Created by Théo Damaville on 13/11/2015.
//  Copyright © 2015 AT Internet. All rights reserved.
//

import Foundation
import UIKit

extension UISwitch {
    /**
     *  Singleton
     */
    struct Static {
        static var token:dispatch_once_t = 0
    }
    
    /**
     UISwitch init
     
     - returns: UISwitch
     */
    public class func at_swizzle() {
        if self !== UISwitch.self {
            return
        }
        
        dispatch_once(&Static.token) { () -> Void in
            do {
                try self.jr_swizzleMethod(#selector(UIResponder.touchesEnded(_:withEvent:)), withMethod: #selector(UISwitch.at_touchesEnded(_:withEvent:)))
            } catch {
                NSException(name: "SwizzleException", reason: "Impossible to find method to swizzle", userInfo: nil).raise()
            }
        }
    }
    
    /**
     Unswizzle
     */
    public class func at_unswizzle() {
        if self !== UISwitch.self {
            return
        }
        
        dispatch_once(&Static.token) { () -> Void in
            do {
                try self.jr_swizzleMethod(#selector(UISwitch.at_touchesEnded(_:withEvent:)), withMethod: #selector(UIResponder.touchesEnded(_:withEvent:)))
            } catch {
                NSException(name: "SwizzleException", reason: "Impossible to find method to swizzle", userInfo: nil).raise()
            }
        }
    }
    
    /**
     Catches the touchesEnded event
     
     - parameter touches: touches
     - parameter event:   event
     */
    func at_touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent) {
        let _ = UIApplicationContext.sharedInstance
        let touch = touches.first
        let touchPoint = touch?.locationInView(nil)
        let lastOperation = EventManager.sharedInstance.lastEvent() as? GestureOperation
        
        at_touchesEnded(touches, withEvent: event)
        
        if let operation = lastOperation {
            if operation.gestureEvent.eventType == Gesture.GestureEventType.Tap {
                if let touchLocation = touchPoint {
                    let gesture = operation.gestureEvent as! TapEvent
                    if gesture.x == Float(touchLocation.x) && gesture.y == Float(touchLocation.y) {
                        operation.cancel()
                    }
                    
                    gesture.view.text = self.on ? "On" : "Off"
                    gesture.view.className = self.classLabel
                    gesture.view.path = self.path
                    gesture.methodName = "setOn:"
                    
                    if let screenshot = self.screenshot() {
                        if let b64 = screenshot.toBase64() {
                            gesture.view.screenshot = b64.stringByReplacingOccurrencesOfString("\n", withString: "").stringByReplacingOccurrencesOfString("\r", withString: "")
                        }
                    }
                    
                    let (_,mehodName,_,_) = UIApplication.sharedApplication().getTouchedViewInfo(self)
                    if let method = mehodName {
                        gesture.methodName = method
                    }
                    EventManager.sharedInstance.addEvent(GestureOperation(gestureEvent: gesture))
                }
            }
        }
    }
}