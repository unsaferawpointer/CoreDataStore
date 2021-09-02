//
//  ObjectFactory.swift
//  
//
//  Created by Anton Cherkasov on 29.07.2021.
//

import Foundation
import CoreData


public class ObjectFactory<T: NSManagedObject> {
	
	public private (set) var viewContext: NSManagedObjectContext
	var errorHandler: ((Error) -> ())?
	
	public init(viewContext context: NSManagedObjectContext) {
		self.viewContext = context
	}
	
}

extension ObjectFactory {
	
	public func save() {
		guard !viewContext.hasChanges else {
			return
		}
		do {
			try viewContext.save()
		} catch {
			DispatchQueue.main.async {
				self.errorHandler?(error)
			}
		}
		
	}
	
	/// Perform block for objects in the same context
	/// - Warning: Objects must has same NSManagedObjectContext
	private func perform<C: Sequence>(block: @escaping ((T) -> ()), for objects: C) where C.Element == T {
		for object in objects {
			block(object)
		}
		save()
	}
	
	@discardableResult
	public func newObject() -> T {
		let newObject = T(context: viewContext)
		save()
		return newObject
	}
	
	@discardableResult
	public func newObject<Value>(with value: Value, for keyPath: ReferenceWritableKeyPath<T, Value>) -> T {
		let newObject = T(context: viewContext)
		newObject[keyPath: keyPath] = value
		save()
		return newObject
	}
	
	@discardableResult
	public func newObject(configurationBlock: (T) -> ()) -> T {
		let newObject = T(context: viewContext)
		configurationBlock(newObject)
		save()
		return newObject
	}
	
	public func set<Value>(value: Value,
						   for keyPath: ReferenceWritableKeyPath<T, Value>,
						   in object: T) {
		object[keyPath: keyPath] = value
		save()
	}
	
	public func delete(object: T) {
		viewContext.delete(object)
		save()
	}
	
	// Batch operations
	
	public func delete<C: Sequence>(objects: C) where C.Element == T {
		objects.forEach{
			viewContext.delete($0)
		}
		save()
	}
	
	public func set<Value, C: Sequence>(value: Value,
										for keyPath: ReferenceWritableKeyPath<T, Value>,
										to objects: C) where C.Element == T {
		objects.forEach {
			$0[keyPath: keyPath] = value
		}
		save()
	}
}

protocol Duplicatable {
	func duplicate() -> Self
}

extension ObjectFactory where T : Duplicatable {
	
	func duplicate(object: T) -> T {
		let result = object.duplicate()
		return result
	}
	
	func duplicate<C: Sequence>(objects: C) -> [T] where C.Element == T {
		let result = objects.compactMap{ $0.duplicate() }
		return result
	}
	
}
