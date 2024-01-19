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
    
    private var countryNameMapping = [String: String]()
    var filteredMappings = [String: String]()
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
                            ForEach(getFilteredResults(searchTerm: searchTerm),
                                    id: \.self) { countryCode in
                                ColorView(countryCode: countryCode,
                                          countryName: viewModel.getCountryName(for: countryCode),
                                          amount: viewModel.amount)
                            }
                        }
            }
        }
    }
    
    func getFilteredResults(searchTerm: String) -> [String] {
        var filteredResult: [String]
        if searchTerm.isEmpty {
            filteredResult = viewModel
                .getCountryCodes()
                .sorted()
        } else {
            filteredResult = viewModel
                .getCountryCodes()
                .sorted()
                .filter({$0.contains(searchTerm.uppercased())})
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
                    viewModel.getConversionAmount(for: countryCode,
                                                  amount: amount)
                )
                .font(Font.body.weight(Font.Weight.light))
                .padding()
                .background(Color.black.opacity(0.5))
                .background(.thinMaterial)
                .cornerRadius(8)
                .onTapGesture {
                    let convertedAmount = viewModel.getConversionAmount(
                        for: countryCode,
                        amount: amount)
                    let conversionString = "\(amount) \(viewModel.getBase()) = \(convertedAmount) \(countryCode) "
                    
                    #if os(macOS)
                    NSPasteboard.general.setString(conversionString, forType: .string)
                    #elseif os(iOS)
                    UIPasteboard.general.string = conversionString
                    #endif
                    
                }
            }.padding()
            .cornerRadius(16)
        }
        .padding(.horizontal)
        .cornerRadius(16)
    }
}

