//
//  Persistence.swift
//  crakt
//
//  Created by Kyle Thompson on 9/16/23.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "crakt")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}

func printCoreSchema(container: NSPersistentContainer) {
    let model = container.managedObjectModel

    for entity in model.entities {
        print("Entity name: \(entity.name ?? "Unknown")")
        for property in entity.properties {
            switch property {
            case let attribute as NSAttributeDescription:
                print("Attribute - \(attribute.name): \(attribute.attributeType)")
            case let relationship as NSRelationshipDescription:
                print("Relationship - \(relationship.name): \(relationship.destinationEntity?.name ?? "Unknown")")
            default:
                print("Unknown property type")
            }
        }
    }
}
