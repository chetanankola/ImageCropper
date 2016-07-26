//
//  MainViewController.swift
//  drawingOnImage
//
//  Created by Chetan Ankola on 7/25/16.
//  Copyright © 2016 Chetan Ankola. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {

    @IBOutlet weak var image1: UIImageView!
    @IBOutlet weak var image2: UIImageView!

    let croppedItemStore = CroppedItemStore()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
    
        croppedItemStore.fetchItems().forEach { (image) in
            image2.image = image
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
