//
//  BoardMeetingAssistantApp.swift
//  BoardMeetingAssistant
//
//  Created by Ryan Smetana on 9/8/24.
//

import SwiftUI
import SwiftData

@main
struct BoardMeetingAssistantApp: App {
    
    init() {
        FileManager.copyScriptToDocuments()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: Project.self)
                .modelContainer(for: Transcript.self)
                .preferredColorScheme(.light)
        }
        .defaultSize(width: 1800, height: 1080)
        .defaultPosition(UnitPoint(x: 0, y: 0))
    }
}
