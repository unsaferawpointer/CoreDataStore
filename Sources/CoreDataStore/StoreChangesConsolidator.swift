//
//  File.swift
//  
//
//  Created by Anton Cherkasov on 30.07.2021.
//

import CoreData

public protocol StoreChangesConsolidatorDelegate : AnyObject {
	func storeChangesConsolidatorDidReloadContent()
	func storeChangesConsolidatorWillChangeContent()
	func storeChangesConsolidatorDidInsert(objects: [(object: NSManagedObject, index: Int)])
	func storeChangesConsolidatorDidDelete(objects: [(object: NSManagedObject, index: Int)])
	func storeChangesConsolidatorDidUpdate(objects: [(object: NSManagedObject, index: Int)])
	func storeChangesConsolidatorDidMove(objects: [(object: NSManagedObject, from: Int, to: Int)])
	func storeChangesConsolidatorDidDelete(sections: [(object: NSFetchedResultsSectionInfo, index: Int)])
	func storeChangesConsolidatorDidInsert(sections: [(object: NSFetchedResultsSectionInfo, index: Int)])
	func storeChangesConsolidatorDidChangeContent()
}

struct ChangesStore {
	
	var sectionsInsertion	: [(object: NSFetchedResultsSectionInfo, index: Int)] = []
	var sectionsDeletion	: [(object: NSFetchedResultsSectionInfo, index: Int)] = []
	
	var objectsInsertion	: [(object: NSManagedObject, index: Int)] = []
	var objectsDeletion		: [(object: NSManagedObject, index: Int)] = []
	var objectsUpdating		: [(object: NSManagedObject, index: Int)] = []
	var objectsMoving		: [(object: NSManagedObject, from: Int, to: Int)] = []
	
	mutating func didInsert(section: NSFetchedResultsSectionInfo, at index: Int) {
		sectionsInsertion.append((object: section, index: index))
	}
	
	mutating func didDelete(section: NSFetchedResultsSectionInfo, at index: Int) {
		sectionsDeletion.append((object: section, index: index))
	}
	
	mutating func didDelete(object: NSManagedObject, at index: Int) {
		objectsDeletion.append((object: object, index: index))
	}
	
	mutating func didInsert(object: NSManagedObject, at index: Int) {
		objectsDeletion.append((object: object, index: index))
	}
	
	mutating func didUpdate(object: NSManagedObject, at index: Int) {
		objectsUpdating.append((object: object, index: index))
	}
	
	mutating func didMove(object: NSManagedObject, from oldIndex: Int, to newIndex: Int) {
		objectsMoving.append((object: object, from: oldIndex, to: newIndex))
	}
	
	func objectsInsertionIndexSet() -> IndexSet {
		let array = objectsInsertion.compactMap { $0.index }
		return IndexSet(array)
	}
	
	func objectsDeletionIndexSet() -> IndexSet {
		let array = objectsDeletion.compactMap { $0.index }
		return IndexSet(array)
	}
	
	func objectsUpdatingIndexSet() -> IndexSet {
		let array = objectsUpdating.compactMap { $0.index }
		return IndexSet(array)
	}
	
	mutating func reset() {
		sectionsInsertion.removeAll()
		sectionsDeletion.removeAll()
		objectsInsertion.removeAll()
		objectsDeletion.removeAll()
		objectsUpdating.removeAll()
		objectsMoving.removeAll()
	}
	
}

/// It is wrapper of the Store class. The class collect all changes to four types set: delete, insert, update and move
public class StoreChangesConsolidator<T : NSManagedObject> {
	
	public weak var delegate: StoreChangesConsolidatorDelegate?
	
	private var store: Store<T>
	private var changesStore = ChangesStore()
	
	public init(viewContext context: NSManagedObjectContext, sortBy sortDescriptors: [NSSortDescriptor]) {
		self.store = Store<T>.init(viewContext: context, sortBy: sortDescriptors)
	}
}

extension StoreChangesConsolidator : StoreDataSource {
	
	public func performFetch(with predicate: NSPredicate?) throws {
		try store.performFetch(with: predicate)
	}
	
	public var objects: [T] {
		return store.objects
	}
	
	public var numberOfObjects: Int {
		return store.numberOfObjects
	}
	
	public var numberOfSections: Int {
		return store.numberOfSections
	}
}

extension StoreChangesConsolidator : StoreDelegate where T == NSManagedObject {
	
	public func storeWillChangeContent() {
		delegate?.storeChangesConsolidatorWillChangeContent()
	}
	
	public func storeDidInsert(section: NSFetchedResultsSectionInfo, at index: Int) {
		changesStore.didInsert(section: section, at: index)
	}
	
	public func storeDidDelete(section: NSFetchedResultsSectionInfo, at index: Int) {
		changesStore.didDelete(section: section, at: index)
	}
	
	public func storeDidReloadContent() {
		delegate?.storeChangesConsolidatorDidReloadContent()
	}
	
	public func storeDelete(object: NSManagedObject, at index: Int) {
		changesStore.didDelete(object: object, at: index)
	}
	
	public func storeInsert(object: NSManagedObject, at index: Int) {
		changesStore.didInsert(object: object, at: index)
	}
	
	public func storeUpdate(object: NSManagedObject, at index: Int) {
		changesStore.didUpdate(object: object, at: index)
	}
	
	public func storeMove(object: NSManagedObject, from fromIndex: Int, to toIndex: Int) {
		changesStore.didMove(object: object, from: fromIndex, to: toIndex)
	}
	
	public func storeDidChangeContent() {
		
		delegate?.storeChangesConsolidatorDidDelete(objects: changesStore.objectsDeletion)
		delegate?.storeChangesConsolidatorDidDelete(sections: changesStore.sectionsDeletion)
		delegate?.storeChangesConsolidatorDidInsert(sections: changesStore.sectionsInsertion)
		delegate?.storeChangesConsolidatorDidInsert(objects: changesStore.objectsInsertion)
		delegate?.storeChangesConsolidatorDidMove(objects: changesStore.objectsMoving)
		delegate?.storeChangesConsolidatorDidUpdate(objects: changesStore.objectsUpdating)
		delegate?.storeChangesConsolidatorDidChangeContent()
		changesStore.reset()
	}
	
}