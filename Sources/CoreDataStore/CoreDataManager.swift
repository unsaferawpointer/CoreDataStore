//
//  CoreDataManager.swift
//  CompactToDo
//
//  Created by Anton Cherkasov on 08.05.2021.
//

import CloudKit
import CoreData

open class CoreDataManager {
    
    public static let shared = CoreDataManager()
    
    private init() { }
    
    public var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
	
	public var containerName: String?
    
    // MARK: - Core Data stack
    
    public lazy var persistentContainer: NSPersistentCloudKitContainer = {

		guard let containerName = containerName else {
			fatalError("container name must be not nil")
		}
		
        let container = NSPersistentCloudKitContainer(name: containerName)
        
        container.persistentStoreDescriptions.first?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        //container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error {
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
                fatalError("Unresolved error \(error)")
            }
        })
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()

    
    // MARK: - Core Data Saving and Undo support
    
    public func saveAction(_ sender: AnyObject?) {
        // Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
        let context = persistentContainer.viewContext
        
        if !context.commitEditing() {
            NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing before saving")
        }
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Customize this code block to include application-specific recovery steps.
                let nserror = error as NSError
                //NSApplication.shared.presentError(nserror)
            }
        }
    }
    
    public func save() {
        // Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
        let context = persistentContainer.viewContext
        
        if !context.commitEditing() {
            NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing before saving")
        }
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Customize this code block to include application-specific recovery steps.
                let nserror = error as NSError
                //NSApplication.shared.presentError(nserror)
            }
        }
    }
    
}

extension CoreDataManager {
	
	var newBackgroundContext: NSManagedObjectContext {
		persistentContainer.newBackgroundContext()
	}
	
	func performForeground(task: @escaping (NSManagedObjectContext) -> Void) {
		viewContext.perform { task(self.viewContext) }
	}
	
	func performBackground(task: @escaping (NSManagedObjectContext) -> Void) {
		persistentContainer.performBackgroundTask(task)
	}
	
}
