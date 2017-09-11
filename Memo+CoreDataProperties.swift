//
//  Memo+CoreDataProperties.swift
//  MyVoiceMemoX
//
//  Created by Junyuan Suo on 7/28/16.
//  Copyright © 2016 JYLock. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Memo {

    @NSManaged var title: String?
    @NSManaged var note: String?
    @NSManaged var date: NSDate?
    @NSManaged var audioFileName: String?

}
