// VoiceCodeXPCServiceProtocol.swift
import Foundation

@objc protocol VoiceCodeXPCServiceProtocol {
  func getLatestCommand(withReply: (String)->())
}
