//
//  urlExtensions.swift
//  WordMark
//
//  Created by Hao Liu on 1/10/21.
//

import Foundation

extension URL {
  func query(_ queryParameterName: String) -> String? {
    guard let url = URLComponents(string: self.absoluteString) else { return nil }
    return url.queryItems?.first(where: { $0.name == queryParameterName })?.value
  }
}
