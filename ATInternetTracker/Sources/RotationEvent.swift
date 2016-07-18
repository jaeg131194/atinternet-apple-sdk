//
//  RotationEvent.swift
//  SmartTracker
//
//  Created by Xavier BELLENGER on 20/11/2015.
//  Copyright © 2015 AT Internet. All rights reserved.
//

//
//  SwipeEvent.swift
//  SmartTracker
//
//  Created by Nicolas Sagnette on 06/11/2015.
//  Copyright © 2015 AT Internet. All rights reserved.
//

import Foundation

/// class used for managing rotation events
class RotationEvent : GestureEvent {
    
    /**
     Rotation direction
     
     - Clockwise:  Clockwise
     - CounterClockwise: CounterClockwise
     */
    enum RotationDirection: String {
        case Clockwise  = "clockwise"
        case CounterClockwise = "counter-clockwise"
    }
    
    /// JSON description
    override var description: String {
        let jsonObj: NSMutableDictionary = [
            "event": Gesture.getEventTypeRawValue(self.eventType.rawValue),
            "data":[
                "x":-1,
                "y":-1,
                "type": Gesture.getEventTypeRawValue(self.eventType.rawValue),
                "methodName": self.methodName ?? "handleRotation:",
                "direction": self.direction,
                "isDefaultMethod": self.methodName == nil,
                "title": self.title ?? "handleRotation:"
            ]
        ]
        let data = jsonObj.objectForKey("data")?.mutableCopy() as! NSMutableDictionary
        data.addEntriesFromDictionary(self.view.description.toJSONObject() as! [NSObject: AnyObject])
        data.addEntriesFromDictionary(self.currentScreen.description.toJSONObject() as! [NSObject: AnyObject])
        jsonObj.setValue(data, forKey: "data")
        
        return jsonObj.toJSON()
    }
    
    /**
     Override init rotation event
     
     - parameter type:          UIApplicationContext.EventType
     - parameter methodName:    String
     - parameter viewClassName: String?
     - parameter direction:     String
     - parameter currentScreen: Screen
     
     - returns: RotationEvent
     */
    init(view: View, direction: RotationDirection, currentScreen: Screen) {
        super.init(type: Gesture.GestureEventType.Rotate, methodName: nil, view: view, direction: direction.rawValue, currentScreen: currentScreen)
    }
}
