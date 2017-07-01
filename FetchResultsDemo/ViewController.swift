//
//  ViewController.swift
//  FetchResultsDemo
//
//  Created by Louis on 2017-07-01.
//  Copyright © 2017 LLSoft. All rights reserved.
//

import UIKit
import CoreData

/// We need to include NSFRCDelegate protocol
class ViewController: UIViewController, NSFetchedResultsControllerDelegate, UITableViewDelegate, UITableViewDataSource  {

	@IBOutlet weak var tableView: UITableView!

	var isFiltered = false

	var sortKey = "name"

	/// Replace the reference of NSManagedObject by the custom class if any
	lazy var fetchedResults: NSFetchedResultsController<NSManagedObject> = {

		/// Request predicate and sortDescriptors can be changed any time afterwards
		let request = NSFetchRequest<NSManagedObject>(entityName: "ContactEntity")
		request.predicate = NSPredicate(value: true)
		request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

		/// sectionNameKeyPath can NOT be modified after
		let result = NSFetchedResultsController(fetchRequest: request,
		                                        managedObjectContext: Data.moc,
		                                        sectionNameKeyPath: nil,
		                                        cacheName: nil)

		result.delegate = self

		return result
	}()


	/// We only need to perform a new fetch and reload the tableView's data when modifying the predicate or sortDescriptors.
	/// Adding, deleting and updating CoreData objects is taken care of by fetchResults and its delegate methods.
	/// If fetchedResults is set to work with a cache, we would need to delete the cache too.
	func reloadData() {

		do {
			try fetchedResults.performFetch()
		} catch  {

		}

		tableView.reloadData()
	}

	//MARK: - ACTIONS

	@IBAction func createDemoContacts( _ sender : AnyObject? ) {

		["Athur","Albert","Nathalie","Gertrude","Paul","Isabelle","Bertrand","Hermine","Arsène","Sherlock","Dupont","Smith","Catherine"].forEach { name in

			let entity = NSEntityDescription.entity(forEntityName: "ContactEntity", in: Data.moc)

			let contact = NSManagedObject(entity: entity!, insertInto: Data.moc)

			contact.setValue(name, forKey: "name")

			contact.setValue( arc4random_uniform(2), forKey: "isAppUser")
		}

	}

	@IBAction func toggleFilter( _ sender : AnyObject? ) {

		isFiltered = !isFiltered

		/// No need to perform a fetch
		fetchedResults.fetchRequest.predicate = isFiltered ?
			NSPredicate(format: "isAppUser = 1") :
			NSPredicate(value: true)

		reloadData()
	}

	@IBAction func toggleSort( _ sender : AnyObject? ) {

		sortKey = sortKey == "name" ? "isAppUser" : "name"
		fetchedResults.fetchRequest.sortDescriptors = [NSSortDescriptor.init(key: sortKey, ascending: true)]

		reloadData()
	}




	//MARK: - FETCHED RESULTS DELEGATE

	/// Arrays to accumulate all changes from our fetchedResultsController in order to process them in batch
	var insertedIndexPaths: [IndexPath]!
	var deletedIndexPaths: [IndexPath]!

	func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {

		///We accumulate insertions and deletions in order to process them all at once when we receive all changes.
		switch type {

		case .insert:
			insertedIndexPaths.append(newIndexPath!)

		case .delete:
			deletedIndexPaths.append(indexPath!)

		case .update, .move :
			tableView.reloadRows(at: [indexPath!], with: .none)
			tableView.reloadRows(at: [newIndexPath!], with: .none)
		}
	}

	func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {

		/// One or more changes will happen on the data set; we initialize array to
		/// accumulate them in order to process all the changes in batch mode.
		insertedIndexPaths = [IndexPath]()
		deletedIndexPaths = [IndexPath]()
	}

	func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {

		/// Now the fetched controller is done processing new changes,
		/// we can ask the tableView to update the display for all of them at once.

		tableView.beginUpdates()

		tableView.insertRows(at: insertedIndexPaths, with: .automatic)

		tableView.deleteRows(at: deletedIndexPaths, with: .automatic)

		tableView.endUpdates()
	}


	//MARK: - TABLEVIEW DELEGATE & DATASOURCE

	func numberOfSections(in tableView: UITableView) -> Int {

		return fetchedResults.sections!.count
	}

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

		return fetchedResults.sections![section].numberOfObjects
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

		let cell = tableView.dequeueReusableCell(withIdentifier: "contactCell", for: indexPath) as UITableViewCell

		let contact = fetchedResults.object(at: indexPath)

		cell.textLabel?.text = contact.value(forKey: "name") as? String

		if let isAppUser = contact.value(forKey: "isAppUser") as? Int, isAppUser == 1 {
			cell.detailTextLabel?.text = "Is an App User"
		} else {
			cell.detailTextLabel?.text = "Not an App User"
		}

		return cell
	}


	//MARK: - LIFE CYCLE

	override func viewDidLoad() {

		super.viewDidLoad()

		reloadData()
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}

}



