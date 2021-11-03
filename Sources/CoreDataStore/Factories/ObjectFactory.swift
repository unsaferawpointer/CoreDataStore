//
//  ObjectFactory.swift
//  
//
//  Created by Anton Cherkasov on 29.07.2021.
//

import Foundation
import CoreData

public protocol Duplicatable {
	func duplicate() -> Self
}

public protocol ObjectFactoryProtocol: AnyObject {
	
	associatedtype T: NSManagedObject
	
	func newObject() -> T
	
	func newObject<Value>(with value: Value, for keyPath: ReferenceWritableKeyPath<T, Value>) -> T
	
	func newObject(configurationBlock: (T) -> ()) -> T
	
	func set<Value>(value: Value,
						   for keyPath: ReferenceWritableKeyPath<T, Value>,
						   in object: T)
	
	func delete(object: T)
	
	func delete<C: Sequence>(objects: C) where C.Element == T
	
	func set<Value, C: Sequence>(value: Value,
								 for keyPath: ReferenceWritableKeyPath<T, Value>,
								 to objects: C) where C.Element == T
	
	func update<C: Sequence>(block: @escaping ((T) -> ()), for objects: C) where C.Element == T
	
}

public final class ObjectFactory<T: NSManagedObject> {
	
	public private (set) var viewContext: NSManagedObjectContext
	public var errorHandler: ((Error) -> ())?
	
	public init(viewContext context: NSManagedObjectContext) {
		self.viewContext = context
	}
	
	public func save() {
		guard viewContext.hasChanges else {
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
	
}

extension ObjectFactory : ObjectFactoryProtocol {
	
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
	
	/// Perform block for objects in the same context
	/// - Warning: Objects must has same NSManagedObjectContext
	public func update<C: Sequence>(block: @escaping ((T) -> ()), for objects: C) where C.Element == T {
		for object in objects {
			block(object)
		}
		save()
	}
	
}

//extension ObjectFactory {
//	func performBatchInsert<C: Sequence>(objects: C) where C.Element == T {
//		let dictionaries = objects.map{ $0.dictionaryWithValues(forKeys: T.attributeKeys()) }
//		let request = NSBatchInsertRequest(entityName: T.className(), objects: dictionaries)
//		let result = try? viewContext.execute(request) as? NSBatchInsertResult
//	}
//

extension ObjectFactory {
	public func deleteObjects<C: Sequence>(withIDs objectIDs: C) where C.Element == NSManagedObjectID {
		objectIDs.compactMap { objectID in
			viewContext.object(with: objectID) as? T
		}.forEach { object in
			viewContext.delete(object)
		}
		save()
	}
}

extension ObjectFactory where T: Duplicatable {
	
	@discardableResult
	public func duplicate(object: T) -> T {
		let result = object.duplicate()
		save()
		return result
	}
	
	@discardableResult
	public func duplicate<C: Sequence>(objects: C) -> [T] where C.Element == T {
		let result = objects.compactMap{ $0.duplicate() }
		save()
		return result
	}
}
