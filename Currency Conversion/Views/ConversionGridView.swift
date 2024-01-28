//
//  ConversionGridView.swift
//  Currency Conversion
//
//  Created by Akash Kahalkar on 11/06/22.
//

import Foundation
import SwiftUI

struct ConversionGridView: View {
    @ObservedObject private var viewModel: ConversionGridViewModel
    @State var searchTerm: String = ""
    @State private var showToastOverlay = false
    
    init(viewModel: ConversionGridViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        VStack {
            SearchBar(text: $searchTerm)
            ScrollView(.vertical) {
                LazyVGrid(
                    columns: [
                        GridItem(.adaptive(minimum: 200, maximum: 1000))]) {
                            ForEach(getFilteredResults(searchTerm: searchTerm), id: \.countryCode) { nameMapping in
                                ColorView(countryCode: nameMapping.countryCode,
                                          countryName: nameMapping.countryName,
                                          amount: viewModel.amount)
                            }
                        }
            }.scrollDismissesKeyboard(.immediately)
        }.overlay {
            if showToastOverlay {
                Text("Copied to Clipboard!")
                    .padding()
                    .transition(.move(edge: .bottom))
                    .background(Color.black.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
    
    func getFilteredResults(searchTerm: String) -> [CountryListPickerData] {
        var filteredResult: [CountryListPickerData]
        if searchTerm.isEmpty {
            filteredResult = viewModel.getCountryCodes()
        } else {
            filteredResult = viewModel.getCountryCodes().filter({ nameMapping in
                nameMapping.countryCode.lowercased().contains(searchTerm.lowercased())
            })
        }
        return filteredResult
    }
    
    @ViewBuilder
    func ColorView(countryCode: String, countryName: String, amount: Double) -> some View {
        ZStack {
            (viewModel.getColor(for: countryCode))
                .frame(minHeight: 40)
                .background(.thinMaterial)
                .cornerRadius(16)
            HStack {
                Text(countryCode).padding().font(Font.body.bold())
                    .background(Color(hex: "51557E"))
                    .background(.thinMaterial)
                    .cornerRadius(8)
                Spacer()
                Text(countryName).font(.body)
                Spacer()
                Text(
                    viewModel.getConversion(for: countryCode,
                                                  amount: amount)
                )
                .font(Font.body.weight(Font.Weight.light))
                .padding()
                .background(Color.black.opacity(0.5))
                .background(.thinMaterial)
                .cornerRadius(8)
                .onTapGesture {
                    let convertedAmount = viewModel.getConversion(
                        for: countryCode,
                        amount: amount)
                    let conversionString = "\(amount) \(viewModel.getBase()) = \(convertedAmount) \(countryCode) "
                    
                    #if os(macOS)
                    NSPasteboard.general.setString(conversionString, forType: .string)
                    #elseif os(iOS)
                    UIPasteboard.general.string = conversionString
                    #endif
                    
                    withAnimation {
                        showToastOverlay = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: {
                            showToastOverlay = false
                        })
                    }
                }
            }.padding()
            .cornerRadius(16)
        }
        .padding(.horizontal)
        .cornerRadius(16)
    }
}

