//
//  SearchBar.swift
//  Currency Conversion
//
//  Created by Akash Kahalkar on 12/06/22.
//

import Foundation

import SwiftUI
 
struct SearchBar: View {
    @Binding var text: String
 
    @State private var isEditing = false
    
    private enum Field: Int {
        case yourTextEdit
    }

    @FocusState private var focusedField: Field?
 
    var body: some View {
        HStack {
            
            TextField("Search with country code ...", text: $text)
                .padding(7)
                .padding(.horizontal, 25)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal, 10)
                .focused($focusedField, equals: .yourTextEdit)
                .onTapGesture {
                    self.isEditing = true
                }
            
            if isEditing {
                Button(action: {
                    self.isEditing = false
                    self.text = ""
                    if focusedField != nil {
                        focusedField = nil
                    }
                }) {
                    Text("Cancel")
                }
                .padding(.trailing, 10)
                .transition(.move(edge: .trailing))
            }
        }
    }
}
