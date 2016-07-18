//
//  DisconnectedState.swift
//  Tracker
//
//  Created by Théo Damaville on 09/06/2016.
//  Copyright © 2016 AT Internet. All rights reserved.
//

import Foundation
class DisconnectedState: LiveNetworkState {
    
    let liveManager: LiveNetworkManager
    init(liveManager: LiveNetworkManager) {
        self.liveManager = liveManager
    }
    
    func deviceAskedForLive() {
        liveManager.current = liveManager.pending
        liveManager.toolbar?.disconnectedToPending()
        liveManager.networkStatus = .Pending
        liveManager.sender?.startAskingForLive()
    }
    func interfaceAskedForLive() {
        if let reject = liveManager.autoReject {
            let elapsed = NSDate().timeIntervalSinceDate(reject)
            guard elapsed > liveManager.COOLDOWN else {
                return
            }
        }
        liveManager.current = liveManager.pending
        liveManager.toolbar?.disconnectedToPending()
        liveManager.networkStatus = .Pending
        liveManager.showPairingPopup()
    }
    
    func deviceAbortedLiveRequest(){ }
    func interfaceAbortedLiveRequest(){}
    func deviceRefusedLive() {}
    func interfaceRefusedLive(){}
    func deviceAcceptedLive() {}
    func interfaceAcceptedLive() {}
    func deviceStoppedLive() {}
    func interfaceStoppedLive() {}
}