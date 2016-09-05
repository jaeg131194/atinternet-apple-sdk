//
//  RotationEvent.swift
//  SmartTracker
//
//  Created by Théo Damaville on 13/11/2015.
//  Copyright © 2015 AT Internet. All rights reserved.
//

import Foundation
import UIKit

/// Object used for manage screen rotation events. Note that face up and face down are ignored at runtime
class DeviceRotationEvent {
    /// Method called by the touched UIView
    lazy var methodName = "rotate"
    
    /// A description of the gesture
    var orientation: UIDeviceOrientation
    
    weak var viewController: UIViewController?
    
    /// current screen
    lazy var currentScreen: Screen = Screen()
    
    lazy var eventType: Gesture.GestureEventType = Gesture.GestureEventType.rotate
    
    /// JSON description
    var description: String {
        var jsonObj: [String: Any] = [
            "event": "deviceRotation",
            "data":[
                "name": self.currentScreen.name,
                "type" : Gesture.getEventTypeRawValue(self.eventType.rawValue),
                "className": self.currentScreen.className,
                "methodName": self.methodName,
                "direction": self.orientation.rawValue,
                "triggeredBy": ""
            ]
        ]
        
        var data = jsonObj["data"] as! [String: Any]
        data.append(self.currentScreen.toJSONObject)
        jsonObj.updateValue(data, forKey: "data")

        return jsonObj.toJSON()
    }
    
    /**
     RotationEvent init
     
     - parameter orientation: device orientation
     
     - returns: RotationEvent
     */
    init(orientation: UIDeviceOrientation) {
        self.orientation = orientation
    }
}
