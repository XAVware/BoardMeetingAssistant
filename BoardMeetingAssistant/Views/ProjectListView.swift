//
//  ProjectListView.swift
//  BoardMeetingAssistant
//
//  Created by Ryan Smetana on 10/3/24.
//

import SwiftUI
import SwiftData

struct ProjectListView: View {
    var projects: [Project]
    @Environment(NavigationContext.self) var navigationContext
    @Environment(\.modelContext) private var modelContext
//    @Query private var projects: [Project]
    
    var body: some View {
        @Bindable var navigationContext = navigationContext
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Your Projects")
                    .font(.headline)
                
                List(selection: $navigationContext.project) {
                    ForEach(projects, id: \.self) { proj in
                        NavigationLink(proj.name, value: proj)
                    }
                    .onDelete(perform: deleteProjects)
                } //: List
                .frame(width: 280)
            }
            
            Button {
                let proj = Project()
                navigationContext.project = proj
                modelContext.insert(proj)
            } label: {
                Text("New Project")
                Image(systemName: "plus")
            }
            .buttonStyle(BorderedProminentButtonStyle())
        } //: VStack
        .padding()
    } //: Body
    
    private func deleteProjects(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(projects[index])
            }
        }
    }
}
