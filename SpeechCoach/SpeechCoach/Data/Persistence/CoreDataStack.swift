//
//  CoreDataStack.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 12/26/25.
//

import CoreData

final class CoreDataStack {
    static let shared = CoreDataStack()

    let container: NSPersistentContainer

    var context: NSManagedObjectContext {
        container.viewContext
    }

    private init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "SpeechCoachModel")

        if inMemory {
            container.persistentStoreDescriptions.first?.url =
                URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { _, error in
            if let error {
                fatalError("CoreData load failed: \(error)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
