//
//  ContentView.swift
//  WordMark
//
//  Created by Hao Liu on 8/28/21.
//

import SwiftUI

enum Sheet: Identifiable {
  case publish,
  serviceList,
  settings
  
  var id: Int {
    hashValue
  }
}

struct ContentView: View {
  @ObservedObject private var keyboard = KeyboardResponder()
  @Binding var document: WordMarkDocument
  @State private var selectedSheet: Sheet?
  
  @AppStorage("hideNavWhenEditing") private var hideNavWhenEditing = false
  
  private func shouldHideNav() -> Bool {
    if !hideNavWhenEditing {
      return false
    }
    return keyboard.isVisible
  }
  
  var body: some View {
    NavigationView {
      VStack {
        EditorWebView(content: $document.text)
          .navigationTitle(document.filename ?? "")
        // TODO: deprecate animation.
          .navigationBarHidden(shouldHideNav()).animation(.easeInOut(duration: 0.2))
          .navigationBarTitleDisplayMode(.inline)
          .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
              Menu {
                Button(action: { selectedSheet = .publish }) {
                  Label("Publish", systemImage: "paperplane")
                }
                
                Button(action: { selectedSheet = .serviceList }) {
                  Label("Sharing Services", systemImage: "globe")
                }
                
                Button(action: { selectedSheet = .settings }) {
                  Label("Settings", systemImage: "gear")
                }
              } label: {
                Image(systemName: "ellipsis.circle")
              }
            }
          }
          .sheet(item: $selectedSheet,
                 onDismiss: { selectedSheet = nil }) { item in
            switch item {
            case .publish: PublishSheet(document: document)
            case .serviceList: ServiceListSheet()
            case .settings: SettingsSheet()
            }
          }
      }
    }
  }
}

