//
//  TapEvent.swift
//  SmartTracker
//
//  Created by Nicolas Sagnette on 06/11/2015.
//  Copyright © 2015 AT Internet. All rights reserved.
//

import Foundation

/// class used for manage tap events 
class TapEvent : GestureEvent {
    
    /// X coordinates
    lazy var x: Float = 0
    
    /// Y coordinates
    lazy var y: Float = 0
    
    /// JSON description
    override var description: String {
        let jsonObj: NSMutableDictionary = [
            "event": Gesture.getEventTypeRawValue(self.eventType.rawValue),
            "data":[
                "x":self.x,
                "y":self.y,
                "type": Gesture.getEventTypeRawValue(self.eventType.rawValue),
                "methodName": self.methodName ?? "handleTap:",
                "direction": self.direction,
                "isDefaultMethod": self.methodName == nil,
                "title": self.title ?? "handleTap:"
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
    init(x: Float, y: Float, view: View, direction: String, currentScreen: Screen) {
        super.init(type: Gesture.GestureEventType.Tap, methodName: nil, view: view, direction: direction, currentScreen: currentScreen)
        self.x = x
        self.y = y
    }
}
