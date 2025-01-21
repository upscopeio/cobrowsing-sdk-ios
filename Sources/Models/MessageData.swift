//
//  MessageData.swift
//  upscopeio-sdk
//
//  Created by Upscope on 25.09.2024.
//

enum MessageData: Codable {
    case hello(HelloData)
    case connectionUpdate(HelloData)
    case youAre(YouAreData)
    case welcome
    case ping
    case pong
    case startSessionPreparation
    case beginSession(BeginSessionData)
    case continueSession(ContinueSessionData)
    case sessionStatusUpdate(String)
    case sessionRatingToken(SessionRatingTokenData)
    case endSession
    case dataError(ErrorData)
    case apiKeyError(ErrorData)
    case customMessage(String) // TODO: - check correct data model
    case screenFrame([ScreenFrameData])
    case modeUpdate(ModeUpdateData)
    case dataBounce(String)
    case dataBounceBack(String)
    case remoteInstruction(RemoteInstructionData)
    case controlRequest(ControlRequestData)
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let helloData = try? container.decode(HelloData.self) {
            self = .hello(helloData)
        } else if let updatedHelloData = try? container.decode(HelloData.self) {
            self = .connectionUpdate(updatedHelloData)
        } else if let youAreData = try? container.decode(YouAreData.self) {
            self = .youAre(youAreData)
        } else if let beginSessionData = try? container.decode(BeginSessionData.self) {
            self = .beginSession(beginSessionData)
        } else if let continueSession = try? container.decode(ContinueSessionData.self) {
            self = .continueSession(continueSession)
        } else if let sessionStatusUpdate = try? container.decode(String.self) {
            self = .sessionStatusUpdate(sessionStatusUpdate)
        } else if let sessionRatingTokenData = try? container.decode(SessionRatingTokenData.self) {
            self = .sessionRatingToken(sessionRatingTokenData)
        } else if let dataError = try? container.decode(ErrorData.self) {
            self = .dataError(dataError)
        } else if let apiKeyError = try? container.decode(ErrorData.self) {
            self = .apiKeyError(apiKeyError)
        } else if let customMessage = try? container.decode(String.self) {
            self = .customMessage(customMessage)
        } else if let screenFrame = try? container.decode([ScreenFrameData].self) {
            self = .screenFrame(screenFrame)
        } else if let modeUpdate = try? container.decode(ModeUpdateData.self) {
            self = .modeUpdate(modeUpdate)
        } else if let dataBounce = try? container.decode(String.self) {
            self = .dataBounce(dataBounce)
        } else if let dataBounceBack = try? container.decode(String.self) {
            self = .dataBounceBack(dataBounceBack)
        } else if let remoteInstruction = try? container.decode(RemoteInstructionData.self) {
            self = .remoteInstruction(remoteInstruction)
        } else if let controlRequest = try? container.decode(ControlRequestData.self) {
            self = .controlRequest(controlRequest)
        } else if container.decodeNil() {
            self = .welcome
        } else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid message data"))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .hello(let data):
            try container.encode(data)
        case .connectionUpdate(let data):
            try container.encode(data)
        case .youAre(let data):
            try container.encode(data)
        case .beginSession(let data):
            try container.encode(data)
        case .continueSession(let data):
            try container.encode(data)
        case .sessionStatusUpdate(let data):
            try container.encode(data)
        case .sessionRatingToken(let data):
            try container.encode(data)
        case .dataError(let data):
            try container.encode(data)
        case .apiKeyError(let data):
            try container.encode(data)
        case .customMessage(let data):
            try container.encode(data)
        case .screenFrame(let data):
            try container.encode(data)
        case .modeUpdate(let data):
            try container.encode(data)
        case .dataBounce(let data):
            try container.encode(data)
        case .dataBounceBack(let data):
            try container.encode(data)
        case .remoteInstruction(let data):
            try container.encode(data)
        case .welcome, .startSessionPreparation, .ping, .pong, .endSession, .controlRequest(_):
            try container.encodeNil()
        }
    }
}
