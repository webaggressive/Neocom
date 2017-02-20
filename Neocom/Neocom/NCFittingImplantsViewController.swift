//
//  NCFittingImplantsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 09.02.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

class NCImplantRow: TreeRow {
	lazy var type: NCDBInvType? = {
		guard let implant = self.implant else {return nil}
		return NCDatabase.sharedDatabase?.invTypes[implant.typeID]
	}()

	
	let implant: NCFittingImplant?
	let slot: Int?
	init(implant: NCFittingImplant) {
		self.implant = implant
		self.slot = nil
		super.init(cellIdentifier: "NCDefaultTableViewCell")
	}
	
	init(dummySlot: Int) {
		self.implant = nil
		self.slot = dummySlot
		super.init(cellIdentifier: "NCDefaultTableViewCell")
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCDefaultTableViewCell else {return}
		if let type = type {
			cell.titleLabel?.text = type.typeName
			cell.iconView?.image = type.icon?.image?.image ?? NCDBEveIcon.defaultType.image?.image
			cell.accessoryType = .detailButton
		}
		else {
			cell.titleLabel?.text = NSLocalizedString("Slot", comment: "") + " \(slot ?? 0)"
			cell.iconView?.image = #imageLiteral(resourceName: "implant")
			cell.accessoryType = .none
		}
	}
	
	override var hashValue: Int {
		return implant?.hashValue ?? slot ?? 0
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCImplantRow)?.hashValue == hashValue
	}
	
}

class NCBoosterRow: TreeRow {
	lazy var type: NCDBInvType? = {
		guard let booster = self.booster else {return nil}
		return NCDatabase.sharedDatabase?.invTypes[booster.typeID]
	}()

	let booster: NCFittingBooster?
	let slot: Int?
	init(booster: NCFittingBooster) {
		self.booster = booster
		self.slot = nil
		super.init(cellIdentifier: "NCDefaultTableViewCell")
	}
	
	init(dummySlot: Int) {
		self.booster = nil
		self.slot = dummySlot
		super.init(cellIdentifier: "NCDefaultTableViewCell")
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCDefaultTableViewCell else {return}
		if let type = type {
			cell.titleLabel?.text = type.typeName
			cell.iconView?.image = type.icon?.image?.image ?? NCDBEveIcon.defaultType.image?.image
			cell.accessoryType = .detailButton
		}
		else {
			cell.titleLabel?.text = NSLocalizedString("Slot", comment: "") + " \(slot ?? 0)"
			cell.iconView?.image = #imageLiteral(resourceName: "booster")
			cell.accessoryType = .none
		}
	}
	
	override var hashValue: Int {
		return booster?.hashValue ?? slot ?? 0
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCBoosterRow)?.hashValue == hashValue
	}
	
}


class NCFittingImplantsViewController: UITableViewController, TreeControllerDelegate {
	@IBOutlet weak var treeController: TreeController!
	
	var engine: NCFittingEngine? {
		return (parent as? NCShipFittingViewController)?.engine
	}
	
	var fleet: NCFittingFleet? {
		return (parent as? NCShipFittingViewController)?.fleet
	}
	
	var typePickerViewController: NCTypePickerViewController? {
		return (parent as? NCShipFittingViewController)?.typePickerViewController
	}

	
	private var observer: NSObjectProtocol?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		treeController.delegate = self
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		if self.treeController.rootNode == nil {
			reload()
		}
		
		if observer == nil {
			observer = NotificationCenter.default.addObserver(forName: .NCFittingEngineDidUpdate, object: engine, queue: nil) { [weak self] (note) in
				self?.reload()
			}
		}
	}
	
	//MARK: - TreeControllerDelegate
	
	func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		if let item = node as? NCImplantRow {
			if let slot = item.slot {
				guard let pilot = fleet?.active else {return}
				guard let typePickerViewController = typePickerViewController else {return}
				let category = NCDBDgmppItemCategory.category(categoryID: .implant, subcategory: slot)
				
				typePickerViewController.category = category
				typePickerViewController.completionHandler = { [weak typePickerViewController] type in
					let typeID = Int(type.typeID)
					self.engine?.perform {
						pilot.addImplant(typeID: typeID)
					}
					typePickerViewController?.dismiss(animated: true)
				}
				present(typePickerViewController, animated: true)
			}
		}
		else if let item = node as? NCBoosterRow {
			if let slot = item.slot {
				guard let pilot = fleet?.active else {return}
				guard let typePickerViewController = typePickerViewController else {return}
				let category = NCDBDgmppItemCategory.category(categoryID: .booster, subcategory: slot)
				
				typePickerViewController.category = category
				typePickerViewController.completionHandler = { [weak typePickerViewController] type in
					let typeID = Int(type.typeID)
					self.engine?.perform {
						pilot.addBooster(typeID: typeID)
					}
					typePickerViewController?.dismiss(animated: true)
				}
				present(typePickerViewController, animated: true)
			}
		}
	}
	
	//MARK: - Private
	
	private func reload() {
		engine?.perform {
			guard let pilot = self.fleet?.active else {return}
			var sections = [TreeNode]()
			
			var implants = (0...9).map({NCImplantRow(dummySlot: $0 + 1)})
			
			for implant in pilot.implants.all {
				guard (1...10).contains(implant.slot) else {continue}
				implants[implant.slot - 1] = NCImplantRow(implant: implant)
			}

			var boosters = (0...3).map({NCBoosterRow(dummySlot: $0 + 1)})
			
			for booster in pilot.boosters.all {
				guard (1...4).contains(booster.slot) else {continue}
				boosters[booster.slot - 1] = NCBoosterRow(booster: booster)
			}

			sections.append(DefaultTreeSection(cellIdentifier: "NCHeaderTableViewCell", nodeIdentifier: "Implants", title: NSLocalizedString("Implants", comment: "").uppercased(), children: implants))
			sections.append(DefaultTreeSection(cellIdentifier: "NCHeaderTableViewCell", nodeIdentifier: "Boosters", title: NSLocalizedString("Boosters", comment: "").uppercased(), children: boosters))
			
			DispatchQueue.main.async {
				if self.treeController.rootNode == nil {
					self.treeController.rootNode = TreeNode()
				}
				self.treeController.rootNode?.children = sections
			}
		}
	}
}