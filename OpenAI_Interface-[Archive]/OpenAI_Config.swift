//
//  OpenAI_Config.swift
//  LMCC Transcriber
//
//  Created by Smetana, Ryan on 5/22/23.
//

import Foundation

public struct OpenAIConfig {
    let apiKey: String
    let organization: String?
    let baseURL: URL
    
    public init(apiKey: String, organization: String? = nil, baseURL: URL = URL(string: "https://api.openai.com")!) {
        self.apiKey = apiKey
        self.organization = organization
        self.baseURL = baseURL
    }
}
