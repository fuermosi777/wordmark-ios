// Sharing service provider raw types.
enum SharingProvider: Int32, CaseIterable {
  case github = 1
  case medium = 2
}

enum SharingType {
  case post
  case image
}

extension SharingProvider {
  var imageName: String {
    switch self {
    case .github: return "Github"
    case .medium: return "Medium"
    }
  }
  var supportedTypes: [SharingType] {
    switch self {
    case .github: return [.post, .image]
    case .medium: return [.post, .image]
    }
  }
  // Whether the provider supports remote destination (file management).
  var supportRemote: Bool {
    switch self {
    case .github: return true
    case .medium: return false
    }
  }
}

struct GithubProvider {
  let accessToken: String
  let repository: String
  let branch: String
}

struct MediumProvider {
  let accessToken: String
  let username: String
  let id: String
}

typealias Posts = (github: GithubPost,
                   medium: MediumPost)
