//
//  PeekView.swift
//  PeekViewDemo
//
//  Created by Huong Do on 2/11/16.
//  Copyright © 2016 Huong Do. All rights reserved.
//

import UIKit

let screenWidth = UIScreen.mainScreen().bounds.size.width
let screenHeight = UIScreen.mainScreen().bounds.size.height
let peekViewTag = 1929
let tickImageViewTag = 1930
let buttonVerticalPadding = CGFloat(15)

@objc public enum PeekViewActionStyle : Int {
    case Default
    case Selected
    case Destructive
}

public struct PeekViewAction {
    var title: String
    var style: PeekViewActionStyle
    
    public init(title: String, style: PeekViewActionStyle){
        self.title = title
        self.style = style
    }
}

@objc public class PeekView: UIView {
    
    var shouldToggleHidingStatusBar = false
    var contentView: UIView?
    var buttonHolderView: UIView?
    var completionHandler: (Int -> Void)?
    
    var arrowImageView: UIImageView?
    
    /**
     *  Helper class function to support objective-c projects
     *  Since struct cannot be bridged to obj-c, user can input an NSArray of NSDictionary objects,
     *  whose key will be treated as option title and value is an NSNumber of PeekViewActionStyle.
     *  (More delicate solution to be found later :[ )
     */
    @objc public class func viewForController(
        parentViewController parentController: UIViewController,
        contentViewController contentController: UIViewController,
        expectedContentViewFrame frame: CGRect,
        fromGesture gesture: UILongPressGestureRecognizer,
        shouldHideStatusBar flag: Bool,
        withOptions menuOptions: NSArray?,
        completionHandler handler: (Int -> Void)?) {
            
            var options: [PeekViewAction]? = nil
            if let menuOptions = menuOptions {
                options = []
                for option in menuOptions {
                    if let dictionary = option as? NSDictionary,
                        title = dictionary.allKeys[0] as? NSString,
                        styleNumber = dictionary[title] as? NSNumber,
                        style = PeekViewActionStyle(rawValue: styleNumber.integerValue) {
                            options?.append(PeekViewAction(title: title as String, style: style))
                    }
                }
            }
            
            PeekView().viewForController(
                parentViewController: parentController,
                contentViewController: contentController,
                expectedContentViewFrame: frame,
                fromGesture: gesture,
                shouldHideStatusBar: flag,
                withOptions: options,
                completionHandler: handler)
    }
    
    /**
     *  
     */
    public func viewForController(
        parentViewController parentController: UIViewController,
        contentViewController contentController: UIViewController,
        expectedContentViewFrame frame: CGRect,
        fromGesture gesture: UILongPressGestureRecognizer,
        shouldHideStatusBar flag: Bool,
        withOptions menuOptions: [PeekViewAction]?=nil,
        completionHandler handler: (Int -> Void)?=nil) {
            
            let window = UIApplication.sharedApplication().keyWindow!
            
            switch gesture.state {
            case .Began:
                let peekView = PeekView(frame: window.frame)
                peekView.configureView(contentController, subviewFrame: frame, shouldHideStatusBar: flag, options: menuOptions, completionHandler: handler)
                peekView.tag = peekViewTag
                window.addSubview(peekView)
                
                parentController.addChildViewController(contentController)
                contentController.didMoveToParentViewController(parentController)
                
            case .Changed:
                if let view = window.viewWithTag(peekViewTag) as? PeekView {
                    view.updateContentViewFrame(gesture.locationInView(view.superview!).y)
                }
            case .Ended:
                if let view = window.viewWithTag(peekViewTag) as? PeekView {
                    if let buttonHolderView = view.buttonHolderView, contentView = view.contentView {
                        if CGRectGetMinY(buttonHolderView.frame) <= CGRectGetMaxY(view.frame) - CGRectGetHeight(buttonHolderView.frame) - buttonVerticalPadding {
                            var frame = contentView.frame
                            frame.origin.y = CGRectGetMinY(buttonHolderView.frame) - CGRectGetHeight(contentView.frame) - buttonVerticalPadding
                            UIView.animateWithDuration(0.3, animations: { () -> Void in
                                contentView.frame = frame
                            })
                        } else {
                            var frame = buttonHolderView.frame
                            frame.origin.y = CGRectGetMaxY(view.frame)
                            UIView.animateWithDuration(0.3, animations: { () -> Void in
                                buttonHolderView.frame = frame
                                contentView.center = CGPoint(x: CGRectGetWidth(view.frame)/2, y: CGRectGetHeight(view.frame)/2)
                                // move arrow along with content view
                                if view.arrowImageView != nil {
                                    var arrowCenterPoint = view.arrowImageView!.center
                                    arrowCenterPoint.y = CGRectGetMinY(contentView.frame) - 17
                                    view.arrowImageView!.center = arrowCenterPoint
                                    view.arrowImageView!.alpha = 0
                                }
                            }, completion: { completed in
                                view.dismissView()
                            })
                        }
                    } else {
                        view.dismissView()
                    }
                }
            default:
                break
            }
            
    }
    
    func configureView(viewController: UIViewController, subviewFrame: CGRect, shouldHideStatusBar: Bool, options: [PeekViewAction]?=nil, completionHandler: (Int -> Void)?=nil) {
        
        self.shouldToggleHidingStatusBar = shouldHideStatusBar
        self.completionHandler = completionHandler
        
        if shouldToggleHidingStatusBar == true {
            UIApplication.sharedApplication().statusBarHidden = true
        }
        
        // Configure vibrancy
        let blurEffect = UIBlurEffect(style: .Light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = self.bounds
        
        let vibrancyEffect = UIVibrancyEffect(forBlurEffect: blurEffect)
        let vibrancyEffectView = UIVisualEffectView(effect: vibrancyEffect)
        vibrancyEffectView.frame = self.bounds
        let vibrancyContentView = UIView(frame: self.bounds)
        vibrancyContentView.backgroundColor = UIColor.whiteColor()
        vibrancyEffectView.contentView.addSubview(vibrancyContentView)
        blurEffectView.contentView.addSubview(vibrancyEffectView)
        
        self.addSubview(blurEffectView)
        
        // Configure content view
        contentView = viewController.view
        contentView!.frame = subviewFrame
        contentView!.layer.masksToBounds = true
        contentView!.layer.cornerRadius = 7
        contentView!.alpha = 0
        self.addSubview(contentView!)
        
        // Add gesture
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(PeekView.dismissView))
        self.addGestureRecognizer(tapGestureRecognizer)
        
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(PeekView.contentViewPanned(_:)))
        contentView!.addGestureRecognizer(panGestureRecognizer)
        
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            self.contentView!.alpha = 1
        })
        
        // If options are provided: configure buttons
        if let options = options {
            
            guard options.count > 0 else {
                return
            }
            
            // Add arrow image
            arrowImageView = UIImageView(frame: CGRect(x: screenWidth/2 - 18, y: CGRectGetMinY(contentView!.frame) - 25, width: 36, height: 11))
            let bundle = NSBundle(forClass: self.classForCoder)
            arrowImageView!.image = UIImage(named: "arrow", inBundle: bundle, compatibleWithTraitCollection: nil)
            self.addSubview(arrowImageView!)
            
            let cornerRadius = CGFloat(10)
            let buttonHeight = CGFloat(58)
            
            buttonHolderView = UIView(frame: CGRect(x: CGRectGetMinX(subviewFrame), y: CGRectGetMaxY(self.frame), width: CGRectGetWidth(subviewFrame), height: buttonHeight*CGFloat(options.count)))
            buttonHolderView!.layer.backgroundColor = UIColor.whiteColor().CGColor
            buttonHolderView!.layer.cornerRadius = cornerRadius
            buttonHolderView!.layer.masksToBounds = true
            self.addSubview(buttonHolderView!)
            
            for index in 0..<options.count {
                let action = options[index]
                let button = UIButton(type: .System)
                button.frame = CGRect(x: 0, y: CGFloat(index)*buttonHeight, width: CGRectGetWidth(subviewFrame), height: buttonHeight)
                button.addTarget(self, action: #selector(PeekView.buttonPressed(_:)), forControlEvents: .TouchUpInside)
                button.tag = index
                button.titleLabel?.font = UIFont.systemFontOfSize(18)
                button.backgroundColor = UIColor.whiteColor()
                button.setTitle(action.title, forState: .Normal)
                buttonHolderView!.addSubview(button)
                
                if action.style == .Destructive {
                    button.setTitleColor(UIColor.redColor(), forState: .Normal)
                } else if action.style == .Selected {
                    let imageView = UIImageView(image: UIImage(named: "checked", inBundle: bundle, compatibleWithTraitCollection: nil))
                    imageView.frame = CGRect(x: CGRectGetWidth(subviewFrame) - 30, y: buttonHeight/2 - 6, width: 15, height: 12)
                    imageView.tag = tickImageViewTag
                    imageView.alpha = 0
                    button.addSubview(imageView)
                }
                
                if index != 0 {
                    let separator = UIView(frame: CGRect(x: 0, y: CGFloat(index)*buttonHeight, width: CGRectGetWidth(subviewFrame), height: 0.5))
                    separator.backgroundColor = UIColor.lightGrayColor().colorWithAlphaComponent(0.3)
                    buttonHolderView!.addSubview(separator)
                }
            }
            
        }
    }
    
    func buttonPressed(sender: UIButton) {
        if let completionHandler = completionHandler {
            completionHandler(sender.tag)
        }
        
        if let imageView = sender.viewWithTag(tickImageViewTag) as? UIImageView {
            imageView.alpha = imageView.alpha == 1 ? 0 : 1
        } else if let buttonHolderView = buttonHolderView, contentView = contentView {
            var buttonHolderViewFrame = buttonHolderView.frame
            buttonHolderViewFrame.origin.y = CGRectGetMaxY(frame)
            
            var contentViewFrame = contentView.frame
            contentViewFrame.origin.y = -CGRectGetHeight(contentViewFrame)
            UIView.animateWithDuration(0.2, animations: { () -> Void in
                buttonHolderView.frame = buttonHolderViewFrame
                contentView.frame = contentViewFrame
                }, completion: { completed in
                    self.dismissView()
            })
        } else {
            dismissView()
        }
    }
    
    func dismissView() {
        if let contentView = contentView {
            if self.shouldToggleHidingStatusBar == true {
                UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: .Fade)
            }
            UIView.animateWithDuration(0.3, animations: { () -> Void in
                contentView.alpha = 0
                }, completion: { completion in
                    self.removeFromSuperview()
            })
        }
    }
    
    func updateContentViewFrame(frameY: CGFloat) {
        if let contentView = contentView {
            var contentCenterPoint = contentView.center
            contentCenterPoint.y = frameY
            contentView.center = contentCenterPoint
            
            // move arrow along with content view
            if arrowImageView != nil {
                var arrowCenterPoint = arrowImageView!.center
                arrowCenterPoint.y = CGRectGetMinY(contentView.frame) - 17
                arrowImageView!.center = arrowCenterPoint
            }
            
            if let buttonHolderView = buttonHolderView {
                if CGRectGetMaxY(contentView.frame) < CGRectGetMaxY(self.frame) - CGRectGetHeight(buttonHolderView.frame) - buttonVerticalPadding*2 {
                    // if option buttons are visible entirely
                    var frame = buttonHolderView.frame
                    frame.origin.y = CGRectGetMaxY(self.frame) - CGRectGetHeight(buttonHolderView.frame) - buttonVerticalPadding
                    UIView.animateWithDuration(0.2, animations: { () -> Void in
                        buttonHolderView.frame = frame
                        self.arrowImageView?.alpha = 0
                    })
                } else if CGRectGetMinY(buttonHolderView.frame) < CGRectGetMaxY(self.frame) && CGRectGetMaxY(contentView.frame) < CGRectGetMaxY(self.frame) - CGRectGetHeight(buttonHolderView.frame) - buttonVerticalPadding {
                    // if option buttons are visible partially
                    var frame = buttonHolderView.frame
                    frame.origin.y = CGRectGetMaxY(contentView.frame) + buttonVerticalPadding
                    buttonHolderView.frame = frame
                    UIView.animateWithDuration(0.2, animations: { () -> Void in
                        self.arrowImageView?.alpha = 0
                    })
                } else {
                    // hide option buttons
                    var frame = buttonHolderView.frame
                    frame.origin.y = CGRectGetMaxY(self.frame)
                    UIView.animateWithDuration(0.2, animations: { () -> Void in
                        buttonHolderView.frame = frame
                        self.arrowImageView?.alpha = 1
                    })
                    
                }
            }
        }
    }
    
    func contentViewPanned(gestureRecognizer: UIPanGestureRecognizer) {
        switch gestureRecognizer.state {
        case .Ended:
            if let buttonHolderView = buttonHolderView, contentView = contentView {
                if CGRectGetMinY(buttonHolderView.frame) <= CGRectGetMaxY(frame) - CGRectGetHeight(buttonHolderView.frame) - buttonVerticalPadding {
                    var frame = contentView.frame
                    frame.origin.y = CGRectGetMinY(buttonHolderView.frame) - CGRectGetHeight(contentView.frame) - buttonVerticalPadding
                    UIView.animateWithDuration(0.2, animations: { () -> Void in
                        contentView.frame = frame
                    })
                } else {
                    var frame = buttonHolderView.frame
                    frame.origin.y = CGRectGetMaxY(self.frame)
                    UIView.animateWithDuration(0.2, animations: { () -> Void in
                        buttonHolderView.frame = frame
                        contentView.center = CGPoint(x: CGRectGetWidth(self.frame)/2, y: CGRectGetHeight(self.frame)/2)
                        // move arrow along with content view
                        if self.arrowImageView != nil {
                            var arrowCenterPoint = self.arrowImageView!.center
                            arrowCenterPoint.y = CGRectGetMinY(contentView.frame) - 17
                            self.arrowImageView!.center = arrowCenterPoint
                            self.arrowImageView!.alpha = 0
                        }
                        
                    }, completion: { completed in
                        self.dismissView()
                    })
                }
            } else {
                dismissView()
            }
        default:
            updateContentViewFrame(gestureRecognizer.locationInView(self).y)
        }
        
    }
    
}
