# CoreDataStore

This package incapsulate work with Core Data stack.

### Example

```swift
extension  DuplicatableNSManagedObject: Duplicatable {
	func duplicate() -> Self {
		if let result = DuplicatableNSManagedObject() as? Self {
			return result
		}
		fatalError("Your type is not the same as Self")
	}
}
```

```swift
let factory = ObjectFactory<NSManagedObject>(viewContext: viewContext)
```
