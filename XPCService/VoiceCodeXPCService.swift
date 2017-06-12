// VoiceCodeXPCService.swift
import Foundation
import Starscream

@objc class VoiceCodeXPCService: NSObject, VoiceCodeXPCServiceProtocol, WebSocketDelegate  {

  var socket: WebSocket
  var messageReceived: String
  var failedToConnect: Bool
  let noMessageStr = "{\"id\": \"no message\"}"
  
  override init() {
    socket = WebSocket(url: URL(string: "ws://localhost:8081/")!)
    messageReceived = noMessageStr
    failedToConnect = false
    super.init()
    socket.delegate = self
    socket.connect()
  }
  
  func sendMessage(message: String) {
    socket.write(string: message)
  }
  
  func getLatestCommand(withReply: (String) -> ()) {

    //we need to handle this better here - it will block until the connection is made, if it can't make the connection
    while(!socket.isConnected && !failedToConnect) {
      // NSLog("connecting")
    }
    
    while(messageReceived == noMessageStr && !failedToConnect) {
      // NSLog("waiting for message")
    }
    
    withReply(messageReceived)
    
    messageReceived = noMessageStr
    failedToConnect = false
  }
  
  func websocketDidConnect(socket: WebSocket) {
    NSLog("Websocket is connected")
    //socket.write(string: "getCommand")
  }
  
  func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
    if let e = error {
      NSLog("Websocket is disconnected: \(e.localizedDescription)")
    } else {
      NSLog("Websocket disconnected")
    }
    
    failedToConnect = true;
  }
  
  func websocketDidReceiveMessage(socket: WebSocket, text: String) {
    NSLog("Received text: \(text)")
    messageReceived = text
  }
  
  func websocketDidReceiveData(socket: WebSocket, data: Data) {
    NSLog("Received data: \(data.count)")
  }
}
