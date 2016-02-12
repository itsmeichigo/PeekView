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
let buttonVerticalPadding = CGFloat(15)

public class PeekView: UIView {
    
    var shouldToggleHidingStatusBar = false
    var contentView: UIView?
    var buttonHolderView: UIView?
    var completionHandler: (Int -> Void)?

    public class func viewForController(
        parentViewController parentController: UIViewController,
        contentViewController contentController: UIViewController,
        expectedContentViewFrame frame: CGRect,
        fromGesture gesture: UILongPressGestureRecognizer,
        shouldHideStatusBar flag: Bool,
        withOptions menuOptions: [String]?=nil,
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
    
    func configureView(viewController: UIViewController, subviewFrame: CGRect, shouldHideStatusBar: Bool, options: [String]?=nil, completionHandler: (Int -> Void)?=nil) {
        
        self.shouldToggleHidingStatusBar = shouldHideStatusBar
        self.completionHandler = completionHandler
        
        if shouldToggleHidingStatusBar == true {
            UIApplication.sharedApplication().statusBarHidden = true
        }
        
        let blurEffect = UIBlurEffect(style: .Light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = self.bounds
        
        // TODO: configure vibrancy
        let vibrancyEffect = UIVibrancyEffect(forBlurEffect: blurEffect)
        let vibrancyEffectView = UIVisualEffectView(effect: vibrancyEffect)
        vibrancyEffectView.frame = self.bounds
        let vibrancyContentView = UIView(frame: self.bounds)
        vibrancyContentView.backgroundColor = UIColor.whiteColor()
        vibrancyEffectView.contentView.addSubview(vibrancyContentView)
        blurEffectView.contentView.addSubview(vibrancyEffectView)
        
        self.addSubview(blurEffectView)
        
        contentView = viewController.view
        contentView!.frame = subviewFrame
        contentView!.layer.masksToBounds = true
        contentView!.layer.cornerRadius = 7
        contentView!.alpha = 0
        self.addSubview(contentView!)
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismissView")
        self.addGestureRecognizer(tapGestureRecognizer)
        
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: "contentViewPanned:")
        contentView!.addGestureRecognizer(panGestureRecognizer)
        
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            self.contentView!.alpha = 1
        })
        
        if let options = options {
            
            let cornerRadius = CGFloat(10)
            let buttonHeight = CGFloat(58)
            
            buttonHolderView = UIView(frame: CGRect(x: CGRectGetMinX(subviewFrame), y: CGRectGetMaxY(self.frame), width: CGRectGetWidth(subviewFrame), height: buttonHeight*CGFloat(options.count)))
            buttonHolderView!.layer.backgroundColor = UIColor.whiteColor().CGColor
            buttonHolderView!.layer.cornerRadius = cornerRadius
            buttonHolderView!.layer.masksToBounds = true
            self.addSubview(buttonHolderView!)
            
            for index in 0..<options.count {
                let button = UIButton(type: .System)
                button.frame = CGRect(x: 0, y: CGFloat(index)*buttonHeight, width: CGRectGetWidth(subviewFrame), height: buttonHeight)
                button.addTarget(self, action: "buttonPressed:", forControlEvents: .TouchUpInside)
                button.tag = index
                button.titleLabel?.font = UIFont.systemFontOfSize(18)
                button.backgroundColor = UIColor.whiteColor()
                button.setTitle(options[index], forState: .Normal)
                buttonHolderView!.addSubview(button)
                
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
        
        if let buttonHolderView = buttonHolderView, contentView = contentView {
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
            var centerPoint = contentView.center
            centerPoint.y = frameY
            contentView.center = centerPoint
            
            if let buttonHolderView = buttonHolderView {
                if CGRectGetMaxY(contentView.frame) < CGRectGetMaxY(self.frame) - CGRectGetHeight(buttonHolderView.frame) - buttonVerticalPadding*2 {
                    var frame = buttonHolderView.frame
                    frame.origin.y = CGRectGetMaxY(self.frame) - CGRectGetHeight(buttonHolderView.frame) - buttonVerticalPadding
                    UIView.animateWithDuration(0.2, animations: { () -> Void in
                        buttonHolderView.frame = frame
                    })
                } else if CGRectGetMinY(buttonHolderView.frame) < CGRectGetMaxY(self.frame) && CGRectGetMaxY(contentView.frame) < CGRectGetMaxY(self.frame) - CGRectGetHeight(buttonHolderView.frame) - buttonVerticalPadding {
                    var frame = buttonHolderView.frame
                    frame.origin.y = CGRectGetMaxY(contentView.frame) + buttonVerticalPadding
                    buttonHolderView.frame = frame
                } else {
                    var frame = buttonHolderView.frame
                    frame.origin.y = CGRectGetMaxY(self.frame)
                    UIView.animateWithDuration(0.2, animations: { () -> Void in
                        buttonHolderView.frame = frame
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
