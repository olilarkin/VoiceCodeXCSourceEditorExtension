//
//  SourceEditorCommand.swift
//  VoiceCode
//
//  Created by Oliver Larkin on 24/05/2017.
//  Copyright © 2017 OliLarkin. All rights reserved.
//

import Foundation
import XcodeKit

class SourceEditorCommand: NSObject, XCSourceEditorCommand {
  
  lazy var connection: NSXPCConnection = {
    let connection = NSXPCConnection(serviceName: "com.ol.VoiceCodeXCSourceEditorExtensionApp.VoiceCodeSourceEditorExtension.VoiceCodeXPCService")
    connection.remoteObjectInterface = NSXPCInterface(with: VoiceCodeXPCServiceProtocol.self)
    connection.resume()
    return connection
  }()

  deinit {
  }
  
  func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void) -> Void
  {
    let handler: (Error) -> () = { error in
      NSLog("remote proxy error: \(error)")
    }
    
    let service = connection.remoteObjectProxyWithErrorHandler(handler) as! VoiceCodeXPCServiceProtocol
    
    service.get_latest_command() { (command) in
      let buffer = invocation.buffer
      NSLog(buffer.contentUTI)
      NSLog(command)
      //TODO: do something with the invocation buffer
      connection.invalidate()
      completionHandler(nil)
    }
  }
  
}
