//
//  Currency_ConversionApp.swift
//  Currency Conversion
//
//  Created by Akash Kahalkar on 10/06/22.
//

import SwiftUI

@main
struct Currency_ConversionApp: App {

    var body: some Scene {
        WindowGroup {
            CurrencyConversionView(appId: AppConfigParser.appId)
        }
    }
}
