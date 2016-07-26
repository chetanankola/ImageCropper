//
//  CroppedItemStore.swift
//  drawingOnImage
//
//  Created by Chetan Ankola on 7/25/16.
//  Copyright © 2016 Chetan Ankola. All rights reserved.
//

import Foundation
import UIKit


class CroppedItemStore {
    
    var items: [UIImage]
    let fileManager = FileManager.default
    var directoryURL : URL {
        do {
            return try fileManager.urlForDirectory(.documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("FaceCrop", isDirectory: true)
        } catch {
            fatalError("unable to set faces directory url")
        }
    }
    
    init () {
        items = []
        initFaceCropDirectory()
    }
    
    private func initFaceCropDirectory() {
        do {
            if !fileManager.fileExists(atPath: directoryURL.absoluteString!) {
                try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
            }
        } catch {
            print(error)
            fatalError("failed to create stickers directory")
        }
    }
    
    func saveFace (faceImage: UIImage) {
        let fileName = "\(UUID().uuidString).jpg"
        guard let fileURL = try? directoryURL.appendingPathComponent(fileName) else {
            fatalError("Unable to create sticker URL")
        }
        
        var data: Data!
        
        do {
            data = UIImagePNGRepresentation(faceImage)
            try data.write(to: fileURL, options: .atomicWrite)
            print("successfully created")
        } catch {
            print("failed to save face to disk : \(error)")
        }
    }

    
    func fetchItems() -> [UIImage] {
        let urls = fetchFileUrls()
        var imageArray:[UIImage] = []
        
        urls.forEach { (url) in
            if let imageData = try? Data(contentsOf: url) {
                imageArray.append(UIImage(data: imageData)!)
            }
            
            
            
        }

        return imageArray
    }
    
    func fetchFileUrls() -> [URL] {
        do {
            return try fileManager.contentsOfDirectory(
                at: directoryURL,
                includingPropertiesForKeys: [URLResourceKey.contentModificationDateKey.rawValue],
                options: [
                    .skipsHiddenFiles,
                    .skipsSubdirectoryDescendants
                ]).sorted(isOrderedBefore: { (a, b) in
                    let aTime = try? a.resourceValues(forKeys: [URLResourceKey.contentModificationDateKey]).contentModificationDate?.timeIntervalSinceReferenceDate ?? 0
                    let bTime = try? b.resourceValues(forKeys: [URLResourceKey.contentModificationDateKey]).contentModificationDate?.timeIntervalSinceReferenceDate ?? 0
                    return aTime > bTime
                })
        } catch {
            fatalError("failed to read stickers directory")
        }

    }
    
}
