//
//  AutocompleteTextField.swift
//  BoardMeetingAssistant
//
//  Created by Ryan Smetana on 9/10/24.
//

import SwiftUI
import Foundation

struct AutocompleteTextField: View {
    @Environment(NavigationContext.self) private var navigationContext
    @Binding var text: String?
    var suggestions: [String]

    
    @State var tempText: String = ""
    
    var body: some View {
        ZStack {
            TextField("Speaker Name", text: $tempText)
                .textFieldStyle(.plain)
                .padding(8)
                .background(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray, lineWidth: 0.5))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .scrollContentBackground(.hidden)
                .disableAutocorrection(true)
                .font(.subheadline)

            if let suggestion = filteredSuggestions().first {
                Text(suggestion)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 8)
                    .font(.subheadline)
            }
        }
        .onChange(of: tempText) { oldValue, newValue in
            text = newValue
        }
        .onChange(of: navigationContext.project) { oldValue, newValue in
            print("Project changed")
        }
    }
    
    private func filteredSuggestions() -> [String] {
        let filtered = suggestions.filter { suggestion in
            suggestion.lowercased().contains(tempText.lowercased())
        }
        return filtered.isEmpty ? [""] : filtered
    }
}


//#Preview {
//    AutocompleteTextField(text: .constant(""), suggestions: ["Victoria Germano", "Stu Conklin"])
//}

import Combine
import SwiftUI

struct KeyEventHandling: ViewModifier {
    @Binding var text: String
    var commit: () -> Void
    
    func body(content: Content) -> some View {
        content
            .onAppear()
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NSKeyDownNotification"))) { notification in
                if let event = notification.userInfo?["NSEvent"] as? NSEvent {
                    handleKeyEvent(event)
                }
            }
    }
    
    private func handleKeyEvent(_ event: NSEvent) {
        if event.keyCode == 36 { // keyCode for Enter key is 36
            print("Enter key tapped")
            commit()
        }
    }
}
