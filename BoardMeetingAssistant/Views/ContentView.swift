//
//  ContentView.swift
//  BoardMeetingAssistant
//
//  Created by Ryan Smetana on 9/8/24.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var navigationContext = NavigationContext()
    @Query private var projects: [Project]
    @Environment(\.modelContext) private var modelContext
    
    private func deleteAll() {
        do {
            try modelContext.delete(model: Project.self)
            try modelContext.delete(model: Transcript.self)
        } catch {
            print("Failed to clear all projects.")
        }
    }
    
    var body: some View {
        @Bindable var navigationContext = navigationContext
        
        NavigationSplitView(columnVisibility: $navigationContext.columnVisibility) {
            VStack(spacing: 16) {
                Button {
                    let proj = Project()
                    navigationContext.project = proj
                    modelContext.insert(proj)
                } label: {
                    Text("New Project")
                    Image(systemName: "plus")
                }
                .buttonStyle(BorderedProminentButtonStyle())
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Existing Projects")
                        .font(.headline)
                    
                    List(selection: $navigationContext.project) {
                        ForEach(projects, id: \.self) { proj in
                            NavigationLink(proj.name, value: proj)
                        }
                        //                        .onDelete(perform: deleteProjects)
                    } //: List
                    .frame(width: 280)
                    
                } //: VStack
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Settings")
                        .font(.largeTitle)
                        .fontWeight(.light)
                        .fontDesign(.rounded)
                    
                    VStack(alignment: .leading) {
                        Text("Assembly AI API Key")
                            .font(.headline)
                        
                        TextField("Assembly AI API Key", text: $navigationContext.key)
                            .font(.subheadline)
                            .textFieldStyle(.roundedBorder)
                    } //: VStack
                } //: VStack
            } //: VStack
            .padding()
            
        } content: {
            if navigationContext.project != nil {
                SetupView(project: navigationContext.project)
                    .padding()
                    .navigationSplitViewColumnWidth(360)
            }
        } detail: {
            if navigationContext.project?.transcript != nil {
                ProjectView(project: navigationContext.project)
            }
        }
        .environment(navigationContext)
//        .onAppear {
//            try? modelContext.delete(model: Project.self, where: #Predicate { project in
//                project.name == ""
//            })
//        }
    } //: Body
}

#Preview {
    ContentView()
        .modelContainer(for: Project.self, inMemory: true)
}
