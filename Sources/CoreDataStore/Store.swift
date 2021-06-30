//
//  NotesStore.swift
//  Just Notepad
//
//  Created by Anton Cherkasov on 12.06.2021.
//

import AppKit
import CoreData

protocol StoreDelegate : AnyObject {
    func storeDidReloadContent()
    func storeWillChangeContent()
    func storeDelete(object: NSManagedObject, at index: Int)
    func storeInsert(object: NSManagedObject, at index: Int)
    func storeUpdate(object: NSManagedObject, at index: Int)
    func storeMove(object: NSManagedObject, from fromIndex: Int, to toIndex: Int)
    func storeDidChangeContent()
}

class Store<T: NSManagedObject>: NSObject, NSFetchedResultsControllerDelegate {
    
    weak var delegate: StoreDelegate?
    
    private var fetchedResultController: NSFetchedResultsController<T>
    private var viewContext: NSManagedObjectContext
    
    init(sortBy sortDescriptors: [NSSortDescriptor]) {
        
        let fetchRequest: NSFetchRequest<T> = NSFetchRequest<T>.init(entityName: T.className())
        self.viewContext = CoreDataManager.shared.viewContext
        
        fetchRequest.sortDescriptors = sortDescriptors
        
        self.fetchedResultController = NSFetchedResultsController.init(fetchRequest: fetchRequest, managedObjectContext: viewContext, sectionNameKeyPath: nil, cacheName: nil)
        
        super.init()
        
        self.fetchedResultController.delegate = self
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        delegate?.storeWillChangeContent()
        print(#function)
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        print(#function)
        print("oldPath = \(indexPath) newPath = \(newIndexPath)")
        guard let object = anObject as? T else {
            fatalError("\(anObject) is not NSManagedObject")
        }
        switch type {
        case .insert:
            if let newIndex = newIndexPath?.item {
                delegate?.storeInsert(object: object, at: newIndex)
            }
        case .delete:
            if let oldIndex = indexPath?.item {
                delegate?.storeDelete(object: object, at: oldIndex)
            }
        case .move:
            if let oldIndex = indexPath?.item, let newIndex = newIndexPath?.item {
                delegate?.storeMove(object: object, from: oldIndex, to: newIndex)
            }
        case .update:
            if let oldIndex = indexPath?.item {
                delegate?.storeUpdate(object: object, at: oldIndex)
            }
        @unknown default:
            fatalError()
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        delegate?.storeDidChangeContent()
        print(#function)
    }
    
}

extension Store {
    var numberOfObjects : Int {
        return fetchedResultController.fetchedObjects?.count ?? 0
    }
}

extension Store {
    
    var objects: [T] {
        return fetchedResultController.fetchedObjects ?? []
    }
    
    func performFetch(with predicate: NSPredicate?) -> [T] {
        fetchedResultController.fetchRequest.predicate = predicate
        do {
            try fetchedResultController.performFetch()
            delegate?.storeDidReloadContent()
        } catch {
            NSApp.presentError(error)
        }
        return objects
    }
    
}

extension Store {
    
    func save() {
        CoreDataManager.shared.save()
    }
    
    func newObject() -> T {
        let newObject = T(context: viewContext)
        save()
        return newObject
    }
    
    func delete(object: T) {
        viewContext.delete(object)
        save()
    }
}
