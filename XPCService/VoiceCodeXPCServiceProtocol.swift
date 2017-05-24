// VoiceCodeXPCServiceProtocol.swift
import Foundation

@objc protocol VoiceCodeXPCServiceProtocol {
  func uppercase(_ string: String, withReply: (String)->())
}
