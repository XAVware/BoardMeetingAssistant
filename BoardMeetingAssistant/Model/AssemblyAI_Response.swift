//
//  Transcript.swift
//  BoardMeetingAssistant
//
//  Created by Ryan Smetana on 9/8/24.
//

import Foundation
import SwiftData

struct AAIResponse: Codable {
    var audio_url: String
    var utterances: [AAIUtterance]
    let sections: [String: SectionData]
    
    struct SectionData: Codable {
        let start: Int
        let name: String
    }
}

struct AAIUtterance: Codable {
    var text: String
    let start: Int
    var end: Int
    let confidence: Double
    var speaker: String
    var speakerName: String?
}

struct AAISection: Codable {
    var name: String?
    var start: Int?
}


