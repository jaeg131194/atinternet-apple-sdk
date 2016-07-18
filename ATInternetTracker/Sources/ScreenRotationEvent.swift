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
class ScreenRotationEvent {
    /// Method called by the touched UIView
    lazy var methodName = "rotate"
    
    /// A description of the gesture
    var orientation: UIDeviceOrientation
    
    /// current screen
    lazy var currentScreen: Screen = Screen()
    
    /// the general event type
    let type: String = "screen"
    
    /// JSON description
    var description: String {
        let jsonObj: NSMutableDictionary = [
            "event": "screenRotation",
            "data":[
                "name": self.currentScreen.name,
                "type" : self.type,
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