//
//  Item.swift
//  BoardMeetingAssistant
//
//  Created by Ryan Smetana on 9/8/24.
//
import SwiftUI
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
    var sections: [String: AAISection]
    var project: Project?
    
    init(audio_url: String? = nil, utterances: [AAIUtterance], sections: [String: AAISection], project: Project? = nil) {
        self.audio_url = audio_url
        self.utterances = utterances
        self.sections = sections
        self.project = project
    }
}
