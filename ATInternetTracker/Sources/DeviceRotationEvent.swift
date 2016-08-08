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
    
    lazy var eventType: Gesture.GestureEventType = Gesture.GestureEventType.Rotate
    
    /// JSON description
    var description: String {
        let jsonObj: NSMutableDictionary = [
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
        let data = jsonObj.objectForKey("data")?.mutableCopy() as! NSMutableDictionary
        data.addEntriesFromDictionary(self.currentScreen.description.toJSONObject() as! [NSObject: AnyObject])
        jsonObj.setValue(data, forKey: "data")
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