//
//  Persistence.swift
//  WordMark
//
//  Created by Hao Liu on 1/3/22.
//

import Foundation
import CoreData

struct PersistenceController {
  static let shared = PersistenceController()
  
  let container: NSPersistentContainer
  
  init(inMemory: Bool = false) {
    container = NSPersistentContainer(name: "WordMarkData")
    
    if inMemory {
      container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
    }
    
    container.loadPersistentStores { _, error in
      if let error = error as NSError? {
        // showing a dialog indicating the app is in a weird state and needs reinstalling
        fatalError("Unresolved error \(error), \(error.userInfo)")
      }
    }
  }
}
