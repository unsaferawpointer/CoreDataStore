//
//  File.swift
//  
//
//  Created by Anton Cherkasov on 13.09.2021.
//

import Foundation
import CoreData

protocol AccumulateChangesStoreDelegate: AnyObject {
	func accumulateChangesStoreDidChangeContent()
	func accumulateChangesStoreWillChangeContent()
	func accumulateChangesStoreDidInsert(indexSet: IndexSet)
	func accumulateChangesStoreDidRemove(indexSet: IndexSet)
	func accumulateChangesStoreDidSelect(indexSet: IndexSet)
	func accumulateChangesStoreDidUpdate(indexSet: IndexSet)
	func accumulateChangesStoreDidReloadContent()
}

class AccumulateChangesStore<T: NSManagedObject> {
	
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

	let store: Store<T>
	weak var delegate: AccumulateChangesStoreDelegate?
	
	// State
	private var selected: Set<T> = []
	
	private var removals: Set<Removal> = []
	private var insertions: Set<Insertion> = []
	private var updatings: Set<Updating> = []
	private var movings: Set<Moving> = []
	
	var isEditing = false
	
	public init(viewContext: NSManagedObjectContext, sortDescriptors: [NSSortDescriptor]) {
		self.store = Store<T>(viewContext: viewContext, sortBy: sortDescriptors)
	}
}

extension AccumulateChangesStore: StoreDelegate {
	
	func storeWillChangeContent() {
		isEditing = true
	}
	
	func storeDidRemove(object: NSManagedObject, at index: Int) {
		let change = Removal(object: object as! T, index: index)
		removals.insert(change)
	}
	
	func storeDidInsert(object: NSManagedObject, at index: Int) {
		let change = Insertion(object: object as! T, index: index)
		insertions.insert(change)
	}
	
	func storeDidUpdate(object: NSManagedObject, at index: Int) {
		let change = Updating(object: object as! T, index: index)
		updatings.insert(change)
	}
	
	func storeDidMove(object: NSManagedObject, from oldIndex: Int, to newIndex: Int) {
		let moving = Moving(object: object as! T, fromIndex: oldIndex, toIndex: newIndex)
		movings.insert(moving)
	}
	
	func storeDidChangeContent() {
		let removedIndexSet = IndexSet(removals.map{ $0.index })
		let insertedIndexSet = IndexSet(insertions.map{ $0.index })
		let updatedIndexSet = IndexSet(updatings.map{ $0.index })
		let movingsFromIndexSet = IndexSet(movings.map{ $0.fromIndex })
		let movingsToIndexSet = IndexSet(movings.map{ $0.toIndex })
		
		delegate?.accumulateChangesStoreWillChangeContent()
		delegate?.accumulateChangesStoreDidRemove(indexSet: removedIndexSet)
		delegate?.accumulateChangesStoreDidInsert(indexSet: insertedIndexSet)
		delegate?.accumulateChangesStoreDidUpdate(indexSet: updatedIndexSet)
		delegate?.accumulateChangesStoreDidRemove(indexSet: movingsFromIndexSet)
		delegate?.accumulateChangesStoreDidInsert(indexSet: movingsToIndexSet)
		delegate?.accumulateChangesStoreDidChangeContent()
		
		let selectedMovedIndexSet = getSelectedIndexSet(from: removals, andInsertions: insertions)
		delegate?.accumulateChangesStoreDidSelect(indexSet: selectedMovedIndexSet)
		resetChanges()
		isEditing = false
	}
	
	func storeDidReloadContent() {
		delegate?.accumulateChangesStoreDidReloadContent()
	}
	
	private func resetChanges() {
		removals.removeAll()
		insertions.removeAll()
		updatings.removeAll()
		movings.removeAll()
	}
	
	private func getSelectedIndexSet(from removals: Set<Removal>, andInsertions insertions: Set<Insertion>) -> IndexSet {
		let removedObjects = Set(removals.compactMap{ $0.object })
		let insertedObjects = Set(insertions.compactMap{ $0.object })
		let movedObjects = removedObjects.intersection(insertedObjects)
		let selectedMovedObjects = movedObjects.intersection(selected)
		let selectedMovedIndices = selectedMovedObjects.compactMap { store.objects.firstIndex(of: $0)}
		return IndexSet(selectedMovedIndices)
	}
	
}
