//
//  UIApplicationContext.swift
//  SmartTracker
//
//  Created by Nicolas Sagnette on 06/11/2015.
//  Copyright © 2015 AT Internet. All rights reserved.
//

import Foundation
import UIKit

/// Context for swizzling of UIApplication class
class UIApplicationContext {
    /// An array representing "noise" UIView that we want to ignore
    let UIViewToIgnore = [
        SmartButtonIgnored.self,
        KLCPopup.self,
        SmartToolbar.self,
        SmartImageViewIgnored.self,
    ] as [Any]
    
    /**
     Enum of pinch direction
     
     - In:      Pinch In
     - Out:     Pinch Out
     - Unknown: Pinch detected but not yet identified
     */
    enum PinchDirection: String {
        case In = "in"
        case Out = "out"
        case Unknown = "?"
    }
    
    /**
     Enum of view types
     
     - Unkwown:          Default type
     - TableViewCell:    TableViewCell
     - BackButton:       BackButton
     - TabBarButton:     TabBarButton
     - SegmentedControl: SegmentedControl
     - Slider:           Slider
     - TextField:        TextField
     - Stepper:          Stepper
     - Button:           Button
     - Switch:           Switch
     - NavigationBar:    NavigationBar
     - PageControl:      PageControl
     - DatePicker:       DatePicker
     */
    enum ViewType: String {
        case unknown = "UIView"
        case tableViewCell = "UITableViewCell"
        case collectionViewCell = "UICollectionViewCell"
        case backButton = "UINavigationBarBackIndicatorView"
        case tabBarButton = "UITabBarButton"
        case segmentedControl = "UISegmentedControl"
        case slider = "UISlider"
        case textField = "UITextField"
        case stepper = "UIStepper"
        case button = "UIButton"
        case uiswitch = "UISwitch"
        case navigationBar = "UINavigationBar"
        case pageControl = "UIPageControl"
        case datePicker = "UIDatePicker"
    }
    
    /// Property to keep event type
    lazy var eventType: Gesture.GestureEventType = Gesture.GestureEventType.unknown
    
    /// Property to keep current touched view in app
    lazy var currentTouchedView : UIView? = nil
    
    /// Touch position
    lazy var initialTouchPosition: CGPoint = CGPoint.zero
    
    /// Time of touch
    var initalTouchTime: TimeInterval?
    
    /// Distance between two fingers
    lazy var initialPinchDistance: CGFloat = 0.0
    
    var rotationObject: Rotator?
    
    /// Pinch direction
    lazy var pinchType = PinchDirection.Unknown
    
    /// Time of previous touch
    var previousTouchTime: TimeInterval?
    
    /// Previous event type - not always sent
    lazy var previousEventType: Gesture.GestureEventType = Gesture.GestureEventType.unknown
    
    /// Previous event - that was SENT
    lazy var previousEventSent: GestureEvent? = nil
    
    /// Singleton
    static let sharedInstance = UIApplicationContext()
    
    fileprivate init() { }
    
    /**
     Return the default methodName for a view
     
     - returns: a default string that represent the default action on this view
     */
    func getDefaultViewMethod(_ currentView: UIView?) -> String? {
        guard let currentView = currentView else {
            return "handleTap:"
        }
        switch currentView.type {
        case UIApplicationContext.ViewType.unknown:
            return nil
        case UIApplicationContext.ViewType.tableViewCell:
            return "handleTap:"
        case UIApplicationContext.ViewType.collectionViewCell:
            return "handleTap:"
        case UIApplicationContext.ViewType.backButton:
            return "handleBack:"
        case UIApplicationContext.ViewType.tabBarButton:
            return "_tabBarItemClicked:"
        case UIApplicationContext.ViewType.segmentedControl:
            return nil
        case UIApplicationContext.ViewType.slider:
            return nil
        case UIApplicationContext.ViewType.textField:
            return "handleFocus:"
        case UIApplicationContext.ViewType.stepper:
            return nil
        case UIApplicationContext.ViewType.button:
            return nil
        case UIApplicationContext.ViewType.uiswitch:
            return "setOn:"
        case UIApplicationContext.ViewType.navigationBar:
            return "handleTap:"
        case UIApplicationContext.ViewType.pageControl:
            return nil
        case UIApplicationContext.ViewType.datePicker:
            return "handleTap:"
        }
    }
    
    class func findMostAccurateTouchedView(_ view: UIView?) -> UIView? {
        var accurateView: UIView?
        
        if let touchedView = view {
            if UIApplicationContext.sharedInstance.initialTouchPosition != CGPoint.zero {
                let frame = touchedView.superview?.convert(touchedView.frame, to: nil)
                
                if frame!.contains(UIApplicationContext.sharedInstance.initialTouchPosition) {
                    accurateView = touchedView
                    
                    if accurateView! is UIControl || accurateView?.type != UIApplicationContext.ViewType.unknown {
                        return accurateView
                    } else {
                        for subview in touchedView.subviews {
                            let accView = findMostAccurateTouchedView(subview)
                            
                            if(accView != nil) {
                                accurateView = accView
                            }
                        }
                    }
                } else {
                    accurateView = nil
                }
            }
        }
        
        return accurateView;
    }
}
