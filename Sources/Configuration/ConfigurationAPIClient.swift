//
//  ConfigurationAPIClient.swift
//  upscopeio-sdk
//
//  Created by Upscope on 11.12.2024.
//

import Foundation

fileprivate enum NetworkingError: Error {
    case encodingFailed(innerError: EncodingError)
    case decodingFailed(innerError: DecodingError)
    case invalidStatusCode(statusCode: Int)
    case requestFailed(innerError: URLError)
    case otherError(innerError: Error)
}

enum ConfigurationAPIClient {
    // All the constants here
    private enum Constants {
        static func getURLString(apiKey: String) -> String {
            return "https://sdkconfig.upscope.io/\(apiKey).json"
        }
    }
    
    static func setConfiguration(with apiKey: String) async -> Configuration? {
        guard let url = URL(string: Constants.getURLString(apiKey: apiKey)) else {
            return nil
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode else {
                throw NetworkingError.invalidStatusCode(statusCode: -1)
            }
            
            guard (200...299).contains(statusCode) else {
                throw NetworkingError.invalidStatusCode(statusCode: statusCode)
            }
            
            let decodedResponse = try JSONDecoder().decode(Configuration.self, from: data)
            debugPrint("Recieved CONFIGURATION \(decodedResponse)")
            return decodedResponse
        } catch {
            debugPrint("Error! Here is \(error.localizedDescription)")
            fatalError(error.localizedDescription) // TODO: - maybe handle this error message with popup?
        }
    }
}
