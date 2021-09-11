//
//  NotesStore.swift
//  Just Notepad
//
//  Created by Anton Cherkasov on 12.06.2021.
//
#if os(macOS)
import AppKit
#endif

#if os(iOS)
import UIKit
#endif

import CoreData

public protocol StoreDataSource {
	associatedtype T
	var objects: [T] { get }
	var numberOfObjects: Int { get }
	var numberOfSections: Int { get }
	func performFetch(with predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]) throws 
}

public protocol StoreDelegate : AnyObject {
	func storeWillChangeContent()
	func storeDelete(object: NSManagedObject, at index: Int)
	func storeInsert(object: NSManagedObject, at index: Int)
	func storeUpdate(object: NSManagedObject, at index: Int)
	func storeMove(object: NSManagedObject, from oldIndex: Int, to newIndex: Int)
	func storeDidChangeContent()
	func storeDidReloadContent()
}

public class Store<T: NSManagedObject>: NSObject, NSFetchedResultsControllerDelegate {
	
	public weak var delegate: StoreDelegate?
	
	private var fetchedResultController: NSFetchedResultsController<T>
	private var viewContext: NSManagedObjectContext
	
	public var errorHandler: ((Error) -> ())?
	
	public init(viewContext: NSManagedObjectContext, sortBy sortDescriptors: [NSSortDescriptor]) {
		self.viewContext = viewContext
		let fetchRequest: NSFetchRequest<T> = NSFetchRequest<T>.init(entityName: T.className())
		fetchRequest.sortDescriptors = sortDescriptors
		
		self.fetchedResultController = NSFetchedResultsController.init(fetchRequest: fetchRequest, managedObjectContext: viewContext, sectionNameKeyPath: nil, cacheName: nil)
		
		super.init()
		
		self.fetchedResultController.delegate = self
	}
	
	public func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		delegate?.storeWillChangeContent()
	}
	
	public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
		guard let object = anObject as? T else {
			fatalError("\(anObject) is not \(T.className())")
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
	
	public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		delegate?.storeDidChangeContent()
	}
	
}

extension Store : StoreDataSource {
	
	public var numberOfObjects : Int {
		return fetchedResultController.fetchedObjects?.count ?? 0
	}
	
	public var numberOfSections: Int {
		return fetchedResultController.sections?.count ?? 0
	}

	public var objects: [T] {
		return fetchedResultController.fetchedObjects ?? []
	}
	
	/// Perform fetch and call 'storeDidReloadContent' of the delegate
	public func performFetch(with predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]) {
		defer {
			delegate?.storeDidReloadContent()
		}
		if !sortDescriptors.isEmpty {
			fetchedResultController.fetchRequest.sortDescriptors = sortDescriptors
		}
		fetchedResultController.fetchRequest.predicate = predicate
		do {
			try fetchedResultController.performFetch()
		} catch {
			errorHandler?(error)
		}
		
	}
	
}


