//
//  FocusedValues+Extensions.swift
//  WordMark
//
//  Created by Hao Liu on 12/29/21.
//

import Foundation
import SwiftUI

// Used to access the current document from the command menu.
// https://lostmoa.com/blog/ProvidingTheCurrentDocumentToMenuCommands/
extension FocusedValues {
  struct DocumentFocusedValues: FocusedValueKey {
    typealias Value = Binding<WordMarkDocument>
  }
  
  var document: Binding<WordMarkDocument>? {
    get {
      self[DocumentFocusedValues.self]
    }
    set {
      self[DocumentFocusedValues.self] = newValue
    }
  }
}
