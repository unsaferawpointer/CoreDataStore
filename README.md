# CoreDataStore

This package incapsulate work with Core Data stack.

### Example of the Store

```swift
extension  DuplicatableNSManagedObject: Duplicatable {
	func duplicate() -> Self {
		guard let context = managedObjectContext else {
			fatalError("managedObjectContext don't exist")
		}
		if let result = DuplicatableNSManagedObject(context: context) as? Self {
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



## To Do
- [ ] Add support of the 'move' operation
