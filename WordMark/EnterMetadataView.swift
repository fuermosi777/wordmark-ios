//
//  PublishDetail.swift
//  WordMark
//
//  Created by Hao Liu on 1/6/22.
//

import SwiftUI

// A view for user to enter post metadata such as title,
// date, etc, so that it can be sent to sharing service, and do the actual publishing.
struct EnterMetadataView: View {
  @Environment(\.openURL) var openURL
  @Environment(\.dismiss) private var dismiss
  
  let service: SharingService?
  
  @Binding var posts: Posts
  
  @State var isLoading = false
  
  @State var presentExistAlert = false
  @State var presentSuccessAlert = false
  @State var presentErrorAlert = false
  @State var errorAlerted: Error?
  @State var previewURL: URL?
  
  // For some providers, check if there is an existed post first.
  private func tryPublish() {
    if let service = service,
       let provider = SharingProvider(rawValue: service.provider) {
      switch provider {
      case .github:
        Task {
          do {
            let exist = try await GithubService.shared.getContent(path: posts.github.filepath,
                                                                  service: service)
            posts.github.sha = exist.sha
            presentExistAlert = true
          } catch AppError.notFound {
            publish()
          } catch {
            presentErrorAlert = true
            errorAlerted = error
          }
        }
      case .medium:
        publish()
      }
    }
  }
  
  // Real publish to the service.
  private func publish() {
    if let service = service,
       let provider = SharingProvider(rawValue: service.provider) {
      switch provider {
      case .github:
        Task {
          do {
            // Create Content
            let published = try await GithubService.shared.createContent(post: posts.github, service: service)
            let url = URL(string: published.content.html_url)
            if let url = url { previewURL = url }
            presentSuccessAlert = true
          } catch {
            errorAlerted = error
          }
        }
      case .medium:
        Task {
          do {
            // Create Content
            let published = try await MediumService.shared.createPost(post: posts.medium, service: service)
            let url = URL(string: published.data.url)
            if let url = url { previewURL = url }
            presentSuccessAlert = true
          } catch {
            errorAlerted = error
          }
        }
      }
    }
  }
  
  private func isPublishDisabled() -> Bool {
    if let service = service,
       let provider = SharingProvider(rawValue: service.provider) {
      switch provider {
      case .github:
        return posts.github.path == "" || posts.github.filename == "" || posts.github.commitMessage == ""
      case .medium:
        return posts.medium.title == ""
      }
    } else {
      return true
    }
  }
  
  var body: some View {
    VStack {
      if let service = service,
         let provider = SharingProvider(rawValue: service.provider) {
        switch provider {
        case .github:
          Form {
            TextField("Path", text: $posts.github.path)
              .autocapitalization(.none)
              .disableAutocorrection(true)
            TextField("File name", text: $posts.github.filename)
              .autocapitalization(.none)
              .disableAutocorrection(true)
            TextField("Commit message", text: $posts.github.commitMessage)
          }
        case .medium:
          Form {
            TextField("Post title", text: $posts.medium.title)
          }
        }
      } else {
        Text("Invalid provider")
      }
      
      Button(action: tryPublish) {
        Text("Publish")
      }.disabled(isPublishDisabled())
        .alert("Found existing post", isPresented: $presentExistAlert, actions: {
          Button("Cancel", role: .cancel, action: {})
          Button("Update", action: publish)
        }, message: {
          Text("Continue will update the post")
        })
        .alert("Published successfully", isPresented: $presentSuccessAlert, actions: {
          Button("Close", action: { dismiss() })
          if let previewURL = previewURL {
            Button("Preview", action: { openURL(previewURL) })
          }
        })
        .alert("Error", isPresented: $presentErrorAlert, actions: {
          Button("OK", action: {})
        }, message: {
          if let errorAlerted = errorAlerted {
            Text(errorAlerted.localizedDescription)
          }
        })
    }
  }
}
