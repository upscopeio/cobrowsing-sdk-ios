//
//  InitialMessageData.swift
//  upscopeio-sdk
//
//  Created by Upscope on 25.09.2024.
//

struct HelloData: Codable {
    var activeSince: String
    var agentPrompt: StringOption  // public
    var allowAgentRedirect: Bool
    var allowFullScreen: Bool
    var allowRemoteClick: Bool
    var allowRemoteConsole: Bool
    var allowRemoteScroll: Bool
    var allowRemoteType: Bool;
    var apiKey: String  // public
    var audioSupported: Bool
    var callName: String?
    var currentUrl: String?
    var fingerprint: String?
    var hasFocus: Bool
    var identities: StringArrayOption   // public
    var integration: String?
    var integrationIds: StringArrayOption  // public
    var jsConfiguration: Bool
    var lookupCode: String?
    var requireAuthorizationForSession: Bool
    var requireControlRequest: Bool
    var reset: Bool
    var screenWidth: Double
    var screenHeight: Double
    var sdk: String  //'ios' | 'android' | 'web'
    var shortId: String? // Save in long term storage
    var tags: StringArrayOption   // public
    var timestamp: Double
    var uniqueConnectionId: String? // Save in short term storage, one per tab
    var uniqueId: StringOption   // public
    var version: String
    
    enum CodingKeys: String, CodingKey {
        case activeSince
        case agentPrompt
        case allowAgentRedirect
        case allowFullScreen
        case allowRemoteClick
        case allowRemoteConsole
        case allowRemoteScroll
        case allowRemoteType
        case apiKey
        case audioSupported
        case callName
        case currentUrl
        case fingerprint
        case hasFocus
        case identities
        case integration
        case integrationIds
        case jsConfiguration
        case lookupCode
        case requireAuthorizationForSession
        case requireControlRequest
        case reset
        case screenWidth
        case screenHeight
        case sdk
        case shortId
        case tags
        case timestamp
        case uniqueConnectionId
        case uniqueId
        case version
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(activeSince, forKey: .activeSince)
        if case .value(let agentPromptValue) = agentPrompt {
            try container.encode(agentPromptValue, forKey: .agentPrompt)
        }
        try container.encode(allowAgentRedirect, forKey: .allowAgentRedirect)
        try container.encode(allowFullScreen, forKey: .allowFullScreen)
        try container.encode(allowRemoteClick, forKey: .allowRemoteClick)
        try container.encode(allowRemoteConsole, forKey: .allowRemoteConsole)
        try container.encode(allowRemoteScroll, forKey: .allowRemoteScroll)
        try container.encode(allowRemoteType, forKey: .allowRemoteType)
        try container.encode(apiKey, forKey: .apiKey)
        try container.encode(audioSupported, forKey: .audioSupported)
        try container.encodeIfPresent(callName, forKey: .callName)
        try container.encodeIfPresent(currentUrl, forKey: .currentUrl)
        try container.encodeIfPresent(fingerprint, forKey: .fingerprint)
        try container.encode(hasFocus, forKey: .hasFocus)
        if case .value(let identitiesValue) = identities {
            try container.encode(identitiesValue, forKey: .identities)
        }
        try container.encodeIfPresent(integration, forKey: .integration)
        if case .value(let integrationIdsValue) = integrationIds {
            try container.encode(integrationIdsValue, forKey: .integrationIds)
        }
        try container.encode(jsConfiguration, forKey: .jsConfiguration)
        try container.encodeIfPresent(lookupCode, forKey: .lookupCode)
        try container.encode(requireAuthorizationForSession, forKey: .requireAuthorizationForSession)
        try container.encode(requireControlRequest, forKey: .requireControlRequest)
        try container.encode(reset, forKey: .reset)
        try container.encode(screenWidth, forKey: .screenWidth)
        try container.encode(screenHeight, forKey: .screenHeight)
        try container.encode(sdk, forKey: .sdk)
        try container.encodeIfPresent(shortId, forKey: .shortId)
        if case .value(let tagsValue) = tags {
            try container.encode(tagsValue, forKey: .tags)
        }
        try container.encode(timestamp, forKey: .timestamp)
        try container.encodeIfPresent(uniqueConnectionId, forKey: .uniqueConnectionId)
        if case .value(let uniqueIdValue) = uniqueId {
            try container.encode(uniqueIdValue, forKey: .uniqueId)
        }
        try container.encode(version, forKey: .version)
    }
}
