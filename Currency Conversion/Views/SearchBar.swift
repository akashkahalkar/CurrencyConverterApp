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
    @State private var isEditing = true
    @FocusState private var focusedField: Field?
    
    private enum Field: Int {
        case yourTextEdit
    }

    var body: some View {
        HStack {
            TextField("Search with country code ...", text: $text)
                .padding(16)
                .foregroundColor(.primary)
                .background(.thinMaterial)
                .background(Color.cyan.gradient.opacity(0.5))
                .cornerRadius(8)
                .focused($focusedField, equals: .yourTextEdit)
                .onTapGesture {
                    self.isEditing = true
                }.textFieldStyle(.plain)
            
            if isEditing {
                
                Button(action: {
                    self.text = ""
                    if focusedField != nil {
                        focusedField = nil
                    }
                    withAnimation {
                        self.isEditing = false
                    }
                }, label: {
                    Image(systemName: "xmark.circle").resizable().frame(width: 20, height: 20)
                        .tint(.black.opacity(0.9))
                        .padding()
                        .background(.thinMaterial)
                        .background(.red.opacity(0.5).gradient)
                        .clipShape(Circle())
                }).transition(.move(edge: .trailing))
            }
        }.padding(.horizontal)
    }
}

#Preview {
    SearchBar(text: .constant("Search here"))
}
