//
//  GestureEvent.swift
//  SmartTracker
//
//  Created by Nicolas Sagnette on 06/11/2015.
//  Copyright © 2015 AT Internet. All rights reserved.
//

import Foundation
import UIKit

/// Class that represent a gesture event. concrete subclass should be used to represent specific events
class GestureEvent {
    
    /// View contains the gesture
    lazy var view: View = View()
    
    var defaultMethodName: String
    
    /// Method called by the touched UIView
    var methodName: String? {
        didSet {
            self.title = self.methodName
        }
    }
    
    /// A description of the gesture
    var direction: String
    
    /// current screen
    lazy var currentScreen: Screen = Screen()
    
    /// Event Type
    lazy var eventType: Gesture.GestureEventType = Gesture.GestureEventType.Unknown
    
    // Alias
    var title: String?
    
    /// View controller of the screen
    weak var viewController: UIViewController?
    
    /// Default description
    var description: String {
        return ""
    }
    
    /**
     Create a new Gesture Event
     
     - parameter type:          EventType enumeration
     - parameter methodName:    Method that triggered the gesture event
     - parameter viewClassName: 
     - parameter direction:
     - parameter currentScreen:
     
     - returns: a gesture event
     */
    init(type: Gesture.GestureEventType, methodName: String?, view: View, direction: String, currentScreen: Screen) {
        self.defaultMethodName = ""
        self.methodName = methodName
        self.direction = direction
        self.currentScreen = currentScreen
        self.view = view
        self.eventType = type
        self.title = methodName
    }
}
