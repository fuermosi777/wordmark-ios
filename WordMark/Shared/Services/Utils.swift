//
//  Utils.swift
//  WordMark
//
//  Created by Hao Liu on 1/15/21.
//

import Foundation

enum AppError: Error, LocalizedError {
  case unknown,
       apiError(reason: String),
       decodeError,
       invalidArguments(reason: String)
  
  var errorDescription: String? {
    switch self {
    case .unknown:
      return "Unknown Error"
    case .apiError(let reason):
      return reason
    case .decodeError:
      return "Something wrong when decoding the response"
    case .invalidArguments(reason: let reason):
      return reason
    }
  }
}
