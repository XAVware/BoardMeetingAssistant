//
//  OpenAI_Enums.swift
//  LMCC Transcriber
//
//  Created by Smetana, Ryan on 5/22/23.
//

import Foundation

public enum OpenAIModel: String {
    case gpt4 = "gpt-4"
    case gpt35Turbo = "gpt-3.5-turbo"
    case whisper1 = "whisper-1"
}

public enum Language: String {
    case english = "en"
    case spanish = "es"
    case french = "fr"
    
    var code: String { rawValue }
}

public enum APIEndpoint: String {
    case completions = "/v1/completions"
    case transcriptions = "/v1/audio/transcriptions"
}
