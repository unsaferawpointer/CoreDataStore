//
//  File.swift
//  
//
//  Created by Anton Cherkasov on 11.10.2021.
//

import Foundation
import CoreData

private class AnyStoreBox<T>: StoreDataSource {
	var objects: [T] = []
	
	var numberOfObjects: Int = 0
	
	func performFetch(with predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]) throws {
		fatalError("It is abstract class")
	}
}

private class StoreBox<Base: StoreDataSource>: AnyStoreBox<Base.T> {
	private let base: Base
	init(_ base: Base) {
		self.base = base
	}
}

public struct AnyStore<T> : StoreDataSource {
	
	private let box: AnyStoreBox<T>
	init<StoreType: StoreDataSource>(_ store: StoreType) where StoreType.T == T {
		box = StoreBox(store)
	}
	
	public var objects: [T] {
		return box.objects
	}
	
	public var numberOfObjects: Int {
		return box.numberOfObjects
	}
	
	public func performFetch(with predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]) throws {
		try box.performFetch(with: predicate, sortDescriptors: sortDescriptors)
	}
	
}
