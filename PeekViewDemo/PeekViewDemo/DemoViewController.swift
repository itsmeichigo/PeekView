//
//  DemoViewController.swift
//  PeekViewDemo
//
//  Created by Huong Do on 2/11/16.
//  Copyright © 2016 Huong Do. All rights reserved.
//

import UIKit

class DemoViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UIViewControllerPreviewingDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    let imageNames = ["iphone", "ipad", "watch", "macbook", "appletv"]
    let showDetailSegue = "showDetail"
    var forceTouchAvailable = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 9.0, *) {
            if traitCollection.forceTouchCapability == .Available {
                forceTouchAvailable = true
                registerForPreviewingWithDelegate(self, sourceView: view)
            } else {
                forceTouchAvailable = false
            }
        } else {
            forceTouchAvailable = false
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == showDetailSegue && sender is UICollectionViewCell {
            if let indexPath = collectionView.indexPathForCell(sender as! UICollectionViewCell) {
                let imageName = imageNames[indexPath.item]
                let controller = segue.destinationViewController as! DetailViewController
                controller.imageName = imageName
            }
        }
    }
    
    // MARK - UIViewControllerPreviewingDelegate
    func previewingContext(previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard #available(iOS 9.0, *) else {
            return nil
        }
        
        let indexPath = collectionView.indexPathForItemAtPoint(collectionView.convertPoint(location, fromView:view))
        if let indexPath = indexPath {
            let imageName = imageNames[indexPath.item]
            if let cell = collectionView.cellForItemAtIndexPath(indexPath) {
                previewingContext.sourceRect = cell.frame
                
                let controller = storyboard?.instantiateViewControllerWithIdentifier("miniDetailController") as! DetailViewController
                controller.imageName = imageName
                return controller
            }
        }
        
        return nil
    }
    
    func previewingContext(previewingContext: UIViewControllerPreviewing, commitViewController viewControllerToCommit: UIViewController) {
        
        let controller = storyboard?.instantiateViewControllerWithIdentifier("detailController") as! DetailViewController
        controller.imageName = (viewControllerToCommit as! DetailViewController).imageName
        
        navigationController?.pushViewController(controller, animated: true)
    }
    
    // MARK - UICollectionViewDatasource
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageNames.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cellIdentifier = "photoCell"
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(cellIdentifier, forIndexPath: indexPath)
        
        let imageView = cell.viewWithTag(1) as! UIImageView
        let imageName = imageNames[indexPath.item]
        imageView.image = UIImage(named: imageName)
        
        return cell
    }
    
    // MARK - UICollectionViewDelegate
    func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        if forceTouchAvailable == false {
            let gesture = UILongPressGestureRecognizer(target: self, action: "longPressCell:")
            gesture.minimumPressDuration = 0.5
            cell.addGestureRecognizer(gesture)
        }
    }
    
    func longPressCell(gestureRecognizer: UILongPressGestureRecognizer) {
        
        if let cell = gestureRecognizer.view as? UICollectionViewCell, indexPath = collectionView.indexPathForCell(cell) {
            let imageName = imageNames[indexPath.item]
            let controller = storyboard?.instantiateViewControllerWithIdentifier("miniDetailController") as! DetailViewController
            controller.imageName = imageName
            
            // you can set different frame for each peek view here
            let frame = CGRect(x: 15, y: (screenHeight - 300)/2, width: screenWidth - 30, height: 300)
            PeekView.viewForController(parentViewController: self, contentViewController: controller, expectedContentViewFrame: frame, fromGesture: gestureRecognizer, shouldHideStatusBar: true, withOptions: ["Option 1": .Destructive, "Option 2": .Default, "Option 3": .Selected], completionHandler: { optionIndex in
                    switch optionIndex {
                    case 0:
                        print("Option 1 selected")
                    case 1:
                        print("Option 2 selected")
                    case 2:
                        print("Option 3 selected")
                    default:
                        break
                    }
                })
        }
    }
}


