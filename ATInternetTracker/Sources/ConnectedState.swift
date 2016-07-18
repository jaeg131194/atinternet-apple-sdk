//
//  File.swift
//  Tracker
//
//  Created by Théo Damaville on 09/06/2016.
//  Copyright © 2016 AT Internet. All rights reserved.
//

import Foundation

class ConnectState: LiveNetworkState {
    
    let liveManager: LiveNetworkManager
    init(liveManager: LiveNetworkManager) {
        self.liveManager = liveManager
    }
    
    func deviceAskedForLive() {}
    func interfaceAskedForLive() {}
    func deviceRefusedLive() {}
    func interfaceRefusedLive(){}
    func deviceAcceptedLive() {}
    func interfaceAcceptedLive() {}
    func deviceAbortedLiveRequest(){ }
    func interfaceAbortedLiveRequest(){}
    
    func deviceStoppedLive() {
        liveManager.current = liveManager.disconnected
        liveManager.toolbar?.connectedToDisconnected()
        liveManager.networkStatus = .Disconnected
        liveManager.sender?.sendMessageForce(DeviceStoppedLive().description)
    }
    func interfaceStoppedLive() {
        liveManager.current = liveManager.disconnected
        liveManager.toolbar?.connectedToDisconnected()
        liveManager.networkStatus = .Disconnected
        liveManager.showStoppedPopup()
    }
}