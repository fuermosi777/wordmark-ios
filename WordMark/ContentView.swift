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
  @Binding var document: WordMarkDocument
  @State private var selectedSheet: Sheet?
  
  @AppStorage("hideNavigationBar") private var hideNavigationBar = false
  
  var body: some View {
    NavigationView {
      VStack {
        EditorWebView(content: $document.text)
          .navigationTitle(document.filename ?? "")
          .navigationBarHidden(hideNavigationBar)
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
      }.onTapGesture {
        hideNavigationBar.toggle()
      }
    }
  }
}

