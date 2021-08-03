//
//  File.swift
//  
//
//  Created by Anton Cherkasov on 30.07.2021.
//

import CoreData

protocol StoreChangesConsolidatorDelegate : AnyObject {
	func storeChangesConsolidatorDidReloadContent()
	func storeChangesConsolidatorWillChangeContent()
	func storeChangesConsolidatorDidInsert(section: NSFetchedResultsSectionInfo, at index: Int)
	func storeChangesConsolidatorDidChangeContent()
}

struct ChangesStore {
	
	enum ChangeType {
		case insert(at: Int)
		case delete(at: Int)
		case update(at: Int)
		case move(from: Int, to: Int)
	}
	
	struct Change<T> {
		var type: ChangeType
		var object: T
	}
	
	var sectionsChanges	: [Change<NSFetchedResultsSectionInfo>] = []
	var objectsChanges	: [Change<NSManagedObject>] = []
	
	mutating func add(change : Change<NSFetchedResultsSectionInfo>) {
		sectionsChanges.append(change)
	}
	
	mutating func add(change : Change<NSManagedObject>) {
		objectsChanges.append(change)
	}
	
	mutating func reset() {
		sectionsChanges.removeAll()
		objectsChanges.removeAll()
	}
	
}

class StoreChangesConsolidator<T : NSManagedObject> {
	
	weak var delegate: StoreChangesConsolidatorDelegate?
	
	private var store: Store<T>
	private var changesStore = ChangesStore()
	
	init(viewContext context: NSManagedObjectContext, sortBy sortDescriptors: [NSSortDescriptor]) {
		self.store = Store<T>.init(viewContext: context, sortBy: sortDescriptors)
	}
}

extension StoreChangesConsolidator : StoreDataSource {
	
	func performFetch(with predicate: NSPredicate?) throws {
		try store.performFetch(with: predicate)
	}
	
	var objects: [T] {
		return store.objects
	}
	
	var numberOfObjects: Int {
		return store.numberOfObjects
	}
	
	var numberOfSections: Int {
		return store.numberOfSections
	}
}

extension StoreChangesConsolidator : StoreDelegate {
	
	typealias Change = ChangesStore.Change
	
	func storeWillChangeContent() {
		delegate?.storeChangesConsolidatorWillChangeContent()
	}
	
	func storeDidInsert(section: NSFetchedResultsSectionInfo, at index: Int) {
		let change = Change(type: .insert(at: index), object: section)
		changesStore.add(change: change)
	}
	
	func storeDidDelete(section: NSFetchedResultsSectionInfo, at index: Int) {
		let change = Change(type: .delete(at: index), object: section)
		changesStore.add(change: change)
	}
	
	func storeDidReloadContent() {
		delegate?.storeChangesConsolidatorDidReloadContent()
	}
	
	func storeDelete(object: NSManagedObject, at index: Int) {
		let change = Change(type: .delete(at: index), object: object)
		changesStore.add(change: change)
	}
	
	func storeInsert(object: NSManagedObject, at index: Int) {
		let change = Change(type: .insert(at: index), object: object)
		changesStore.add(change: change)
	}
	
	func storeUpdate(object: NSManagedObject, at index: Int) {
		let change = Change(type: .update(at: index), object: object)
		changesStore.add(change: change)
	}
	
	func storeMove(object: NSManagedObject, from fromIndex: Int, to toIndex: Int) {
		let change = Change(type: .move(from: fromIndex, to: toIndex), object: object)
		changesStore.add(change: change)
	}
	
	func storeDidChangeContent() {
		changesStore.reset()
	}
	
}
