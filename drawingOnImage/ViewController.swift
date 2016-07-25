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

class ViewController: UIViewController {

    @IBOutlet weak var faceImageView: UIImageView!
    @IBOutlet weak var canvasImageView: UIImageView!
    @IBOutlet weak var gifImageView: UIImageView!
    var lastTouchPoint = CGPoint.zero //last drawn point on view
    var swiped = false //indicates if stroke is continuous
    
    
    var cropPointArray = [CGPoint]()
    
    
    //draw tools
    var brushWidth: CGFloat = 2.0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
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
        
        
        
        
        
        
        let maskLayer = CAShapeLayer()
        maskLayer.frame = gifImageView.frame
        maskLayer.path = cropPath.cgPath
        
        
        //Crops the original image
//        gifImageView.layer.mask = maskLayer
    
        
          // copies the original image and tries to crop on it
//        var copiedCGImage :CGImage
//        if let image = gifImageView.image {
//            copiedCGImage = CGImage(copy:image.cgImage!)!
//            
//            
//            faceImageView.image = UIImage(cgImage: copiedCGImage, scale: gifImageView.image!.scale, orientation: gifImageView.image!.imageOrientation)
//            
//            
//            faceImageView.layer.mask = maskLayer
//        }
        
//        let copiedCGImage = CGImage(copy: (gifImageView.image?.cgImage)!)!
        
        
        
        
  
//        faceImageView.layer.mask = maskLayer
        
        
//        gifImageView.contentMode = .topLeft
        let imageSize = gifImageView.image!.size
        let viewSize = gifImageView.bounds.size
        let scale = imageSize.ratio > viewSize.ratio ? viewSize.width / imageSize.width : viewSize.height / imageSize.width
        let presentedSize = gifImageView.image!.size.apply(transform: CGAffineTransform(scaleX: scale, y: scale))
        let presentedSizeOrigin = CGPoint(x: (viewSize.width - presentedSize.width) / 2, y: (viewSize.height - presentedSize.height) / 2)
        let presentedRect = CGRect(origin: presentedSizeOrigin, size: presentedSize)
        
        
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



