//
//  NotesStore.swift
//  Just Notepad
//
//  Created by Anton Cherkasov on 12.06.2021.
//

import Foundation
import CoreData

#if os(macOS)
import AppKit
#endif

#if os(iOS)
import UIKit
#endif

public protocol StoreDataSource {
	associatedtype T
	var objects: [T] { get }
	var numberOfObjects: Int { get }
	func performFetch(with predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]) throws
}

public protocol StoreDelegate : AnyObject {
	func storeWillChangeContent()
	func storeDidRemove(object: NSManagedObject, at index: Int)
	func storeDidInsert(object: NSManagedObject, at index: Int)
	func storeDidUpdate(object: NSManagedObject, at index: Int)
	func storeDidMove(object: NSManagedObject, from oldIndex: Int, to newIndex: Int)
	func storeDidChangeContent()
	func storeDidReloadContent()
}

public class Store<T: NSManagedObject>: NSObject, NSFetchedResultsControllerDelegate {
	
	public weak var delegate: StoreDelegate?
	
	private var fetchedResultController: NSFetchedResultsController<T>
	private var viewContext: NSManagedObjectContext
	
	/// Use this initializer if the class name is not the same as the entity name
	public init(viewContext: NSManagedObjectContext, sortBy sortDescriptors: [NSSortDescriptor], entityName: String) {
		assert(!sortDescriptors.isEmpty, "Store must have at least one sort descriptor")
		self.viewContext = viewContext
		let fetchRequest: NSFetchRequest<T> = NSFetchRequest<T>.init(entityName: entityName)
		fetchRequest.sortDescriptors = sortDescriptors
		self.fetchedResultController = NSFetchedResultsController.init(fetchRequest: fetchRequest, managedObjectContext: viewContext, sectionNameKeyPath: nil, cacheName: nil)
		super.init()
		self.fetchedResultController.delegate = self
	}
	
	public convenience init(viewContext: NSManagedObjectContext, sortBy sortDescriptors: [NSSortDescriptor]) {
		let entityName = T.className()
		self.init(viewContext: viewContext, sortBy: sortDescriptors, entityName: entityName)
	}
	
	public func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		#if DEBUG
		NSLog(#function)
		#endif
		delegate?.storeWillChangeContent()
	}
	
	#if os(macOS)
	public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
		guard let object = anObject as? T else {
			fatalError("\(anObject) is not \(T.className())")
		}
		#if DEBUG
		NSLog(#function)
		NSLog("\(anObject) at indexPath = \(indexPath) newIndexPath = \(newIndexPath)")
		#endif
		switch type {
		case .insert:
			if let newIndex = newIndexPath?.item {
				delegate?.storeDidInsert(object: object, at: newIndex)
			}
		case .delete:
			if let oldIndex = indexPath?.item {
				delegate?.storeDidRemove(object: object, at: oldIndex)
			}
		case .move:
			if let oldIndex = indexPath?.item, let newIndex = newIndexPath?.item {
				delegate?.storeDidMove(object: object, from: oldIndex, to: newIndex)
			}
		case .update:
			if let oldIndex = indexPath?.item {
				delegate?.storeDidUpdate(object: object, at: oldIndex)
			}
		@unknown default:
			fatalError()
		}
	}
	#endif
	
	#if os(iOS)
	public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
		guard let object = anObject as? T else {
			fatalError("\(anObject) is not \(T.className())")
		}
		#if DEBUG
		NSLog(#function)
		NSLog("\(anObject) at indexPath = \(indexPath) newIndexPath = \(newIndexPath)")
		#endif
		switch type {
		case .insert:
			if let newIndex = newIndexPath?.row {
				delegate?.storeDidInsert(object: object, at: newIndex)
			}
		case .delete:
			if let oldIndex = indexPath?.row {
				delegate?.storeDidRemove(object: object, at: oldIndex)
			}
		case .move:
			if let oldIndex = indexPath?.row, let newIndex = newIndexPath?.item {
				delegate?.storeDidMove(object: object, from: oldIndex, to: newIndex)
			}
		case .update:
			if let oldIndex = indexPath?.row {
				delegate?.storeDidUpdate(object: object, at: oldIndex)
			}
		@unknown default:
			fatalError()
		}
	}
	#endif
	
	
	public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		#if DEBUG
		NSLog(#function)
		#endif
		delegate?.storeDidChangeContent()
	}
	
}

extension Store {
	public subscript(index: Int) -> T {
		get {
			return objects[index]
		}
	}
}

extension Store : StoreDataSource {
	
	public var numberOfObjects : Int {
		return fetchedResultController.fetchedObjects?.count ?? 0
	}
	
	public var objects: [T] {
		return fetchedResultController.fetchedObjects ?? []
	}
	
	/// Perform fetch and call 'storeDidReloadContent' of the delegate
	public func performFetch(with predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]) throws {
		defer {
			delegate?.storeDidReloadContent()
		}
		if !sortDescriptors.isEmpty {
			fetchedResultController.fetchRequest.sortDescriptors = sortDescriptors
		}
		fetchedResultController.fetchRequest.predicate = predicate
		try fetchedResultController.performFetch()
	}
	
}


