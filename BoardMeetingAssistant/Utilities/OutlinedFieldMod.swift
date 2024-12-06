//
//  OutlinedFieldMod.swift
//  BoardMeetingAssistant
//
//  Created by Ryan Smetana on 10/2/24.
//

import SwiftUI

struct OutlinedFieldMod: ViewModifier {
    @State var title: String = ""
    func body(content: Content) -> some View {
        content
            .padding()
            .overlay(
                RoundedRectangle(cornerRadius: 6).stroke(lineWidth: 0.5).blur(radius: 0.5)
            )
            .frame(maxWidth: 640)
            .background(.thickMaterial)
            .overlay(
                Text(title)
                    .padding(.horizontal, 6)
                    .background(.thickMaterial)
                    .offset(x: 10, y: -10)
                , alignment: .topLeading)
    }
}
    
    

