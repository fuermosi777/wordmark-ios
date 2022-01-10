//
//  Date+Extensions.swift
//  WordMark
//
//  Created by Hao Liu on 1/2/22.
//

import Foundation

extension Date {
  func toString(format: String) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = format
    return dateFormatter.string(from: self)
  }
}
