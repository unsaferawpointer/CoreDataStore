//
//  ObjectFactory.swift
//  
//
//  Created by Anton Cherkasov on 29.07.2021.
//

import Foundation
import CoreData

class ObjectFactory<T: NSManagedObject> {
	
	private var viewContext: NSManagedObjectContext
	var errorHandler: ((Error) -> ())?
	
	init(context: NSManagedObjectContext) {
		self.viewContext = context
	}
	
}

extension ObjectFactory {
	
	func save() {
		do {
			try viewContext.save()
		} catch {
			errorHandler?(error)
		}
	}
	
	@discardableResult
	func newObject() -> T {
		let newObject = T(context: viewContext)
		save()
		return newObject
	}
	
	func newObject<Value>(with value: Value, for keyPath: ReferenceWritableKeyPath<T, Value>) -> T {
		let newObject = T(context: viewContext)
		newObject[keyPath: keyPath] = value
		save()
		return newObject
	}
	
	func newObject(configurationBlock: (T) -> ()) -> T {
		let newObject = self.newObject()
		configurationBlock(newObject)
		return newObject
	}
	
	func set<Value>(value: Value, for keyPath: ReferenceWritableKeyPath<T, Value>, in object: T) {
		object[keyPath: keyPath] = value
		save()
	}
	
	func delete(object: T) {
		viewContext.delete(object)
		save()
	}
	
	// Batch operation
	
	func delete(objects: [T]) {
		objects.forEach{
			viewContext.delete($0)
		}
		save()
	}
	
	func set<Value>(value: Value, for keyPath: ReferenceWritableKeyPath<T, Value>, to objects: [T]) {
		objects.forEach {
			$0[keyPath: keyPath] = value
		}
		save()
	}
}
