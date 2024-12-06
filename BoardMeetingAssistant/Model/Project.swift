//
//  Item.swift
//  BoardMeetingAssistant
//
//  Created by Ryan Smetana on 9/8/24.
//

import Foundation
import SwiftData

@Model
final class Project {
    var id: UUID
    var createdOn: Date
    var name: String
    var audioFilePath: String?
    
    @Relationship(deleteRule: .cascade, inverse: \Transcript.project)
    var transcript: Transcript?
    
    init(name: String = "", audioFilePath: String = "", transcript: Transcript? = nil) {
        self.id = UUID()
        self.createdOn = Date()
        self.name = name
        self.audioFilePath = audioFilePath
        self.transcript = transcript
    }
}

@Model
final class Transcript {
    var audio_url: String?
    var utterances: [AAIUtterance]
    var project: Project?
    
    init(audio_url: String? = nil, utterances: [AAIUtterance], project: Project? = nil) {
        self.audio_url = audio_url
        self.utterances = utterances
        self.project = project
    }
}

struct AAIUtterance: Codable {
    var text: String
    let start: Int
    var end: Int
    let confidence: Double
    var speaker: String
//    let channel: String?
//    let words: [Word]
    
    var speakerName: String?
}

// For exporting to JSON
struct ProjectExport: Encodable {
    let id: UUID
    let createdOn: Date
    let name: String
    let audioFilePath: String?
    let transcript: TranscriptExport?
}

struct TranscriptExport: Encodable {
    let audio_url: String?
    let utterances: [AAIUtterance]
}

extension Project {
    func toExportModel() -> ProjectExport {
        return ProjectExport(
            id: self.id,
            createdOn: self.createdOn,
            name: self.name,
            audioFilePath: self.audioFilePath,
            transcript: self.transcript?.toExportModel()
        )
    }
}

extension Transcript {
    func toExportModel() -> TranscriptExport {
        return TranscriptExport(
            audio_url: self.audio_url,
            utterances: self.utterances
        )
    }
}
