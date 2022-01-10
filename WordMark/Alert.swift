//
//  alert.swift
//  WordMark
//
//  Created by Hao Liu on 1/3/22.
//

import Foundation

enum AlertType {
  case none, importingFailed
  
  var title: String {
    switch self {
    case .none:
      return ""
    case .importingFailed:
      return "Unable to open file"
    }
  }
}
