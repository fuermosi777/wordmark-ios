//
//  ServiceListSheet.swift
//  WordMark
//
//  Created by Hao Liu on 1/9/22.
//

import SwiftUI

// A sheet view to list all sharing services added.
struct ServiceListSheet: View {
  @Environment(\.managedObjectContext) var managedObjectContext
  @Environment(\.dismiss) private var dismiss
  
  @FetchRequest(entity: SharingService.entity(), sortDescriptors: [
    NSSortDescriptor(keyPath: \SharingService.createdAt, ascending: true)
  ])
  var sharingServices: FetchedResults<SharingService>
  
  @State private var showCreateServiceSheet = false
  
  private func deleteService(offsets: IndexSet) {
    for index in offsets {
      let service = sharingServices[index]
      managedObjectContext.delete(service)
    }
    saveContext()
  }
  
  private func saveContext() {
    do {
      try managedObjectContext.save()
    } catch {
      print("Error saving new sharing service: \(error)")
    }
  }
  
  var body: some View {
    NavigationView {
      VStack {
        List {
          ForEach(sharingServices) { service in
            SharingServiceRow(data: service)
          }.onDelete(perform: deleteService)
        }
      }
      .navigationTitle("Sharing Services")
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
      }
    }
  }
}
