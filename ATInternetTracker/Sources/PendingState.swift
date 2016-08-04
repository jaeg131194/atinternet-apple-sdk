//
//  PendingState.swift
//  Tracker
//
//  Created by Théo Damaville on 09/06/2016.
//  Copyright © 2016 AT Internet. All rights reserved.
//

import Foundation
class PendingState: LiveNetworkState {
    
    let liveManager: LiveNetworkManager
    init(liveManager: LiveNetworkManager) {
        self.liveManager = liveManager
    }
    
    func deviceAskedForLive() {}
    func interfaceAskedForLive() {
        // special patch: interface and device made a request, making deadlock...
        let isAsking: Bool? = self.liveManager.sender?.timer?.valid
        if isAsking.getOrElse(false) {
            liveManager.sender?.stopAskingForLive()
            liveManager.toolbar?.pendingToConnected()
            liveManager.current = liveManager.connected
            liveManager.networkStatus = .Connected
            self.liveManager.sender?.sendMessageForce(DeviceAcceptedLive().description)
            liveManager.sender?.sendAll()
        }
    }
    
    func deviceAbortedLiveRequest(){
        liveManager.toolbar?.pendingToDisconnected()
        liveManager.networkStatus = .Disconnected
        liveManager.current = liveManager.disconnected
        liveManager.sender?.stopAskingForLive()
        liveManager.sender?.sendMessageForce(DeviceAbortedLiveRequest().description)
    }
    
    func deviceRefusedLive() {
        liveManager.toolbar?.pendingToDisconnected()
        liveManager.networkStatus = .Disconnected
        liveManager.current = liveManager.disconnected
        liveManager.autoReject = NSDate()
        self.liveManager.sender?.sendMessageForce(DeviceRefusedLive().description)
    }
    
    func deviceAcceptedLive() {
        liveManager.toolbar?.pendingToConnected()
        liveManager.current = liveManager.connected
        liveManager.networkStatus = .Connected
        liveManager.sender?.sendMessage(App().description)
        self.liveManager.sender?.sendMessageForce(DeviceAcceptedLive().description)
        liveManager.sender?.sendAll()
    }
    
    func interfaceAcceptedLive() {
        liveManager.toolbar?.pendingToConnected()
        liveManager.current = liveManager.connected
        liveManager.networkStatus = .Connected
        liveManager.sender?.stopAskingForLive()
        liveManager.sender?.sendMessage(App().description)
        self.liveManager.sender?.sendAll()
    }
    func interfaceRefusedLive(){
        liveManager.toolbar?.pendingToDisconnected()
        liveManager.networkStatus = .Disconnected
        liveManager.current = liveManager.disconnected
        liveManager.sender?.stopAskingForLive()
        liveManager.showRefusedPopup()
    }
    
    func deviceStoppedLive() { }
    
    func interfaceAbortedLiveRequest() {
        liveManager.toolbar?.pendingToDisconnected()
        liveManager.networkStatus = .Disconnected
        liveManager.current = liveManager.disconnected
        liveManager.currentPopupDisplayed?.dismiss(true)
        liveManager.showAbortedPopup()
    }
    
    func interfaceStoppedLive() {}
}
