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
