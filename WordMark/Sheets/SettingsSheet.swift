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
  @AppStorage("editorFontSize") private var editorFontSize = 16.0
  @AppStorage("styleActiveLine") private var styleActiveLine = false
  @AppStorage("hideNavWhenEditing") private var hideNavWhenEditing = false

  
  var body: some View {
    NavigationView {
      VStack {
        Form {
            Picker("Font", selection: $regularFontFamily) {
              ForEach(Font.allCases) { font in
                Text(font.label).tag(font.rawValue)
              }
            }.pickerStyle(.inline)
            
            HStack {
              Text("Font Size")
              Slider(value: $editorFontSize, in: 12...24)
            }
            
            Toggle("Hide Title When Typing", isOn: $hideNavWhenEditing)
            Toggle("Highlight Active Line", isOn: $styleActiveLine)
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
