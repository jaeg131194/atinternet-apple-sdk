//
//  App.swift
//  SmartTracker
//
//  Created by Théo Damaville on 16/12/2015.
//  Copyright © 2015 AT Internet. All rights reserved.
//

import Foundation

class App {
    static var token: String? = ATInternet.sharedInstance.defaultTracker.token
    
    var toJSONObject: [String: Any] {
        let s = Screen()
        let jsonObj: [String: Any] = [
            "event":"app",
            "data" :[
                "appIcon": TechnicalContext.applicationIcon ?? "",
                "version": TechnicalContext.applicationVersion.isEmpty ? "" : TechnicalContext.applicationVersion,
                "device" : TechnicalContext.device.isEmpty ? "" : TechnicalContext.device,
                "token" : App.token ?? "",
                "package" : TechnicalContext.applicationIdentifier,
                "platform":"ios",
                "title": TechnicalContext.applicationName,
                "width": s.width,
                "height": s.height,
                "scale": s.scale,
                "screenOrientation": s.orientation,
                "siteID": ATInternet.sharedInstance.defaultTracker.configuration.parameters["site"]!,
                "name": UIDevice.current.name
            ]
        ]
        return jsonObj
    }
    
    var description: String {
        return self.toJSONObject.toJSON()
    }
    
    init() {}
}
