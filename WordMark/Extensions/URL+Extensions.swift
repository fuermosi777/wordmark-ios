import Foundation

extension URL {
  func query(_ queryParameterName: String) -> String? {
    guard let url = URLComponents(string: self.absoluteString) else { return nil }
    return url.queryItems?.first(where: { $0.name == queryParameterName })?.value
  }
}
