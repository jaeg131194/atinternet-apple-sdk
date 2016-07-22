//
//  ScreenshotEvent.swift
//  SmartTracker
//
//  Created by Théo Damaville on 14/04/2016.
//  Copyright © 2016 AT Internet. All rights reserved.
//

import Foundation

/// ScreenshotEvent - this class handle the screenshot of a screen and the event detected in the screen to display them as *suggested*
class ScreenshotEvent: CustomStringConvertible {
    /// Default method name
    let methodName = "screenshot"
    /// the screen associated
    let screen: Screen
    /// Base64 Screenshot - can be a hardcoded one if we detect that the screenshot is broken
    let screenshot: String?
    /// the suggested events on the screen
    let suggestedEvents: [AnyObject]
    
    /// JSON formatting
    var description:String {
        let jsonObj:NSMutableDictionary = [
            "event": self.methodName,
            "data":[
                "screenshot":screenshot ?? "",
                "siteID": ATInternet.sharedInstance.defaultTracker.configuration.parameters["site"]!
            ]
        ]
        
        let data = jsonObj.objectForKey("data")?.mutableCopy() as! NSMutableDictionary
        data.addEntriesFromDictionary(self.screen.description.toJSONObject() as! [NSObject: AnyObject])
        data.setValue(suggestedEvents, forKey: "tree")
        jsonObj.setValue(data, forKey: "data")
        return jsonObj.toJSON()
    }
    
    /**
     Init a screenshot event
     
     - parameter screen:          the screen to be screened
     - parameter screenshot:      the screenshot associated with the screen
     - parameter suggestedEvents: the suggested events on the screen
     
     - returns: the ScreenshotEvent
     */
    init(screen: Screen, screenshot: String?, suggestedEvents: [AnyObject]) {
        self.screen = screen
        self.screenshot = screenshot
        self.suggestedEvents = suggestedEvents
    }
}