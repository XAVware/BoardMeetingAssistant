//
//  NavigationContext.swift
//  BoardMeetingAssistant
//
//  Created by Ryan Smetana on 10/5/24.
//

import SwiftUI

@Observable
class NavigationContext {
    var key: String = AssemblyAI_APIKey
    var project: Project?
    var columnVisibility: NavigationSplitViewVisibility
    
    init(project: Project? = nil,
         columnVisibility: NavigationSplitViewVisibility = .automatic) {
        self.project = project
        self.columnVisibility = columnVisibility
    }
}
