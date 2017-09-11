//
//  Memo.swift
//  MyVoiceMemoX
//
//  Created by Junyuan Suo on 7/28/16.
//  Copyright © 2016 JYLock. All rights reserved.
//

import Foundation
import CoreData


class Memo: NSManagedObject {

    // Insert code here to add functionality to your managed object subclass
    convenience init(title: String = "New Memo", note: String = "", audioFileName: String = "", context: NSManagedObjectContext) {
        
        // An EntityDescription is an object that has access to all
        // the information you provided in the Entity part of the model
        // you need it to create an instance of this class.
        if let ent = NSEntityDescription.entityForName("Memo", inManagedObjectContext: context){
            self.init(entity: ent, insertIntoManagedObjectContext: context)
            self.title = title
            self.note = note
            self.date = NSDate()
            self.audioFileName = audioFileName
        }else{
            fatalError("Unable to find Entity name!")
        }
        
        
    }
    
    // Delete and remove audio file ref in document directory
    func removeAudioFile() {
        let fileManager = NSFileManager.defaultManager()
        let nsDocumentDirectory = NSSearchPathDirectory.DocumentDirectory
        let nsUserDomainMask = NSSearchPathDomainMask.UserDomainMask
        let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
        guard let dirPath = paths.first else {
            return
        }
        let filePath = "\(dirPath)/\(self.audioFileName!)"
        do {
            try fileManager.removeItemAtPath(filePath)
            print("--- deletion successful ---")
        } catch let error as NSError {
            print(error.debugDescription)
        }
    }

}
