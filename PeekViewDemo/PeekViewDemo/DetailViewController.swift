//
//  DetailViewController.swift
//  QuickActionViewDemo
//
//  Created by Huong Do on 2/9/16.
//  Copyright © 2016 Huong Do. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {

    var imageName: String!
    
    @IBOutlet weak var detailImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Details"
        detailImageView.image = UIImage(named: imageName)
        titleLabel.text = imageName

    }
    
    @available(iOS 9.0, *)
    override func previewActionItems() -> [UIPreviewActionItem] {
        let dummyAction = UIPreviewAction(title: "3D Touch is Awesome!", style: .Default, handler: { action, previewViewController in
            print("Action selected!")
        })
        
        return [dummyAction]
    }
}
