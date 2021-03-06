//
//  File.swift
//  
//
//  Created by Anton Cherkasov on 13.09.2021.
//

import Foundation
import CoreData

public protocol AccumulateChangesStoreDelegate: AnyObject {
	func accumulateChangesStoreDidChangeContent()
	func accumulateChangesStoreWillChangeContent()
	func accumulateChangesStoreDidInsert(indexSet: IndexSet)
	func accumulateChangesStoreDidRemove(indexSet: IndexSet)
	func accumulateChangesStoreDidSelect(indexSet: IndexSet)
	func accumulateChangesStoreDidUpdate(indexSet: IndexSet)
	func accumulateChangesStoreDidReloadContent()
	func getSelectedRows() -> IndexSet
}

public class AccumulateChangesStore<T: NSManagedObject> {
	
	struct Moving : Hashable {
		var object: T
		var fromIndex: Int
		var toIndex: Int
	}
	
	struct Insertion : Hashable {
		var object: T
		var index: Int
	}
	
	struct Removal : Hashable {
		var object: T
		var index: Int
	}
	
	struct Updating : Hashable {
		var object: T
		var index: Int
	}

	private let store: CoreDataFetchStore<T>
	public weak var delegate: AccumulateChangesStoreDelegate?
	
	// State
	private var selected: Set<T> = []
	
	private var removals: Set<Removal> = []
	private var insertions: Set<Insertion> = []
	private var updatings: Set<Updating> = []
	private var movings: Set<Moving> = []
	
	public init(viewContext: NSManagedObjectContext, sortDescriptors: [NSSortDescriptor]) {
		self.store = CoreDataFetchStore<T>(viewContext: viewContext, sortBy: sortDescriptors)
		self.store.delegate = self
	}
	
}

extension AccumulateChangesStore {
	public subscript(index: Int) -> T {
		get {
			return store.objects[index]
		}
	}
}

extension AccumulateChangesStore: StoreDelegate {
	
	public func storeWillChangeContent() {
		delegate?.accumulateChangesStoreWillChangeContent()
		selected = Set(delegate?.getSelectedRows().map{ store[$0] } ?? [])
	}
	
	public func storeDidRemove(object: NSManagedObject, at index: Int) {
		let change = Removal(object: object as! T, index: index)
		removals.insert(change)
	}
	
	public func storeDidInsert(object: NSManagedObject, at index: Int) {
		let change = Insertion(object: object as! T, index: index)
		insertions.insert(change)
	}
	
	public func storeDidUpdate(object: NSManagedObject, at index: Int) {
		let change = Updating(object: object as! T, index: index)
		updatings.insert(change)
	}
	
	public func storeDidMove(object: NSManagedObject, from oldIndex: Int, to newIndex: Int) {
		let moving = Moving(object: object as! T, fromIndex: oldIndex, toIndex: newIndex)
		movings.insert(moving)
	}
	
	public func storeDidChangeContent() {
		let removedIndexSet = IndexSet(removals.map{ $0.index })
		let insertedIndexSet = IndexSet(insertions.map{ $0.index })
		let updatedIndexSet = IndexSet(updatings.map{ $0.index })
		let movingsFromIndexSet = IndexSet(movings.map{ $0.fromIndex })
		let movingsToIndexSet = IndexSet(movings.map{ $0.toIndex })
		
		delegate?.accumulateChangesStoreDidRemove(indexSet: removedIndexSet)
		delegate?.accumulateChangesStoreDidInsert(indexSet: insertedIndexSet)
		delegate?.accumulateChangesStoreDidUpdate(indexSet: updatedIndexSet)
		delegate?.accumulateChangesStoreDidRemove(indexSet: movingsFromIndexSet)
		delegate?.accumulateChangesStoreDidInsert(indexSet: movingsToIndexSet)
		delegate?.accumulateChangesStoreDidChangeContent()
		
		let selectedMovedIndexSet = getSelectedIndexSet(from: removals, andInsertions: insertions)
		delegate?.accumulateChangesStoreDidSelect(indexSet: selectedMovedIndexSet)
		resetChanges()
		
	}
	
	public func storeDidReloadContent() {
		delegate?.accumulateChangesStoreDidReloadContent()
	}
	
	private func resetChanges() {
		removals.removeAll()
		insertions.removeAll()
		updatings.removeAll()
		movings.removeAll()
	}
	
	private func getSelectedIndexSet(from removals: Set<Removal>, andInsertions insertions: Set<Insertion>) -> IndexSet {
		let movedObjects = Set(movings.map{ $0.object })
		let selectedMovedObjects = movedObjects.intersection(selected)
		let selectedMovedIndices = selectedMovedObjects.compactMap { store.objects.firstIndex(of: $0)}
		return IndexSet(selectedMovedIndices)
	}
	
}

extension AccumulateChangesStore: StoreDataSource {
	public var objects: [T] {
		return store.objects
	}
	
	public var numberOfObjects: Int {
		return store.numberOfObjects
	}
	
	public func performFetch(with predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]) throws {
		try store.performFetch(with: predicate, sortDescriptors: sortDescriptors)
	}
}
