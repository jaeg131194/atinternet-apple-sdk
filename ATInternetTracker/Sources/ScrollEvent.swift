//
//  ScrollEvent.swift
//  SmartTracker
//
//  Created by Nicolas Sagnette on 06/11/2015.
//  Copyright © 2015 AT Internet. All rights reserved.
//

import Foundation

/// class to store scroll events
class ScrollEvent : GestureEvent {
    
    /**
     Scroll direction
     
     - Up:   Up
     - Down: Down
     */
    enum ScrollDirection: String {
        case Up   = "up"
        case Down = "down"
    }
    
    /// JSON description
    override var description: String {
        var jsonObj: [String: Any] = [
            "event": Gesture.getEventTypeRawValue(self.eventType.rawValue),
            "data":[
                "x":-1,
                "y":-1,
                "type": Gesture.getEventTypeRawValue(self.eventType.rawValue),
                "methodName": self.methodName ?? defaultMethodName,
                "direction": self.direction,
                "isDefaultMethod": self.methodName == nil,
                "title": self.title ?? defaultMethodName
            ]
        ]
        
        var data = jsonObj["data"] as! [String: Any]
        data.append(self.view.toJSONObject)
        data.append(self.currentScreen.toJSONObject)
        jsonObj.updateValue(data, forKey: "data")
        
        return jsonObj.toJSON()
    }
    
    /**
     Override init tap event
     
     - parameter type:          UIApplicationContext.EventType
     - parameter methodName:    String
     - parameter viewClassName: String?
     - parameter direction:     String
     - parameter currentScreen: Screen
     
     - returns: TapEvent
     */
    init(view: View, direction: ScrollDirection, currentScreen: Screen) {
        super.init(type: Gesture.GestureEventType.scroll, methodName: nil, view: view, direction: direction.rawValue, currentScreen: currentScreen)
        self.defaultMethodName = "handleScroll:"
    }
}
