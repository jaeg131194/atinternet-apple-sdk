//
//  UIApplicationExtension.swift
//  SmartTracker
//
//  Created by Nicolas Sagnette on 06/11/2015.
//  Copyright © 2015 AT Internet. All rights reserved.
//

import Foundation
import UIKit

extension UIApplication {
    
    /**
     *  Singleton
     */
    struct Static {
        static var token:dispatch_once_t    = 0
        static let HorizontalSwipeDragMin   = 50.0
        static let VerticalSwipeDragMax     = 50.0
        static let MaxMoveTimeInterval      = 0.7
        static let PinchDragMin             = 1.0
        static let MinimumRotation: CGFloat = 35.0
    }
    
    /**
     Initialize: called once at the runtime
     in swift you have to init the swizzling from this method
     */
    public class func at_swizzle() {
        dispatch_once(&Static.token) { () -> Void in
            do {
                try self.jr_swizzleMethod(#selector(UIApplication.sendEvent(_:)), withMethod: #selector(UIApplication.at_sendEvent(_:)))
            } catch {
                NSException(name: "SwizzleException", reason: "Impossible to find method to swizzle", userInfo: nil).raise()
            }
        }
    }
    
    /**
     Unswizzle method
     */
    public class func at_unswizzle() {
        dispatch_once(&Static.token) { () -> Void in
            do {
                try self.jr_swizzleMethod(#selector(UIApplication.at_sendEvent(_:)), withMethod: #selector(UIApplication.sendEvent(_:)))
            } catch {
                NSException(name: "SwizzleException", reason: "Impossible to find method to swizzle", userInfo: nil).raise()
            }
        }
    }
    
    /**
     Custom send event method (swizzled)
     
     - parameter event: UIEvent
     */
    func at_sendEvent(event: UIEvent) {
        // sometimes we need to wait the end of the event in order
        // to get a correct capture (uiswitch, uislider...)
        if shouldSendNow() {
            queueEvent(event)
            at_sendEvent(event)
        } else {
            at_sendEvent(event)
            queueEvent(event)
        }
    }
    
    /**
     Get the current event type/text/method/...
     and send it to the sender queue
     
     - parameter event: the UIEvent from sendEvent:
     */
    func queueEvent(event: UIEvent) {
        let gestureEvent = gestureFromEvent(event)
        
        if let gesture = gestureEvent {
            if !ATInternet.sharedInstance.defaultTracker.debug {
                fillWithScreenshot(gesture)
            }
            
            gesture.viewController = UIViewControllerContext.sharedInstance.currentViewController
            EventManager.sharedInstance.addEvent(GestureOperation(gestureEvent: gesture))
        }
    }
    
    /**
     Takes a screenshot of the current touched view
     
     - parameter gesture: Gesture event
     */
    func fillWithScreenshot(gesture: GestureEvent) {
        let optImage = UIApplicationContext.sharedInstance.currentTouchedView?.screenshot()
        if let image = optImage {
            if let b64 = image.toBase64() {
                gesture.view.screenshot = b64.stringByReplacingOccurrencesOfString("\n", withString: "").stringByReplacingOccurrencesOfString("\r", withString: "")
            }
        }
    }
    
    /**
     Checks wheter the event must be sent before or after the call of the sendEvent: method
     
     - returns: Bool
     */
    func shouldSendNow() -> Bool {
        let ctx = UIApplicationContext.sharedInstance
        if let view = ctx.currentTouchedView {
            if  view.type == UIApplicationContext.ViewType.Button ||
                view.type == UIApplicationContext.ViewType.TableViewCell ||
                view.type == UIApplicationContext.ViewType.TextField ||
                view.type == UIApplicationContext.ViewType.NavigationBar ||
                view.type == UIApplicationContext.ViewType.BackButton ||
                view.type == UIApplicationContext.ViewType.CollectionViewCell ||
                view.type == UIApplicationContext.ViewType.Unkwown
            {
                return true
            }
        }
        return false
    }
    
    /**
     Gesture detection: this method is called each time an event is detected.
     this method is called several times per moves with different parameters
     (phase state began/moved/ended, number of fingers...)
     
     - parameter event: UIEvent
     
     - returns: GestureEvent detected
     */
    func gestureFromEvent(event: UIEvent) -> GestureEvent? {
        guard let touches = event.allTouches() else {
            return nil
        }
        
        if event.type == UIEventType.Touches {
            let appContext = UIApplicationContext.sharedInstance
            
            guard let touch = touches.first else {
                return nil
            }
            
            if touch.phase == UITouchPhase.Began {
                initContext(touches)
                if isDoubleTap(touches) {
                    EventManager.sharedInstance.cancelLastEvent()
                }
            }
            else if touch.phase == UITouchPhase.Moved {
                if touches.count == 1 {
                    let currentPos = touch.locationInView(nil)
                    let xDelta = fabs(appContext.initialTouchPosition.x - currentPos.x)
                    let yDelta = fabs(appContext.initialTouchPosition.y - currentPos.y)
                    
                    if  isSwipe(xDelta, yDelta: yDelta) {
                        appContext.eventType = Gesture.GestureEventType.Swipe
                    }
                    else if isScroll(xDelta, yDelta: yDelta) {
                        appContext.eventType = Gesture.GestureEventType.Scroll
                    }
                    else if isTap(xDelta, yDelta: yDelta) {
                       appContext.eventType = Gesture.GestureEventType.Tap
                    }
                    else {
                        if #available(iOS 9.0, *) {
                            if touch.force/touch.maximumPossibleForce > 0.5 {
                                appContext.eventType = Gesture.GestureEventType.Tap
                                print("P33K")
                            }
                        } else {
                            print("[warning] unknown gesture")
                            appContext.eventType = Gesture.GestureEventType.Unknown
                        }
                    }
                } else if touches.count == 2 {
                    if isRotation(touches) {
                        appContext.eventType = Gesture.GestureEventType.Rotate
                    } else {
                        appContext.eventType = Gesture.GestureEventType.Pinch
                    }
                }
            }
            else if touch.phase == UITouchPhase.Ended {
                assert(appContext.currentTouchedView != nil)
                
                // sometimes we have unwanted taps or double taps moves after pinch/rotation
                if((appContext.previousEventType == Gesture.GestureEventType.Pinch || appContext.previousEventType == Gesture.GestureEventType.Rotate) && appContext.initalTouchTime! - appContext.previousTouchTime! < 0.1) {
                    //clearContext()
                    return nil
                }
                
                // Remove noise from the toolbar or any SmartTracker events (pairing...)
                if shouldIgnoreView(appContext.currentTouchedView!) {
                    //clearContext()
                    return nil
                }
                
                var gestureEvent: GestureEvent?
                var eventType = appContext.eventType
                var methodName: String?
                
                // get method from action
                let (infoText, infoMethodName, infoClassName, position) = getTouchedViewInfo(appContext.currentTouchedView!)
                methodName = infoMethodName
                
                /// Try to get a more precise event type by looking at target/action from gesturerecognizers attached to the current view
                if let info = ATGestureRecognizer.getRecognizerInfo(touches, eventType: Gesture.getEventTypeRawValue(appContext.eventType.rawValue)) {
                    if((info["eventType"]) != nil) {
                        eventType = Gesture.GestureEventType(rawValue: Gesture.getEventTypeIntValue(info["eventType"] as! String))!
                    }
                    
                    if (methodName == nil) || (methodName != nil && methodName!.isEmpty) {
                        methodName = info["action"] as? String
                        if (methodName == nil) || (methodName != nil && methodName!.isEmpty) {
                            methodName = UIApplicationContext.sharedInstance.getDefaultViewMethod(appContext.currentTouchedView)
                            // the object does not respond to anything
                            if methodName == nil {
                                //clearContext()
                                return nil
                            }
                        }
                    }
                }
                
                if let segmentedControl = appContext.currentTouchedView as? UISegmentedControl {
                    let segs = segmentedControl.valueForKey("segments") as! [UIView]
                    appContext.currentTouchedView = segs[position!]
                }
                
                if UIViewControllerContext.sharedInstance.isPeekAndPoped {
                    methodName = "peekAndPop"
                    UIViewControllerContext.sharedInstance.isPeekAndPoped = false
                }
                
                switch eventType {
                case Gesture.GestureEventType.Tap :
                    gestureEvent = logTap(touch, method: methodName)
                case Gesture.GestureEventType.Swipe :
                    gestureEvent = logSwipe(touch, method: methodName)
                case Gesture.GestureEventType.Pan:
                    gestureEvent = logPan(touch, method: methodName)
                case Gesture.GestureEventType.Scroll:
                    gestureEvent = logScroll(touch, method: nil)
                case Gesture.GestureEventType.Rotate:
                    gestureEvent = logRotation(methodName)
                case Gesture.GestureEventType.Pinch:
                    if(touches.count == 2) {
                        appContext.pinchType = getPinchType(touches)
                    }
                    gestureEvent = logPinch(touch, method: methodName)
                default :
                    gestureEvent = nil
                    break
                }
                
                if let text = infoText {
                    gestureEvent?.view.text = text
                }
                
                if let className = infoClassName {
                    gestureEvent?.view.className = className
                }
                
                if let pos = position {
                    gestureEvent?.view.position = pos
                }
                
                clearContext()
                return gestureEvent
            }
        }
        //clearContext()
        return nil
    }
    
    /**
     function used to determine if a set of touches should be considered as a double tap
     
     - parameter touches: Set of UITouches
     
     - returns: return true if double tap determined
     */
    func isDoubleTap(touches: Set<UITouch>) -> Bool {
        return touches.count == 1 && touches.first!.tapCount == 2
    }
    
    /**
     function used to determine if a set of touches should shoudl be considered as a rotation move
     
     - parameter touches: set of current touches - use the context that stores the initial touches
     
     - returns: true if the context thinks a rotation is happening
     */
    func isRotation(touches: NSSet) -> Bool {
        let appContext = UIApplicationContext.sharedInstance
        let t = Array(touches)
        let currP1 = t[0].locationInView(nil)
        let currP2 = t[1].locationInView(nil)
        appContext.rotationObject?.setCurrentPoints(currP1, p2: currP2)
        if let obj = appContext.rotationObject {
            return obj.isValidRotation()
        } else {
            appContext.rotationObject = Rotator(p1: currP1, p2: currP2)
            return false
        }
    }
    
    /**
     Determines whether the gesture is a Swipe
     
     - parameter xDelta: Delta value between the initial X position and the final position
     - parameter yDelta: Delta value between the initial Y position and the final position
     
     - returns: true if it's detected as a swipe
     */
    func isSwipe(xDelta: CGFloat, yDelta: CGFloat) -> Bool {
        let appContext = UIApplicationContext.sharedInstance
        if  Double(xDelta) >= UIApplication.Static.HorizontalSwipeDragMin &&
            Double(yDelta) <= UIApplication.Static.VerticalSwipeDragMax {
                let now = NSDate().timeIntervalSinceNow
                if now - appContext.initalTouchTime! <= UIApplication.Static.MaxMoveTimeInterval {
                    return true
                }
        }
        return false
    }
    
    func isTap(xDelta: CGFloat, yDelta: CGFloat) -> Bool {
        return (xDelta == 0 && yDelta == 0)
    }
    
    /**
     Determines whether the gesture is a Scroll
     
     - parameter xDelta: Delta value between the initial X position and the final position
     - parameter yDelta: Delta value between the initial Y position and the final position
     
     - returns: true if it's a scroll
     */
    func isScroll(xDelta: CGFloat, yDelta: CGFloat) -> Bool {
        let appContext = UIApplicationContext.sharedInstance
        
        if  Double(xDelta) <= UIApplication.Static.HorizontalSwipeDragMin &&
            Double(yDelta) >= UIApplication.Static.VerticalSwipeDragMax {
                let now = NSDate().timeIntervalSinceNow
                if now - appContext.initalTouchTime! <= UIApplication.Static.MaxMoveTimeInterval {
                    return true
                }
        }
        return false
    }
    
    /**
     Gets the pinch direction
     
     - parameter touches: Touches
     
     - returns: Pinch Direction
     */
    func getPinchType(touches: Set<UITouch>) -> UIApplicationContext.PinchDirection {
        let t = Array(touches)
        var pinchType = UIApplicationContext.PinchDirection.Unknown
        let appContext = UIApplicationContext.sharedInstance
        
        let finalDist = Maths.CGPointDist(t[0].locationInView(nil), b: t[1].locationInView(nil))
        let initialDist = appContext.initialPinchDistance
        
        if  Double(fabs(finalDist - initialDist)) > UIApplication.Static.PinchDragMin &&
            initialDist > 0
        {
            if initialDist < finalDist {
                pinchType = UIApplicationContext.PinchDirection.In
            } else {
                pinchType = UIApplicationContext.PinchDirection.Out
            }
        }
        
        appContext.initialPinchDistance = finalDist
        return pinchType
    }
    
    /**
     Initialize the UIApplicationContext to store value when the touch begins
     
     - parameter touches: touces
     */
    func initContext(touches: Set<UITouch>) {
        if let touch = touches.first {
            let appContext = UIApplicationContext.sharedInstance
            appContext.eventType = Gesture.GestureEventType.Tap
            appContext.initialTouchPosition = touch.locationInView(nil)
            appContext.initalTouchTime = touch.timestamp
            appContext.initialPinchDistance = 0
            let touchedView = getTouchedView(touches);
            let accurateTouchedView = UIApplicationContext.findMostAccurateTouchedView(touchedView);
            if shouldIgnoreView(touchedView) {
                appContext.currentTouchedView = touchedView
            } else {
                appContext.currentTouchedView = accurateTouchedView == nil ? touchedView : accurateTouchedView
            }
            if touches.count == 2 {
                let t = Array(touches)
                appContext.eventType = Gesture.GestureEventType.Pinch
                appContext.initialPinchDistance = Maths.CGPointDist(t[0].locationInView(nil), b: t[1].locationInView(nil))
                appContext.initialTouchPosition = t[0].locationInView(nil)
                appContext.rotationObject = Rotator(p1: t[0].locationInView(nil), p2: t[1].locationInView(nil))
            }
        }
    }
    
    /* check is we should ignore the event */
    func shouldIgnoreView(optView: UIView?) -> Bool {
        guard let view = optView else {
            return true
        }
        
        if view is SmartButtonIgnored || view is KLCPopup || view is SmartToolbar || view is SmartImageViewIgnored || view is SmartViewIgnored {
            return true
        }
        return false
    }
    
    /**
     Restores context with default values
     */
    func clearContext() {
        let appContext = UIApplicationContext.sharedInstance
        appContext.previousTouchTime = appContext.initalTouchTime
        appContext.previousEventType = appContext.eventType
        appContext.initialTouchPosition = CGPointZero
        appContext.initalTouchTime = NSDate().timeIntervalSinceNow
        appContext.initialPinchDistance = 0
        appContext.rotationObject = nil
    }
    
    /**
     Gets a Tap object
     
     - parameter touch: touch
     
     - returns: TapEvent
     */
    func logTap(touch: UITouch, method: String?) -> TapEvent {
        let appContext = UIApplicationContext.sharedInstance
        
        let p = appContext.initialTouchPosition
        let tap = TapEvent(x:Float(p.x), y:Float(p.y), view: View(), direction:touch.tapCount == 1 ? "single" : "double", currentScreen: Screen())
        
        if let methodName = method {
            tap.methodName = methodName
        }
        return tap
    }
    
    /**
     Gets a Swipe object
     
     - parameter touch: touch
     
     - returns: SwipeEvent
     */
    func logSwipe(touch: UITouch, method: String?) -> SwipeEvent {
        let appContext = UIApplicationContext.sharedInstance
        let p = touch.locationInView(nil)
        let swipe = SwipeEvent(view: View(), direction:appContext.initialTouchPosition.x < p.x ? SwipeEvent.SwipeDirection.Right : SwipeEvent.SwipeDirection.Left, currentScreen: Screen())
        
        if let methodName = method {
            swipe.methodName = methodName
        }

        return swipe
    }
    
    /**
     Gets a Rotation object
     
     - parameter touch: touch
     
     - returns: RotationEvent
     */
    func logRotation(method: String?) -> RotationEvent {
        let appContext = UIApplicationContext.sharedInstance
        let finalAngle = appContext.rotationObject?.getCurrentRotation()
        let initialAngle = appContext.rotationObject?.initialRotation
        let rotation = RotationEvent(view: View(), direction:finalAngle!-initialAngle! > 0 ? RotationEvent.RotationDirection.Clockwise : RotationEvent.RotationDirection.CounterClockwise, currentScreen: Screen())
        if let methodName = method {
            rotation.methodName = methodName
        }
        
        return rotation
    }
    
    /**
     Gets a Pan object
     
     - parameter touch: touch
     
     - returns: PanEvent
     */
    func logPan(touch: UITouch, method: String?) -> PanEvent {
        let appContext = UIApplicationContext.sharedInstance
        let p = touch.locationInView(nil)
        var direction = PanEvent.PanDirection.Left
        
        if(appContext.eventType == Gesture.GestureEventType.Swipe) {
            direction = appContext.initialTouchPosition.x < p.x ? PanEvent.PanDirection.Right : PanEvent.PanDirection.Left
        } else if(appContext.eventType == Gesture.GestureEventType.Scroll) {
            direction = appContext.initialTouchPosition.y < p.y ? PanEvent.PanDirection.Up : PanEvent.PanDirection.Down
        }
        
        let pan = PanEvent(view: View(), direction: direction, currentScreen: Screen())
        
        if let methodName = method {
            pan.methodName = methodName
        }
        
        return pan
    }
    
    /**
     Gets a Scroll object
     
     - parameter touch: touch
     
     - returns: ScrollEvent
     */
    func logScroll(touch: UITouch, method: String?) -> ScrollEvent {
        let appContext = UIApplicationContext.sharedInstance
        let p = touch.locationInView(nil)
        let optTouchedView = appContext.currentTouchedView
        
        if let touchedView = optTouchedView {
            if(touchedView.isInScrollView) {
                appContext.currentTouchedView = touchedView.parentScrollView!
            }
        }
        
        let scroll = ScrollEvent(view: View(), direction:appContext.initialTouchPosition.y < p.y ? ScrollEvent.ScrollDirection.Up : ScrollEvent.ScrollDirection.Down, currentScreen: Screen())
        
        if let methodName = method {
            scroll.methodName = methodName
        }
        
        return scroll
    }
    
    /**
     Gets a Pinch object
     
     - parameter touch: touch
     
     - returns: PinchEvent
     */
    func logPinch(touch: UITouch, method: String?) -> PinchEvent {
        let appContext = UIApplicationContext.sharedInstance
        let pinch = PinchEvent(view: View(), direction:(appContext.pinchType == UIApplicationContext.PinchDirection.In) ? PinchEvent.PinchDirection.In : PinchEvent.PinchDirection.Out , currentScreen: Screen())
        
        if let methodName = method {
            pinch.methodName = methodName
        }

        return pinch
    }
    
    /**
     Get touched view from set
     
     - parameter touches: Set<UITouch>
     
     - returns: UIView?
     */
    func getTouchedView(touches: Set<UITouch>) -> UIView? {
        for touch in touches {
            if let view = touch.view {
                
                if(view.isInTableViewCell) {
                    return view.parentTableViewCell!
                } else {
                    return view
                }
            }
        }
        return nil
    }
    
    /**
     get the position of a cell in a collectionViewCell
     
     - returns: the position
     */
    func getIndexPathForCollectionCell() -> NSInteger? {
        let c: UICollectionViewCell? = UIApplicationContext.sharedInstance.currentTouchedView?.parentCollectionViewCell
        if let cell = c {
            let col = self.collectionViewForCell(cell)
            if let collection = col {
                return collection.indexPathForCell(cell)?.row
            }
        }
        return nil
    }
    
    /**
     Return the collectionView that belong to the cell (or the opposition ? :p)
     
     - parameter cell: an UICollectionViewCell
     
     - returns: the collectionViewCell
     */
    func collectionViewForCell(cell: UICollectionViewCell) -> UICollectionView?{
        var superView = cell.superview
        while superView != nil && !superView!.isKindOfClass(UICollectionView.self) {
            superView = superView?.superview
        }
        
        return superView as? UICollectionView
    }
    
    /**
     Return the index of a cell in a tableView
     
     - returns: the indexpath.row
     */
    func getIndexPathForTableCell() -> NSInteger? {
        let c: UITableViewCell? = UIApplicationContext.sharedInstance.currentTouchedView?.parentTableViewCell
        if let cell = c {
            let t = self.tableViewForCell(cell)
            if let table = t {
                return table.indexPathForCell(cell)?.row
            }
        }
        return nil
    }
    
    /**
     Return the tableView that belong to a tableViewCell
     
     - parameter cell: the cell
     
     - returns: the tableViewCell
     */
    func tableViewForCell(cell: UITableViewCell) -> UITableView? {
        var superView = cell.superview
        while superView != nil && !superView!.isKindOfClass(UITableView.self) {
            superView = superView?.superview
        }
        
        return superView as? UITableView
    }
    
    /**
     Tries to get the text, method and className of the touched view
     
     - parameter object: touched view
     
     - returns: text, method and className
     */
    func getTouchedViewInfo(object: AnyObject) -> (text: String?, method: String?, className: String?, position: Int?) {
        var text: String?
        var method: String?
        var className: String?
        var position = -1
        
        if let o = object as? NSObject {
            text = o.accessibilityLabel
        }
        
        if let view = object as? UIView {
            if view.type == UIApplicationContext.ViewType.TableViewCell {
                let cell = view.parentTableViewCell!
                if let textLabel = cell.textLabel {
                    if let cellText = textLabel.textValue {
                        text = cellText
                    }
                }
                className = "UITableViewCell"
                if let index = getIndexPathForTableCell() {
                    position = index
                }
            } else if view.type == UIApplicationContext.ViewType.CollectionViewCell {
                let cell = view.parentCollectionViewCell!
                if let cellText = cell.contentView.textValue {
                    text = cellText
                }
                className = "UICollectionViewCell"
                if let index = getIndexPathForCollectionCell() {
                    position = index
                }
                
            } else if view.type == UIApplicationContext.ViewType.BackButton {
                text = "Back"
                method = "handleBack:"
            } else if view.type == UIApplicationContext.ViewType.NavigationBar {
                text = view.textValue
                className = "UINavigationBar"
            } else if view.type == UIApplicationContext.ViewType.TextField  {
                let textField = view as! UITextField
                
                if let fieldText = textField.text {
                    if !fieldText.isEmpty  {
                        text = fieldText
                    } else if let placeHolder = textField.placeholder {
                        if !placeHolder.isEmpty  {
                            text = placeHolder
                        }
                    }
                } else if let placeHolder = textField.placeholder {
                    if !placeHolder.isEmpty  {
                        text = placeHolder
                    }
                }
            } else if view.type == UIApplicationContext.ViewType.Button  {
                let button = view as! UIButton
                
                if let title = button.currentTitle {
                    text = title
                } else if let image = button.currentImage {
                    if let title = image.accessibilityLabel {
                        text = title
                    }
                    else if let title = image.accessibilityIdentifier {
                        text = title
                    }
                }
                
                let classType:AnyClass? = NSClassFromString("UINavigationButton")
                if view.isKindOfClass(classType!) {
                    position = getPositionFromNavigationBar(view)
                }
                
            } else if view.type == UIApplicationContext.ViewType.SegmentedControl  {
                let segment = view as! UISegmentedControl
                text = segment.titleForSegmentAtIndex(segment.selectedSegmentIndex)
                position = segment.selectedSegmentIndex
                className = "UISegment"
            } else if view.type == UIApplicationContext.ViewType.Slider  {
                let slider = view as! UISlider
                
                text = String(slider.value)
            } else if view.type == UIApplicationContext.ViewType.Stepper  {
                let stepper = view as! UIStepper
                
                text = String(stepper.value)
            }
        } else if let barButton = object as? UIBarButtonItem {
            let view = barButton.valueForKey("view") as! UIView
            var barButtonContainer = view.superview
            
            if let title = barButton.title {
                text = title
            }
            method = NSStringFromSelector(barButton.action)
            if barButtonContainer is UIToolbar {
                position = getPositionFromUIToolbarButton(barButton)
            }
        }
        
        if let control = object as? UIControl {
            for target in control.allTargets() {
                if target.isKindOfClass(NSClassFromString("UIBarButtonItem")!)  {
                    let barButtonInfo = getTouchedViewInfo(target as! UIBarButtonItem)
                    if let title = barButtonInfo.text {
                        text = title
                    }
                    
                    if let barButtonMethod = barButtonInfo.method {
                        method = barButtonMethod
                    }
                    
                    if let pos = barButtonInfo.position {
                        if position == -1 {
                            position = pos
                        }
                    }
                } else if target.isKindOfClass(NSClassFromString("UITabBar")!)  {
                    let tabBar = target as! UITabBar
                    
                    let (idx, title) = getItemFromButton(tabBar, currentButton: object as! UIControl)
                    if let _ = idx {
                        position = idx!
                    }
                    text = title
                    method = "_tabBarItemClicked:"
                    className = "UITabBarController"
                } else {
                    if let actions = control.actionsForTarget(target, forControlEvent: control.allControlEvents()) {
                        func getAction(actions: [String]) -> String? {
                            return actions.filter({$0 != "at_refresh"}).first
                        }
                        if let action = getAction(actions) {
                            method = action
                        }
                    }
                }
            }
        }
        
        if position == -1 {
            position = getPositionInSuperView(object)
        }
        
        return (text: text, method: method, className: className, position: position)
    }
    
    /**
     Get the position in the index of superview
     KAIZEN : move to UIViewExtension ?
     
     - parameter obj: An object - should be an UIView
     
     - returns: the position in its parent's subviews array
     */
    func getPositionInSuperView(obj: AnyObject) -> Int {
        let defaultValue = -1
        guard let view = obj as? UIView else {
            return defaultValue
        }
        
        guard let parent = view.superview else {
            return defaultValue
        }
        
        return zip((0...parent.subviews.count), parent.subviews).filter({$0.1 == view})[0].0
    }
    
    /**
     get the title and the position of a button in a UITabBar
     
     - parameter tabBar:        the TabBar
     - parameter currentButton: the clicked button
     
     - returns: (index, title) tuple
     */
    func getItemFromButton(tabBar: UITabBar, currentButton: UIControl) -> (Int?, String?) {
        guard let tabBarItems = tabBar.items else {
            return (nil, nil)
        }
        for (idx, item) in tabBarItems.enumerate() {
            if item.at_hasProperty("view") {
                if currentButton == item.valueForKey("view") as! UIControl {
                    let text = item.title
                    return (idx, text)
                }
            }
        }
        return (nil,nil)
    }
    
    /**
     get the position of a ToolBarButton in its toolbar.
     Note that the accessible view is a UIBarButtonItem but we test later the UIToolbarButton class
     
     - parameter barButton: the barbutton clicked
     
     - returns: the position
     */
    func getPositionFromUIToolbarButton(barButton: UIBarButtonItem) -> Int {
        if let embedView = barButton.valueForKey("view") as? UIView {
            if let parent = embedView.superview {
                let subs = parent.subviews
                let buttonArray = subs.filter({$0.isKindOfClass(NSClassFromString("UIToolbarButton")!)})
                return buttonArray.indexOf(embedView) ?? -1
            }
        }
        return -1
    }
    
    func getPositionFromNavigationBar(view: UIView) -> Int {
        let classType:AnyClass? = NSClassFromString("UINavigationButton")
        if view.isKindOfClass(classType!) {
            let navBar = view.superview as! UINavigationBar
            var navButtons = navBar.subviews.filter({ $0.isKindOfClass(classType!) })
            navButtons.sortInPlace({ (button1: UIView, button2: UIView) -> Bool in
                button1.frame.origin.x < button2.frame.origin.x
            })
            return navButtons.indexOf(view) ?? -1
        }
        return -1
    }
}
