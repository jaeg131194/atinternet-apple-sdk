//
//  ScreenEvent.swift
//  SmartTracker
//
//  Created by Théo Damaville on 05/11/2015.
//  Copyright © 2015 AT Internet. All rights reserved.
//

import Foundation
import UIKit

/// Class that represent a ScreenEvent (screen apparition)
class ScreenEvent: CustomStringConvertible {
    
    lazy var screen: Screen = Screen()
    
    /// The origin method that created this event
    var methodName: String
    
    /// A description of the event on the screen
    var direction: String
    
    /// the general event type
    let type: String = "screen"
    
    /// Event that made the view controller appear
    var triggeredBy: GestureEvent?
    
    /// View controller of the screen
    weak var viewController: UIViewController?
    
    /// JSON representation of the event
    var description: String {
        var jsonObj: [String: Any] = [
            "event": self.methodName,
            "data":[
                "type" : self.type,
                "methodName": self.methodName,
                "direction": self.direction,
                "triggeredBy":self.triggeredBy?.description.toJSONObject() ?? ""
            ]
        ]
        
        var data = jsonObj["data"] as! [String: Any]
        data.append(self.screen.toJSONObject)
        jsonObj.updateValue(data, forKey: "data")
        
        return jsonObj.toJSON()
    }
    
    // Maj s8: suppression de title - on utilise screen.className a la place
    convenience init(title: String, className: String, triggeredBy: GestureEvent?) {
        self.init(title: title, methodName: "viewDidAppear", className: className, direction: "appear", triggeredBy: triggeredBy)
    }
    
    /**
     create a new screen event
     
     - parameter title:      Title of the screen
     - parameter methodName: Name of the method that triggered the new screen event
     - parameter className:  Name of the uiviewcontroller class
     - parameter direction:  Direction of the event (appear)
     
     - returns: A new ScreenEvent object
     */
    init(title: String, methodName: String, className: String, direction: String, triggeredBy: GestureEvent?) {
        self.methodName = methodName
        self.direction = direction
        self.screen.name = title
        self.screen.className = className
        self.triggeredBy = triggeredBy
    }
}
