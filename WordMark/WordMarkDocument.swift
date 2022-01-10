//
//  WordMarkDocument.swift
//  WordMark
//
//  Created by Hao Liu on 8/28/21.
//

import SwiftUI
import UniformTypeIdentifiers

extension UTType {
  static var markdownText: UTType {
    UTType(importedAs: "com.wordmarkapp.markdown")
  }
}

struct WordMarkDocument: FileDocument {
  var text: String
  var filename: String?
  
  init(text: String = "") {
    self.text = text
  }
  
  static var readableContentTypes: [UTType] { [.markdownText] }
  
  init(configuration: ReadConfiguration) throws {
    guard let data = configuration.file.regularFileContents,
          let text = String(data: data, encoding: .utf8)
    else {
      throw CocoaError(.fileReadCorruptFile)
    }

    self.filename = configuration.file.filename
    self.text = text
  }
  
  func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
    let data = text.data(using: .utf8)!
    return .init(regularFileWithContents: data)
  }
}
