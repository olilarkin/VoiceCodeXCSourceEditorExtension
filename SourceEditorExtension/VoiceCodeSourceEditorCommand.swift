//
//  SourceEditorCommand.swift
//  VoiceCode
//
//  Created by Oliver Larkin on 24/05/2017.
//  Copyright © 2017 OliLarkin. All rights reserved.
//

import Foundation
import XcodeKit
import SwiftyJSON

class SourceEditorCommand: NSObject, XCSourceEditorCommand {
  
  lazy var connection: NSXPCConnection = {
    let connection = NSXPCConnection(serviceName: "com.ol.VoiceCodeXCSourceEditorExtensionApp.VoiceCodeSourceEditorExtension.VoiceCodeXPCService")
    connection.remoteObjectInterface = NSXPCInterface(with: VoiceCodeXPCServiceProtocol.self)
    connection.resume()
    return connection
  }()

  deinit {
  }
  
  func isInsertionPoint(range: XCSourceTextRange) -> Bool{
    
    if (range.start.line != range.end.line) {
      return false
    }
    
    if (range.start.column != range.end.column) {
      return false
    }
    
    return true
  }
  
  func checkLineNumber(lineNumber: Int, nLinesInBuffer: Int) -> Int {
    var checkedLineNumber = -1 //TODO: probably better to use an optional
    
    if(lineNumber < 0) {
      checkedLineNumber = 0
    }
    else if(lineNumber >= nLinesInBuffer) {
      checkedLineNumber = nLinesInBuffer - 1
    }
    else {
      checkedLineNumber = lineNumber
    }
    
    return checkedLineNumber
  }
  
  func getLineLength(lineNumber: Int, nLinesInBuffer: Int, buffer: XCSourceTextBuffer) -> Int{
    let text = buffer.lines[checkLineNumber(lineNumber: lineNumber, nLinesInBuffer: nLinesInBuffer)] as! String
    return text.characters.count
  }

  func makeRange(startLine: Int, endLine: Int, nLinesInBuffer: Int, startColumn: Int = 0, endColumn: Int = 0, numberOfColumnsInLine: Int = 0) -> XCSourceTextRange {
    let newRange = XCSourceTextRange()

    if(startColumn < 0) {
      newRange.start.column = 0
    }
    else if(startColumn > numberOfColumnsInLine) {
      newRange.start.column = numberOfColumnsInLine
    }
    else {
      newRange.start.column = startColumn
    }
    
    if(endColumn < 0) {
      newRange.end.column = 0
    }
    else if(endColumn > numberOfColumnsInLine) {
      newRange.end.column = numberOfColumnsInLine
    }
    else {
      newRange.end.column = endColumn
    }

    newRange.start.line = checkLineNumber(lineNumber: startLine, nLinesInBuffer: nLinesInBuffer)
    newRange.end.line = checkLineNumber(lineNumber: endLine, nLinesInBuffer: nLinesInBuffer)
    
    return newRange
  }
  
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
      
      let dataFromString = command.data(using: .utf8)
      let json = try? JSON(data: dataFromString!)
      let nLinesInBuffer = buffer.lines.count
      
      switch(json!["id"].stringValue) {

        case "initial-state":
          NSLog("initial state - not handled")
          break
        // MARK: -
        // MARK: Editor overrides
        case "editor:move-to-line-number":
          let line = json!["line"].intValue - 1
          buffer.selections[0] = makeRange(startLine: line, endLine: line, nLinesInBuffer: nLinesInBuffer)
          break
        case "editor:move-to-line-number-and-way-right":
          let line = json!["line"].intValue - 1
          let lineLength = getLineLength(lineNumber: line, nLinesInBuffer: nLinesInBuffer, buffer: buffer)

          buffer.selections[0] = makeRange(startLine: line, endLine: line, nLinesInBuffer: nLinesInBuffer, startColumn:  lineLength - 1, endColumn:  lineLength - 1, numberOfColumnsInLine: lineLength)
          // TODO:  tell xcode 2 navigate to selection in case selection was offscreen
          break
        case "editor:move-to-line-number-and-way-left":
          let line = json!["line"].intValue - 1
          let lineLength = getLineLength(lineNumber: line, nLinesInBuffer: nLinesInBuffer, buffer: buffer)
          
          buffer.selections[0] = makeRange(startLine: line, endLine: line, nLinesInBuffer: nLinesInBuffer, startColumn:  0, endColumn:  0, numberOfColumnsInLine: lineLength)
          // TODO:  tell xcode 2 navigate to selection in case selection was offscreen
          break
        case "editor:insert-under-line-number":
          let line = checkLineNumber(lineNumber: json!["line"].intValue - 1, nLinesInBuffer: nLinesInBuffer)
          //TODO: probably better to use an optional
          if line > -1 {
            buffer.lines.insert("", at: line)
          }
          break
        case "editor:select-line-number":
          let line = json!["line"].intValue - 1
          let lineLength = getLineLength(lineNumber: line, nLinesInBuffer: nLinesInBuffer, buffer: buffer)

          buffer.selections[0] = makeRange(startLine: line, endLine: line, nLinesInBuffer: nLinesInBuffer, startColumn: 0, endColumn: lineLength, numberOfColumnsInLine: lineLength)
        
          // TODO:  tell xcode 2 navigate to selection in case selection was offscreen
          break
//        case "editor:expand-selection-to-scope":
//          break
//        case "editor:click-expand-selection-to-scope":
//          break
        case "editor:select-line-number-range":
          let firstLine = json!["first"].intValue - 1
          let lastLine = json!["last"].intValue - 1
          let lineLength = getLineLength(lineNumber: lastLine, nLinesInBuffer: nLinesInBuffer, buffer: buffer)

          buffer.selections[0] = makeRange(startLine: firstLine, endLine: lastLine, nLinesInBuffer: nLinesInBuffer, startColumn: 0, endColumn: lineLength, numberOfColumnsInLine: lineLength)
          
          // TODO:  tell xcode 2 navigate to selection in case selection was offscreen
          break
        case "editor:extend-selection-to-line-number":
          break
        case "editor:insert-from-line-number":
          //TODO: this is not quite working
          let line = json!["line"].intValue - 1
          let checkedLine = checkLineNumber(lineNumber: line, nLinesInBuffer: nLinesInBuffer)
          //TODO: probably better to use an optional
          let range = buffer.selections[0] as! XCSourceTextRange
          if checkedLine > -1 && isInsertionPoint(range: range) {
            var currentLine = buffer.lines[range.start.line] as! String
            let textToInsert = buffer.lines[checkedLine] as! String
            let insertIndex = currentLine.index(currentLine.startIndex, offsetBy: range.start.column)
            currentLine.insert(contentsOf: textToInsert.characters, at: insertIndex)
            buffer.lines.replaceObject(at: range.start.line, with: currentLine)
          }
          break
//        case "editor:toggle-comments":
//          break
//        case "editor:insert-code-template":
//          break
//        case "editor:complete-code-template":
//          break
        
        // MARK: -
        // MARK: Selection overrides
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
        default:
          NSLog("not handled")
      }
      
      connection.invalidate()
      completionHandler(nil)
    }
  }
  
}
