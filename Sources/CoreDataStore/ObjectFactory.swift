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
	
	public init(context: NSManagedObjectContext) {
		self.viewContext = context
	}
	
}

extension ObjectFactory {
	
	public func save() {
		do {
			try viewContext.save()
		} catch {
			errorHandler?(error)
		}
	}
	
	public func updateRelations(of object: T) {
		
		var objectsIDs : Set<NSManagedObjectID> = []
		
		let toOneRelationshipKeys = object.toOneRelationshipKeys
		let toManyRelationshipKeys = object.toManyRelationshipKeys
		
		for key in toOneRelationshipKeys {
			let relationshipObjectIDs = object.objectIDs(forRelationshipNamed: key)
			for objectID in relationshipObjectIDs {
				objectsIDs.insert(objectID)
			}
		}
		
		for key in toManyRelationshipKeys {
			let relationshipObjectIDs = object.objectIDs(forRelationshipNamed: key)
			for objectID in relationshipObjectIDs {
				objectsIDs.insert(objectID)
			}
		}
	}
	
	@discardableResult
	public func newObject() -> T {
		let newObject = T(context: viewContext)
		save()
		return newObject
	}
	
	public func newObject<Value>(with value: Value, for keyPath: ReferenceWritableKeyPath<T, Value>) -> T {
		let newObject = T(context: viewContext)
		newObject[keyPath: keyPath] = value
		save()
		return newObject
	}
	
	public func newObject(configurationBlock: (T) -> ()) -> T {
		let newObject = self.newObject()
		configurationBlock(newObject)
		return newObject
	}
	
	public func set<Value>(value: Value,
						   for keyPath: ReferenceWritableKeyPath<T, Value>,
						   in object: T,
						   updateRelationships: Bool = false) {
		object[keyPath: keyPath] = value
		updateRelations(of: object)
		save()
	}
	
	public func delete(object: T) {
		viewContext.delete(object)
		save()
	}
	
	// Batch operation
	
	public func delete(objects: [T]) {
		objects.forEach{
			viewContext.delete($0)
		}
		save()
	}
	
	public func set<Value>(value: Value, for keyPath: ReferenceWritableKeyPath<T, Value>, to objects: [T]) {
		objects.forEach {
			$0[keyPath: keyPath] = value
		}
		save()
	}
}

//protocol Duplicable {
//	associatedtype Element: NSManagedObject
//	func duplicate() -> NSManagedObject
//}
//
//extension ObjectFactory {
//	func duplicate<T: Duplicable>(object: T) -> T {
//		return object.duplicate()
//	}
//}
