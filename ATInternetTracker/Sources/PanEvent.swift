//
//  PanEvent.swift
//  SmartTracker
//
//  Created by Nicolas Sagnette on 06/11/2015.
//  Copyright © 2015 AT Internet. All rights reserved.
//

import Foundation

/// class to store Pan gesture Events
class PanEvent : GestureEvent {
    
    enum PanDirection: String {
        case Left  = "left"
        case Right = "right"
        case Up = "up"
        case Down = "down"
    }
    
    /// JSON description
    override var description: String {
        let jsonObj: NSMutableDictionary = [
            "event": Gesture.getEventTypeRawValue(self.eventType.rawValue),
            "data":[
                "x":-1,
                "y":-1,
                "type": Gesture.getEventTypeRawValue(self.eventType.rawValue),
                "methodName": self.methodName ?? "handlePan:",
                "direction": self.direction,
                "isDefaultMethod": self.methodName == nil ,
                "title": self.title ?? "handlePan:"
            ]
        ]
        let data = jsonObj.objectForKey("data")?.mutableCopy() as! NSMutableDictionary
        data.addEntriesFromDictionary(self.view.description.toJSONObject() as! [NSObject: AnyObject])
        data.addEntriesFromDictionary(self.currentScreen.description.toJSONObject() as! [NSObject: AnyObject])
        jsonObj.setValue(data, forKey: "data")
        
        return jsonObj.toJSON()
    }
    
    /**
     Override init pan event
     
     - parameter type:          UIApplicationContext.EventType
     - parameter methodName:    String
     - parameter viewClassName: String?
     - parameter direction:     String
     - parameter currentScreen: Screen
     
     - returns: TapEvent
     */
    init(view: View, direction: PanDirection, currentScreen: Screen) {
        super.init(type: Gesture.GestureEventType.Pan, methodName: nil, view: view, direction: direction.rawValue, currentScreen: currentScreen)
    }
}
