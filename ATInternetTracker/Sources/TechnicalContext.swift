/*
This SDK is licensed under the MIT license (MIT)
Copyright (c) 2015- Applied Technologies Internet SAS (registration number B 403 261 258 - Trade and Companies Register of Bordeaux – France)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/





//
//  TechnicalContext.swift
//  Tracker
//
#if os(iOS)
import CoreTelephony
#endif

#if os(watchOS)
import WatchKit
#else
import UIKit
#endif

    
/// Contextual information from user device
class TechnicalContext: NSObject {
    
    enum ConnexionType: String {
        case
        offline = "offline",
        gprs = "gprs",
        edge = "edge",
        twog = "2g",
        threeg = "3g",
        threegplus = "3g+",
        fourg = "4g",
        wifi = "wifi",
        unknown = "unknown"
    }
    
    /// Name of the last tracked screen
    static var screenName: String = ""
    /// ID of the last level2 id set in parameters
    static var level2: Int = 0
    
    /// Enable or disable tracking
    class var doNotTrack: Bool {
        get {
            let userDefaults = UserDefaults.standard
            
            if (userDefaults.object(forKey: "ATDoNotTrack") == nil) {
                return false
            } else {
                return userDefaults.bool(forKey: "ATDoNotTrack")
            }
        } set {
            let userDefaults = UserDefaults.standard
            userDefaults.set(newValue, forKey: "ATDoNotTrack")
            userDefaults.synchronize()
        }
    }
    
    
    
    /// Unique user id
    class func userId(_ identifier: String?) -> String {
        
        if(!self.doNotTrack) {
            
            let uuid: () -> String = {
                if UserDefaults.standard.object(forKey: "ATIdclient") != nil {
                    return UserDefaults.standard.object(forKey: "ATIdclient") as! String
                } else if UserDefaults.standard.object(forKey: "ATApplicationUniqueIdentifier") == nil {
                    let UUID = Foundation.UUID().uuidString
                    UserDefaults.standard.set(UUID, forKey: "ATApplicationUniqueIdentifier")
                    UserDefaults.standard.synchronize()
                    return UUID
                } else {
                    return UserDefaults.standard.object(forKey: "ATApplicationUniqueIdentifier") as! String
                }
            }
            
            let idfa: () -> String = {
                var idfa: String = ""
                
                if let ASIdentifierManagerClass = NSClassFromString("ASIdentifierManager") {
                    let sharedManagerSelector = NSSelectorFromString("sharedManager")
                    if let sharedManagerIMP = ASIdentifierManagerClass.method(for: sharedManagerSelector) {
                        typealias sharedManagerCType = @convention(c) (AnyObject, Selector) -> AnyObject!
                        let getSharedManager = unsafeBitCast(sharedManagerIMP, to: sharedManagerCType.self)
                        if let sharedManager = getSharedManager(ASIdentifierManagerClass.self, sharedManagerSelector) {
                            let advertisingTrackingEnabledSelector = NSSelectorFromString("isAdvertisingTrackingEnabled")
                            if let isTrackingEnabledIMP = sharedManager.method(for: advertisingTrackingEnabledSelector) {
                                typealias isTrackingEnabledCType = @convention(c) (AnyObject, Selector) -> Bool
                                let getIsTrackingEnabled = unsafeBitCast(isTrackingEnabledIMP, to: isTrackingEnabledCType.self)
                                let isTrackingEnabled = getIsTrackingEnabled(self, advertisingTrackingEnabledSelector)
                                if isTrackingEnabled {
                                    let advertisingIdentifierSelector = NSSelectorFromString("advertisingIdentifier")
                                    if let advertisingIdentifierIMP = sharedManager.method(for: advertisingIdentifierSelector) {
                                        typealias adIdentifierCType = @convention(c) (AnyObject, Selector) -> NSUUID
                                        let getIdfa = unsafeBitCast(advertisingIdentifierIMP, to: adIdentifierCType.self)
                                        idfa = getIdfa(self, advertisingIdentifierSelector).uuidString
                                    }
                                } else {
                                    return "opt-out"
                                }
                            }
                        }
                    }
                }
                return idfa
            }
            
            if let optIdentifier = identifier {
                #if !os(watchOS)
                switch(optIdentifier.lowercased())
                {
                case "idfv":
                    return UIDevice.current.identifierForVendor!.uuidString
                case "idfa":
                    return idfa()
                default:
                    return uuid()
                }
                #else
                    return uuid()
                #endif
            } else {
                return uuid()
            }
            
        } else {
            
            return "opt-out"
            
        }
        
    }
    
    /// SDK Version
    class var sdkVersion: String {
        get {
            if let optInfoDic = Bundle(for: Tracker.self).infoDictionary {
                return optInfoDic["CFBundleShortVersionString"] as! String
            } else {
                return ""
            }
        }
    }
    
    /// Device language (eg. en_US)
    class var language: String {
        get {
            return Locale.autoupdatingCurrent.identifier.lowercased()
        }
    }
    
    /// Device type (eg. iphone3,1)
    class var device: String {
        get {
            var size : Int = 0
            sysctlbyname("hw.machine", nil, &size, nil, 0)
            var machine = [CChar](repeating: 0, count: Int(size))
            sysctlbyname("hw.machine", &machine, &size, nil, 0)
            return String(format: "%@", String.init(cString: machine).lowercased())
        }
    }
    
    /// Device OS (name + version)
    class var operatingSystem: String {
        get {
            #if os(watchOS)
            return String(format: "[%@]-[%@]", WKInterfaceDevice.current().systemName.removeSpaces().lowercased(), WKInterfaceDevice.current().systemVersion)
            #else
            return String(format: "[%@]-[%@]", UIDevice.current.systemName.removeSpaces().lowercased(), UIDevice.current.systemVersion)
            #endif
        }
    }
    
    /// Application localized name
    class var applicationName: String {
        get {
            let name = Bundle.main.infoDictionary!["CFBundleDisplayName"] as? String
            
            if let optName = name {
                return optName
            } else {
                
                if let localizedDic = Bundle.main.localizedInfoDictionary {
                    let localizedName = localizedDic["CFBundleDisplayName"] as? String
                    
                    if let optLocalizedName = localizedName {
                        return optLocalizedName
                    }
                }
            }
            
            return TechnicalContext.applicationIdentifier
        }
    }
    
    #if os(iOS) && AT_SMART_TRACKER
    /// Application icon
    class var applicationIcon: String? {
        let iconImg = UIImage(named: "AppIcon60x60")
        return iconImg?.toBase64()?.replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "\r", with: "")
    }
    #endif
    
    /// Application identifier (eg. com.atinternet.testapp)
    class var applicationIdentifier: String {
        get {
            let identifier = Bundle.main.infoDictionary!["CFBundleIdentifier"] as? String
            
            if let optIdentifier = identifier {
                return String(format:"%@", optIdentifier)
            } else {
                return ""
            }
        }
    }
    
    /// Application version (eg. [5.0])
    class var applicationVersion: String {
        get {
            let version = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String
            
            if let optVersion = version {
                return String(format:"%@", optVersion)
            } else {
                return ""
            }
        }
    }
    
    /// Local hour (eg. 23x59x59)
    class var localHour: String {
        get {
            let hourFormatter = DateFormatter()
            hourFormatter.locale = LifeCycle.locale
            hourFormatter.dateFormat = "HH'x'mm'x'ss"
            
            return hourFormatter.string(from: Date())
        }
    }
    
    /// Screen resolution (eg. 1024x768)
    class var screenResolution: String {
        get {
            #if os(watchOS)
            let screenBounds = WKInterfaceDevice.current().screenBounds
            let screenScale = WKInterfaceDevice.current().screenScale
            #else
            let screenBounds = UIScreen.main.bounds
            let screenScale = UIScreen.main.scale
            #endif
                
            return String(format:"%ix%i", Int(screenBounds.size.width * screenScale), Int(screenBounds.size.height * screenScale))
        }
    }
    
    #if os(iOS)
    /// Carrier
    class var carrier: String {
        get {
            let networkInfo = CTTelephonyNetworkInfo()
            let provider = networkInfo.subscriberCellularProvider
            
            if let optProvider = provider {
                let carrier = optProvider.carrierName
                
                if carrier != nil {
                    return carrier!
                }
            } else {
                return ""
            }
            
            return ""
        }
    }
    #endif
    
    /// Download Source
    class func downloadSource(_ tracker: Tracker) -> String {
        if let optDls = tracker.configuration.parameters["downloadSource"] {
            return optDls
        } else {
            return "ext"
        }
    }

    #if os(watchOS)
    class var connectionType: ConnexionType {
        get {
            return ConnexionType.unknown
        }
    }
    #else
    /// Connexion type (3G, 4G, Edge, Wifi ...)
    class var connectionType: ConnexionType {
        get {
            let reachability = Reachability.reachabilityForInternetConnection()
            
            if let optReachability = reachability {
                if(optReachability.currentReachabilityStatus == Reachability.NetworkStatus.reachableViaWiFi) {
                    return ConnexionType.wifi
                } else if(optReachability.currentReachabilityStatus == Reachability.NetworkStatus.notReachable) {
                    return ConnexionType.offline
                } else {
                    #if os(iOS)
                    let telephonyInfo = CTTelephonyNetworkInfo()
                    let radioType = telephonyInfo.currentRadioAccessTechnology
                    
                    if(radioType != nil) {
                        switch(radioType!) {
                        case CTRadioAccessTechnologyGPRS:
                            return ConnexionType.gprs
                        case CTRadioAccessTechnologyEdge:
                            return ConnexionType.edge
                        case CTRadioAccessTechnologyCDMA1x:
                            return ConnexionType.twog
                        case CTRadioAccessTechnologyWCDMA:
                            return ConnexionType.threeg
                        case CTRadioAccessTechnologyCDMAEVDORev0:
                            return ConnexionType.threeg
                        case CTRadioAccessTechnologyCDMAEVDORevA:
                            return ConnexionType.threeg
                        case CTRadioAccessTechnologyCDMAEVDORevB:
                            return ConnexionType.threeg
                        case CTRadioAccessTechnologyeHRPD:
                            return ConnexionType.threegplus
                        case CTRadioAccessTechnologyHSDPA:
                            return ConnexionType.threegplus
                        case CTRadioAccessTechnologyHSUPA:
                            return ConnexionType.threegplus
                        case CTRadioAccessTechnologyLTE:
                            return ConnexionType.fourg
                        default:
                            return ConnexionType.unknown
                        }
                    } else {
                        return ConnexionType.unknown
                    }
                    #else
                        return ConnexionType.unknown
                    #endif
                }
            } else {
                return ConnexionType.unknown
            }
        }
    }
    #endif
}
