//
//  UIViewControllerExtension.swift
//  SmartTracker
//
//  Created by Théo Damaville on 04/11/2015.
//  Copyright © 2015 AT Internet. All rights reserved.
//

import Foundation
import UIKit

// MARK: - extension of UIViewController: used for detecting screen apparitions
extension UIViewController {
    
    /**
     *  Singleton
     */
    struct Static {
        static var token:dispatch_once_t = 0
    }
    
    /// Return a title for the screen based on the navBar title, uivc title...
    var screenTitle:String {
        var title = self.title;
        
        if (title == nil || title == "") {
            title = self.navigationController?.navigationBar.topItem?.title
        }
        if (title == nil || title == "") {
            title = self.navigationController?.navigationItem.title;
        }
        
        if (title == nil || title == "") {
            title = self.navigationItem.title;
        }
        
        if (title == nil || title == "") {
            title = self.classLabel
        }
        
        return title ?? "";
    }
    
    /**
     Initialize: called once at the runtime
     in swift you have to init the swizzling from this method
     */
    public class func at_swizzle() {
        if self !== UIViewController.self {
            return
        }
        
        dispatch_once(&Static.token) { () -> Void in
            do {
                try self.jr_swizzleMethod(#selector(UIViewController.viewDidAppear(_:)), withMethod: #selector(UIViewController.at_viewDidAppear(_:)))
                try self.jr_swizzleMethod(#selector(UIViewController.viewDidDisappear(_:)), withMethod: #selector(UIViewController.at_viewDidDisappear(_:)))
                try self.jr_swizzleMethod(#selector(UIViewController.viewWillDisappear(_:)), withMethod: #selector(UIViewController.at_viewWillDisappear(_:)))
            } catch {
                NSException(name: "SwizzleException", reason: "Impossible to find method to swizzle", userInfo: nil).raise()
            }
        }
    }
    
    public class func at_unswizzle() {
        if self !== UIViewController.self {
            return
        }
        
        dispatch_once(&Static.token) { () -> Void in
            do {
                try self.jr_swizzleMethod(#selector(UIViewController.at_viewDidAppear(_:)), withMethod: #selector(UIViewController.viewDidAppear(_:)))
                try self.jr_swizzleMethod(#selector(UIViewController.at_viewDidDisappear(_:)), withMethod: #selector(UIViewController.viewDidDisappear(_:)))
                try self.jr_swizzleMethod(#selector(UIViewController.at_viewWillDisappear(_:)), withMethod: #selector(UIViewController.viewWillDisappear(_:)))
            } catch {
                NSException(name: "SwizzleException", reason: "Impossible to find method to swizzle", userInfo: nil).raise()
            }
        }
    }
    
    /**
     Catching the screen events here
     
     - parameter animated: not related
     */
    func at_viewDidAppear(animated: Bool) {
        if shouldIgnoreViewController() {
            at_viewDidAppear(animated)
            return
        }
        
        let now = NSDate().timeIntervalSinceNow
        let context = UIViewControllerContext.sharedInstance
        
        context.activeViewControllers.append(self)
        let screenEvent = ScreenEvent(title: self.screenTitle, className: self.classLabel, triggeredBy: nil)
        screenEvent.viewController = self
        
        let operation = ScreenOperation(screenEvent: screenEvent)
        
        if now - context.viewAppearedTime <= 0.1 {
            EventManager.sharedInstance.cancelLastScreenEvent()
        }
        
        context.viewAppearedTime = now
        
        EventManager.sharedInstance.addEvent(operation)
        
        at_viewDidAppear(animated)
    }
    
    /**
     Check whether a UIViewContoller should be ignored from the Event detection
     we have to ignore some protocol too
     
     - returns: true if the uiviewcontroller must be ignored, false otherwise
     */
    func shouldIgnoreViewController() -> Bool {
        let context = UIViewControllerContext.sharedInstance
        
        for protocolType in context.UIProtocolToIgnore {
            if let type = protocolType {
                if self.conformsToProtocol(type) {
                    return true
                }
            }
        }
        
        for classType in context.UIClassToIgnore {
            if let type = classType {
                if self.isKindOfClass(type) {
                    return true
                }
            }
        }
        
        return false
    }
    
    /**
     Catches the viewWillDisappear event
     
     - parameter animated: animated
     */
    func at_viewWillDisappear(animated: Bool) {
        self.at_viewWillDisappear(animated)
        
        // User did tap on back button ?
        if self.isMovingFromParentViewController() {
            if let operation = EventManager.sharedInstance.lastEvent() as? GestureOperation {
                if operation.gestureEvent.view.className == "UINavigationBar" {
                    let pendingEvent = operation.gestureEvent
                    EventManager.sharedInstance.cancelLastEvent()
                    pendingEvent.methodName = "handleBack:"
                    if pendingEvent.view.text.isEmpty {
                        pendingEvent.view.text = "Back"
                    }
                    
                    EventManager.sharedInstance.addEvent(GestureOperation(gestureEvent: pendingEvent))
                }
            }
        }
    }
    
    /**
     Called when a uiviewcontroller disappeared on the phone
     
     - parameter animated: not related (how the VC is transitioning)
     */
    func at_viewDidDisappear(animated: Bool) {
        let context = UIViewControllerContext.sharedInstance
        
        for i in (0 ..< context.activeViewControllers.count).reverse() {
            if self == context.activeViewControllers[i] {
                context.activeViewControllers.removeAtIndex(i)
                break
            }
        }
        
        at_viewDidDisappear(animated)
    }
    
    /**
     return the possible gesture events detected in the current view controller
     those are going to be the "suggested events" feature
     
     - returns: GestureEvent array
     */
    func getControls() -> [GestureEvent] {
        var controls:[UIView] = []
        var events: [GestureEvent] = []
        // 3 steps : ViewController, NavBar, TabBar
        getControlsInView(self.view, allControls: &controls)
        if let navigationController = self.navigationController {
            getControlsInView(navigationController.navigationBar, allControls: &controls)
        }
        if let tabBarController = self.tabBarController {
            getControlsInView(tabBarController.tabBar, allControls: &controls)
        }
        
        let currentScreen = Screen()
        for aView in controls {
            let v = View(view: aView)
            var (text,methodName,className,position) = UIApplication.sharedApplication().getTouchedViewInfo(aView)
            let info = ATGestureRecognizer.getRecognizerInfoFromView(aView, withExpected: Gesture.getEventTypeRawValue(Gesture.GestureEventType.Tap.rawValue))
            
            if methodName == nil || (methodName != nil && methodName!.isEmpty) {
                methodName = info["action"] as? String
                if methodName == nil || (methodName != nil && methodName!.isEmpty) {
                    methodName = UIApplicationContext.sharedInstance.getDefaultViewMethod(aView)
                    // the object does not respond to anything
                    if methodName == nil || (methodName != nil && methodName!.isEmpty) {
                        continue
                    }
                }
            }
            
            let tap = TapEvent(x:-1, y:-1, view: v, direction:"single", currentScreen: currentScreen)
            
            if let _ = methodName {
                tap.methodName = methodName!
            }
            if let _ = className {
                tap.view.className = className!
            }
            if let _ = text {
                tap.view.text = text!
            }
            if let _ = position {
                tap.view.position = position!
            }
            
            // In case of an UISegmentedControl we have to create X events (X=subsegment number)
            if let segmented =  aView as? UISegmentedControl {
                let nb = segmented.numberOfSegments
                let segments = segmented.valueForKey("segments") as! [UIView]
                for i in 0..<nb {
                    let aTap = TapEvent(x: -1, y: -1, view: View(view: segments[i]), direction: "single", currentScreen: currentScreen)
                    aTap.methodName = tap.methodName
                    aTap.view.position = i
                    aTap.view.text = segmented.titleForSegmentAtIndex(i) ?? ""
                    events.append(aTap)
                }
            }
            else if let _ = aView as? UIRefreshControl {
                let refreshControl = RefreshEvent(method: methodName, view: View(view: aView), currentScreen: currentScreen)
                events.append(refreshControl)
            }
            else {
                events.append(tap)
            }
        }
        return events
    }
    
    /**
     Parse the uiview to get all the uicontrols available
     part of the "suggested events" feature
     note: the initial call should pass the current uiwindow as first parameter and a ref to an array as a second parameter
     POSSIBLE KAIZEN => Move to UIViewExtension
     
     - parameter root:        the root uiview to be parsed
     - parameter allControls: the uicontrol array
     */
    func getControlsInView(root: UIView, inout allControls:[UIView]) {
        if root is UIControl && !root.isInTableViewCellIgnoreControl {
            allControls.append(root)
        }
        else {
            root.subviews.forEach({getControlsInView($0, allControls: &allControls)})
        }
    }
}