//
//  Export_Ext.swift
//  BoardMeetingAssistant
//
//  Created by Ryan Smetana on 12/8/24.
//


import Foundation
import SwiftData

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
