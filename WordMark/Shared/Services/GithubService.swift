//
//  GithubService.swift
//  WordMark
//
//  Created by Hao Liu on 1/12/21.
//

import Foundation
import Combine

struct GithubAccessTokenResponse: Decodable {
  let access_token: String
  let token_type: String
  let scope: String
}

struct GithubRepoResponse: Decodable, Identifiable, Hashable {
  let id: Int
  let name: String
  let full_name: String
}

// https://docs.github.com/en/rest/reference/repos#get-repository-content
struct GithubRepoContentResponse: Decodable, Identifiable, Hashable {
  let type: String
  let name: String
  let sha: String
  let encoding: String
  let content: String
  let download_url: String
  var id: String { sha }
}

struct GithubBranchResponse: Decodable, Hashable {
  let name: String
}

// Sample: https://api.github.com/repos/fuermosi777/bbb/git/trees/master?recursive=1
struct GithubTreeResponse: Decodable {
  let sha: String
  let url: String
  let tree: [GithubTree]
}

enum GithubTreeType: String, Codable {
  case blob = "blob",
  tree = "tree"
}

struct GithubContent: Decodable, Identifiable {
  let name: String
  let path: String
  let sha: String
  let html_url: String
  let type: String
  var id: String { sha }
}

struct GithubCommit: Decodable {
  let sha: String
}

struct GithubTree: Decodable {
  let path: String
  let type: GithubTreeType
  let sha: String
  let url: String
}

// https://docs.github.com/en/rest/reference/repos#create-or-update-file-contents
struct GithubCreateContentResponse: Decodable {
  let content: GithubContent
  let commit: GithubCommit
}

struct GithubPost {
  var content: String
  var path: String
  var filename: String
  var commitMessage: String
  
  // Implicitly set.
  var filepath: String {
    path.appendPath(filename)
  }
  
  // For editing.
  var sha: String?
}


extension GithubBranchResponse: Identifiable {
  var id: String { return name }
}

final class GithubService: APIService {
  static let shared = GithubService(host: "api.github.com")
  
  let clientID = "5b18182f6b75a03caec6"
  let clientSecret = "7a771d7b8a4a6c00574ad3832786e30932713b49"
  let accessTokenURL = "https://github.com/login/oauth/access_token"
  
  var disposables = Set<AnyCancellable>()
  
  func getAuthorizeURL(_ state: String) -> URL {
    return URL(string: "https://github.com/login/oauth/authorize?client_id=\(clientID)&redirect_uri=https://wordmarkapp.com/callback&scope=user,repo,gist&state=\(state)")!
  }
  
  func getAccessToken(code: String, state: String) -> AnyPublisher<GithubAccessTokenResponse, AppError> {
    let body = [
      "client_id": clientID,
      "client_secret": clientSecret,
      "code": code,
      "state": state,
      "redirect_uri": "https://wordmarkapp.com/callback"
    ]
    
    let url = URL(string: accessTokenURL)!
    var request = buildRequest(url: url, method: "POST")
    request.httpBody = try! JSONSerialization.data(withJSONObject: body, options: [])
    
    return fetch(for: request)
  }
  
  func getRepos(accessToken: String) -> AnyPublisher<[GithubRepoResponse], AppError> {
    var comps = buildURLComponents("/user/repos")
    comps.queryItems = [
      URLQueryItem(name: "visibility", value: "all"),
      URLQueryItem(name: "affiliation", value: "owner"),
      URLQueryItem(name: "sort", value: "updated"),
      URLQueryItem(name: "per_page", value: "100"),
    ]
    var request = buildRequest(url: comps.url!, method: "GET")
    request.addValue("token \(accessToken)", forHTTPHeaderField: "Authorization")
    
    return fetch(for: request)
  }
  
  func getContent(path: String, service: SharingService) -> AnyPublisher<GithubRepoContentResponse, AppError> {
    guard let repository = service.repository,
          let accessToken = service.accessToken else {
            return Fail(error: AppError.invalidArguments(reason: "Missing properties in service.")).eraseToAnyPublisher()
          }
    let url = "/repos"
      .appendPath(repository)
      .appendPath("contents")
      .appendPath(path)
    let comps = buildURLComponents(url)
    
    var request = buildRequest(url: comps.url!, method: "GET")
    request.addValue("token \(accessToken)", forHTTPHeaderField: "Authorization")
    
    return fetch(for: request)
  }
  
  func getContent(path: String, service: SharingService) async throws -> GithubRepoContentResponse {
    guard let repository = service.repository,
          let accessToken = service.accessToken else {
            throw AppError.invalidArguments(reason: "Missing properties in service.")
          }
    let url = "/repos"
      .appendPath(repository)
      .appendPath("contents")
      .appendPath(path)
    let comps = buildURLComponents(url)
    
    var request = buildRequest(url: comps.url!, method: "GET")
    request.addValue("token \(accessToken)", forHTTPHeaderField: "Authorization")
    
    let (data, _) = try await URLSession.shared.data(for: request)
    let result = try JSONDecoder().decode(GithubRepoContentResponse.self, from: data)
    
    return result
  }
  
  
  func getBranches(accessToken: String, repoFullName: String) -> AnyPublisher<[GithubBranchResponse], AppError> {
    let path = "/repos"
      .appendPath(repoFullName)
      .appendPath("branches")
    var comps = buildURLComponents(path)
    comps.queryItems = [
      URLQueryItem(name: "per_page", value: "100"),
    ]
    var request = buildRequest(url: comps.url!, method: "GET")
    request.addValue("token \(accessToken)", forHTTPHeaderField: "Authorization")
    
    return fetch(for: request)
  }
  
  // https://docs.github.com/en/rest/reference/git#get-a-tree
  func getTree(service: SharingService) async throws -> GithubTreeResponse {
    guard let repository = service.repository,
          let accessToken = service.accessToken,
          let branch = service.branch else {
            throw AppError.invalidArguments(reason: "Missing properties in service.")
          }
    let path = "/repos"
      .appendPath(repository)
      .appendPath("git/trees")
      .appendPath(branch)
    var comps = buildURLComponents(path)
        comps.queryItems = [
          URLQueryItem(name: "recursive", value: "1"),
        ]
    var request = buildRequest(url: comps.url!, method: "GET")
    request.addValue("token \(accessToken)", forHTTPHeaderField: "Authorization")
    
    let (data, response) = try await URLSession.shared.data(for: request)
    guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
      throw AppError.apiError(reason: "Received wrong HTTP status code")
    }
    
    do {
      let decoded = try JSONDecoder().decode(GithubTreeResponse.self, from: data)
      return decoded
    } catch {
      throw AppError.decodeError
    }
  }
  
  // https://docs.github.com/en/rest/reference/repos#create-or-update-file-contents
  func createContent(post: GithubPost, service: SharingService) -> AnyPublisher<GithubCreateContentResponse, AppError> {
    guard let branch = service.branch,
          let repository = service.repository,
          let accessToken = service.accessToken else {
            return Fail(error: AppError.invalidArguments(reason: "Missing properties in service.")).eraseToAnyPublisher()
          }
    let path = "/repos"
      .appendPath(repository)
      .appendPath("contents")
      .appendPath(post.filepath)
    let comps = buildURLComponents(path)
    var body = [
      "branch": branch,
      "message": post.commitMessage,
      "content": post.content.toBase64()
    ]
    if let sha = post.sha {
      body["sha"] = sha
    }
    
    var request = buildRequest(url: comps.url!, method: "PUT")
    request.addValue("token \(accessToken)", forHTTPHeaderField: "Authorization")
    request.httpBody = try! JSONSerialization.data(withJSONObject: body, options: [])
    
    return fetch(for: request)
  }
}
