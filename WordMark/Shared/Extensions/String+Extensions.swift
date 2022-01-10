//
//  String+Extensions.swift
//  WordMark
//
//  Created by Hao Liu on 2/13/21.
//

import Foundation

extension String {
  func fromBase64() -> String? {
    guard let data = Data(base64Encoded: self) else {
      return nil
    }
    
    return String(data: data, encoding: .utf8)
  }
  
  func toBase64() -> String {
    return Data(self.utf8).base64EncodedString()
  }
  
  func appendPath(_ path: String) -> String {
    return (self as NSString).appendingPathComponent(path)
  }
  
  // From "foo/bar/poo" get "foo/bar", for "" if there is no parent path.
  func parentPath() -> String {
    var components = self.components(separatedBy: "/")
    let _ = components.popLast()
    let result = components.joined(separator: "/")
    return result
  }
  
  func lastPathComponent() -> String {
    return (self as NSString).lastPathComponent
  }
}
