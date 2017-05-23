//
//  SourceEditorExtension.swift
//  VoiceCode
//
//  Created by Oliver Larkin on 24/05/2017.
//  Copyright © 2017 OliLarkin. All rights reserved.
//

import Foundation
import XcodeKit

class SourceEditorExtension: NSObject, XCSourceEditorExtension {
  
  func extensionDidFinishLaunching() {
    print("Extension launched...")
  }
  
  /*
  var commandDefinitions: [[XCSourceEditorCommandDefinitionKey: Any]] {
      // If your extension needs to return a collection of command definitions that differs from those in its Info.plist, implement this optional property getter.
      return []
  }
  */
  
}
