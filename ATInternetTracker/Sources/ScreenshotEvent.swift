//
//  ScreenshotEvent.swift
//  SmartTracker
//
//  Created by Théo Damaville on 14/04/2016.
//  Copyright © 2016 AT Internet. All rights reserved.
//

import Foundation

class ScreenshotEvent: CustomStringConvertible {
    let methodName = "screenshot"
    let screen: Screen
    let screenshot: String?
    let suggestedEvents: [AnyObject]
    
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
    
    init(screen: Screen, screenshot: String?, suggestedEvents: [AnyObject]){
        self.screen = screen
        self.screenshot = screenshot
        self.suggestedEvents = suggestedEvents
    }
}