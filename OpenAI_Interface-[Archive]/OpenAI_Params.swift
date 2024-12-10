//
//  OpenAI_Params.swift
//  Recording Transcriber
//
//  Created by Smetana, Ryan on 5/22/23.
//

import Foundation

struct TranscriptionParams: Codable {
    let file: Data?
    let model: String
    let prompt: String?
    let language: String?
}

struct CompletionParams: Codable {
    let model: String
    let prompt: String
    let temperature: Float
}
