//
//  File.swift
//  
//
//  Created by Anton Cherkasov on 03.07.2021.
//

import Foundation
import CoreData

public class CountManager<T: NSManagedObject>: NSObject, NSFetchedResultsControllerDelegate {
	
	private var fetchedResultController: NSFetchedResultsController<T>
	private var viewContext: NSManagedObjectContext
	
	public init(viewContext: NSManagedObjectContext, sortBy sortDescriptors: [NSSortDescriptor]) {
		self.viewContext = viewContext
		let fetchRequest: NSFetchRequest<T> = NSFetchRequest<T>.init(entityName: T.className())
		fetchRequest.resultType = .countResultType
		fetchRequest.sortDescriptors = sortDescriptors
		
		self.fetchedResultController = NSFetchedResultsController.init(fetchRequest: fetchRequest, managedObjectContext: viewContext, sectionNameKeyPath: nil, cacheName: nil)
		
		super.init()
		
		self.fetchedResultController.delegate = self
	}
	
	public func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		
		print(#function)
	}
	
	//	public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
	//		switch type {
	//		case .insert:
	//			delegate?.storeDidInsert(section: sectionInfo, at: sectionIndex)
	//		case .delete:
	//			delegate?.storeDidDelete(section: sectionInfo, at: sectionIndex)
	//		default:
	//			fatalError("other types are not supported ")
	//		}
	//	}
	
	//#if os(macOS)
	public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
		print(#function)
		print("oldPath = \(indexPath) newPath = \(newIndexPath)")
		guard let object = anObject as? T else {
			fatalError("\(anObject) is not \(T.className())")
		}
//		switch type {
//		case .insert:
//			if let newIndex = newIndexPath?.item {
//				delegate?.storeInsert(object: object, at: newIndex)
//			}
//		case .delete:
//			if let oldIndex = indexPath?.item {
//				delegate?.storeDelete(object: object, at: oldIndex)
//			}
//		case .move:
//			if let oldIndex = indexPath?.item, let newIndex = newIndexPath?.item {
//				delegate?.storeMove(object: object, from: oldIndex, to: newIndex)
//			}
//		case .update:
//			if let oldIndex = indexPath?.item {
//				delegate?.storeUpdate(object: object, at: oldIndex)
//			}
//		@unknown default:
//			fatalError()
//		}
	}
	//#endif
	
	public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		
		print(#function)
	}
	
}


