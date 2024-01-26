//
//  AppConfigParser.swift
//  Currency Conversion
//
//  Created by Akash Kahalkar on 11/06/22.
//

import Foundation

struct AppConfigParser {
  
  static var appId: String {
    get {
      guard let filePath = Bundle.main.path(forResource: "AppConfigs", ofType: "plist") else {
        fatalError("Couldn't find file 'App config'.")
      }
        
      let plist = NSDictionary(contentsOfFile: filePath)
      guard let value = plist?.object(forKey: "appId") as? String else {
        fatalError("Couldn't find key 'AppId' in 'App config'.")
      }
        
      return value
    }
  }
}
