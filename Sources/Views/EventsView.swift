//
//  EventsView.swift
//
//
//  Created by Upscope on 17.12.2024.
//

import SwiftUI
import AVKit

private struct EventsView: View {
    @State private var newText = ""
    @State private var isFullScreenPresented = false
    @State private var savedTexts: [String] = []
    @State private var selectedImage: UIImage?
    @State private var isAlertPresented = false
    @State private var isRequestControlPresented = false
    
    var body: some View {
        NavigationView {
            TabView {
                ScrollView {
                    VStack(spacing: 10) {
//                        helloEventButton
//                        connectionUpdateButton
//                        focusButton
//                        sessionStatusUpdateButton
//                        stopSessionButton
//                        customMessageButton
//                        grantControlRequestButton
//                        screenFrameButton
//                        dataBounceButton
//                        dataBounceBackButton
                    }
                }
                .tabItem { Label("Events", systemImage: "square.and.pencil") }
            }
            .padding()
            .navigationTitle("Record SDK Example")
        }
    }
    
//    private var capturedFramesView: some View {
//        VStack {
//            Text("Captured Frames")
//                .font(.headline)
//            
//            ScrollView {
//                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
//                    ForEach(viewModel.capturedFrames.indices, id: \.self) { index in
//                        Image(uiImage: viewModel.capturedFrames[index])
//                            .resizable()
//                            .scaledToFit()
//                            .frame(height: 100)
//                            .cornerRadius(8)
//                            .onTapGesture {
//                                selectedImage = viewModel.capturedFrames[index]
//                                isFullScreenPresented = true
//                            }
//                    }
//                }
//            }
//            
//            Button(action: {
//                viewModel.showRecordedFrames = false
//                viewModel.capturedFrames = []
//            }) {
//                Text("Close")
//                    .foregroundColor(.white)
//                    .padding()
//                    .background(Color.blue)
//                    .cornerRadius(10)
//            }
//        }
//    }
//    
//    private func videoPlayerView(url: URL) -> some View {
//        ZStack(alignment: .topTrailing) {
//            VideoPlayer(player: AVPlayer(url: url))
//                .onAppear {
//                    AVPlayer(url: url).play()
//                }
//            
//            Button(action: {
//                viewModel.showRecordedVideo.toggle()
//            }) {
//                Image(systemName: "xmark.circle.fill")
//                    .resizable()
//                    .frame(width: 30, height: 30)
//                    .padding()
//                    .foregroundColor(.white)
//            }
//        }
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
//        .background(Color.black.edgesIgnoringSafeArea(.all))
//    }
    
    // To-Server Events
//    private var helloEventButton: some View {
//        Button(action: { viewModel.hello() }) {
//            Text("Hello")
//                .foregroundColor(.white)
//                .padding()
//                .frame(maxWidth: .infinity)
//                .background(viewModel.isConnected ? Color.green : Color.green.opacity(0.2))
//                .cornerRadius(10)
//        }
//        .disabled(!viewModel.isConnected)
//    }
//    
//    private var connectionUpdateButton: some View {
//        Button(action: { viewModel.connectionUpdate() }) {
//            Text("Connection Update")
//                .foregroundColor(.white)
//                .padding()
//                .frame(maxWidth: .infinity)
//                .background(viewModel.isConnected ? Color.green : Color.green.opacity(0.2))
//                .cornerRadius(10)
//        }
//        .disabled(!viewModel.isConnected)
//    }
//    
//    private var focusButton: some View {
//        Button(action: { viewModel.focus() }) {
//            Text("Focus")
//                .foregroundColor(.white)
//                .padding()
//                .frame(maxWidth: .infinity)
//                .background(viewModel.isConnected ? Color.green : Color.green.opacity(0.2))
//                .cornerRadius(10)
//        }
//        .disabled(!viewModel.isConnected)
//    }
//    
//    private var sessionStatusUpdateButton: some View {
//        Button(action: { viewModel.sessionStatusUpdate() }) {
//            Text("Session Status Update")
//                .foregroundColor(.white)
//                .padding()
//                .frame(maxWidth: .infinity)
//                .background(viewModel.isConnected ? Color.green : Color.green.opacity(0.2))
//                .cornerRadius(10)
//        }
//        .disabled(!viewModel.isConnected)
//    }
//    
//    private var stopSessionButton: some View {
//        Button(action: { viewModel.stopSession() }) {
//            Text("Stop Session")
//                .foregroundColor(.white)
//                .padding()
//                .frame(maxWidth: .infinity)
//                .background(viewModel.isConnected ? Color.green : Color.green.opacity(0.2))
//                .cornerRadius(10)
//        }
//        .disabled(!viewModel.isConnected)
//    }
//    
//    private var customMessageButton: some View {
//        Button(action: { viewModel.sendCustomMessage() }) {
//            Text("Custom Message")
//                .foregroundColor(.white)
//                .padding()
//                .frame(maxWidth: .infinity)
//                .background(viewModel.isConnected ? Color.green : Color.green.opacity(0.2))
//                .cornerRadius(10)
//        }
//        .disabled(!viewModel.isConnected)
//    }
//    
//    private var grantControlRequestButton: some View {
//        Button(action: { viewModel.grantRequest() }) {
//            Text("Grant Control")
//                .foregroundColor(.white)
//                .padding()
//                .frame(maxWidth: .infinity)
//                .background(viewModel.isConnected ? Color.green : Color.green.opacity(0.2))
//                .cornerRadius(10)
//        }
//        .disabled(!viewModel.isConnected)
//    }
//    
//    private var screenFrameButton: some View {
//        Button(action: { viewModel.sendScreenFrame() }) {
//            Text("Screen Frame")
//                .foregroundColor(.white)
//                .padding()
//                .frame(maxWidth: .infinity)
//                .background(viewModel.isConnected ? Color.green : Color.green.opacity(0.2))
//                .cornerRadius(10)
//        }
//        .disabled(!viewModel.isConnected)
//    }
//    
//    private var dataBounceButton: some View {
//        Button(action: { viewModel.sendDataBounce() }) {
//            Text("Data Bounce")
//                .foregroundColor(.white)
//                .padding()
//                .frame(maxWidth: .infinity)
//                .background(viewModel.isConnected ? Color.green : Color.green.opacity(0.2))
//                .cornerRadius(10)
//        }
//        .disabled(!viewModel.isConnected)
//    }
//    
//    private var dataBounceBackButton: some View {
//        Button(action: { viewModel.sendDataBounceBack() }) {
//            Text("Data Bounce Back")
//                .foregroundColor(.white)
//                .padding()
//                .frame(maxWidth: .infinity)
//                .background(viewModel.isConnected ? Color.green : Color.green.opacity(0.2))
//                .cornerRadius(10)
//        }
//        .disabled(!viewModel.isConnected)
//    }
}



