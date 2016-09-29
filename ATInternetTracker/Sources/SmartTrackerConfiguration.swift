//
//  SmartTrackerConfiguration.swift
//  ATInternetTracker
//
//  Created by Théo Damaville on 23/09/2016.
//
//

import Foundation

class SmartTrackerConfiguration {
    
    private let ebs = [
        "dev"       : "wss://tag-smartsdk-dev.atinternet-solutions.com/",
        "preprod"   : "wss://tag-smartsdk-preprod.atinternet-solutions.com/",
        "prod"       : "wss://tag-smartsdk.atinternet-solutions.com/"
    ]

    
    private let apiConf = [
        "dev"       : "https://8me4zn67yd.execute-api.eu-west-1.amazonaws.com/dev/token/{token}/version/{version}",
        "preprod"       : "https://8me4zn67yd.execute-api.eu-west-1.amazonaws.com/preprod/token/{token}/version/{version}",
        "prod"           : "https://8me4zn67yd.execute-api.eu-west-1.amazonaws.com/prod/token/{token}/version/{version}",
    ]
    
    private let apiCheck = [
        "dev"          : "https://8me4zn67yd.execute-api.eu-west-1.amazonaws.com/dev/token/{token}/version/{version}/lastUpdate",
        "preprod"       : "https://8me4zn67yd.execute-api.eu-west-1.amazonaws.com/preprod/token/{token}/version/{version}/lastUpdate",
        "prod"           : "https://8me4zn67yd.execute-api.eu-west-1.amazonaws.com/prod/token/{token}/version/{version}/lastUpdate",
    ]

    static let sharedInstance = SmartTrackerConfiguration()
    let env: String
    
    private init() {
        guard let environment = Bundle(for: SmartTrackerConfiguration.self).object(forInfoDictionaryKey: "AT-env") as? String else {
            assert(false, "something went wrong, AT-env is not set")
        }
        env = environment
    }
    
    func getEndPoint(zone: [String: String]) -> String {
        guard let endPoint = zone[env] else {
            assert(false, "no AT-env set in plist")
        }
        
        return endPoint
    }
    
    var ebsEndpoint: String {
        return getEndPoint(zone: ebs)
    }
    
    var apiCheckEndPoint: String {
        return getEndPoint(zone: apiCheck)
    }
    
    var apiConfEndPoint: String {
        return getEndPoint(zone: apiConf)
    }
}
