//
//  PinchEvent.swift
//  SmartTracker
//
//  Created by Nicolas Sagnette on 06/11/2015.
//  Copyright © 2015 AT Internet. All rights reserved.
//

import Foundation

/// class used for manage Pinch events (zooms)
class PinchEvent : GestureEvent {
    
    /**
     Pinch direction
     
     - In:  In
     - Out: Out
     */
    internal enum PinchDirection: String {
        case In  = "in"
        case Out = "out"
    }
    
    /// JSON description
    override var description: String {
        let jsonObj: NSMutableDictionary = [
            "event": Gesture.getEventTypeRawValue(self.eventType.rawValue),
            "data":[
                "x":-1,
                "y":-1,
                "type": Gesture.getEventTypeRawValue(self.eventType.rawValue),
                "methodName": self.methodName ?? "handlePinch:",
                "direction": self.direction,
                "isDefaultMethod": self.methodName == nil,
                "title": self.title ?? "handlePinch:"
            ]
        ]
        let data = jsonObj.objectForKey("data")?.mutableCopy() as! NSMutableDictionary
        data.addEntriesFromDictionary(self.view.description.toJSONObject() as! [NSObject: AnyObject])
        data.addEntriesFromDictionary(self.currentScreen.description.toJSONObject() as! [NSObject: AnyObject])
        jsonObj.setValue(data, forKey: "data")
        
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
    init(view: View, direction: PinchDirection, currentScreen: Screen) {
        super.init(type: Gesture.GestureEventType.Pinch, methodName: nil, view: view, direction: direction.rawValue, currentScreen: currentScreen)
    }
}
