//
//  OpenAI.swift
//  LMCC Transcriber
//
//  Created by Smetana, Ryan on 5/22/23.
//

import Foundation

public class OpenAIClient {
    private let config: OpenAIConfig
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let queue = DispatchQueue(label: "com.openai.client", attributes: .concurrent)
    
    public init(config: OpenAIConfig, session: URLSession = .shared, decoder: JSONDecoder = .init(), encoder: JSONEncoder = .init()) {
        self.config = config
        self.session = session
        self.decoder = decoder
        self.encoder = encoder
    }
    
    public func createCompletion(prompt: String, model: OpenAIModel = .gpt35Turbo, temperature: Float = 0.7) async throws -> CompletionResponse {
        let params = CompletionParams(model: model.rawValue, prompt: prompt, temperature: temperature)
        return try await performRequest(endpoint: .completions, body: params)
    }
    
    public func createTranscription(audioData: Data, filename: String, model: OpenAIModel = .whisper1, prompt: String? = nil, language: Language? = nil) async throws -> TranscriptionResponse {
        let params = TranscriptionParams(file: audioData, model: model.rawValue, prompt: prompt, language: language?.code)
        return try await performMultipartRequest(endpoint: .transcriptions, params: params, filename: filename)
    }

    private func createRequest(for endpoint: APIEndpoint, method: String) throws -> URLRequest {
        guard let url = URL(string: endpoint.rawValue, relativeTo: config.baseURL) else {
            throw OpenAIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        
        if let organization = config.organization {
            request.setValue(organization, forHTTPHeaderField: "OpenAI-Organization")
        }
        
        return request
    }
    
    private func performRequest<T: Encodable, U: Decodable>( endpoint: APIEndpoint, body: T) async throws -> U {
        var request = try createRequest(for: endpoint, method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(body)
        
        return try await executeRequest(request)
    }
    
    private func performMultipartRequest<T: Decodable>(endpoint: APIEndpoint, params: TranscriptionParams, filename: String) async throws -> T {
        var request = try createRequest(for: endpoint, method: "POST")
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        request.httpBody = createMultipartFormData(params: params, boundary: boundary, filename: filename)
        
        return try await executeRequest(request)
    }
    
    private func executeRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            let errorResponse = try decoder.decode(APIErrorResponse.self, from: data)
            throw OpenAIError.apiError(message: errorResponse.error.message, type: errorResponse.error.type, code: errorResponse.error.code)
        }
        
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw OpenAIError.decodingError(error)
        }
    }
    
    private func createMultipartFormData(params: TranscriptionParams, boundary: String, filename: String) -> Data {
        var formData = Data()
        
        // Add model
        formData.append("--\(boundary)\r\n")
        formData.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n")
        formData.append("\(params.model)\r\n")
        
        // Add file
        if let fileData = params.file {
            formData.append("--\(boundary)\r\n")
            formData.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n")
            formData.append("Content-Type: audio/mpeg\r\n\r\n")
            formData.append(fileData)
            formData.append("\r\n")
        }
        
        // Add optional parameters
        if let prompt = params.prompt {
            formData.append("--\(boundary)\r\n")
            formData.append("Content-Disposition: form-data; name=\"prompt\"\r\n\r\n")
            formData.append("\(prompt)\r\n")
        }
        
        if let language = params.language {
            formData.append("--\(boundary)\r\n")
            formData.append("Content-Disposition: form-data; name=\"language\"\r\n\r\n")
            formData.append("\(language)\r\n")
        }
        
        formData.append("--\(boundary)--\r\n")
        return formData
    }
    
    
}
