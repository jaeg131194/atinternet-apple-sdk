//
//  RefreshEvent.swift
//  SmartTracker
//
//  Created by Nicolas Sagnette on 06/11/2015.
//  Copyright © 2015 AT Internet. All rights reserved.
//

import Foundation

/// class used for manage swipe events
class RefreshEvent : GestureEvent {
    
    
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
     
     - parameter viewClassName: String?
     - parameter currentScreen: Screen
     
     - returns: TapEvent
     */
    init(method: String?, view: View, currentScreen: Screen) {
        super.init(type: Gesture.GestureEventType.refresh, methodName: method, view: view, direction: "down", currentScreen: currentScreen)
        self.defaultMethodName = "handleRefresh:"
        self.view.position = -1
    }
}
