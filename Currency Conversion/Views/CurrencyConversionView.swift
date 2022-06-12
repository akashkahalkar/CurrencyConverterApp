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
    @Namespace var namespace
    @State var id: String = ""
    
    private enum Field: Int {
        case yourTextEdit
    }

    @FocusState private var focusedField: Field?
    
    init(appId: String) {
        viewModel = CurrencyConversionViewModel(appId: appId)
    }
    
    var body: some View {
        if viewModel.isLoading {
            ProgressView().padding()
        } else if !(viewModel.errorMessage ?? "").isEmpty {
            Text(Constants.ErrorMessages.somthingWentWrong).padding()
        } else {
            ZStack(alignment: .topLeading) {
                Color(hex: "#171717").ignoresSafeArea()
                getBackgroundView()
                VStack {
                    getInputView().padding()
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
            .onTapGesture {
                if focusedField != nil {
                    focusedField = nil
                }
            }
            
            .onReceive(NotificationCenter.default.publisher(
                for: UIApplication.willEnterForegroundNotification)) { _ in
                //update if needed
                    synceDataSourceIfNeeded()
            }
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
            viewModel.fetchData(forceUpdate: true)
        }
    }
    
     func getBackgroundView() -> some View {
        VStack {
            Circle()
                .fill(Color(hex: "646FD4"))
                .frame(height: 150).offset(x: -150, y: 150)
            
            Circle()
                .fill(Color(hex: "B3E8E5"))
                .frame(height: 200).offset(x: 200, y: 100)
            
            Circle()
                .fill(Color(hex: "646FD4"))
                .frame(height: 50).offset(x: -150, y: 100)
        }
    }
    
    func getPickerView() -> some View {
        HStack {
            Spacer()
            Picker("", selection: $viewModel.base) {
                ForEach(viewModel.dataSource.getCountryCodes()
                    .compactMap({ $0 })
                    .sorted(),
                        id: \.self) {
                    Text(viewModel.dataSource.getcountryName(code: $0))
                }
            }.labelsHidden().hidden().frame(width: 1)
            Menu {
                Picker("CountrySelection", selection: $viewModel.base) {
                    ForEach(viewModel.dataSource.getCountryCodes()
                        .compactMap({ $0 })
                        .sorted(),
                            id: \.self) {
                        Text(viewModel.dataSource.getcountryName(code: $0))
                    }
                }.labelsHidden()
            } label: {
                Text(viewModel.selectedCountryName)
                .font(.system(size: 12))
                .foregroundColor(Color.white)
                .padding(.vertical, 10)
            }
            .tint(Color.white)
            .foregroundColor(Color.mint)
            .padding(.horizontal)
            .background(Color.black.opacity(0.2))
            .cornerRadius(16)
            .padding(.horizontal)
        }.padding(.vertical)
            
    }
    
    func getInputView() -> some View {
        VStack() {
            HStack {
                Spacer()
                Text("last updated at: \(viewModel.dataSource.getLastUpdateDate())")
                    .foregroundColor(.white.opacity(0.8))
                    .font(.system(size: 12))
                    .padding(.horizontal)
                    .padding(.top, 8)
            }
            TextField("input amount", text: $inputValue)
                .textFieldStyle(PlainTextFieldStyle())
                .padding()
                .background(border)
                .foregroundColor(.white.opacity(0.8))
                .tint(Color.mint)
                .padding(.horizontal)
                .focused($focusedField, equals: .yourTextEdit)
                .keyboardType(.decimalPad)
                .onChange(of: inputValue) { newValue in
                    let parseAmount = viewModel.parseAmount(newValue)
                    withAnimation(.easeInOut(duration: 0.3)) {
                        amount = parseAmount.amount ?? 0
                        error = parseAmount.error
                    }
                    
                }
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
        }.background(.ultraThinMaterial)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.4), radius: 10, x: 1, y: 1)
    }
}
