# CoreDataStore

This package incapsulate work with Core Data stack and NSTableView.
NSTableView don't support Core Data batch operation out of box.

### Example of the Core Data ObjectFactory

First of all, you must implement the Duplicatable - protocol for your NSManagedObject class.

```swift
extension  DuplicatableNSManagedObject: Duplicatable {
	func duplicate() -> Self {
		guard let context = managedObjectContext else {
			fatalError("managedObjectContext don't exist")
		}
		if let result = DuplicatableNSManagedObject(context: context) as? Self {
			// Configure your diplicate here...
			return result
		}
		fatalError("Your type is not the same as Self")
	}
}
```

```swift
let factory = ObjectFactory<DuplicatableNSManagedObject>(viewContext: viewContext)
```

### Example of the Accumulate Changes Store

- [x] Support Core Data batch operation
- [x] Save table selection

```swift

extension ContentViewController : NSTableViewDelegate {
	func tableViewSelectionDidChange(_ notification: Notification) {
		accumulateChangesStore.selectionDidChanged(newSelection: tableView.selectedRowIndexes)
	}
}

extension ContentViewController : AccumulateChangesStoreDelegate {
	
	func accumulateChangesStoreWillChangeContent() {
		tableView.beginUpdates()
	}
	
	func accumulateChangesStoreDidInsert(indexSet: IndexSet) {
		tableView.insertRows(at: indexSet, withAnimation: .slideRight)
	}
	
	func accumulateChangesStoreDidRemove(indexSet: IndexSet) {
		tableView.removeRows(at: indexSet, withAnimation: .slideLeft)
	}
	
	func accumulateChangesStoreDidUpdate(indexSet: IndexSet) {
		let columnIndexes = IndexSet(integersIn: 0..<tableView.numberOfColumns)
		tableView.reloadData(forRowIndexes: indexSet, columnIndexes: columnIndexes)
	}
	
	func accumulateChangesStoreDidChangeContent() {
		tableView.endUpdates()
	}
	
	func accumulateChangesStoreDidReloadContent() {
		tableView.reloadData()
	}
	
	func accumulateChangesStoreDidSelect(indexSet: IndexSet) {
		tableView.selectRowIndexes(indexSet, byExtendingSelection: true)
	}
}
```


## To Do
- [ ] Add support of the 'move' operation
