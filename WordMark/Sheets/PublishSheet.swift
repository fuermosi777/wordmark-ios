//
//  PublishSheet.swift
//  WordMark
//
//  Created by Hao Liu on 1/3/22.
//

import SwiftUI

struct PublishSheet: View {
  @Environment(\.managedObjectContext) var managedObjectContext
  @Environment(\.dismiss) private var dismiss

  let document: WordMarkDocument
  
  @FetchRequest(entity: SharingService.entity(), sortDescriptors: [
    NSSortDescriptor(keyPath: \SharingService.createdAt, ascending: true)
  ])
  var sharingServices: FetchedResults<SharingService>
  
  @State private var selectedService: SharingService?
  @State private var showCreateServiceSheet = false
  @State private var navigateToDetail = false
  @State private var posts: Posts
  
  init(document: WordMarkDocument) {
    self.document = document
    _posts = State(initialValue: (github: GithubPost(content: document.text,
                                                     path: "",
                                                     filename: document.filename ?? "Untitled.md",
                                                     commitMessage: "" ,
                                                     sha: nil),
                                  medium: MediumPost(content: document.text,
                                                     title: document.filename ?? "Untitled.md",
                                                     tags: [],
                                                     publishStatus: "public")))
  }
  
  var body: some View {
    NavigationView {
      VStack {
        Form {
          Picker("Select a publish service", selection: $selectedService) {
            ForEach(sharingServices) { service in
              SharingServiceRow(data: service)
                .tag(service as SharingService?)
            }
          }.pickerStyle(.inline)
        }
        
        NavigationLink(destination: EnterMetadataView(service: selectedService, posts: $posts),
                       isActive: $navigateToDetail) { EmptyView() }
      }
      .navigationTitle("Publish")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button(action: { dismiss() }) {
            Image(systemName: "xmark")
          }
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
          Button(action: { showCreateServiceSheet = true }) {
            Image(systemName: "plus")
          }.sheet(isPresented: $showCreateServiceSheet,
                  onDismiss: { showCreateServiceSheet = false}) {
            CreateSharingServiceSheet()
          }
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
          Button(action: { navigateToDetail = true }) {
            Image(systemName: "chevron.right")
          }.disabled(selectedService == nil)
        }
      }
    }
  }
}
