//
//  ApiS3.swift
//  Tracker
//
//  Created by Théo Damaville on 21/06/2016.
//  Copyright © 2016 AT Internet. All rights reserved.
//

import Foundation

/**
 *  Simple storage for the config interface
 */
protocol SimpleStorageProtocol {
    func getByName(name: String) -> AnyObject?
    func saveByName(config: AnyObject, name: String) -> Bool
}

/// Simple storage impl
class UserDefaultSimpleStorage: SimpleStorageProtocol {
    
    func getByName(name: String) -> AnyObject? {
        let userDefault = NSUserDefaults.standardUserDefaults()
        return userDefault.objectForKey(name)
    }
    
    func saveByName(config: AnyObject, name: String) -> Bool {
        let userDefault = NSUserDefaults.standardUserDefaults()
        userDefault.setObject(config, forKey: name)
        return true
    }
}

/**
 *  Light network service interface for JSON download
 */
protocol SimpleNetworkService {
    func getURL(url: NSURL, onLoaded: (JSON?) -> (), onError: () -> (), retryCount: Int)
}

/// Light network service impl with error handling
class S3NetworkService: SimpleNetworkService {
    
    func retry( f: (NSURL, (JSON?) -> (), () -> (), Int) -> (), url: NSURL, onLoaded: (JSON?) -> (), onError: () -> (), retryCount: Int) -> () {
        if retryCount >= 0 {
            print("retrying... remaining:\(retryCount)")
            sleep(5)
            f(url, onLoaded, onError, retryCount)
        } else {
            onError()
        }
    }
    
    func getURL(url: NSURL, onLoaded: (JSON?) -> (), onError: () -> (), retryCount: Int) {
        print(url.absoluteString)
        let request = NSMutableURLRequest(URL: url, cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData, timeoutInterval: 30)
        request.HTTPMethod = "GET"
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue()) { (r: NSURLResponse?, data: NSData?, err: NSError?) in
            if let _ = err {
                self.retry(self.getURL, url: url, onLoaded: onLoaded, onError: onError, retryCount: retryCount-1)
            }
            if let jsonData = data {
                let res = JSON(data: jsonData)
                if res["type"] >= 500 {
                    self.retry(self.getURL, url: url, onLoaded: onLoaded, onError: onError, retryCount: retryCount-1)
                }
                else if res["type"] >= 400 {
                    onError()
                }
                else {
                    onLoaded(res)
                }
            }
        }
    }
}

class ApiS3Client {
    let S3URL = "https://rtmofuf655.execute-api.eu-west-1.amazonaws.com/dev/siteID/{siteID}/token/{token}/version/{version}"
    let S3URLCheck = "https://rtmofuf655.execute-api.eu-west-1.amazonaws.com/dev/siteID/{siteID}/token/{token}/version/{version}/lastupdate"
    //var config: JSON?
    let store: SimpleStorageProtocol
    let network: SimpleNetworkService
    let token: String
    let version: String
    let siteID: String

    init(siteID: String, token: String, version: String, store: SimpleStorageProtocol, networkService: SimpleNetworkService) {
        self.siteID = siteID
        self.token = token
        self.version = version
        self.store = store
        self.network = networkService
    }

    func getMappingURL() -> NSURL {
        return NSURL(string:S3URL
            .stringByReplacingOccurrencesOfString("{siteID}", withString: self.siteID)
            .stringByReplacingOccurrencesOfString("{token}", withString: self.token)
            .stringByReplacingOccurrencesOfString("{version}", withString: self.version)
        )!
    }
    
    private func getCheckURL() -> NSURL {
        return NSURL(string:S3URLCheck
            .stringByReplacingOccurrencesOfString("{siteID}", withString: self.siteID)
            .stringByReplacingOccurrencesOfString("{token}", withString: self.token)
            .stringByReplacingOccurrencesOfString("{version}", withString: self.version)
        )!
    }

    func fetchSmartSDKMapping(onLoaded: (JSON?) -> (), onError: () -> ()) {
        network.getURL(getMappingURL(), onLoaded: onLoaded, onError: onError, retryCount: 5)
    }

    func saveSmartSDKMapping(mapping: JSON) {
        store.saveByName(mapping.object, name: "at_smartsdk_config")
    }
    
    private func getSmartSDKMapping() -> JSON? {
        let jsonObj = store.getByName("at_smartsdk_config")
        if let obj = jsonObj {
            let o = JSON(obj)
            print(o)
            return JSON(obj)
        }
        return nil
    }
    
    private func fetchCheckSum(callback: (JSON?) -> ()) {
        network.getURL(getCheckURL(), onLoaded: callback, onError: {}, retryCount: 1)
    }
    
    func fetchMapping(callback: (JSON?) -> ()) {
        func getRemoteMapping(callback: (JSON?) -> ()) {
            self.fetchSmartSDKMapping({ (mapping: JSON?) in
                callback(mapping)
                }, onError: {
                    callback(nil)
            })
        }
        
        if let localMapping = getSmartSDKMapping() {
            let localTimestamp = localMapping["timestamp"].intValue
            fetchCheckSum({ (remote: JSON?) in
                if remote == nil || remote!["timestamp"].intValue != localTimestamp {
                    getRemoteMapping(callback)
                } else {
                    callback(localMapping)
                }
            })
        } else {
            getRemoteMapping(callback)
        }
    }
}