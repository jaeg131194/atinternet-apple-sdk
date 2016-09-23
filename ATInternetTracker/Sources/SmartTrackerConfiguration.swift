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
        "dev"       : "ws://tag-smartsdk-dev.eu-west-1.elasticbeanstalk.com:5000/",
        "preprod"   : "-",
        "prod"       : "-"
    ]

    
    private let apiConf = [
        "dev"       : "https://8me4zn67yd.execute-api.eu-west-1.amazonaws.com/dev/token/{token}/version/{version}",
        "preprod"       : "-",
        "prod"           : "-",
    ]
    
    private let apiCheck = [
        "dev"          : "https://8me4zn67yd.execute-api.eu-west-1.amazonaws.com/dev/token/{token}/version/{version}/lastUpdate",
        "preprod"       : "-",
        "prod"           : "-",
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
