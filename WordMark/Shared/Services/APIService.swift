//
//  APIService.swift
//  WordMark
//
//  Created by Hao Liu on 1/15/21.
//

import Foundation
import Combine

class APIService {
  internal let host: String
  
  internal init(host: String) {
    self.host = host
  }
  
  internal func buildURLComponents(_ path: String) -> URLComponents {
    var components = URLComponents()
    components.scheme = "https"
    components.host = self.host
    components.path = path
    return components
  }
  
  internal func buildRequest(url: URL, method: String) -> URLRequest {
    var request = URLRequest(url: url)
    request.httpMethod = method
    request.addValue("application/json", forHTTPHeaderField: "Accept")
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    return request
  }
  
  internal func fetch<Resp: Decodable>(for request: URLRequest) ->
  AnyPublisher<Resp, AppError> {
    return URLSession.shared.dataTaskPublisher(for: request)
      .tryMap { data, response in
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
          throw AppError.apiError(reason: "Received wrong HTTP status code")
        }
        return data
      }
      .decode(type: Resp.self, decoder: JSONDecoder())
      .mapError { error in
        if let error = error as? AppError {
          return error
        } else {
          return AppError.apiError(reason: error.localizedDescription)
        }
      }
      .eraseToAnyPublisher()
  }
}
