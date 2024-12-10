//
//  OpenAI_Responses.swift
//  LMCC Transcriber
//
//  Created by Smetana, Ryan on 5/22/23.
//

import Foundation

public struct CompletionResponse: Codable {
    public let id: String
    public let choices: [Choice]
    public let usage: Usage
    
    public struct Choice: Codable {
        public let text: String
        public let finishReason: String
        
        enum CodingKeys: String, CodingKey {
            case text
            case finishReason = "finish_reason"
        }
    }
}

public struct TranscriptionResponse: Codable {
    public let text: String
}

public struct Usage: Codable {
    public let promptTokens: Int
    public let completionTokens: Int
    public let totalTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
}

struct APIErrorResponse: Decodable {
    let error: APIError
    
    struct APIError: Decodable {
        let message: String
        let type: String
        let code: String?
    }
}

// MARK: - Error Handling

public enum OpenAIError: LocalizedError {
    case invalidURL
    case noData
    case invalidResponse
    case networkError(Error)
    case apiError(message: String, type: String, code: String?)
    case decodingError(Error)
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL configuration"
        case .noData: return "No data received from server"
        case .invalidResponse: return "Invalid response from server"
        case .networkError(let error): return "Network error: \(error.localizedDescription)"
        case .apiError(let message, let type, let code):
            return "API error (\(type))\(code.map { " [\($0)]" } ?? ""): \(message)"
        case .decodingError(let error): return "Failed to decode response: \(error.localizedDescription)"
        }
    }
}
