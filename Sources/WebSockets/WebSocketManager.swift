//
//  WebsocketManager.swift
//  upscopeio-sdk
//
//  Created by Upscope on 20.09.2024.
//

import Foundation
import Security
import Network
import UIKit

protocol WebSocketManagerDelegate: AnyObject {
    func websocketDidUpdateStatus(_ status: ConnectionStatus)
    func logErrorMessage(_ error: String)
    func showControlRequest(with request: String?)
    func showFrame(_ frame: ScreenFrameData)
    func startSendingFrames()
    func stopSendingFrames()
}

protocol EventObserver {
    func notify(for event: MessageType, with data: Any?)
}

enum ConnectionStatus {
    case connecting
    case connected
    case disconnected
    case failed(error: Error)
}

enum ErrorType {
    case apiError, dataError
}

enum WebSocketError: Error {
    case noActiveConnection
    case encodingFailed
    case connectionLost
    case sendFailed(underlyingError: Error)
    case tooManyRequests
    case maxReconnectAttemptsReached
    case unexpectedError(Error)
}

class WebsocketManager {
    private enum Constants {
        static func url(apiKey: String, defaultRegion: String) -> String {
            return "wss://data.upscope.io/session?apiKey=\(apiKey)&version=2024.12.0&region=\(defaultRegion)"
        }
        
        static func testURL(apiKey: String) -> String {
            return "ws://206.189.121.228:3005/session?apiKey=\(apiKey)&version=0.0.0"
        }
        
        static let kShortIdKey = "shortId"
        static let kUniqueConnectionIdKey = "uniqueConnectionId"
    }
    
    weak var connectionDelegate: WebSocketManagerDelegate?
    private weak var delegate: URLSessionWebSocketDelegate?
    
    private let apiKey: String
    private var webSocketTask: URLSessionWebSocketTask?
    private var pingTask: Task<Void, Never>?
    
    private var url: URL?
    private var shortId: String?
    private var uniqueConnectionId: String?
    private var defaultRegion: String?
    private var attempts: Int?
    
    private let networkMonitor = NWPathMonitor()
    var isConnected = false
    private var connectionStatus = ConnectionStatus.disconnected
    private var configuration: Configuration?
    private var eventObserver: EventObserver
    
    private let group = DispatchGroup()
    
    private var helloData = HelloData(
        activeSince: Date.now.formatted(),        // private
        agentPrompt: .undefined,                               // public
        allowAgentRedirect: false,                      // private
        allowFullScreen: false,                      // private
        allowRemoteClick: false,                      // private
        allowRemoteConsole: false,                      // private
        allowRemoteScroll: false,                      // private
        allowRemoteType: false,                      // private
        apiKey: "",                            // public
        audioSupported: false,                      // private
        callName: nil,                          //private
        currentUrl: nil,                      // private
        fingerprint: nil,                      // private
        hasFocus: true,
        identities: .undefined,                      // public, we should not send this parameter if it is empty
        integration: nil,                      // private
        integrationIds: .undefined,                      // public, we should not send this parameter if it is empty
        jsConfiguration: false,                      // private
        lookupCode: nil,                      // private
        requireAuthorizationForSession: true,                      // private
        requireControlRequest: false,                      // private
        reset: false,                      // private
        screenWidth: UIScreen.main.bounds.size.width,                      // private
        screenHeight: UIScreen.main.bounds.size.height,                      // private
        sdk: "ios",                      // private
        shortId: "",                      // private
        tags: .undefined,                      // public, we should not send this parameter if it is empty
        timestamp: Date().timeIntervalSince1970,     // private
        uniqueConnectionId: "",                      // private
        uniqueId: .undefined,                      // public, we should not send this parameter if it is empty
        version: ""                      // private
    )
    
    var agentPrompt: StringOption = .undefined
    var identities: StringArrayOption = .undefined
    var integrationIds: StringArrayOption = .undefined
    var tags: StringArrayOption = .undefined
    var uniqueId: StringOption = .undefined
    
    init?(
        apiKey: String,
        agentPrompt: StringOption = .undefined,
        identities: StringArrayOption = .undefined,
        integrationIds: StringArrayOption = .undefined,
        tags: StringArrayOption = .undefined,
        uniqueId: StringOption = .undefined,
        delegate: URLSessionWebSocketDelegate,
        connectionDelegate: WebSocketManagerDelegate,
        eventObserver: EventObserver
    ) {
        self.apiKey = apiKey
        self.agentPrompt = agentPrompt
        self.identities = identities
        self.integrationIds = integrationIds
        self.tags = tags
        self.uniqueId = uniqueId
        self.delegate = delegate
        self.connectionDelegate = connectionDelegate
        self.eventObserver = eventObserver
        
        group.enter()
        getConfiguration(apiKey: apiKey)
        group.notify(queue: .main) { [weak self] in
            self?.setupWebSocketURL()
            self?.loadConnectionData()
            //self?.setupNetworkMonitor()
            self?.connectIfNeeded()
        }
    }
    
    public func updateOptionsAndUpdateConnection(
        agentPrompt: StringOption = .undefined,
        identities: StringArrayOption = .undefined,
        integrationIds: StringArrayOption = .undefined,
        tags: StringArrayOption = .undefined,
        uniqueId: StringOption = .undefined
    ) {
        setPublicOptions(
            agentPrompt: agentPrompt,
            identities: identities,
            integrationIds: integrationIds,
            tags: tags,
            uniqueId: uniqueId
        )
        Task {
            await connectionUpdate()
        }
    }
    
    private func setPublicOptions(
        agentPrompt: StringOption = .undefined,
        identities: StringArrayOption = .undefined,
        integrationIds: StringArrayOption = .undefined,
        tags: StringArrayOption = .undefined,
        uniqueId: StringOption = .undefined
    ) {
        if case .value(_) = agentPrompt {
            debugPrint("HEREEEEE agentPrompt updated!")
            helloData.agentPrompt = agentPrompt
        }
        if case .value(_) = identities {
            debugPrint("HEREEEEE identities updated!")
            helloData.identities = identities
        }
        if case .value(_) = integrationIds {
            debugPrint("HEREEEEE integrationIds updated!")
            helloData.integrationIds = integrationIds
        }
        if case .value(_) = tags {
            debugPrint("HEREEEEE tags updated!")
            helloData.tags = tags
        }
        if case .value(_) = uniqueId {
            debugPrint("HEREEEEE uniqueId updated!")
            helloData.uniqueId = uniqueId
        }
    }
    
    private func setupWebSocketURL() {
        if let defaultRegion, let url = URL(string: Constants.url(apiKey: apiKey, defaultRegion: defaultRegion)) {
            self.url = url
            debugPrint("Here is setuping URL \(url)")
        }
    }
    
    // MARK: - WebSocketManager Functions
    public func close() {
        debugPrint("Closing connection")
        debugPrint("Stop Sending PING")
        pingTask?.cancel()
        let reason = "Closing connection".data(using: .utf8)
        webSocketTask?.cancel(with: .goingAway, reason: reason)
    }
    
    public func sendLookUpCode(_ code: String) {
        helloData.lookupCode = code
        let helloMessage = Message(type: .connectionUpdate, data: .connectionUpdate(helloData))
        
        do {
            let jsonEncoder = JSONEncoder()
            jsonEncoder.dateEncodingStrategy = .iso8601
            let jsonData = try jsonEncoder.encode(helloMessage)
            
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                Task {
                    await send(jsonString)
                }
            }
        } catch {
            debugPrint("Error creating JSON: \(error)")
        }
    }
    
    public func connectionUpdate() async {
        let helloMessage = Message(type: .connectionUpdate, data: .connectionUpdate(helloData))
        
        do {
            let jsonEncoder = JSONEncoder()
            jsonEncoder.dateEncodingStrategy = .iso8601
            let jsonData = try jsonEncoder.encode(helloMessage)
            
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                await send(jsonString)
            }
        } catch {
            debugPrint("Error creating JSON: \(error)")
        }
    }
    
    public func connectAndListen() async throws {
        guard let url else { return }
        let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: OperationQueue())
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        
        await sendHello()
        try await receive()
    }
    
    public func reconnect() async {
        guard isConnected else {
                debugPrint("Cannot reconnect: No network connection")
                updateConnectionStatus(.disconnected)
                return
        }
        
        updateConnectionStatus(.connecting)
        if attempts == nil {
            attempts = 0
        }
        
        attempts = (attempts ?? 0) + 1
        guard let attempts else { return }
        
        guard attempts < 10 else {
            debugPrint("Failed to reconnect after 10 attempts. Giving up.")
            updateConnectionStatus(.failed(error: WebSocketError.maxReconnectAttemptsReached))
            self.attempts = nil
            return
        }
        
        debugPrint("Attempting to reconnect (Attempt \(attempts + 1) of 10)...")
        
        do {
            try await connectAndListen()
            debugPrint("Successfully reconnected after \(attempts + 1) attempt(s).")
            updateConnectionStatus(.connected)
        } catch let error as WebSocketError {
            await handleReconnectionError(error, attempts: attempts)
        } catch {
            debugPrint("Unexpected error during reconnection: \(error)")
            await retryReconnection()
        }
    }
    
    public func sendCustomMessage(value: String) {
        let dataBounceBackMessage = Message(type: .customMessage, data: .customMessage(value))
        // sending back dataBounceBack
        Task {
            do {
                let jsonData = try JSONEncoder().encode(dataBounceBackMessage)
                if let jsonString = String(data: jsonData, encoding: .utf8) {
                    await send(jsonString)
                    eventObserver.notify(for: .customMessage, with: value)
                }
            } catch {
                debugPrint("Error sending dataBounceBack: \(error)")
                connectionDelegate?.logErrorMessage(error.localizedDescription)
            }
        }
    }
    
    public func reset() {
        shortId = nil
        uniqueConnectionId = nil
        storeConnectionIds()
        Task {
            await reconnect()
        }
    }
    
    public func stopSession() async {
        await sendMessage(.stopSession)
    }
    
    public func getShortId() -> String? {
        return shortId
    }
    
    public func sendCustomMessage(message: String) {
        sendCustomMessage(value: """
"d": [
        {
            "visitor": "cBSAKZQZXXR20EYFZH"
        },
        "{\"foo\":1}"
    ]
""")
    }
    
    // MARK: - CONFIGURATION
    private func getConfiguration(apiKey: String) {
        Task {
            debugPrint("HERE IS Starting...")
            configuration = await ConfigurationAPIClient.setConfiguration(with: apiKey)
            debugPrint("HERE IS CONFIGURATION \(configuration)")
            setupDefaultRegionIfNeeded()
            group.leave()
        }
    }
    
    // MARK: - Default Region
    private func setupDefaultRegionIfNeeded() {
        guard let configuration = configuration else {
            return
        }
        
        if let savedDefaultRegion = UserDefaults.standard.string(forKey: UserDefaults.UpscopeKeys.defaultRegion) {
            self.configuration?.defaultRegion = savedDefaultRegion
            defaultRegion = savedDefaultRegion
            debugPrint("HERE IS SAVED default region \(defaultRegion)")
        } else {
            UserDefaults.standard.setValue(configuration.defaultRegion, forKey: UserDefaults.UpscopeKeys.defaultRegion)
            defaultRegion = configuration.defaultRegion
            debugPrint("HERE IS SAVING... default region \(defaultRegion)")
        }
    }
    
    // MARK: - Utility Methods
    private func connectIfNeeded() {
        debugPrint("HERE IS CONNECTING!")
        if let autoconnect = configuration?.settings.autoconnect, autoconnect {
            Task {
                do {
                    try await connectAndListen()
                } catch {
                    debugPrint("Error while connecting \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func setupNetworkMonitor() {
        debugPrint("Setuping network monitor")
        networkMonitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            Task {
                await self.handleNetworkStatusChange(connected: path.status == .satisfied)
            }
        }
        let queue = DispatchQueue(label: "NetworkMonitor")
        networkMonitor.start(queue: queue)
    }
    
    private func handleNetworkStatusChange(connected: Bool) async {
        isConnected = connected
        if isConnected {
            debugPrint("Network connection restored")
            if case .disconnected = connectionStatus {
                await reconnect()
            }
        } else {
            debugPrint("Network connection lost")
            updateConnectionStatus(.disconnected)
            close()
        }
    }
    
    private func startPing() {
        pingTask = Task {
            while !Task.isCancelled {
                do {
                    debugPrint("Start Sending PONG")
                    await sendMessage(.ping)
                    try await Task.sleep(nanoseconds: 15_000_000_000) //15s
                } catch {
                    debugPrint("Error when sending PING: \(error)")
                    break
                }
            }
        }
    }
    
    private func sendPong() {
        Task {
            debugPrint("Sending PONG")
            await sendMessage(.pong)
        }
    }
    
    private func sendHello() async {
        if let configuration {
            helloData.requireAuthorizationForSession = configuration.settings.requireAuthorizationForSession
        }
        
        helloData.apiKey = apiKey
        helloData.agentPrompt = agentPrompt
        helloData.identities = identities
        helloData.integrationIds = integrationIds
        helloData.tags = tags
        helloData.uniqueId = uniqueId
        helloData.shortId = shortId
        helloData.uniqueConnectionId = uniqueConnectionId
            
        let helloMessage = Message(type: .hello, data: .hello(helloData))
        
        do {
            let jsonEncoder = JSONEncoder()
            jsonEncoder.dateEncodingStrategy = .iso8601
            let jsonData = try jsonEncoder.encode(helloMessage)
            
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                await send(jsonString)
            }
        } catch {
            debugPrint("Error creating JSON: \(error)")
        }
    }
    
    private func focus() async {
        await sendMessage(.focus)
    }
    
    private func sessionStatusUpdate() async {
        let message = Message(type: .sessionStatusUpdate, data: .sessionStatusUpdate(SessionStatus.pending.rawValue))
        
        do {
            let jsonEncoder = JSONEncoder()
            let jsonData = try jsonEncoder.encode(message)
            
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                await send(jsonString)
            } else {
                throw WebSocketError.encodingFailed
            }
        } catch {
            debugPrint("Error sending Session Status Update JSON: \(error)")
        }
    }
    
    private func grantControl() async {
        await sendMessage(.grantControl)
    }
    
    private func sendMessage(_ type: MessageType) async {
        let message = Message(type: type, data: nil)
        
        do {
            let jsonEncoder = JSONEncoder()
            let jsonData = try jsonEncoder.encode(message)
            
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                await send(jsonString)
                // emiting to all of the observers about event received
                eventObserver.notify(for: message.type, with: message.data)
            } else {
                throw WebSocketError.encodingFailed
            }
        } catch {
            debugPrint("Error sending \(type.rawValue) JSON: \(error)")
        }
    }

    private func send(_ message: String) async {
        guard let task = webSocketTask else {
            return
        }
        
        do {
            try await task.send(.string(message))
        } catch {
            var socketError: WebSocketError
            if let urlError = error as? URLError, urlError.code == .networkConnectionLost {
                socketError =  WebSocketError.connectionLost
            } else {
                socketError = WebSocketError.sendFailed(underlyingError: error)
            }
            await handleReconnectionError(socketError, attempts: 0)
        }
    }
    
    private func receive() async throws {
        guard let task = webSocketTask else {
            throw NSError(
                domain: "WebSocketError",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "WebSocket task is nil"]
            )
        }
        
        do {
            while true {
                let result = try await task.receive()
                switch result {
                case .data(let data):
                    eventObserver.notify(for: .customMessage, with: data)
                    debugPrint("Data received \(data)")
                case .string(let text):
                    debugPrint("text received \(text)")
                    await handleReceivedMessage(text)
                @unknown default:
                    debugPrint("Websockets Unknown message data type")
                }
            }
        } catch {
            debugPrint("Error when receiving: \(error)")
            throw error
        }
    }
    
    private func handleReceivedMessage(_ message: String) async {
        do {
            guard let data = message.data(using: .utf8) else { return }
            let decodedMessage = try JSONDecoder().decode(Message.self, from: data)
            debugPrint("Received \(decodedMessage.type.rawValue)")
            
            // emiting to all of the observers about event received
            eventObserver.notify(for: decodedMessage.type, with: decodedMessage.data)
            
            switch decodedMessage.type {
            case .youAre:
                if case .youAre(let youAreData) = decodedMessage.data {
                    shortId = youAreData.shortId
                    uniqueConnectionId = youAreData.uniqueConnectionId
                    debugPrint("You are: with \(shortId) and \(uniqueConnectionId)")
                    storeConnectionIds()
                    updateConnectionStatus(.connected)
                }
                
            case .welcomeBack:
                debugPrint("Welcome back received - maintaining existing connection IDs")
                shortId = nil
                uniqueConnectionId = nil
                storeConnectionIds()
                updateConnectionStatus(.connected)
                startPing()
                
            case .startSessionPreparation:
                debugPrint("startSessionPreparation")
            case .beginSession:
                if case .beginSession(let data) = decodedMessage.data {
                    debugPrint("Received beginSession with \(data.requestingAgent)")
                    handleBeginSession(data)
                }
                
            case .sessionRatingToken:
                if case .sessionRatingToken(let sessionRatingTokenData) = decodedMessage.data {
                    debugPrint("Received beginSession with \(sessionRatingTokenData.requestingAgent)")
                }
                
            case .continueSession:
                if case .continueSession(let data) = decodedMessage.data {
                    handleContinueSession(data)
                }
                
            case .sessionStatusUpdate:
                if case .sessionStatusUpdate(let status) = decodedMessage.data {
                    handleSessionStatusUpdate(status)
                }
                
            case .controlRequest:
                if case .controlRequest(let request) = decodedMessage.data {
                    handleControlRequest(request)
                }
                
            case .endSession:
                handleEndSession()
                
            case .controlGranted:
                debugPrint("Received controlGranted")
                
            case .remoteInstruction:
                if case .remoteInstruction(let data) = decodedMessage.data {
                    handleRemoteInstruction(data)
                    debugPrint("remoteInstruction data: \(data)")
                }
                
            case .screenFrame:
                if case .screenFrame(let data) = decodedMessage.data {
                    handleScreenFrame(data)
                }
                
            case .modeUpdate:
                if case .modeUpdate(let data) = decodedMessage.data {
                    handleModeUpdate(data)
                    debugPrint("modeUpdate data: \(data)")
                }
                
            case .dataError:
                if case .dataError(let errorData) = decodedMessage.data {
                    handleError(errorData, type: .dataError)
                }
                
            case .apiKeyError:
                if case .dataError(let errorData) = decodedMessage.data {
                    handleError(errorData, type: .apiError)
                }
                
            case .doNotReconnect:
                close()
                
            case .ping:
                sendPong()
                
            case .pong:
                pingTask?.cancel()
                
            case .dataBounce:
                if case .dataBounce(let data) = decodedMessage.data {
                    handleDataBounce(data)
                    debugPrint("dataBounce data: \(data)")
                }
                
            case .dataBounceBack:
                if case .dataBounceBack(let data) = decodedMessage.data {
                    handleDataBounceBack(data)
                    debugPrint("dataBounceBack data: \(data)")
                }
                
            case .customMessage:
                if case .customMessage(let data) = decodedMessage.data {
                    handleCustomMessage(data)
                    debugPrint("customMessage data: \(data)")
                }
                
            default:
                debugPrint("Unhandled message type: \(decodedMessage.type)")
            }
        } catch {
            eventObserver.notify(for: .customMessage, with: error)
            debugPrint("Error parsing received message: \(error)")
        }
    }
    
    private func handleBeginSession(_ data: BeginSessionData) {
        let sessionStatus = SessionStatus.active // or "pending"
        Task {
            await sendSessionStatusUpdate(sessionStatus)
        }
    }
    
    private func handleContinueSession(_ data: ContinueSessionData) {
        if data.mode == .visitorScreen {
            startSendingFrames()
        }
    }
    
    // TODO: - more clarification for this one
    private func handleSessionStatusUpdate(_ value: String) {
        let status = SessionStatus(rawValue: value)
        debugPrint("Session status update: \(status?.rawValue ?? "")")
        if status == .active {
            debugPrint("Session is now active")
            startSendingFrames()
            // connectionDelegate.showRequest() if user is in agent_mode ???
        }
    }
    
    private func handleControlRequest(_ data: ControlRequestData) {
        connectionDelegate?.showControlRequest(with: data.request)
    }
    
    private func handleEndSession() {
        stopSendingFrames()
        // Clean up session resources
    }
    
    private func handleRemoteInstruction(_ data: RemoteInstructionData) {
        debugPrint("Handle remote instruction in the future with data: \(data)")
    }
    
    private func handleScreenFrame(_ data: [ScreenFrameData]) {
        debugPrint("Recieved screenFrame: \(data.first)")
        
    }
    
    private func handleModeUpdate(_ data: ModeUpdateData) {
        if data.desiredMode == .visitorScreen {
            startSendingFrames()
        } else {
            stopSendingFrames()
        }
    }
    
    private func handleError(_ errorData: ErrorData, type: ErrorType) {
        switch type {
        case .apiError:
            debugPrint("Data error received: \(errorData.description)")
        case .dataError:
            debugPrint("API key error received: \(errorData.description)")
        }
        connectionDelegate?.logErrorMessage(errorData.description)
    }
    
    private func sendDataBounce() {
        let timestamp = "\(Int(Date().timeIntervalSince1970 * 1000))"
        let dataBounceMessage = Message(type: .dataBounce, data: .dataBounce(timestamp))
        
        Task {
            do {
                let jsonData = try JSONEncoder().encode(dataBounceMessage)
                if let jsonString = String(data: jsonData, encoding: .utf8) {
                    await send(jsonString)
                }
            } catch {
                debugPrint("Error sending dataBounce: \(error)")
                connectionDelegate?.logErrorMessage(error.localizedDescription)
            }
        }
    }
    
    private func sendDataBounceBack(with value: String) {
        let dataBounceBackMessage = Message(type: .dataBounceBack, data: .dataBounceBack(value))
        // sending back dataBounceBack
        Task {
            do {
                let jsonData = try JSONEncoder().encode(dataBounceBackMessage)
                if let jsonString = String(data: jsonData, encoding: .utf8) {
                    await send(jsonString)
                }
            } catch {
                debugPrint("Error sending dataBounceBack: \(error)")
                connectionDelegate?.logErrorMessage(error.localizedDescription)
            }
        }
    }
    
    func sendScreenFrame(_ base64Frame: String) {
        let imageSize = ImageSize(
            w: helloData.screenWidth,
            h: helloData.screenHeight
        )
        
        let frameMessage = Message(
            type: .screenFrame,
            data: .screenFrame([.base64String(base64Frame), .size(imageSize)])
        )
                
        Task {
            do {
                let jsonData = try JSONEncoder().encode(frameMessage)
                if let jsonString = String(data: jsonData, encoding: .utf8) {
                    await send(jsonString)
                    eventObserver.notify(for: .screenFrame, with: "\(imageSize)")
                }
            } catch {
                debugPrint("Error sending screen frame: \(error)")
                connectionDelegate?.logErrorMessage(error.localizedDescription)
            }
        }
    }
    
    private func handleDataBounce(_ data: String) {
        let dataBounceBackMessage = Message(type: .dataBounceBack, data: .dataBounceBack(data))
        // sending back dataBounceBack
        Task {
            do {
                let jsonData = try JSONEncoder().encode(dataBounceBackMessage)
                if let jsonString = String(data: jsonData, encoding: .utf8) {
                    await send(jsonString)
                }
            } catch {
                debugPrint("Error sending dataBounceBack: \(error)")
                connectionDelegate?.logErrorMessage(error.localizedDescription)
            }
        }
    }
    
    private func handleDataBounceBack(_ data: String) {
        debugPrint("Received dataBounceBack with data: \(data)")
    }
    
    private func handleCustomMessage(_ data: String) {
        debugPrint("Recieved custom messages \(data)")
    }
    
    private func sendSessionStatusUpdate(_ status: SessionStatus) async {
        let message = Message(type: .sessionStatusUpdate, data: .sessionStatusUpdate(status.rawValue))
        do {
            let jsonData = try JSONEncoder().encode(message)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                await send(jsonString)
            }
        } catch {
            debugPrint("Error sending session status update: \(error)")
        }
    }
    
    private func startSendingFrames() {
        print("HERE SHOULD BE START")
        self.connectionDelegate?.startSendingFrames()
    }
    
    private func stopSendingFrames() {
        self.connectionDelegate?.stopSendingFrames()
    }
    
    private func handleReconnectionError(_ error: WebSocketError, attempts: Int) async {
        switch error {
        case .noActiveConnection:
            debugPrint("No active connection. Retrying...")
            await retryReconnection()
        case .encodingFailed:
            debugPrint("Message encoding failed. This is likely a client-side issue.")
            updateConnectionStatus(.failed(error: error))
        case .connectionLost:
            debugPrint("Connection lost. Retrying...")
            await retryReconnection()
        case .sendFailed(let underlyingError):
            if let urlError = underlyingError as? URLError {
                switch urlError.code {
                case .cannotConnectToHost:
                    debugPrint("Cannot connect to host. Ensure the server is running and the URL is correct.")
                case .notConnectedToInternet, .networkConnectionLost:
                    debugPrint("Not connected to the internet. Please check your network connection.")
                case .timedOut:
                    debugPrint("Connection timed out. The server might be slow or unresponsive.")
                default:
                    debugPrint("URLError: \(urlError.localizedDescription)")
                }
                debugPrint("Retrying...")
                await retryReconnection()
                
            } else {
                debugPrint("Failed to send message: \(underlyingError). Retrying...")
                await retryReconnection()
            }
        case .tooManyRequests:
            debugPrint("Server is handling too many requests. Retrying after a longer delay...")
            await retryReconnection(delay: 10_000_000_000) // 10 seconds
        case .maxReconnectAttemptsReached:
            debugPrint("Max reconnection attempts reached.")
            updateConnectionStatus(.failed(error: error))
        case .unexpectedError(_):
            debugPrint("Unexpected unknown error.")
            updateConnectionStatus(.failed(error: error))
        }
    }
    
    private func retryReconnection(delay: UInt64 = 3_000_000_000) async {
        do {
            try await Task.sleep(nanoseconds: delay)
            await reconnect()
        } catch {
            debugPrint("Error during delay before reconnection: \(error)")
            updateConnectionStatus(.failed(error: WebSocketError.unexpectedError(error)))
        }
    }
    
    private func updateConnectionStatus(_ status: ConnectionStatus) {
        DispatchQueue.main.async {
            self.connectionStatus = status
            self.connectionDelegate?.websocketDidUpdateStatus(status)
            NotificationCenter.default.post(name: .websocketStatusDidChange, object: nil, userInfo: ["status": status])
            
            switch status {
            case .connecting:
                debugPrint("WebSocket is connecting...")
            case .connected:
                debugPrint("WebSocket connected successfully")
            case .disconnected:
                debugPrint("WebSocket disconnected")
            case .failed(let error):
                debugPrint("WebSocket connection failed: \(error)")
            }
        }
    }
    
    private func loadConnectionData() {
        debugPrint("Loading connection data")
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: Constants.kShortIdKey
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecSuccess, let data = result as? Data, let shortId = String(data: data, encoding: .utf8) {
            self.shortId = shortId
        }
        
        query = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: Constants.kUniqueConnectionIdKey
        ]
        result = nil
        let status2 = SecItemCopyMatching(query as CFDictionary, &result)
        if status2 == errSecSuccess, let data = result as? Data, let uniqueConnectionId = String(data: data, encoding: .utf8) {
            self.uniqueConnectionId = uniqueConnectionId
        }
    }
    
    private func storeConnectionIds() {
        debugPrint("Storing connection data")

        let shortIdData = (self.shortId ?? "").data(using: .utf8)
        let uniqueConnectionIdData = (self.uniqueConnectionId ?? "").data(using: .utf8)
        
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: Constants.kShortIdKey,
            kSecValueData as String: shortIdData ?? Data()
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
        
        query = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: Constants.kUniqueConnectionIdKey,
            kSecValueData as String: uniqueConnectionIdData ?? Data()
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    deinit {
        networkMonitor.cancel()
    }
}

//MARK: - User Defaults
extension WebsocketManager {
    func save(_ value: String, for key: String) {
        UserDefaults.standard.setValue(value, forKey: key)
    }
}

extension Notification.Name {
    static let websocketStatusDidChange = Notification.Name("websocketStatusDidChange")
}
