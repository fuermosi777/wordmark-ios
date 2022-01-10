//
//  MediumService.swift
//  WordMark
//
//  Created by Hao Liu on 2/13/21.
//

import Foundation
import Combine

// https://github.com/Medium/medium-api-docs#33-posts
struct MediumPost {
  var content: String
  var title: String
  let contentFormat = "markdown"
  var tags: [String]
  
  // "public", "draft", "unlisted"
  var publishStatus: String
}

struct MediumMapResponse<T: Decodable>: Decodable {
  let data: T
}

struct MediumListResponse<T: Decodable>: Decodable {
  let data: [T]
}

// https://github.com/Medium/medium-api-docs#31-users
struct MediumUserResponse: Decodable {
  let id: String
  let username: String
  let name: String
  let url: String
  let imageUrl: String
}

// https://github.com/Medium/medium-api-docs#33-posts
struct MediumPostResponse: Decodable {
  let id: String
  let url: String
}

final class MediumService: APIService {
  static let shared = MediumService(host: "api.medium.com")
  
  var disposables = Set<AnyCancellable>()
  
  func getUser(accessToken: String) -> AnyPublisher<MediumMapResponse<MediumUserResponse>, AppError> {
    let comps = buildURLComponents("/v1/me")
    var request = buildRequest(url: comps.url!, method: "GET")
    request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
    
    return fetch(for: request)
  }
  
  
  // TODO: remove all the ! in this func.
  func createPost(post: MediumPost, service: SharingService) -> AnyPublisher<MediumMapResponse<MediumPostResponse>, AppError> {
    let comps = buildURLComponents("/v1/users/\(service.identifier!)/posts")
    var request = buildRequest(url: comps.url!, method: "POST")
    request.addValue("Bearer \(service.accessToken!)", forHTTPHeaderField: "Authorization")
    
    // TODO: use struct directly instead of creating this body thing.
    let body = [
      "content": post.content,
      "title": post.title,
      "contentFormat": post.contentFormat,
      "tags": post.tags,
      "publishStatus": post.publishStatus
    ] as [String : Any]
    request.httpBody = try! JSONSerialization.data(withJSONObject: body, options: [])
    
    return fetch(for: request)
  }
}
