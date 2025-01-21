//
//  UpscopeManager.swift
//
//
//  Created by Upscope on 16.12.2024.
//

import Foundation
import ReplayKit
import UIKit
import Photos
import SwiftUI

protocol UpscopeIOProtocol {
    func connect()
    func reset()
    func getShortId() -> String?
    func getLookupCode() -> String
    func updateConnection()
    func getWatchLink() -> URL?
    func on(event: MessageType, listener: @escaping (Any?) -> Void)
    func off(event: MessageType)
    func stopSession()
    func customMessage(message: String)
    
    func subscribeToIsConnected(onConnectedChanged: @escaping (Bool) -> ())
}

public enum StringOption: Codable {
    case undefined
    case value(String?)
}

public enum StringArrayOption: Codable {
    case undefined
    case value([String])
}

public class UpscopeManager: NSObject, EventObserver, UpscopeIOProtocol {
    private enum Constants {
        static func watchLink(shortId: String) -> String {
            return "https://helloscreen.com/w/\(shortId)"
        }
    }
    
    private let recorder = RPScreenRecorder.shared()
    private var isRecording = false
    private var isCapturing = false
    private var isConnected = false {
        didSet {
            onConnectedChanged(isConnected)
        }
    }
    private var showRecordedVideo = false
    private var showRecordedFrames = false
    private var capturedFrames: [UIImage] = []
    private var videoURL: URL?
    private var error: String = ""
    private var controlRequest: String = ""
    private var screenFrame: ScreenFrameData?
    
    private var currentRecordType: RecordType = .video
    private let frameStorage = FrameStorage()
    private var captureEngine: ScreenCaptureEngine?
    private var websocketManager: WebsocketManager?
    private var eventListeners: [MessageType: [(Any) -> Void]] = [:]
    private var onConnectedChanged: (Bool) -> () = { _ in }
        
    public init(
        apiKey: String,
        agentPrompt: StringOption = .undefined,
        identities: StringArrayOption = .undefined,
        integrationIds: StringArrayOption = .undefined,
        tags: StringArrayOption = .undefined,
        uniqueId: StringOption = .undefined
    ) {
        super.init()
        self.websocketManager = WebsocketManager(
            apiKey: apiKey,
            agentPrompt: agentPrompt,
            identities: identities,
            integrationIds: integrationIds,
            tags: tags,
            uniqueId: uniqueId,
            delegate: self,
            connectionDelegate: self,
            eventObserver: self
        )
    }
        
    //MARK: Record video
    private func startVideoRecording() {
        recorder.isMicrophoneEnabled = false
        recorder.startRecording { error in
            if let error {
                debugPrint(error.localizedDescription)
            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.isRecording = true
                }
            }
        }
    }
    
    private func stopVideoRecording() {
        let name = UUID().uuidString + ".mov"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        recorder.stopRecording(withOutput: url) { [weak self] error in
            if let error {
                debugPrint(error.localizedDescription)
            } else {
                DispatchQueue.main.async {
                    self?.videoURL = url
                    self?.isRecording = false
                    self?.showRecordedVideo.toggle()
                }
            }
        }
    }
    
    // MARK: Capture frames
    private func startScreenCapturing() {
        Task {
            await frameStorage.clearFrames()
        }
        
        captureEngine = ScreenCaptureEngine(frameHandler: { [weak self] image in
            guard let self = self else { return }
            Task {
                let isNewFrame = await self.frameStorage.addFrameIfNeeded(image)
                if isNewFrame, let imageBase64 = image.base64 {
                    self.websocketManager?.sendScreenFrame(imageBase64)
                }
            }
        })
        
        captureEngine?.startCapture()
        isCapturing = true
    }
    
    private func stopScreenCapturing(saveToPhotos: Bool = false) {
        captureEngine?.stopCapture()
        captureEngine = nil
        
        Task {
            capturedFrames = await getCapturedFrames()
            isCapturing = false
            showRecordedFrames = true
            let frameCount = await frameStorage.frames.count
            debugPrint("Captured \(frameCount) frames")
            if saveToPhotos {
                await saveCapturedFramesToGallery()
            }
        }
    }
    
    private func saveCapturedFramesToGallery() async {
        let status = PHPhotoLibrary.authorizationStatus()
        if status == .notDetermined {
            PHPhotoLibrary.requestAuthorization { newStatus in
                if newStatus != .authorized {
                    debugPrint("Permission not granted to save to photo library.")
                    return
                }
            }
        }
        
        if PHPhotoLibrary.authorizationStatus() == .authorized {
            let frames = await self.getCapturedFrames()
            PHPhotoLibrary.shared().performChanges {
                
                for frame in frames {
                    PHAssetChangeRequest.creationRequestForAsset(from: frame)
                }
            } completionHandler: { success, error in
                if success {
                    debugPrint("Frames saved to photo library successfully.")
                } else if let error = error {
                    debugPrint("Error saving frames to photo library: \(error.localizedDescription)")
                }
            }
        } else {
            debugPrint("Permission not granted to save to photo library.")
        }
    }
    
    private func getCapturedFrames() async -> [UIImage] {
        await frameStorage.frames
    }

    // MARK: - Official API Methods
    public func connect() {
        Task {
            do {
                try await self.websocketManager?.connectAndListen()
                notify(for: .beginSession, with: "Connected")
            } catch {
                debugPrint("Error while connecting \(error.localizedDescription)")
                notify(for: .beginSession, with: "Error")
            }
        }
    }
    
    public func stopSession() {
        Task {
            await websocketManager?.stopSession()
            websocketManager?.close()
            eventListeners.removeAll()
        }
    }
    
    public func reset() {
        stopSession()
        Task {
            await websocketManager?.reconnect()
        }
    }
    
    public func getShortId() -> String? {
        return websocketManager?.getShortId()
    }
    
    public func getLookupCode() -> String {
        let code = Int.random(in: 1000...9999)
        
        let expirationDate = Date().addingTimeInterval(86400) // 24 hours from now
        UserDefaults.standard.set(code, forKey: UserDefaults.UpscopeKeys.lookupCode)
        UserDefaults.standard.set(expirationDate, forKey: UserDefaults.UpscopeKeys.lookupCodeExpriration)
        UserDefaults.standard.synchronize()
        
        websocketManager?.sendLookUpCode(code.description)
        
        return code.description
    }
    
    public func updateConnection() {
        Task {
            await websocketManager?.connectionUpdate()
        }
    }
    
    public func getWatchLink() -> URL? {
        guard let shortId = websocketManager?.getShortId() else {
            return nil
        }
        return URL(string: Constants.watchLink(shortId: shortId))
    }
    
    public func on(event: MessageType, listener: @escaping (Any?) -> Void) {
        if eventListeners[event] == nil {
            eventListeners[event] = []
        }
        eventListeners[event]?.append(listener)
    }
    
    // Function to emit an event
    internal func notify(for event: MessageType, with data: Any?) {
        guard let listeners = eventListeners[event] else { return }
        for listener in listeners {
            listener(data)
        }
    }
    
    public func customMessage(message: String) {
        websocketManager?.sendCustomMessage(value: message)
        notify(for: .customMessage, with: message) // TODO: - remove if not needed
    }
    
    public func off(event: MessageType) {
        if let eventListeners = eventListeners[event], !eventListeners.isEmpty {
            self.eventListeners[event] = []
        }
    }
    
    public func updateOptions(
        agentPrompt: StringOption = .undefined,
        identities: StringArrayOption = .undefined,
        integrationIds: StringArrayOption = .undefined,
        tags: StringArrayOption = .undefined,
        uniqueId: StringOption = .undefined
    ) {
        self.websocketManager?.updateOptionsAndUpdateConnection(
            agentPrompt: agentPrompt,
            identities: identities,
            integrationIds: integrationIds,
            tags: tags,
            uniqueId: uniqueId
        )
    }
    
    // TODO: - remove when it is not needed anymore
    public func getIsConnected() -> Bool {
        return websocketManager?.isConnected ?? false
    }
    
    public func subscribeToIsConnected(onConnectedChanged: @escaping (Bool) -> ()) {
        self.onConnectedChanged = onConnectedChanged
    }
}

extension UpscopeManager: RecordingProtocol {
    internal func startRecordingAction(_ type: RecordType) {
        currentRecordType = type
        switch type {
        case .video:
            startVideoRecording()
        case .frames:
            startScreenCapturing()
        }
    }
    
    internal func stopRecordingAction() {
        switch currentRecordType {
        case .video:
            stopVideoRecording()
        case .frames:
            stopScreenCapturing()
        }
    }
}

extension UpscopeManager: URLSessionWebSocketDelegate {
//    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
//        debugPrint("Web Socket did connect")
//    }
//
//    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
//        debugPrint("Web Socket did disconnect")
//    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didReceiveResponse
                    response: AnyObject) {
        debugPrint("Web Socket did receive response")
    }
}

extension UpscopeManager: WebSocketManagerDelegate {
    internal func websocketDidUpdateStatus(_ status: ConnectionStatus) {
        if case .connected = status {
            isConnected = true
        } else {
            isConnected = false
        }
    }
    
    internal func logErrorMessage(_ error: String) {
        self.error = error
    }
    
    internal func showControlRequest(with request: String?) {
        controlRequest = request ?? "May Upscope share your screen with others?"
    }
    
    internal func showFrame(_ frame: ScreenFrameData) {
        screenFrame = frame
    }
    
    internal func startSendingFrames() {
        startScreenCapturing()
    }
    
    internal func stopSendingFrames() {
        stopSendingFrames()
    }
}
