//
//  SettingsView.swift
//  WordMark
//
//  Created by Hao Liu on 1/20/22.
//

import SwiftUI

struct SettingsSheet: View {
  @Environment(\.dismiss) private var dismiss
  
  @AppStorage("regularFontFamily") private var regularFontFamily = Font.Default.rawValue
  
  var body: some View {
    NavigationView {
      VStack {
        Form {
          Picker("Font", selection: $regularFontFamily) {
            ForEach(Font.allCases) { font in
              Text(font.label).tag(font.rawValue)
            }
          }.pickerStyle(.inline)
        }
      }
      .navigationTitle("Settings")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button(action: { dismiss() }) {
            Image(systemName: "xmark")
          }
        }
      }
    }
  }
}
