//
//  ContentView.swift
//  Currency Conversion
//
//  Created by Akash Kahalkar on 10/06/22.
//

import SwiftUI

struct CurrencyConversionView: View {
    
    @ObservedObject private var viewModel: CurrencyConversionViewModel
    @State private var message = "Loading..."
    @State private var error: String = ""
    @State private var inputValue: String = ""
    @State private var amount: Double = 0
    
    init(appId: String) {
        viewModel = CurrencyConversionViewModel(appId: appId)
    }
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView().padding()
            } else if !(viewModel.errorMessage ?? "").isEmpty {
                Text(Constants.ErrorMessages.somthingWentWrong).padding()
            } else {
                ZStack(alignment: .topLeading) {
                    Color(hex: "#171717").ignoresSafeArea()
                    getBackgroundView()
                    VStack {
                        getInputView().padding(.horizontal)
                        if amount > 0 {
                            ConversionGridView(
                                viewModel: ConversionGridViewModel(
                                    base: viewModel.base,
                                    dataSource: viewModel.dataSource,
                                    amount: amount
                                )
                            )
                        } else {
                            Spacer()
                        }
                    }
                }
                .onReceive(NotificationCenter.default.publisher(
                    for: UIApplication.willEnterForegroundNotification)
                ) { _ in
                    //update if needed
                    synceDataSourceIfNeeded()
                }
            }
        }.task {
            viewModel.fetchData()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    
    static var previews: some View {
        CurrencyConversionView(appId: AppConfigParser.appId)
            .previewDevice("iPhone 13 mini")
    }
}

extension CurrencyConversionView {
    
    var border: some View {
        RoundedRectangle(cornerRadius: 8)
          .strokeBorder(
            LinearGradient(
              gradient: .init(
                colors: [
                    error.isEmpty ? Color.mint : Color.red.opacity(0.5) ,
                    error.isEmpty ? Color.mint : Color.orange.opacity(0.5)
                ]
              ),
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            ),
            lineWidth: 2
          )
      }
    
    func synceDataSourceIfNeeded() {
        let currentDateTimeStamp = viewModel.dataSource.getCurrentDateTimeStamp()
        let lastFetched = viewModel.dataSource.getLastFetchTimeStamp()
        // did not get chance to check this
        if (lastFetched + 1800) > currentDateTimeStamp {
            print("Threshold breach for last sync, force synching")
            viewModel.fetchData(forceUpdate: true)
        }
    }
    
    func getBackgroundView() -> some View {
        GeometryReader { geometry in
            VStack {
                Circle()
                    .fill(.blue.gradient)
                    .frame(height: 150).offset(x: geometry.size.width - 100, y: 40)
                
                Circle()
                    .fill(.red.gradient).offset(x: 200, y: 300)
                    .frame(height: 200)
                
                Circle()
                    .fill(.green.gradient)
                    .frame(height: 80)
            }
        }
    }
    
    func getPickerView() -> some View {
        HStack {
            Spacer()
            Picker("Country Selection", selection: $viewModel.base) {
                ForEach(viewModel.pickerData, id: \.countryCode) {
                    Text($0.countryName)
                }
            }
            .accentColor(.primary)
                .background(.black.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.vertical)
                .padding(.trailing)
            }
        }
    
    func getInputView() -> some View {
        VStack() {
            HStack {
                Spacer()
                Text("last synced at: \(viewModel.dataSource.getLastUpdateDate())")
                    .foregroundColor(.white.opacity(0.8))
                    .font(.system(size: 12))
                    .padding(.horizontal)
                    .padding(.top, 8)
                
            }
            HStack{
                TextField("Input amount", text: $inputValue)
                    .frame(height: 40)
                    .textFieldStyle(.plain)
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.leading)
                    .keyboardType(.decimalPad)
                    .onChange(of: inputValue) { newValue in
                        let parseAmount = viewModel.parseAmount(newValue)
                        amount = parseAmount.amount ?? 0
                        error = parseAmount.error
                        print("amount received", Date().description)
                    }.onTapGesture {
                        print("View tapped", Date().description)
                    }
                Text(viewModel.base).padding(.horizontal)
            }.padding(.vertical)
                .background(border)
                .tint(Color.mint)
                .padding(.horizontal)
            if !error.isEmpty {
                HStack {
                    Spacer()
                    Text(error)
                        .padding(EdgeInsets(top: 4,
                                            leading: 8,
                                            bottom: 8,
                                            trailing: 16))
                        .foregroundColor(Color(hex: "FAC213"))
                        .font(.system(size: 12))
                }.padding(.horizontal)
            }
            getPickerView()
        }.background(.ultraThinMaterial).background(Color.clear)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.4), radius: 10, x: 1, y: 1)
    }
}
