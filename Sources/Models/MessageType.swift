//
//  Message.swift
//  upscopeio-sdk
//
//  Created by Upscope on 25.09.2024.
//

public enum MessageType: String, Codable, CaseIterable {
    case hello = "hello"
    case welcome = "welcome" // welcomeBack
    case youAre = "youAre"
    case ping = "ping"
    case pong = "pong"
    case startSessionPreparation = "startSessionPreparation"
    case beginSession = "beginSession"
    case sessionRatingToken = "sessionRatingToken"
    case endSession = "endSession"
    // new ones
    case connectionUpdate = "connectionUpdate"
    case focus
    case sessionStatusUpdate = "sessionStatusUpdate"
    case stopSession = "stopSession"
    case customMessage = "customMessage"
    case grantControl = "grantControl"
    case screenFrame = "screenFrame"
    case dataBounce = "dataBounce"
    case dataBounceBack = "dataBounceBack"
    case dataError = "dataError"
    case apiKeyError = "apiKeyError"
    case welcomeBack = "welcomeBack"
    case continueSession = "continueSession"
    case stopSessionPreparation = "stopSessionPreparation"
    case doNotReconnect = "doNotReconnect"
    case controlRequest = "controlRequest"
    case controlGranted = "controlGranted"
    case remoteInstruction = "remoteInstruction"
    case modeUpdate = "modeUpdate"
}

struct Message: Codable {
    let type: MessageType
    let data: MessageData?
    
    enum CodingKeys: String, CodingKey {
        case type = "c"
        case data = "d"
    }
}

