//
// Created by Théo Damaville on 19/02/2016.
// Copyright (c) 2016 AT Internet. All rights reserved.
//

import Foundation
import UIKit

/// Mostly static messages for the websocket

/// Device ask for a live
class DeviceAskingForLive {
    var description: String {
        let askForLive: NSMutableDictionary = [
            "event": "DeviceAskedForLive",
            "data": [
                "token": ATInternet.sharedInstance.defaultTracker.token ?? "0",
                "name" : UIDevice.currentDevice().name
            ]
        ]
        return askForLive.toJSON()
    }
}

/// Device refuse a live
class DeviceRefusedLive {
    var description: String {
        let deviceRefusedLive: NSMutableDictionary = [
            "event": "DeviceRefusedLive",
            "data": [
                "token": ATInternet.sharedInstance.defaultTracker.token ?? "0"
            ]
        ]
        return deviceRefusedLive.toJSON()
    }
}

/// Device abort a live
class DeviceAbortedLiveRequest {
    var description: String {
        let deviceAbortedLiveRequest: NSMutableDictionary = [
            "event": "DeviceAbortedLiveRequest",
            "data": [
                "token": ATInternet.sharedInstance.defaultTracker.token ?? "0"
            ]
        ]
        return deviceAbortedLiveRequest.toJSON()
    }
}

/// Device stop a live
class DeviceStoppedLive {
    var description: String {
        let deviceStoppedLive: NSMutableDictionary = [
            "event": "DeviceStoppedLive",
            "data": [
                "token": ATInternet.sharedInstance.defaultTracker.token ?? "0"
            ]
        ]
        return deviceStoppedLive.toJSON()
    }
}

/// Device accept the live
class DeviceAcceptedLive {
    var description: String {
        let deviceAcceptedLive: NSMutableDictionary = [
            "event": "DeviceAcceptedLive",
            "data": [
                "token": ATInternet.sharedInstance.defaultTracker.token ?? "0"
            ]
        ]
        return deviceAcceptedLive.toJSON()
    }
}

/// Send a fresh screenshot for the current screen
class ScreenshotUpdated {
    let screenshot:String
    let currentScreen: Screen
    
    init(screenshot: String?, screen: Screen) {
        assert(screenshot != nil)
        self.screenshot = screenshot ?? ""
        self.currentScreen = screen
    }
    
    var description: String {
        let refreshScreenshot: NSMutableDictionary = [
            "event": "ScreenshotUpdated",
            "data": [
                "screenshot":self.screenshot,
                "siteID": ATInternet.sharedInstance.defaultTracker.configuration.parameters["site"]!
            ]
        ]
        let data = refreshScreenshot.objectForKey("data")?.mutableCopy() as! NSMutableDictionary
        data.addEntriesFromDictionary(self.currentScreen.description.toJSONObject() as! [NSObject: AnyObject])
        refreshScreenshot.setValue(data, forKey: "data")
        return refreshScreenshot.toJSON()
    }
}