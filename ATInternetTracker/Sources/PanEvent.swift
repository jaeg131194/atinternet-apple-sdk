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
    
    /**
     Generic pan moves
     
     - Left:  left
     - Right: right
     - Up:    up
     - Down:  down
     */
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
                "methodName": self.methodName ?? defaultMethodName,
                "direction": self.direction,
                "isDefaultMethod": self.methodName == nil ,
                "title": self.title ?? defaultMethodName
            ]
        ]
        let data = jsonObj.objectForKey("data")?.mutableCopy() as! NSMutableDictionary
        data.addEntriesFromDictionary(self.view.description.toJSONObject() as! [NSObject: AnyObject])
        data.addEntriesFromDictionary(self.currentScreen.description.toJSONObject() as! [NSObject: AnyObject])
        jsonObj.setValue(data, forKey: "data")
        
        return jsonObj.toJSON()
    }
    
    /**
     Init a Pan Event
     
     - parameter view:          a View where the pan was detected
     - parameter direction:     the direction of the pan event
     - parameter currentScreen: the screen where the pan occured
     
     - returns: a PanEvent
     */
    init(view: View, direction: PanDirection, currentScreen: Screen) {
        super.init(type: Gesture.GestureEventType.Pan, methodName: nil, view: view, direction: direction.rawValue, currentScreen: currentScreen)
        self.defaultMethodName = "handlePan:"
    }
}
