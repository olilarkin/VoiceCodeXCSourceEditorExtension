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
  
//  func convertToDictionary(text: String) -> [String: Any]? {
//    if let data = text.data(using: .utf8) {
//      do {
//        return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
//      } catch {
//        print(error.localizedDescription)
//      }
//    }
//    return nil
//  }

  
  func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void) -> Void
  {
    let handler: (Error) -> () = { error in
      NSLog("remote proxy error: \(error)")
    }
    
    let service = connection.remoteObjectProxyWithErrorHandler(handler) as! VoiceCodeXPCServiceProtocol
    
    service.get_latest_command() { (command) in
      let buffer = invocation.buffer
      //NSLog(buffer.contentUTI)
      NSLog(command)
      
//      let dict = convertToDictionary(text: command)
//
//      switch(dict!["id"]) {
//
//        case "initial-state":
//          NSLog("initial state - not handled")
//          break
//        case "editor:move-to-line-number":
//          let newRange = XCSourceTextRange()
//          newRange.start.column = 0
//          newRange.start.line = 3
//          newRange.end.column = 0
//          newRange.end.line = 3
//
//          buffer.selections[0] = newRange
//          break
//        case "editor:move-to-line-number-and-way-right":
//          break
//        case "editor:move-to-line-number-and-way-left":
//          break
//        case "editor:insert-under-line-number":
//          break
//        case "editor:select-line-number":
//          break
//        case "editor:expand-selection-to-scope":
//          break
//        case "editor:click-expand-selection-to-scope":
//          break
//        case "editor:select-line-number-range":
//          break
//        case "editor:extend-selection-to-line-number":
//          break
//        case "editor:insert-from-line-number":
//          break
//        case "editor:toggle-comments":
//          break
//        case "editor:insert-code-template":
//          break
//        case "editor:complete-code-template":
//          break
//        case "selection:previous-occurrence":
//          break
//        case "selection:next-occurrence":
//          break
//        case "selection:extend-to-next-occurrence":
//          break
//        case "selection:extend-to-previous-occurrence":
//          break
//        case "selection:previous-selection-occurrence":
//          break
//        case "selection:next-selection-occurrence":
//          break
//        case "selection:range-upward":
//          break
//        case "selection:range-downward":
//          break
//        case "selection:range-on-current-line":
//          break
//        case "selection:previous-word-by-surrounding-characters":
//          break
//        case "selection:next-word-by-surrounding-characters":
//          break
//        default:
//          NSLog("not handled")
//      }
      
      //TODO: do something with the invocation buffer
      connection.invalidate()
      completionHandler(nil)
    }
  }
  
}
