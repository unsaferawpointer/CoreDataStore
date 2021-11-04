//
//  File.swift
//  
//
//  Created by Anton Cherkasov on 14.10.2021.
//

import Foundation
import CoreData

private class AnyFactoryBox<T: NSManagedObject>: ObjectFactoryProtocol {
	func newObject() -> T {
		fatalError("It is abstract class")
	}
	
	func newObject<Value>(with value: Value, for keyPath: ReferenceWritableKeyPath<T, Value>) -> T {
		fatalError("It is abstract class")
	}
	
	func newObject(configurationBlock: (T) -> ()) -> T {
		fatalError("It is abstract class")
	}
	
	func set<Value>(value: Value, for keyPath: ReferenceWritableKeyPath<T, Value>, in object: T) {
		fatalError("It is abstract class")
	}
	
	func delete(object: T) {
		fatalError("It is abstract class")
	}
	
	func delete<C>(objects: C) where C : Sequence, T == C.Element {
		fatalError("It is abstract class")
	}
	
	func set<Value, C>(value: Value, for keyPath: ReferenceWritableKeyPath<T, Value>, to objects: C) where C : Sequence, T == C.Element {
		fatalError("It is abstract class")
	}
	
	func perform<C>(block: @escaping ((T) -> ()), for objects: C) where C : Sequence, T == C.Element {
		fatalError("It is abstract class")
	}
}

private class FactoryBox<Base: ObjectFactoryProtocol>: AnyFactoryBox<Base.T> {
	private var base: Base
	init(_ base: Base) {
		self.base = base
		
	}
}

public final class AnyFactory<T: NSManagedObject> : ObjectFactoryProtocol {
	private let box: AnyFactoryBox<T>
	init<FactoryType: ObjectFactoryProtocol>(_ factory: FactoryType) where FactoryType.T == T {
		self.box = FactoryBox(factory)
	}
	
	public func newObject() -> T {
		return box.newObject()
	}
	
	public func newObject<Value>(with value: Value, for keyPath: ReferenceWritableKeyPath<T, Value>) -> T {
		return box.newObject(with: value, for: keyPath)
	}
	
	public func newObject(configurationBlock block: (T) -> ()) -> T {
		return box.newObject(configurationBlock: block)
	}
	
	public func set<Value>(value: Value, for keyPath: ReferenceWritableKeyPath<T, Value>, in object: T) {
		box.set(value: value, for: keyPath, in: object)
	}
	
	public func delete(object: T) {
		box.delete(object: object)
	}
	
	public func delete<C>(objects: C) where C : Sequence, T == C.Element {
		box.delete(objects: objects)
	}
	
	public func set<Value, C>(value: Value, for keyPath: ReferenceWritableKeyPath<T, Value>, to objects: C) where C : Sequence, T == C.Element {
		box.set(value: value, for: keyPath, to: objects)
	}
	
	public func perform<C>(block: @escaping ((T) -> ()), for objects: C) where C : Sequence, T == C.Element {
		box.perform(block: block, for: objects)
	}
}
