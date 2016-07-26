//
//  ViewController.swift
//  drawingOnImage
//
//  Created by Chetan Ankola on 7/21/16.
//  Copyright © 2016 Chetan Ankola. All rights reserved.
//

import UIKit

extension CGSize {
    var ratio : CGFloat {
        return width / height
    }
    
}

extension UIImageView {
    var presentedRect : CGRect {
        
        guard let image = image else {
            return .zero
        }
        
        let imageSize = image.size
        let viewSize = bounds.size
        let scale = imageSize.ratio > viewSize.ratio ? viewSize.width / imageSize.width : viewSize.height / imageSize.width
        
        let presentedSize = image.size.apply(transform: CGAffineTransform(scaleX: scale, y: scale))
        let presentedSizeOrigin = CGPoint(x: (viewSize.width - presentedSize.width) / 2, y: (viewSize.height - presentedSize.height) / 2)
        return CGRect(origin: presentedSizeOrigin, size: presentedSize)
        
    }
}

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate  {

    
    //FileSystem and Store stuff
    let croppedItemStore = CroppedItemStore()
    
    
    //Draw Variables
    //Touch Point data
    var lastTouchPoint = CGPoint.zero //last drawn point on view
    var swiped = false //indicates if stroke is continuous
    var cropPointArray = [CGPoint]()
    //Drawing Params
    var brushWidth: CGFloat = 2.0
    
    
    
    //Outlets
    @IBOutlet weak var faceImageView: UIImageView!      // Has the cropped Face
    @IBOutlet weak var canvasImageView: UIImageView!    // On which you draw
    @IBOutlet weak var gifImageView: UIImageView!       // Image on which you perform crop
    @IBAction func onOpenCameraRoll(_ sender: AnyObject) {
        openCamera()
    }
    @IBAction func onSaveFace(_ sender: AnyObject) {
        croppedItemStore.saveFace(faceImage: faceImageView.image!)
        dismiss(animated: true, completion: nil)
    }
    
    func openCamera () {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .photoLibrary
            imagePicker.allowsEditing = false
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        //TODO:should we enable edited image?
        if let pickedImage = info["UIImagePickerControllerOriginalImage"] as? UIImage {
            gifImageView.image = pickedImage
        } else {
            return
        }
        dismiss(animated: true, completion: nil)
    }


    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //Automatically open camera when view Opens up
        if (gifImageView.image == nil) {
            openCamera()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        gifImageView.image = nil
        canvasImageView.image = nil
        faceImageView.image = nil
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    //drawLine(from:a,to:B)
    func drawLine(from fromPoint:CGPoint, to toPoint:CGPoint) {
        
        let canvasToDraw = canvasImageView!
        let sizeOfCanvas = view.frame.size
        //Start===============
        UIGraphicsBeginImageContext(sizeOfCanvas)
        
        let context = UIGraphicsGetCurrentContext()!
        canvasToDraw.image?.draw(in: CGRect(x: 0, y: 0, width: sizeOfCanvas.width, height: sizeOfCanvas.height))
        //set points
        context.moveTo(x: fromPoint.x, y: fromPoint.y)//go to fromPointFirst first
        context.addLineTo(x: toPoint.x, y: toPoint.y) //add line from X to Y
        
        
        //style
        context.setLineCap(.round)
        context.setLineWidth(brushWidth)
        context.setStrokeColor(UIColor.red().cgColor)
        context.setBlendMode(.darken)
        
        //draw
        context.strokePath()
        
        canvasToDraw.image = UIGraphicsGetImageFromCurrentImageContext()
        
        
        UIGraphicsEndImageContext()
        //End ========================
    }
    
    func drawCroppedFace () {
        
        let cropPath = UIBezierPath()
        cropPath.move(to: lastTouchPoint)
        cropPointArray.forEach { (point) in
            cropPath.addLine(to: point)
        }
        cropPath.close()
        let presentedSizeOrigin = gifImageView.presentedRect.origin
        let presentedSize = gifImageView.presentedRect.size
        
        let renderer = UIGraphicsImageRenderer(size: cropPath.bounds.size)
        let origin = cropPath.bounds.offsetBy(dx: -presentedSizeOrigin.x, dy: -presentedSizeOrigin.y).origin
        cropPath.apply(CGAffineTransform(translationX: -cropPath.bounds.minX, y: -cropPath.bounds.minY))
        faceImageView.contentMode = .scaleAspectFit
        faceImageView.image =  renderer.image { context in
            cropPath.addClip()
            gifImageView.image?.draw(in: CGRect(origin: CGPoint(x: -origin.x, y: -origin.y), size: presentedSize))

        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        canvasImageView.image = nil
        cropPointArray = []
        swiped = false
        if let touch = touches.first {
            lastTouchPoint = touch.location(in: gifImageView)
            cropPointArray.append(lastTouchPoint)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        swiped = true
        if let touch = touches.first {
            let currentPoint = touch.location(in:gifImageView)
            cropPointArray.append(currentPoint)
            drawLine(from: lastTouchPoint, to: currentPoint)
            
            //update last touchpoint to current point
            lastTouchPoint = currentPoint
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if !swiped {
            // draw a single point
            drawLine(from:lastTouchPoint, to: lastTouchPoint)
        }
        drawCroppedFace()
    }
}
