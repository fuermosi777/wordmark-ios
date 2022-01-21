//
//  WordMarkApp.swift
//  WordMark
//
//  Created by Hao Liu on 8/28/21.
//

import SwiftUI

@main
struct WordMarkApp: App {
  let persistenceController = PersistenceController.shared
  
  init() {
    Logger.shared.appStart()
  }
  
  var body: some Scene {
    DocumentGroup(newDocument: WordMarkDocument()) { file in
      ContentView(document: file.$document)
        .environment(\.managedObjectContext, persistenceController.container.viewContext)
    }
  }
}
