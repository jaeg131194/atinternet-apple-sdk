//
//  ApiS3.swift
//  Tracker
//
//  Created by Théo Damaville on 21/06/2016.
//  Copyright © 2016 AT Internet. All rights reserved.
//

import Foundation


typealias MappingRequest = (url: URL, onLoaded: (JSON?) -> (), onError: () -> ())
/**
 *  Simple storage protocol
 */
protocol SimpleStorageProtocol {
    /**
     Get an object by his name
     
     - parameter name: the name of the object
     
     - returns: the object or nil
     */
    func getByName(_ name: String) -> Any?
    /**
     Save an object by his name
     
     - parameter config: the object
     - parameter name:   the name of the object
     
     - returns: true if success
     */
    func saveByName(_ config: Any, name: String) -> Bool
}

/// Simple storage impl with UserDefault
class UserDefaultSimpleStorage: SimpleStorageProtocol {
    /**
     get from user default
     
     - parameter name: a name
     
     - returns: the object
     */
    func getByName(_ name: String) -> Any? {
        let userDefault = UserDefaults.standard
        return userDefault.object(forKey: name)
    }
    
    /**
     save to user default
     
     - parameter config: an object
     - parameter name:   the name
     
     - returns: true if success
     */
    func saveByName(_ config: Any, name: String) -> Bool {
        let userDefault = UserDefaults.standard
        userDefault.set(config, forKey: name)
        return true
    }
}

/**
 *  Light network service interface for JSON download
 */
protocol SimpleNetworkService {
    /**
     Simple Network Service protocol
     
     - parameter url:        url of the ressource
     - parameter onLoaded:   callback when loaded
     - parameter onError:    callback if an error is detected
     - parameter retryCount: retrycount if error
     */
    func getURL(_ request: MappingRequest, retryCount: Int)
}

/// Light network service impl with error handling
class S3NetworkService: SimpleNetworkService {
    
    /// retry wrapper for getURL
    func retry( _ f: (MappingRequest, Int) -> (), request: MappingRequest, retryCount: Int) -> () {
        if retryCount >= 0 {
            sleep(3+arc4random_uniform(5))
            f((request.url, request.onLoaded, request.onError), retryCount)
        } else {
            request.onError()
        }
    }
    
    func getURL(_ request: MappingRequest, retryCount: Int) {
        var urlRequest = URLRequest(url: request.url, cachePolicy: URLRequest.CachePolicy.reloadIgnoringLocalCacheData, timeoutInterval: 30)
        urlRequest.httpMethod = "GET"
        
        let session = URLSession.shared
        let task = session.dataTask(with: urlRequest) { (data, urlResponse, err) in
            if let _ = err {
                self.retry(self.getURL, request: (url: request.url, onLoaded: request.onLoaded, onError: request.onError), retryCount: retryCount-1)
            }
            if let jsonData = data {
                let res = JSON(data: jsonData)
                if res["type"] >= 500 {
                    self.retry(self.getURL, request: (url: request.url, onLoaded: request.onLoaded, onError: request.onError), retryCount: retryCount-1)
                }
                else if res["type"] >= 400 {
                    request.onError()
                }
                else {
                    request.onLoaded(res)
                }
            }
        }
        task.resume()
        
        /*
        NSURLConnection.sendAsynchronousRequest(urlRequest, queue: OperationQueue()) { (r, data, err) in
            if let _ = err {
                self.retry(self.getURL, request: (url: request.url, onLoaded: request.onLoaded, onError: request.onError), retryCount: retryCount-1)
            }
            if let jsonData = data {
                let res = JSON(data: jsonData)
                if res["type"] >= 500 {
                    self.retry(self.getURL, request: (url: request.url, onLoaded: request.onLoaded, onError: request.onError), retryCount: retryCount-1)
                }
                else if res["type"] >= 400 {
                    request.onError()
                }
                else {
                    request.onLoaded(res)
                }
            }
        }*/
        
    }
}

/// Class handling the  loading of the LiveTagging configuration file
class ApiS3Client {
    let S3URL = "https://8me4zn67yd.execute-api.eu-west-1.amazonaws.com/dev/token/{token}/version/{version}"
    let S3URLCheck = "https://8me4zn67yd.execute-api.eu-west-1.amazonaws.com/dev/token/{token}/version/{version}/lastUpdate"
    let store: SimpleStorageProtocol
    let network: SimpleNetworkService
    let token: String
    let version: String

    init(token: String, version: String, store: SimpleStorageProtocol, networkService: SimpleNetworkService) {
        self.token = token
        self.version = version
        self.store = store
        self.network = networkService
    }

    /**
     get the livetagging configuration mapping url
     
     - returns: the correct url
     */
    func getMappingURL() -> URL {
        return URL(string:S3URL
            .replacingOccurrences(of: "{token}", with: self.token)
            .replacingOccurrences(of: "{version}", with: self.version)
        )!
    }
    
    /**
     get the check url
     
     - returns: the url
     */
    fileprivate func getCheckURL() -> URL {
        return URL(string:S3URLCheck
            .replacingOccurrences(of: "{token}", with: self.token)
            .replacingOccurrences(of: "{version}", with: self.version)
        )!
    }

    func fetchSmartSDKMapping(_ onLoaded: @escaping (JSON?) -> (), onError: @escaping () -> ()) {
        network.getURL((getMappingURL(), onLoaded: onLoaded, onError: onError), retryCount: 5)
    }

    /**
     save the config
     
     - parameter mapping: the config
     */
    func saveSmartSDKMapping(_ mapping: JSON) {
        _ = store.saveByName(mapping.object, name: "at_smartsdk_config")
    }
    
    /**
     get the config
     
     - returns: the config
     */
    fileprivate func getSmartSDKMapping() -> JSON? {
        let jsonObj = store.getByName("at_smartsdk_config")
        if let obj = jsonObj {
            return JSON(obj)
        }
        return nil
    }
    
    /**
     get the checksum - actually it's a timestamp used to know if we need to fetch the configuration or not
     
     - parameter callback: the checksum
     */
    fileprivate func fetchCheckSum(_ callback: @escaping (JSON?) -> ()) {
        
        func err() -> () {
            callback(nil)
        }
        
        network.getURL((getCheckURL(), onLoaded: callback, onError: err), retryCount: 1)
    }
    
    /**
     Main method - get the most recent configuration from the network/cache
     
     - parameter callback: the configuration
     */
    func fetchMapping(_ callback: @escaping (JSON?) -> ()) {
        func getRemoteMapping(_ callback: @escaping (JSON?) -> ()) {
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
