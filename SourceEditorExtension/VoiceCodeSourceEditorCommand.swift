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
  
  let jumpToSelectionMessage: JSON = [
    "id": "jumpToSelection"
  ]
  
  lazy var connection: NSXPCConnection = {
    let connection = NSXPCConnection(serviceName: "com.ol.VoiceCodeXCSourceEditorExtensionApp.VoiceCodeSourceEditorExtension.VoiceCodeXPCService")
    connection.remoteObjectInterface = NSXPCInterface(with: VoiceCodeXPCServiceProtocol.self)
    connection.resume()
    return connection
  }()

  deinit {
    connection.invalidate()
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
  
  enum errorTypes : Error{
    case invalidLineNumber
  }
  
  //MARK: TODO: for some operations an out of bounds line number should not be clamped
  func clampLineNumber(lineNumber: Int, nLinesInBuffer: Int) -> Int {
    if(lineNumber < 0) {
      return 0
    }
    else if(lineNumber >= nLinesInBuffer) {
      return nLinesInBuffer - 1
    }
    else {
      return lineNumber
    }
  }
  
  func getLineLength(lineNumber: Int, nLinesInBuffer: Int, buffer: XCSourceTextBuffer) -> Int{
    let text = buffer.lines[lineNumber] as! String
    return text.characters.count
  }

  func makeRange(startLine: Int, endLine: Int, nLinesInBuffer: Int, startColumn: Int = 0, endColumn: Int = 0, numberOfColumnsInLine: Int = 0) -> XCSourceTextRange {
    //MARK: TODO:  what am I doing with nLinesInBuffer?
    let newRange = XCSourceTextRange()

    if(startColumn < 0) {
      newRange.start.column = 0
    }
    else if(startColumn > numberOfColumnsInLine) {
      newRange.start.column = numberOfColumnsInLine - 1
    }
    else {
      newRange.start.column = startColumn
    }
    
    if(endColumn < 0) {
      newRange.end.column = 0
    }
    else if(endColumn > numberOfColumnsInLine) {
      newRange.end.column = numberOfColumnsInLine - 1
    }
    else {
      newRange.end.column = endColumn
    }

    newRange.start.line = startLine
    newRange.end.line = endLine
    
    return newRange
  }
  
  func getSelectedText(selectionRange: XCSourceTextRange, buffer: XCSourceTextBuffer) -> String {
    var selectedText = ""
    
    if(isInsertionPoint(range: selectionRange)) {
      return selectedText
    }
    
    //all on same line
    if(selectionRange.start.line == selectionRange.end.line) {
      let lineStr = buffer.lines[selectionRange.start.line] as! String
      let startIndex = lineStr.index(lineStr.startIndex, offsetBy: selectionRange.start.column)
      let endIndex = lineStr.index(lineStr.startIndex, offsetBy: selectionRange.end.column)
      let range = startIndex..<endIndex
      selectedText.append(lineStr.substring(with:range))
    }
    else {
      for index in selectionRange.start.line...selectionRange.end.line {
        let lineStr = buffer.lines[index] as! String
        if index == selectionRange.start.line {
          let startIndex = lineStr.index(lineStr.startIndex, offsetBy: selectionRange.start.column)
          selectedText.append(lineStr.substring(from: startIndex))
        }
        else if index == selectionRange.end.line{
          let endIndex = lineStr.index(lineStr.startIndex, offsetBy: selectionRange.end.column)
          selectedText.append(lineStr.substring(to: endIndex))
        }
        else{
          selectedText.append(lineStr)
        }
      }
    }
    
    return selectedText
  }
  
  func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void) -> Void
  {
    let handler: (Error) -> () = { error in
      NSLog("remote proxy error: \(error)")
    }
    
    let service = connection.remoteObjectProxyWithErrorHandler(handler) as! VoiceCodeXPCServiceProtocol
    
    service.getLatestCommand() { (command) in

      NSLog("Command received: " + command)
      
      do {
        let json = try JSON(data: command.data(using: .utf8)!)

        try parseJSON(buffer: invocation.buffer, json: json, service: service)
      }
      catch {
        NSLog("error parsing json")
      }
      
      connection.invalidate()
      completionHandler(nil)
    }
  }
  
  func parseJSON(buffer: XCSourceTextBuffer, json : JSON, service: VoiceCodeXPCServiceProtocol) throws {
    let nLinesInBuffer = buffer.lines.count
    let line = clampLineNumber(lineNumber: json["line"].intValue - 1, nLinesInBuffer: nLinesInBuffer)

    switch(json["id"].stringValue) {
      case "no message":
        NSLog("Could not connect to VoiceCode websocket")

      case "initial-state":
        NSLog("Initial state - not handled")

        
// MARK: -
// MARK: OS overrides
      case "os:get-selected-text":
        let currentSelectionRange = buffer.selections[0] as! XCSourceTextRange
        
        let message: JSON = [
          "id": "setSelectedText",
          "text": getSelectedText(selectionRange: currentSelectionRange, buffer: buffer)
        ]
        
        service.sendMessage(message: message.rawString()!)
// MARK: -
// MARK: DELETE overrides
//      case "delete:delete-lines":
// MARK: TODO: case "delete:delete-lines":
      
// MARK: -
// MARK: OBJECT overrides
      case "object:duplicate":
        let currentSelectionRange = buffer.selections[0] as! XCSourceTextRange
        let numberOfLinesSelected = (currentSelectionRange.end.line - currentSelectionRange.start.line) + 1;
        let insertionPoint = currentSelectionRange.end.line;
        
        var linesToInsert : [String] = []
        for readLine in 0..<numberOfLinesSelected {
          let currentLine = buffer.lines[currentSelectionRange.start.line + readLine] as! String
          linesToInsert.append(currentLine)
        }
        
        let indexes = IndexSet((currentSelectionRange.end.line + 1)...(currentSelectionRange.end.line+numberOfLinesSelected))
        buffer.lines.insert(linesToInsert, at:indexes)
        buffer.selections[0] = makeRange(startLine: insertionPoint + numberOfLinesSelected, endLine: insertionPoint + numberOfLinesSelected, nLinesInBuffer: nLinesInBuffer)
      
// MARK: -
// MARK: EDITOR overrides
      case "editor:move-to-line-number":
        buffer.selections[0] = makeRange(startLine: line, endLine: line, nLinesInBuffer: nLinesInBuffer)
        service.sendMessage(message: jumpToSelectionMessage.rawString()!)

      case "editor:move-to-line-number-and-way-right":
        let lineLength = getLineLength(lineNumber: line, nLinesInBuffer: nLinesInBuffer, buffer: buffer)
        buffer.selections[0] = makeRange(startLine: line, endLine: line, nLinesInBuffer: nLinesInBuffer, startColumn:  lineLength - 1, endColumn:  lineLength - 1, numberOfColumnsInLine: lineLength)
        service.sendMessage(message: jumpToSelectionMessage.rawString()!)

      case "editor:move-to-line-number-and-way-left":
        let lineLength = getLineLength(lineNumber: line, nLinesInBuffer: nLinesInBuffer, buffer: buffer)
        
        buffer.selections[0] = makeRange(startLine: line, endLine: line, nLinesInBuffer: nLinesInBuffer, startColumn:  0, endColumn:  0, numberOfColumnsInLine: lineLength)
        service.sendMessage(message: jumpToSelectionMessage.rawString()!)

      case "editor:insert-under-line-number":
        buffer.lines.insert("", at: line)

      case "editor:select-line-number":
        let lineLength = getLineLength(lineNumber: line, nLinesInBuffer: nLinesInBuffer, buffer: buffer)
        buffer.selections[0] = makeRange(startLine: line, endLine: line, nLinesInBuffer: nLinesInBuffer, startColumn: 0, endColumn: lineLength, numberOfColumnsInLine: lineLength)
        service.sendMessage(message: jumpToSelectionMessage.rawString()!)

//    case "editor:expand-selection-to-scope":
// MARK: TODO: editor:expand-selection-to-scope

//    case "editor:click-expand-selection-to-scope":
// MARK: TODO: editor:click-selection-to-scope

      case "editor:select-line-number-range":
        let lastLine = clampLineNumber(lineNumber: json["lastline"].intValue - 1, nLinesInBuffer: nLinesInBuffer)
        let lineLength = getLineLength(lineNumber: lastLine, nLinesInBuffer: nLinesInBuffer, buffer: buffer)
        
        buffer.selections[0] = makeRange(startLine: line, endLine: lastLine, nLinesInBuffer: nLinesInBuffer, startColumn: 0, endColumn: lineLength, numberOfColumnsInLine: lineLength)
        service.sendMessage(message: jumpToSelectionMessage.rawString()!)

      case "editor:extend-selection-to-line-number":
        let currentSelectionRange = buffer.selections[0] as! XCSourceTextRange
        let lineLength = getLineLength(lineNumber: line, nLinesInBuffer: nLinesInBuffer, buffer: buffer)
        buffer.selections[0] = makeRange(startLine: currentSelectionRange.start.line, endLine: line, nLinesInBuffer: nLinesInBuffer, startColumn: 0, endColumn: lineLength, numberOfColumnsInLine: lineLength)
        

      case "editor:insert-from-line-number":
        let currentSelectionRange = buffer.selections[0] as! XCSourceTextRange
        if isInsertionPoint(range: currentSelectionRange) {
          var currentLine = buffer.lines[currentSelectionRange.start.line] as! String
          var textToInsert = buffer.lines[line] as! String //MARK: TODO: if line is out of range nothing should happen here
          let insertIndex = currentLine.index(currentLine.startIndex, offsetBy: currentSelectionRange.start.column)
          currentLine.insert(contentsOf: textToInsert.characters, at: insertIndex)
          currentLine.remove(at: currentLine.index(currentLine.endIndex, offsetBy: -1))
          buffer.lines.replaceObject(at: currentSelectionRange.start.line, with: currentLine)
        }

//        case "editor:toggle-comments":
//    
//        case "editor:insert-code-template":
//    
//        case "editor:complete-code-template":
//    
// MARK: -
// MARK: SELECTION overrides
//        case "selection:previous-occurrence":
// MARK: TODO: selection:previous-occurrence


//        case "selection:next-occurrence":
// MARK: TODO: selection:next-occurrence


//        case "selection:extend-to-next-occurrence":
// MARK: TODO: selection:extend-to-next-occurrence


//        case "selection:extend-to-previous-occurrence":
// MARK: TODO: selection:extend-to-previous-occurrence


//        case "selection:previous-selection-occurrence":
//    
//        case "selection:next-selection-occurrence":
//    
//        case "selection:range-upward":
//    
//        case "selection:range-downward":
//    
//        case "selection:range-on-current-line":
// MARK: TODO: selection:range-on-current-line


//        case "selection:previous-word-by-surrounding-characters":
// MARK: TODO: selection:previous-word-by-surrounding-characters


//        case "selection:next-word-by-surrounding-characters":
// MARK: TODO: selection:next-word-by-surrounding-characters

      
      default:
        NSLog("not handled")
    }
    
  }
  
}
