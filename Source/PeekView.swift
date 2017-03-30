//
//  PeekView.swift
//  PeekViewDemo
//
//  Created by Huong Do on 2/11/16.
//  Copyright © 2016 Huong Do. All rights reserved.
//

import UIKit

let screenWidth = UIScreen.main.bounds.size.width
let screenHeight = UIScreen.main.bounds.size.height
let peekViewTag = 1929
let tickImageViewTag = 1930
let buttonVerticalPadding = CGFloat(15)
var fromTouchToContentCenter = CGFloat(0)

@objc public enum PeekViewActionStyle : Int {
    case `default`
    case selected
    case destructive
}

public struct PeekViewAction {
    var title: String
    var style: PeekViewActionStyle
    
    public init(title: String, style: PeekViewActionStyle){
        self.title = title
        self.style = style
    }
}

@objc open class PeekView: UIView {
    
    var shouldToggleHidingStatusBar = false
    var contentView: UIView?
    var buttonHolderView: UIView?
    var completionHandler: ((Int) -> Void)?
    var dismissHandler: (()->Void)?
    
    var arrowImageView: UIImageView?
    
    /**
     *  Helper class function to support objective-c projects
     *  Since struct cannot be bridged to obj-c, user can input an NSArray of NSDictionary objects,
     *  whose key will be treated as option title and value is an NSNumber of PeekViewActionStyle.
     *  (More delicate solution to be found later :[ )
     */
    @objc open class func viewForController(
        parentViewController: UIViewController,
        contentViewController: UIViewController,
        expectedContentViewFrame: CGRect,
        fromGesture: UILongPressGestureRecognizer,
        shouldHideStatusBar: Bool,
        menuOptions: NSArray?,
        completionHandler: ((Int) -> Void)?,
        dismissHandler: (()->Void)?) {
            
            var options: [PeekViewAction]? = nil
            if let menuOptions = menuOptions {
                options = []
                for option in menuOptions {
                    if let dictionary = option as? NSDictionary,
                        let title = dictionary.allKeys[0] as? NSString,
                        let styleNumber = dictionary[title] as? NSNumber,
                        let style = PeekViewActionStyle(rawValue: styleNumber.intValue) {
                            options?.append(PeekViewAction(title: title as String, style: style))
                    }
                }
            }
            
            PeekView().viewForController(
                parentViewController: parentViewController,
                contentViewController: contentViewController,
                expectedContentViewFrame: expectedContentViewFrame,
                fromGesture: fromGesture,
                shouldHideStatusBar: shouldHideStatusBar,
                menuOptions: options,
                completionHandler: completionHandler,
                dismissHandler: dismissHandler)
    }
    
    /**
     *  
     */
    open func viewForController(
        parentViewController: UIViewController,
        contentViewController: UIViewController,
        expectedContentViewFrame: CGRect,
        fromGesture: UILongPressGestureRecognizer,
        shouldHideStatusBar: Bool,
        menuOptions: [PeekViewAction]?=nil,
        completionHandler: ((Int) -> Void)?=nil,
        dismissHandler: (()->Void)?=nil) {
            
            let window = UIApplication.shared.keyWindow!
            
            switch fromGesture.state {
            case .began:
                let peekView = PeekView(frame: window.frame)
                peekView.configureView(viewController: contentViewController,
                                       subviewFrame: expectedContentViewFrame,
                                       shouldHideStatusBar: shouldHideStatusBar,
                                       options: menuOptions,
                                       completionHandler: completionHandler,
                                       dismissHandler: dismissHandler)
                peekView.tag = peekViewTag
                window.addSubview(peekView)
                
                parentViewController.addChildViewController(contentViewController)
                contentViewController.didMove(toParentViewController: parentViewController)
                
                // DuyNT: Calculate distance from touch location to vertical center point of contentView, and when the touch location moves as the user swiping his hand, vertical center point of contentView will be recalculated, resulting in a nicer visual which contentView center does not necessary be aligned with user's finger as in original solution.
                if let view = window.viewWithTag(peekViewTag) as? PeekView {
                    let pointOfHand = fromGesture.location(in: view.superview).y
                    fromTouchToContentCenter = pointOfHand - screenHeight / 2
                }
                
            case .changed:
                if let view = window.viewWithTag(peekViewTag) as? PeekView {
                    
                    // DuyNT: Here we use the number calculated before to get 'better' center position of contentView
                    let pointOfHand = fromGesture.location(in: view.superview!).y
                    var centerOfContent = CGFloat(0)
                    
                    centerOfContent = pointOfHand - fromTouchToContentCenter
                    
                    view.updateContentViewFrame(centerOfContent)
                }
            case .ended:
                fromTouchToContentCenter = CGFloat(0)
                
                if let view = window.viewWithTag(peekViewTag) as? PeekView {
                    if let buttonHolderView = view.buttonHolderView, let contentView = view.contentView {
                        if buttonHolderView.frame.minY <= view.frame.maxY - buttonHolderView.frame.height - buttonVerticalPadding {
                            var frame = contentView.frame
                            frame.origin.y = buttonHolderView.frame.minY - contentView.frame.height - buttonVerticalPadding
                            UIView.animate(withDuration: 0.3, animations: { () -> Void in
                                contentView.frame = frame
                            })
                        } else {
                            var frame = buttonHolderView.frame
                            frame.origin.y = view.frame.maxY
                            UIView.animate(withDuration: 0.3, animations: { () -> Void in
                                buttonHolderView.frame = frame
                                contentView.center = CGPoint(x: view.frame.width/2, y: view.frame.height/2)
                                // move arrow along with content view
                                if view.arrowImageView != nil {
                                    var arrowCenterPoint = view.arrowImageView!.center
                                    arrowCenterPoint.y = contentView.frame.minY - 17
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
                fromTouchToContentCenter = CGFloat(0)
                break
            }
            
    }
    
    func configureView(viewController: UIViewController, subviewFrame: CGRect, shouldHideStatusBar: Bool, options: [PeekViewAction]?=nil, completionHandler: ((Int) -> Void)?=nil, dismissHandler: (()->Void)?=nil) {
        
        self.shouldToggleHidingStatusBar = shouldHideStatusBar
        self.completionHandler = completionHandler
        self.dismissHandler = dismissHandler
        
        if shouldToggleHidingStatusBar == true {
            UIApplication.shared.isStatusBarHidden = true
        }
        
        // Configure vibrancy
        let blurEffect = UIBlurEffect(style: .light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = self.bounds
        
        let vibrancyEffect = UIVibrancyEffect(blurEffect: blurEffect)
        let vibrancyEffectView = UIVisualEffectView(effect: vibrancyEffect)
        vibrancyEffectView.frame = self.bounds
        let vibrancyContentView = UIView(frame: self.bounds)
        vibrancyContentView.backgroundColor = UIColor.white
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
        
        UIView.animate(withDuration: 0.3, animations: { () -> Void in
            self.contentView!.alpha = 1
        })
        
        // If options are provided: configure buttons
        if let options = options {
            
            guard options.count > 0 else {
                return
            }
            
            // Add arrow image
            arrowImageView = UIImageView(frame: CGRect(x: screenWidth/2 - 18, y: contentView!.frame.minY - 25, width: 36, height: 11))
            let bundle = Bundle(for: self.classForCoder)
            arrowImageView!.image = UIImage(named: "arrow", in: bundle, compatibleWith: nil)
            self.addSubview(arrowImageView!)
            
            let cornerRadius = CGFloat(10)
            let buttonHeight = CGFloat(58)
            
            buttonHolderView = UIView(frame: CGRect(x: subviewFrame.minX, y: self.frame.maxY, width: subviewFrame.width, height: buttonHeight*CGFloat(options.count)))
            buttonHolderView!.layer.backgroundColor = UIColor.white.cgColor
            buttonHolderView!.layer.cornerRadius = cornerRadius
            buttonHolderView!.layer.masksToBounds = true
            self.addSubview(buttonHolderView!)
            
            for index in 0..<options.count {
                let action = options[index]
                let button = UIButton(type: .system)
                button.frame = CGRect(x: 0, y: CGFloat(index)*buttonHeight, width: subviewFrame.width, height: buttonHeight)
                button.addTarget(self, action: #selector(PeekView.buttonPressed(_:)), for: .touchUpInside)
                button.tag = index
                button.titleLabel?.font = UIFont.systemFont(ofSize: 18)
                button.backgroundColor = UIColor.white
                button.setTitle(action.title, for: UIControlState())
                buttonHolderView!.addSubview(button)
                
                if action.style == .destructive {
                    button.setTitleColor(UIColor.red, for: UIControlState())
                } else if action.style == .selected {
                    let imageView = UIImageView(image: UIImage(named: "checked", in: bundle, compatibleWith: nil))
                    imageView.frame = CGRect(x: subviewFrame.width - 30, y: buttonHeight/2 - 6, width: 15, height: 12)
                    imageView.tag = tickImageViewTag
                    imageView.alpha = 0
                    button.addSubview(imageView)
                }
                
                if index != 0 {
                    let separator = UIView(frame: CGRect(x: 0, y: CGFloat(index)*buttonHeight, width: subviewFrame.width, height: 0.5))
                    separator.backgroundColor = UIColor.lightGray.withAlphaComponent(0.3)
                    buttonHolderView!.addSubview(separator)
                }
            }
            
        }
    }
    
    func buttonPressed(_ sender: UIButton) {
        if let completionHandler = completionHandler {
            completionHandler(sender.tag)
        }
        
        if let imageView = sender.viewWithTag(tickImageViewTag) as? UIImageView {
            imageView.alpha = imageView.alpha == 1 ? 0 : 1
        } else if let buttonHolderView = buttonHolderView, let contentView = contentView {
            var buttonHolderViewFrame = buttonHolderView.frame
            buttonHolderViewFrame.origin.y = frame.maxY
            
            var contentViewFrame = contentView.frame
            contentViewFrame.origin.y = -contentViewFrame.height
            UIView.animate(withDuration: 0.2, animations: { () -> Void in
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
                UIApplication.shared.setStatusBarHidden(false, with: .fade)
            }
            UIView.animate(withDuration: 0.3, animations: { () -> Void in
                contentView.alpha = 0
                }, completion: { completion in
                    self.dismissHandler?()
                    self.removeFromSuperview()
            })
        }
    }
    
    func updateContentViewFrame(_ frameY: CGFloat) {
        if let contentView = contentView {
            var contentCenterPoint = contentView.center
            contentCenterPoint.y = frameY
            contentView.center = contentCenterPoint
            
            // move arrow along with content view
            if arrowImageView != nil {
                var arrowCenterPoint = arrowImageView!.center
                arrowCenterPoint.y = contentView.frame.minY - 17
                arrowImageView!.center = arrowCenterPoint
            }
            
            if let buttonHolderView = buttonHolderView {
                if contentView.frame.maxY < self.frame.maxY - buttonHolderView.frame.height - buttonVerticalPadding*2 {
                    // if option buttons are visible entirely
                    var frame = buttonHolderView.frame
                    frame.origin.y = self.frame.maxY - buttonHolderView.frame.height - buttonVerticalPadding
                    UIView.animate(withDuration: 0.2, animations: { () -> Void in
                        buttonHolderView.frame = frame
                        self.arrowImageView?.alpha = 0
                    })
                } else if buttonHolderView.frame.minY < self.frame.maxY && contentView.frame.maxY < self.frame.maxY - buttonHolderView.frame.height - buttonVerticalPadding {
                    // if option buttons are visible partially
                    var frame = buttonHolderView.frame
                    frame.origin.y = contentView.frame.maxY + buttonVerticalPadding
                    buttonHolderView.frame = frame
                    UIView.animate(withDuration: 0.2, animations: { () -> Void in
                        self.arrowImageView?.alpha = 0
                    })
                } else {
                    // hide option buttons
                    var frame = buttonHolderView.frame
                    frame.origin.y = self.frame.maxY
                    UIView.animate(withDuration: 0.2, animations: { () -> Void in
                        buttonHolderView.frame = frame
                        self.arrowImageView?.alpha = 1
                    })
                    
                }
            }
        }
    }
    
    func contentViewPanned(_ gestureRecognizer: UIPanGestureRecognizer) {
        switch gestureRecognizer.state {
        case .ended:
            if let buttonHolderView = buttonHolderView, let contentView = contentView {
                if buttonHolderView.frame.minY <= frame.maxY - buttonHolderView.frame.height - buttonVerticalPadding {
                    var frame = contentView.frame
                    frame.origin.y = buttonHolderView.frame.minY - contentView.frame.height - buttonVerticalPadding
                    UIView.animate(withDuration: 0.2, animations: { () -> Void in
                        contentView.frame = frame
                    })
                } else {
                    var frame = buttonHolderView.frame
                    frame.origin.y = self.frame.maxY
                    UIView.animate(withDuration: 0.2, animations: { () -> Void in
                        buttonHolderView.frame = frame
                        contentView.center = CGPoint(x: self.frame.width/2, y: self.frame.height/2)
                        // move arrow along with content view
                        if self.arrowImageView != nil {
                            var arrowCenterPoint = self.arrowImageView!.center
                            arrowCenterPoint.y = contentView.frame.minY - 17
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
            let pointOfHand = gestureRecognizer.location(in: self).y
            var centerOfContent = CGFloat(0)
            centerOfContent = pointOfHand - fromTouchToContentCenter
            
            updateContentViewFrame(centerOfContent)
        }
        
    }
    
}
