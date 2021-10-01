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
	
	enum ChangeType {
		case insert
		case remove
		case update
	}
	
	struct Change : Hashable {
		let type: ChangeType
		let object: T
		let index: Int
	}
	
	let store: Store<T>
	weak var delegate: AccumulateChangesStoreDelegate?
	
	// State
	private var selected: Set<T> = []
	private var changes: Set<Change> = []
	
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
		let change = Change(type: .remove, object: object as! T, index: index)
		changes.insert(change)
	}
	
	func storeDidInsert(object: NSManagedObject, at index: Int) {
		let change = Change(type: .insert, object: object as! T, index: index)
		changes.insert(change)
	}
	
	func storeDidUpdate(object: NSManagedObject, at index: Int) {
		let change = Change(type: .update, object: object as! T, index: index)
		changes.insert(change)
	}
	
	func storeDidMove(object: NSManagedObject, from oldIndex: Int, to newIndex: Int) {
		let insertion = Change(type: .insert, object: object as! T, index: newIndex)
		let deletion = Change(type: .remove, object: object as! T, index: oldIndex)
		changes.insert(insertion)
		changes.insert(deletion)
	}
	
	func storeDidChangeContent() {
		
		let removals = 		changes.filter { $0.type == .remove }
		let insertions = 	changes.filter { $0.type == .insert }
		let update = 		changes.filter { $0.type == .update }
		
		let removedIndexSet = IndexSet(removals.compactMap{ $0.index })
		let insertedIndexSet = IndexSet(insertions.compactMap{ $0.index })
		let updatedIndexSet = IndexSet(update.compactMap{ $0.index })
		
		delegate?.accumulateChangesStoreWillChangeContent()
		delegate?.accumulateChangesStoreDidRemove(indexSet: removedIndexSet)
		delegate?.accumulateChangesStoreDidInsert(indexSet: insertedIndexSet)
		delegate?.accumulateChangesStoreDidUpdate(indexSet: updatedIndexSet)
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
		changes.removeAll()
	}
	
	private func getSelectedIndexSet(from removals: Set<Change>, andInsertions insertions: Set<Change>) -> IndexSet {
		
		let removedObjects = Set(removals.compactMap{ $0.object })
		let insertedObjects = Set(insertions.compactMap{ $0.object })
		
		let movedObjects = removedObjects.intersection(insertedObjects)
		let selectedMovedObjects = movedObjects.intersection(selected)
		let selectedMovedIndices = selectedMovedObjects.compactMap { store.objects.firstIndex(of: $0)}
		return IndexSet(selectedMovedIndices)
	}
	
}
