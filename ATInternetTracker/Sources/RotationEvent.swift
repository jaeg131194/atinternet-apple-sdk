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
        var jsonObj: [String: Any] = [
            "event": Gesture.getEventTypeRawValue(self.eventType.rawValue),
            "data":[
                "x":-1,
                "y":-1,
                "type": Gesture.getEventTypeRawValue(self.eventType.rawValue),
                "methodName": self.methodName,
                "direction": self.direction,
                "isDefaultMethod": self._methodName == nil,
                "title": self.title ?? defaultMethodName
            ]
        ]
        
        var data: [String: Any] = jsonObj["data"] as! [String: Any]
        data.append(self.view.toJSONObject)
        data.append(self.currentScreen.toJSONObject)
        jsonObj.updateValue(data, forKey: "data")
        
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
        super.init(type: Gesture.GestureEventType.rotate, methodName: nil, view: view, direction: direction.rawValue, currentScreen: currentScreen)
        self.defaultMethodName = "handleRotation:"
    }
}
