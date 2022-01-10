//
//  CreateSharingServiceSheet.swift
//  WordMark
//
//  Created by Hao Liu on 1/3/22.
//

import SwiftUI

struct CreateSharingServiceSheet: View {
  @State private var provider: SharingProvider = .github
  @Environment(\.dismiss) private var dismiss
  
  var body: some View {
    NavigationView {
      VStack {
        Form {
          Picker("Publish Service provider", selection: $provider) {
            ForEach(SharingProvider.allCases) { provider in
              Text(provider.imageName)
                .tag(provider)
            }
          }.pickerStyle(.inline)
        }
      }
      .navigationTitle("Add Publish Service")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          NavigationLink(destination: CreateGenericService(provider: provider, done: { dismiss() })) {
            Image(systemName: "chevron.right")
          }
        }
      }
    }
  }
}

// A generic nagivation view for handling adding publish services.
// Will communicate with core data here, too. It has a handle for
// confirming the operation is done.
struct CreateGenericService: View {
  @Environment(\.managedObjectContext) var managedObjectContext
  
  var provider: SharingProvider
  var done: () -> Void
  
  var body: some View {
    switch provider {
    case .github:
      CreateGithubService(onContinue: handleCreateGithubService)
    case .medium:
      CreateMediumService(onContinue: handleCreateMediumService)
    }
  }
  
  private func handleCreateGithubService(_ provider: GithubProvider) {
    let newService = SharingService(context: managedObjectContext)
    newService.accessToken = provider.accessToken
    newService.repository = provider.repository
    newService.branch = provider.branch
    newService.provider = SharingProvider.github.rawValue
    newService.createdAt = Date()
    
    saveContext()
    done()
  }
  
  private func handleCreateMediumService(_ provider: MediumProvider) {
    let newService = SharingService(context: managedObjectContext)
    newService.accessToken = provider.accessToken
    newService.name = provider.username
    newService.provider = SharingProvider.medium.rawValue
    newService.identifier = provider.id
    
    saveContext()
    done()
  }
  
  private func saveContext() {
    do {
      try managedObjectContext.save()
    } catch {
      print("Error saving new sharing service: \(error)")
    }
  }
}

// The view to add a Github account as a publishing service.
// Has a callback handle for confirmation, which will be handled in its owner's view.
struct CreateGithubService: View {
  @State var state = UUID().uuidString
  @State var code: String?
  
  @State var accessToken: String?
  
  @State var repos: [GithubRepoResponse] = []
  @State var selectedRepoID = 0
  @State var branches: [GithubBranchResponse] = []
  @State var selectedBranchID = ""
  
  var onContinue: (_ service: GithubProvider) -> Void
  
  var body: some View {
    VStack {
      if code == nil {
        AuthWebView(defaultURL: GithubService.shared.getAuthorizeURL(self.state),
                    code: $code)
      } else if accessToken == nil {
        ProgressView().onAppear(perform: loadAccessData)
      } else {
        Form {
          Picker(selection: $selectedRepoID,
                 label: Text(NSLocalizedString("Repository",
                                               comment: "Label for repository"))) {
            ForEach(repos) { repo in
              Text(repo.full_name)
            }
          }
                                               .onChange(of: selectedRepoID, perform: handleRepoChange)
                                               .disabled(repos.count == 0)
                                               .onAppear(perform: loadRepos)
          
          Picker(selection: $selectedBranchID,
                 label: Text(NSLocalizedString("Branch",
                                               comment: "Label for branch"))) {
            ForEach(branches) { branch in
              Text(branch.name)
            }
          }.disabled(branches.count == 0)
        }
        
        Button(action: handleContinueAction) {
          Text("Continue")
        }
      }
    }
    
  }
  
  
  func loadAccessData() {
    GithubService.shared.getAccessToken(code: code!, state: state)
      .sink(
        receiveCompletion: { completion in
          switch completion {
          case .failure(let error):
            print("err", error.localizedDescription)
          case .finished:
            break
          }
        },
        receiveValue: { value in
          self.accessToken = value.access_token
        }
      ).store(in: &GithubService.shared.disposables)
  }
  
  func loadRepos() {
    if accessToken != nil {
      GithubService.shared.getRepos(accessToken: accessToken!)
        .sink(
          receiveCompletion: { completion in
            switch completion {
            case .failure(let error):
              print("err", error.localizedDescription)
            case .finished:
              break
            }
          },
          receiveValue: { value in
            self.repos = value
          }
        ).store(in: &GithubService.shared.disposables)
    }
  }
  
  func handleRepoChange(repoIndex: Int) {
    if let repo = self.repos.first(where: { $0.id == repoIndex}) {
      if accessToken == nil {
        return
      }
      
      GithubService.shared.getBranches(accessToken: accessToken!, repoFullName: repo.full_name)
        .sink(
          receiveCompletion: { completion in
            switch completion {
            case .failure(let error):
              print("err", error.localizedDescription)
            case .finished:
              break
            }
          },
          receiveValue: { value in
            self.branches = value
          }
        ).store(in: &GithubService.shared.disposables)
    }
  }
  
  func handleContinueAction() {
    if self.accessToken == nil || self.selectedBranchID == "" {
      return
    }
    if let repo = self.repos.first(where: { $0.id == selectedRepoID}) {
      self.onContinue(GithubProvider(accessToken: self.accessToken!,
                                     repository: repo.full_name,
                                     branch: self.selectedBranchID))
    }
  }
}

struct CreateMediumService: View {
  @State var accessToken: String = ""
  @State var presentErrorAlert = false
  @State var errorMessage = ""
  
  var onContinue: (_ service: MediumProvider) -> Void
  
  private func tryAddService() {
    guard accessToken != "" else { return }
    
    MediumService.shared.getUser(accessToken: accessToken)
      .sink(
        receiveCompletion: { completion in
          switch completion {
          case .failure(_):
            presentErrorAlert = true
            errorMessage = NSLocalizedString("Please enter a valid access token", comment: "")
          case .finished:
            break
          }
        },
        receiveValue: { value in
          self.onContinue(MediumProvider(accessToken: accessToken,
                                         username: value.data.username,
                                         id: value.data.id))
        }
      ).store(in: &MediumService.shared.disposables)
  }
  
  var body: some View {
    VStack {
      Form {
        TextField("Access token", text: $accessToken)
          .autocapitalization(.none)
          .disableAutocorrection(true)
      }
      
      Button(action: tryAddService) {
        Text(NSLocalizedString("Continue", comment: "Label for continue"))
      }.disabled(accessToken == "")
        .alert("Error", isPresented: $presentErrorAlert, actions: {
          Button("Try again", action: {})
        }, message: {
          Text(errorMessage)
        })
    }
  }
}
