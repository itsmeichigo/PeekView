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
        forceTouchAvailable = false
    }
    
//    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
//        super.traitCollectionDidChange(previousTraitCollection)
//        if #available(iOS 9.0, *) {
//            if traitCollection.forceTouchCapability == .available {
//                forceTouchAvailable = true
//                registerForPreviewing(with: self, sourceView: view)
//            } else {
//                forceTouchAvailable = false
//            }
//        } else {
//            forceTouchAvailable = false
//        }
//    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showDetailSegue && sender is UICollectionViewCell {
            if let indexPath = collectionView.indexPath(for: sender as! UICollectionViewCell) {
                let imageName = imageNames[(indexPath as NSIndexPath).item]
                let controller = segue.destination as! DetailViewController
                controller.imageName = imageName
            }
        }
    }
    
    // MARK - UIViewControllerPreviewingDelegate
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard #available(iOS 9.0, *) else {
            return nil
        }
        
        let indexPath = collectionView.indexPathForItem(at: collectionView.convert(location, from:view))
        if let indexPath = indexPath {
            let imageName = imageNames[(indexPath as NSIndexPath).item]
            if let cell = collectionView.cellForItem(at: indexPath) {
                previewingContext.sourceRect = cell.frame
                
                let controller = storyboard?.instantiateViewController(withIdentifier: "miniDetailController") as! DetailViewController
                controller.imageName = imageName
                return controller
            }
        }
        
        return nil
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        
        let controller = storyboard?.instantiateViewController(withIdentifier: "detailController") as! DetailViewController
        controller.imageName = (viewControllerToCommit as! DetailViewController).imageName
        
        navigationController?.pushViewController(controller, animated: true)
    }
    
    // MARK - UICollectionViewDatasource
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageNames.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cellIdentifier = "photoCell"
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath)
        
        let imageView = cell.viewWithTag(1) as! UIImageView
        let imageName = imageNames[(indexPath as NSIndexPath).item]
        imageView.image = UIImage(named: imageName)
        
        return cell
    }
    
    // MARK - UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if forceTouchAvailable == false {
            let gesture = UILongPressGestureRecognizer(target: self, action: #selector(DemoViewController.longPressCell(_:)))
            gesture.minimumPressDuration = 0.5
            cell.addGestureRecognizer(gesture)
        }
    }
    
    @objc func longPressCell(_ gestureRecognizer: UILongPressGestureRecognizer) {
        
        if let cell = gestureRecognizer.view as? UICollectionViewCell, let indexPath = collectionView.indexPath(for: cell) {
            let imageName = imageNames[(indexPath as NSIndexPath).item]
            let controller = storyboard?.instantiateViewController(withIdentifier: "miniDetailController") as! DetailViewController
            controller.imageName = imageName
            
            // you can set different frame for each peek view here
            let frame = CGRect(x: 15, y: (screenHeight - 300)/2, width: screenWidth - 30, height: 300)
            
            let options = [
                PeekViewAction(title: "Option 1", style: .destructive),
                PeekViewAction(title: "Option 2", style: .default),
                PeekViewAction(title: "Option 3", style: .selected) ]
            PeekView().viewForController(parentViewController: self, contentViewController: controller, expectedContentViewFrame: frame, fromGesture: gestureRecognizer, shouldHideStatusBar: true, menuOptions: options, completionHandler: { optionIndex in
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
            }, dismissHandler: {
                print("Peekview dismissed!")
            })
        }
    }
}


