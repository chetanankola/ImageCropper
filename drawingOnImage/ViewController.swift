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

    @IBOutlet weak var faceImageView: UIImageView!
    @IBOutlet weak var canvasImageView: UIImageView!
    @IBOutlet weak var gifImageView: UIImageView!
    
    
    
    let fileManager = FileManager.default
    var directoryURL : URL {
        do {
            return try fileManager.urlForDirectory(.documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("FaceCrop", isDirectory: true)
        } catch {
            fatalError("unable to set faces directory url")
        }
    }
    
    func initFaceCropDirectory() {
        do {
            if !fileManager.fileExists(atPath: directoryURL.absoluteString!) {
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
            }
        } catch {
            print(error)
            fatalError("failed to create stickers directory")
        }
    }
    
    
    @IBAction func onOpenCameraRoll(_ sender: AnyObject) {
        openCamera()

    }
    @IBAction func onSaveFace(_ sender: AnyObject) {
        saveFace()
    }
    
    
    
    func saveFace () {
        let fileName = "\(UUID().uuidString).jpg"
        guard let fileURL = try? directoryURL.appendingPathComponent(fileName) else {
            fatalError("Unable to create sticker URL")
        }
        
        var data: Data!
        
        do {
            data = UIImagePNGRepresentation(faceImageView.image!)
            try data.write(to: fileURL, options: .atomicWrite)
            print("successfully created")
        } catch {
            print("failed to save face to disk : \(error)")
        }
        
        
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
        if let pickedImage = info["UIImagePickerControllerOriginalImage"] as? UIImage {
            gifImageView.image = pickedImage
        } else {
            return
        }
        
        dismiss(animated: true, completion: nil)
    }

    
    //Touch Point data
    var lastTouchPoint = CGPoint.zero //last drawn point on view
    var swiped = false //indicates if stroke is continuous
    var cropPointArray = [CGPoint]()
    
    //Drawing Params
    var brushWidth: CGFloat = 2.0
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initFaceCropDirectory()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //only first time
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
