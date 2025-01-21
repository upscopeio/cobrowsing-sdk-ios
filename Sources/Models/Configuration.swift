//
//  Configuration.swift
//  upscopeio-sdk
//
//  Created by Upscope on 9.11.2024.
//

struct Configuration: Codable {
    struct Settings: Codable {
        let beta: Bool
        let teamDomain: String
        let showUpscopeLink: Bool
        let showTerminateButton: Bool
        let enableLookupCodeOnShake: Bool
        let lookupCodeKeyTitle: String?
        let lookupCodeKeyMessage: String?
        let requireAuthorizationForSession: Bool
        let authorizationPromptTitle: String?
        let authorizationPromptMessage: String?
        let endOfScreenshareMessage: String?
        let translationsYes: String?
        let translationsNo: String?
        let translationsOk: String?
        let translationsStopSession: String?
        let autoconnect: Bool
        let region: String?
    }
    
    let settings: Settings
    var defaultRegion: String
    let exists: Bool
}

extension Configuration {
    static var fakeItem: Configuration {
        .init(
            settings: .init(
                beta: false,
                teamDomain: "mobile.upscope.io",
                showUpscopeLink: false,
                showTerminateButton: false,
                enableLookupCodeOnShake: false,
                lookupCodeKeyTitle: nil,
                lookupCodeKeyMessage: nil,
                requireAuthorizationForSession: true,
                authorizationPromptTitle: "Some title here",
                authorizationPromptMessage: "Some message here",
                endOfScreenshareMessage: nil,
                translationsYes: "Yes",
                translationsNo: "No",
                translationsOk: "Ok",
                translationsStopSession: "Stop",
                autoconnect: false,
                region: "Great Britain"
            ),
            defaultRegion: "Great Britain",
            exists: true
        )
    }
}
