//
//  MemosTableViewController.swift
//  MyVoiceMemoX
//
//  Created by Junyuan Suo on 7/26/16.
//  Copyright © 2016 JYLock. All rights reserved.
//

import UIKit
import CoreData

// uses CoreDataTableViewController as its superclass
// so all we need to do is set the fetchedResultsController var
// and implement tableView(cellForRowAtIndexPath:)

class MemosTableViewController: CoreDataTableViewController, UISearchBarDelegate
{
    // MARK: - Properties
    var managedObjectContext: NSManagedObjectContext? =
    (UIApplication.sharedApplication().delegate as? AppDelegate)?.managedObjectContext
    
    
    // Search bar
    @IBOutlet weak var searchBar: UISearchBar!
    
    
    
    
    
    
    
    // MARK: - View Cycle Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        
    }
    
    override func viewWillAppear(animated: Bool) {
        searchBar.text = ""
        updateUI()
    }
    
    
    

    
    // MARK: - Helper functions
    private func updateUI() {
        if let context = managedObjectContext {
            let request = NSFetchRequest(entityName: "Memo")
            
            // Search logic
            if let query = searchBar.text where searchBar.text != ""  {
                
                managedObjectContext?.performBlockAndWait {
                    request.predicate = NSPredicate(format: "title CONTAINS[cd] %@", query)
                    request.sortDescriptors = [NSSortDescriptor(
                        key: "title",
                        ascending: true,
                        selector: #selector(NSString.localizedCaseInsensitiveCompare(_:))
                        )]
                }
            }
            else {
                request.sortDescriptors = [NSSortDescriptor(
                    key: "date",
                    ascending: true
                    )]
            }
            
            fetchedResultsController = NSFetchedResultsController(
                fetchRequest: request,
                managedObjectContext: context,
                sectionNameKeyPath: nil,
                cacheName: nil
            )
            
            tableView.performSelectorOnMainThread(#selector(UITableView.reloadData), withObject: nil, waitUntilDone: true)
        }
        else {
            fetchedResultsController = nil
        }
    }
    
    
    
    // MARK: - UISEARCHBar
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        updateUI()
    }
    
    
    
    // MARK: - UITableView functions
    
    // this is the only UITableViewDataSource method we have to implement
    // if we use a CoreDataTableViewController
    // the most important call is fetchedResultsController?.objectAtIndexPath(indexPath)
    // (that's how we get the object that is in this row so we can load the cell up)
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        
        if let memo = fetchedResultsController?.objectAtIndexPath(indexPath) as? Memo {
            var title: String?
            var date: NSDate?
            memo.managedObjectContext?.performBlockAndWait {
                // it's easy to forget to do this on the proper queue
                title = memo.title
                date = memo.date
                // we're not assuming the context is a main queue context
                // so we'll grab the screenName and return to the main queue
                // to do the cell.textLabel?.text setting
            }
            cell.textLabel?.text = title
            cell.detailTextLabel?.text = String(date!)
        }
        
        return cell
    }
    
    
    // Delete a memo
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        if let context = fetchedResultsController?.managedObjectContext,
            memo = fetchedResultsController?.objectAtIndexPath(indexPath) as? Memo
            where editingStyle == .Delete{
            
            // delete audio file first, then remove obj from core data
            memo.removeAudioFile()
            context.deleteObject(memo)
            
            do {
                try context.save()
            } catch let error {
                print("Core Data Error: \(error)")
            }
        }
        
    }

    
    
    // MARK: - Segue
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if segue.identifier == "displaySavedMemo"{
            
            if let ip = tableView.indexPathForSelectedRow,
                savedMemoVC = segue.destinationViewController as? SavedMemoViewController{
            
                savedMemoVC.fetchedResultsController = fetchedResultsController
                
                savedMemoVC.indexPath = ip
            }
        }
    }

    
}


