//
//  NetworkState.swift
//  Tracker
//
//  Created by Théo Damaville on 09/06/2016.
//  Copyright © 2016 AT Internet. All rights reserved.
//

import Foundation

protocol LiveNetworkState {
    func deviceAskedForLive()
    func interfaceAskedForLive()
    
    func interfaceAbortedLiveRequest()
    func deviceAbortedLiveRequest()
    
    func deviceRefusedLive()
    func interfaceRefusedLive()
    
    func deviceAcceptedLive()
    func interfaceAcceptedLive()
    
    func deviceStoppedLive()
    func interfaceStoppedLive()
}

class LiveNetworkManager: LiveNetworkState {
    enum NetworkStatus: String {
        case Connected = "Connected"
        case Disconnected = "Disconnected"
        case Pending = "Pending"
    }
    
    lazy var disconnected: LiveNetworkState = DisconnectedState(liveManager: self)
    lazy var connected : LiveNetworkState = ConnectState(liveManager: self)
    lazy var pending: LiveNetworkState = PendingState(liveManager: self)
    var current: LiveNetworkState?
    var networkStatus: NetworkStatus = .Disconnected
    var currentPopupDisplayed: KLCPopup?
    var autoReject: NSDate?
    let COOLDOWN = 3.0
    
    var sender: SocketSender?
    var toolbar: SmartToolBarController?
    
    init(sender: SocketSender, toobar: SmartToolBarController) {
        self.sender = sender
        self.toolbar = toobar
    }
    
    init() {
        self.sender = nil
        self.toolbar = nil
    }
    
    func initState() {
        current = disconnected
    }
    
    func deviceAskedForLive() {
        current?.deviceAskedForLive()
    }
    func interfaceAskedForLive() {
        current?.interfaceAskedForLive()
    }
    
    func deviceRefusedLive() {
        current?.deviceRefusedLive()
    }
    func interfaceRefusedLive(){
        current?.interfaceRefusedLive()
    }
    
    func deviceAcceptedLive() {
        current?.deviceAcceptedLive()
    }
    func interfaceAcceptedLive() {
        current?.interfaceAcceptedLive()
    }
    
    func deviceStoppedLive() {
        current?.deviceStoppedLive()
    }
    func interfaceStoppedLive() {
        current?.interfaceStoppedLive()
    }
    func deviceAbortedLiveRequest(){
        current?.deviceAbortedLiveRequest()
    }
    func interfaceAbortedLiveRequest(){
        current?.interfaceAbortedLiveRequest()
    }
    
    func showPairingPopup() {
        self.currentPopupDisplayed?.dismiss(true)
        let texts = getTexts()
        let p = SmartPopUp(frame: CGRectZero, title: texts["ASK_PAIRING_TITLE"]!, message: texts["ASK_PAIRING_TEXT"]!, okTitle: texts["CONFIRM"]!, cancelTitle: texts["CANCEL"]!)
        let popup = KLCPopup(contentView: p,
                             showType: KLCPopupShowType.BounceInFromTop,
                             dismissType: KLCPopupDismissType.BounceOutToBottom,
                             maskType: KLCPopupMaskType.Dimmed,
                             dismissOnBackgroundTouch: false,
                             dismissOnContentTouch: false)
        p.addOkAction { () -> () in
            self.deviceAcceptedLive()
            popup.dismiss(true)
        }
        p.addCancelAction { () -> () in
            self.deviceRefusedLive()
            popup.dismiss(true)
        }
        self.currentPopupDisplayed = popup
        
        popup.show()
    }
    
    
    
    func showAbortedPopup() {
        let texts = getTexts()
        self.currentPopupDisplayed?.dismiss(true)
        let p = SmartPopUp(frame: CGRectZero, title: texts["INFO_PAIRING_CANCELED_TITLE"]!, message: texts["INFO_PAIRING_CANCELED_TEXT"]!, okTitle: texts["CONFIRM"]!)
        let popup = KLCPopup(contentView: p,
                             showType: KLCPopupShowType.BounceInFromTop,
                             dismissType: KLCPopupDismissType.BounceOutToBottom,
                             maskType: KLCPopupMaskType.Dimmed,
                             dismissOnBackgroundTouch: false,
                             dismissOnContentTouch: false)
        p.addOkAction { () -> () in
            popup.dismiss(true)
        }
        popup.show()
    }
    
    func showStoppedPopup() {
        let texts = getTexts()
        self.currentPopupDisplayed?.dismiss(true)
        let p = SmartPopUp(frame: CGRectZero, title: texts["INFO_PAIRING_STOPPED_TITLE"]!, message: texts["INFO_PAIRING_STOPPED_TEXT"]!, okTitle: texts["CONFIRM"]!)
        let popup = KLCPopup(contentView: p,
                             showType: KLCPopupShowType.BounceInFromTop,
                             dismissType: KLCPopupDismissType.BounceOutToBottom,
                             maskType: KLCPopupMaskType.Dimmed,
                             dismissOnBackgroundTouch: false,
                             dismissOnContentTouch: false)
        p.addOkAction { () -> () in
            popup.dismiss(true)
        }
        popup.show()
    }
    
    func showRefusedPopup() {
        let texts = getTexts()
        self.currentPopupDisplayed?.dismiss(true)
        let p = SmartPopUp(frame: CGRectZero, title: texts["INFO_PAIRING_REFUSED_TITLE"]!, message: texts["INFO_PAIRING_REFUSED_TEXT"]!, okTitle: texts["CONFIRM"]!)
        let popup = KLCPopup(contentView: p,
                             showType: KLCPopupShowType.BounceInFromTop,
                             dismissType: KLCPopupDismissType.BounceOutToBottom,
                             maskType: KLCPopupMaskType.Dimmed,
                             dismissOnBackgroundTouch: false,
                             dismissOnContentTouch: false)
        p.addOkAction { () -> () in
            popup.dismiss(true)
        }
        popup.show()
    }
    
    func getTexts() -> [String:String] {
        return [
            "ASK_PAIRING_TITLE": NSLocalizedString("ASK_PAIRING_TITLE", tableName: nil, bundle: NSBundle(forClass: Tracker.self), value: "", comment: "titre"),
            "ASK_PAIRING_TEXT" : NSLocalizedString("ASK_PAIRING_TEXT", tableName: nil, bundle: NSBundle(forClass: Tracker.self), value: "", comment: "content"),
            "CONFIRM": NSLocalizedString("CONFIRM", tableName: nil, bundle: NSBundle(forClass: Tracker.self), value: "", comment: "content"),
            "CANCEL": NSLocalizedString("CANCEL", tableName: nil, bundle: NSBundle(forClass: Tracker.self), value: "", comment: "content"),
            "INFO_PAIRING_CANCELED_TEXT": NSLocalizedString("INFO_PAIRING_CANCELED_TEXT", tableName: nil, bundle: NSBundle(forClass: Tracker.self), value: "", comment: "content"),
            "INFO_PAIRING_CANCELED_TITLE": NSLocalizedString("INFO_PAIRING_CANCELED_TITLE", tableName: nil, bundle: NSBundle(forClass: Tracker.self), value: "", comment: "titre"),
            "INFO_PAIRING_STOPPED_TITLE": NSLocalizedString("INFO_PAIRING_STOPPED_TITLE", tableName: nil, bundle: NSBundle(forClass: Tracker.self), value: "", comment: "titre"),
            "INFO_PAIRING_STOPPED_TEXT": NSLocalizedString("INFO_PAIRING_STOPPED_TEXT", tableName: nil, bundle: NSBundle(forClass: Tracker.self), value: "", comment: "content"),
            "INFO_PAIRING_REFUSED_TEXT": NSLocalizedString("INFO_PAIRING_REFUSED_TEXT", tableName: nil, bundle: NSBundle(forClass: Tracker.self), value: "", comment: "content"),
            "INFO_PAIRING_REFUSED_TITLE": NSLocalizedString("INFO_PAIRING_REFUSED_TITLE", tableName: nil, bundle: NSBundle(forClass: Tracker.self), value: "", comment: "titre"),
        ]
    }
    
    func setToolbarHidden(isHidden: Bool) {
        self.toolbar?.setToolbarHidden(isHidden)
    }
}
