//
//  SocketSender.swift
//  SmartTracker
//
//  Created by Théo Damaville on 01/12/2015.
//  Copyright © 2015 AT Internet. All rights reserved.
//

import Foundation

/// Class reponsible for sending events
public class SocketSender {
    
    /// Websocket
    var socket: SRWebSocket?
    
    /// askforlive
    var timer: Timer?
    
    /// askforlive every RECONNECT_INTERVAL
    let RECONNECT_INTERVAL: Double = 2.0
    
    /// delegate to handle incoming msg
    var socketHandler: SocketDelegate
    
    /// URL of the ws
    let URL: String
    
    /// handler for the different scenarios of pairing
    let liveManager: LiveNetworkManager
    
    /// Buffer used to save the App and the current Screen displayed
    var buffer = EventBuffer()
    
    /**
     *  Buffer used to handle the App and the current screen displayed in case of reconnections
     *  note : The App can be different at different time (orientation)
     */
    struct EventBuffer {
        var currentScreen: String = ""
        var currentApp: String {
            return App().description
        }
    }
    
    /// queue managing events
    var queue:Array<String> = []
    
    /**
     init
     
     - parameter liveManager: a live manager
     - parameter token:       a valid token
     
     - returns: SocketSender (should be a single instance)
     */
    init(liveManager: LiveNetworkManager, token: String) {
        //self.URL = "ws://172.20.23.137:5000/"+token
        //self.URL = "ws://172.20.23.156:5000/"+token
        //self.URL = "ws://tagsmartsdk.eu-west-1.elasticbeanstalk.com:5000/"+token
        self.URL = "ws://172.20.23.145:5000/"+token
        //self.URL = "ws://tagsmartsdk.eu-west-1.elasticbeanstalk.com:5000/"+token
        self.liveManager = liveManager
        self.socketHandler = SocketDelegate(liveManager: liveManager)
    }
    
    /**
     open the socket
     */
    func open() {
        if isConnected() || ATInternet.sharedInstance.defaultTracker.enableLiveTagging == false || socket?.readyState == SRReadyState.CONNECTING {
            return
        }
        print(URL)
        let url = Foundation.URL(string: URL)
        socket = SRWebSocket(url:url)
        socket?.delegate = socketHandler
        socket?.open()
    }
    
    /**
     Close socket
     */
    func close() {
        if isConnected() {
            socket?.close()
        }
    }
    
    /**
     check if the socket is connected
     
     - returns: the state of the connexion
     */
    fileprivate func isConnected() -> Bool {
        return (socket != nil) && (socket?.readyState == SRReadyState.OPEN)
    }
    
    func sendBuffer() {
        print("send buffer")
        assert(isConnected())
        assert(self.liveManager.networkStatus == .Connected)
        socket?.send(buffer.currentApp)
        socket?.send(buffer.currentScreen)
    }
    
    /**
     send all events in the buffer list
     */
    func sendAll() {
        assert(isConnected())
        assert(self.liveManager.networkStatus == .Connected)
        while queue.count > 0 {
            self.sendFirst()
        }
    }
    
    /**
     send a JSON message to the server
     
     - parameter json: the message as a String (JSON formatted)
     */
    func sendMessage(_ json: String) {
        let eventName = JSON.parse(json)["event"].string
        print(eventName)
        // keep a ref to the last screen
        if eventName == "viewDidAppear" {
            buffer.currentScreen = json
            if self.liveManager.networkStatus == .Disconnected {
                return
            }
        }
        
        self.queue.append(json)
        if self.liveManager.networkStatus == .Connected {
            self.sendAll()
        }
    }
    
    /**
     Send a message even if not paired
     
     - parameter json: the message
     */
    func sendMessageForce(_ json: String) {
        if isConnected() {
            socket?.send(json)
        }
    }
    
    /**
     Ask for live with a timer so the pairing looks in real time
     */
    func startAskingForLive() {
        timer?.invalidate()
        timer = Timer(timeInterval: RECONNECT_INTERVAL, target: self, selector: #selector(SocketSender.sendAskingForLive), userInfo: nil, repeats: true)
        timer?.fire()
        RunLoop.main.add(timer!, forMode: RunLoopMode.commonModes)
    }
    
    /**
     AskForLive - we force it because not currently in live
     */
    @objc func sendAskingForLive() {
        sendMessageForce(DeviceAskingForLive().description)
    }
    
    /**
     Stop the askforlive timer
     */
    func stopAskingForLive() {
        timer?.invalidate()
    }
    
    /**
     Send the first message (act as a FIFO)
     */
    fileprivate func sendFirst() {
        let msg = queue.first
        socket?.send(msg)
        self.queue.remove(at: 0)
    }
}
