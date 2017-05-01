//
//  NCTypePickerTypesViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 11.01.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData

class NCTypePickerTypesViewController: UITableViewController, UISearchResultsUpdating {
	private var results: NSFetchedResultsController<NSDictionary>?
	private var searchController: UISearchController?
	private let gate = NCGate()
	var predicate: NSPredicate?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		if navigationController != nil {
			setupSearchController()
		}
		//title = category?.categoryName
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		if results == nil {
			reloadData()
		}
	}
	
	func reloadData() {
		gate.perform {
			NCDatabase.sharedDatabase?.performTaskAndWait({ (managedObjectContext) in
				let request = NSFetchRequest<NSDictionary>(entityName: "InvType")
				request.predicate = self.predicate ?? NSPredicate(value: false)
				request.sortDescriptors = [
					NSSortDescriptor(key: "metaGroup.metaGroupID", ascending: true),
					NSSortDescriptor(key: "metaLevel", ascending: true),
					NSSortDescriptor(key: "typeName", ascending: true)]
				
				let entity = managedObjectContext.persistentStoreCoordinator!.managedObjectModel.entitiesByName[request.entityName!]!
				let propertiesByName = entity.propertiesByName
				var properties = [NSPropertyDescription]()
				properties.append(propertiesByName["typeID"]!)
				properties.append(propertiesByName["typeName"]!)
				properties.append(propertiesByName["metaLevel"]!)
				properties.append(NSExpressionDescription(name: "metaGroupID", resultType: .integer32AttributeType, expression: NSExpression(forKeyPath: "metaGroup.metaGroupID")))
				properties.append(NSExpressionDescription(name: "icon", resultType: .objectIDAttributeType, expression: NSExpression(forKeyPath: "icon")))
				properties.append(NSExpressionDescription(name: "dgmppItem", resultType: .objectIDAttributeType, expression: NSExpression(forKeyPath: "dgmppItem")))
				properties.append(NSExpressionDescription(name: "metaGroupName", resultType: .stringAttributeType, expression: NSExpression(forKeyPath: "metaGroup.metaGroupName")))
				request.propertiesToFetch = properties
				request.resultType = .dictionaryResultType
				
				let results = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: "metaGroupName", cacheName: nil)
				try? results.performFetch()
				
				DispatchQueue.main.async {
					self.results = results
					self.tableView.reloadData()
					self.tableView.backgroundView = (results.fetchedObjects?.count ?? 0) == 0 ? NCTableViewBackgroundLabel(text: NSLocalizedString("No Results", comment: "")) : nil
				}
			})
		}
	}
	
	override func didReceiveMemoryWarning() {
		if !isViewLoaded || view.window == nil {
			results = nil
		}
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "NCDatabaseTypeInfoViewController" {
			let controller = segue.destination as? NCDatabaseTypeInfoViewController
			let object = (sender as! NCDefaultTableViewCell).object as! NSDictionary
			controller?.type = NCDatabase.sharedDatabase?.invTypes[object["typeID"] as! Int]
		}
	}
	
	//MARK: UITableViewDataSource
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		return results?.sections?.count ?? 0
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return results?.sections?[section].numberOfObjects ?? 0
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! NCDefaultTableViewCell
		let object = results?.object(at: indexPath)
		cell.object = object
		cell.titleLabel?.text = object?["typeName"] as? String
		let icon: NCDBEveIcon?
		
		if let objectID = object?["icon"] as? NSManagedObjectID, let img = try? NCDatabase.sharedDatabase?.viewContext.existingObject(with: objectID) as? NCDBEveIcon {
			icon = img
		}
		else {
			icon = nil
		}
		
		cell.iconView?.image = icon?.image?.image ?? NCDBEveIcon.defaultType.image?.image
		return cell
	}
	
	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return self.results?.sections?[section].name
	}
	
	//MARK: UITableViewDelegate
	
	
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		guard let typePickerController =  (presentingViewController?.navigationController as? NCTypePickerViewController) ??
			navigationController as? NCTypePickerViewController else {return}
		guard let object = results?.object(at: indexPath) else {return}
		guard let type = NCDatabase.sharedDatabase?.invTypes[object["typeID"] as! Int] else {return}
		guard let context = NCCache.sharedCache?.viewContext else {return}
		
		guard let category = typePickerController.category else {return}
		var recent: NCCacheTypePickerRecent? = context.fetch("TypePickerRecent", where: "category == %d AND subcategory == %d AND raceID == %d AND typeID == %d", category.category, category.subcategory, category.race?.raceID ?? 0, type.typeID)
		if recent == nil {
			recent = NCCacheTypePickerRecent(entity: NSEntityDescription.entity(forEntityName: "TypePickerRecent", in: context)!, insertInto: context)
			recent?.category = category.category
			recent?.subcategory = category.subcategory
			recent?.raceID = category.race?.raceID ?? 0
			recent?.typeID = type.typeID
		}
		recent?.date = Date() as NSDate
		if context.hasChanges {
			try? context.save()
		}
		typePickerController.completionHandler(typePickerController, type)
	}
	
	//MARK: UISearchResultsUpdating
	
	func updateSearchResults(for searchController: UISearchController) {
		let predicate: NSPredicate
		guard let controller = searchController.searchResultsController as? NCDatabaseTypesViewController else {return}
		if let text = searchController.searchBar.text, let other = self.predicate, text.characters.count > 0 {
			predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [other, NSPredicate(format: "typeName CONTAINS[C] %@", text)])
		}
		else {
			predicate = NSPredicate(value: false)
		}
		controller.predicate = predicate
		controller.reloadData()
	}
	
	//MARK: Private
	
	private func setupSearchController() {
		searchController = UISearchController(searchResultsController: self.storyboard?.instantiateViewController(withIdentifier: "NCDatabaseTypesViewController"))
		searchController?.searchBar.searchBarStyle = UISearchBarStyle.default
		searchController?.searchResultsUpdater = self
		searchController?.searchBar.barStyle = UIBarStyle.black
		searchController?.hidesNavigationBarDuringPresentation = false
		tableView.backgroundView = UIView()
		tableView.tableHeaderView = searchController?.searchBar
		definesPresentationContext = true
		
	}
}
