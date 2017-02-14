//
//  NCFittingActionsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 10.02.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit


class NCFittingTypeRow: TreeRow {
	let type: NCDBInvType
	
	init(type: NCDBInvType, segue: String? = nil, accessoryButtonSegue: String? = nil) {
		self.type = type
		super.init(cellIdentifier: "Cell", segue: segue, accessoryButtonSegue: accessoryButtonSegue)
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCDefaultTableViewCell else {return}
		cell.object = type
		cell.titleLabel?.text = type.typeName
		cell.iconView?.image = type.icon?.image?.image ?? NCDBEveIcon.defaultType.image?.image
		cell.accessoryType = .detailButton
	}
	
	override var hashValue: Int {
		return type.hashValue
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCFittingTypeRow)?.hashValue == hashValue
	}
	
	override func changed(from: TreeNode) -> Bool {
		return false
	}
}

class NCFittingDamagePatternRow: TreeRow {
	let damagePattern: NCFittingDamage
	
	init(damagePattern: NCFittingDamage) {
		self.damagePattern = damagePattern
		super.init(cellIdentifier: "NCDamageTypeTableViewCell", segue: "NCFittingDamagePatternsViewController")
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCDamageTypeTableViewCell else {return}
		
		func fill(label: NCDamageTypeLabel, value: Double) {
			label.progress = Float(value)
			label.text = "\(Int(round(value * 100)))%"
		}
		
		fill(label: cell.emLabel, value: damagePattern.em)
		fill(label: cell.kineticLabel, value: damagePattern.kinetic)
		fill(label: cell.thermalLabel, value: damagePattern.thermal)
		fill(label: cell.explosiveLabel, value: damagePattern.explosive)
	}
	
	override var hashValue: Int {
		return damagePattern.hashValue
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCFittingDamagePatternRow)?.hashValue == hashValue
	}
	
	override func changed(from: TreeNode) -> Bool {
		return damagePattern != (from as? NCFittingDamagePatternRow)?.damagePattern
	}

}



class NCFittingActionsViewController: UITableViewController, TreeControllerDelegate {
	@IBOutlet var treeController: TreeController!
	var pilot: NCFittingCharacter?
	
	private var observer: NSObjectProtocol?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		//navigationController?.preferredContentSize = CGSize(width: view.bounds.size.width, height: 320)
		
		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		treeController.delegate = self
		
		reload()
		tableView.layoutIfNeeded()
		var size = tableView.contentSize
		size.height += tableView.contentInset.top
		size.height += tableView.contentInset.bottom
		navigationController?.preferredContentSize = size
		
		if let pilot = pilot, observer == nil {
			observer = NotificationCenter.default.addObserver(forName: .NCFittingEngineDidUpdate, object: pilot.engine, queue: nil) { [weak self] (note) in
				self?.reload()
			}
		}
		
	}
	
	//MARK: - TreeControllerDelegate
	
	func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		guard let node = node as? TreeRow else {return}
		guard let segue = node.segue else {return}
		performSegue(withIdentifier: segue, sender: treeController.cell(for: node))
	}
	
	func treeController(_ treeController: TreeController, accessoryButtonTappedWithNode node: TreeNode) {
		guard let node = node as? TreeRow else {return}
		guard let segue = node.accessoryButtonSegue else {return}
		performSegue(withIdentifier: segue, sender: treeController.cell(for: node))
	}
	
	func treeController(_ treeController: TreeController, editActionsForNode node: TreeNode) -> [UITableViewRowAction]? {
		guard node is NCFittingAreaEffectRow else {return nil}
		return [UITableViewRowAction(style: .default, title: NSLocalizedString("Delete", comment: ""), handler: {[weak self] _ in
			guard let engine = self?.pilot?.engine else {return}
			engine.perform {
				engine.area = nil
			}
		})]
	}

	
	//MARK: - Navigation
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		switch segue.identifier {
		case "NCDatabaseTypeInfoViewController"?:
			guard let controller = segue.destination as? NCDatabaseTypeInfoViewController,
				let cell = sender as? NCTableViewCell,
				let type = cell.object as? NCDBInvType else {
					return
			}
			controller.type = type
		case "NCFittingAreaEffectsViewController"?:
			guard let controller = segue.destination as? NCFittingAreaEffectsViewController else {return}
			controller.completionHandler = { [weak self, weak controller] type in
				let typeID = Int(type.typeID)
				controller?.dismiss(animated: true) {
					self?.pilot?.engine?.perform {
						self?.pilot?.engine?.area = NCFittingArea(typeID: typeID)
					}
				}
			}
		default:
			break
		}
	}

	
	//MARK: - Private
	
	private func reload() {
		guard let pilot = pilot else {return}
		guard let engine = pilot.engine else {return}
		
		var sections = [TreeNode]()

		let invTypes = NCDatabase.sharedDatabase?.invTypes

		engine.performBlockAndWait {
			if let ship = pilot.ship, let type = invTypes?[ship.typeID] {
				let row = NCFittingTypeRow(type: type, segue: "NCDatabaseTypeInfoViewController", accessoryButtonSegue: "NCDatabaseTypeInfoViewController")
				sections.append(DefaultTreeSection(cellIdentifier: "NCHeaderTableViewCell", nodeIdentifier: "Ship", title: NSLocalizedString("Ship", comment: "").uppercased(), children: [row]))
			}
			
			sections.append(DefaultTreeSection(cellIdentifier: "NCHeaderTableViewCell", nodeIdentifier: "Character", title: NSLocalizedString("Character", comment: "").uppercased(), children: [NCFittingCharactersRow(pilot: pilot)]))

			
			if let area = engine.area, let type = invTypes?[area.typeID] {
				let row = NCFittingAreaEffectRow(objectID: type.objectID)
				row.segue = "NCFittingAreaEffectsViewController"
				sections.append(DefaultTreeSection(cellIdentifier: "NCHeaderTableViewCell", nodeIdentifier: "Area", title: NSLocalizedString("Area Effects", comment: "").uppercased(), children: [row]))
			}
			else {
				let row = NCActionRow(cellIdentifier: "Cell", title: NSLocalizedString("Select Area Effects", comment: ""),  segue: "NCFittingAreaEffectsViewController")
				sections.append(DefaultTreeSection(cellIdentifier: "NCHeaderTableViewCell", nodeIdentifier: "Area", title: NSLocalizedString("Area Effects", comment: "").uppercased(), children: [row]))
			}
			
			let damagePattern = pilot.ship?.damagePattern ?? .omni
			sections.append(DefaultTreeSection(cellIdentifier: "NCHeaderTableViewCell", nodeIdentifier: "DamagePattern", title: NSLocalizedString("Damage Pattern", comment: "").uppercased(), children: [NCFittingDamagePatternRow(damagePattern: damagePattern)]))
		}
		
		if treeController.rootNode == nil {
			let root = TreeNode()
			root.children = sections
			treeController.rootNode = root
		}
		else {
			treeController.rootNode?.children = sections
		}

	}
}
