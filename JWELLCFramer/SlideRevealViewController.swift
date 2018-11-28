//
//  SlideRevealViewController.swift
//
//  Created by William Thompson on 9/23/18.
//  Copyright © 2018 William Thompson. All rights reserved.
//
/*
Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is furnished
to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
 
 Inspired by Joan Lluch's SWRevealViewController class
 
 version 1.0
 - Release notes
 - Supports sliding the front view controller left or right to expose view controllers beneath
 - Supports iOS 9.0 and later
 - If SlideRevealViewControllerDelegate is implemented all transitions must be re created in delegate methods
*/
//
//
//
//
//TODO: Add more comments

import UIKit
import QuartzCore
import UIKit.UIGestureRecognizerSubclass


// MARK: - ViewPosition Enum
/*
 Constants to hold the view position of the front view controller exposing view controllers beneath
 */
@objc public enum ViewPosition: Int {
    case none = 0
    case leftSideMostRemoved = 1
    case leftSideMost = 2
    case leftSide = 3
    case left = 4
    case right = 5
    case rightMost = 6
    case rightSideMostRemoved = 7
}

// MARK: - SlideRevealViewOperation Enum
/*
 Constants to hold the current operation
 */
@objc enum SlideRevealViewOperation: Int {
    case none = 0
    case replaceLeftController = 1
    case replaceFrontController = 2
    case replaceRightController = 3
}

// MARK: - Animation type
@objc enum SlideRevealAnimationType: Int {
    case spring
    case easeout
}

@objc enum SlideRevealViewLocation: Int {
    case above
    case beneath
}

// MARK: - SlideRevealViewBlurEffect Enum
/*
 Constants to hold the selected blur effect of the left and right view controller when exposed above the front(main) view controller
 */
@objc enum SlideRevealViewBlurEffect: Int {
    case none = -1
    case lightest
    case light
    case dark
}

// MARK: - SlideRevealViewControllerDelegate
@objc protocol SlideRevealViewControllerDelegate: NSObjectProtocol {
    // All methods are optional. Delegate use is optional.
    
    // The following delegate methods will be called before and after the front view moves to a position.
    @objc optional func revealController(_ revealController: SlideRevealViewController, willMoveTo position: ViewPosition)
    /*
     Called right before the front(main) view controller moves to a new position to expose view controllers beneath
     used mostly as a notification method.
     
     -Parameters:
     -revealController: The reveal view controller object typically passed as self
     -position: The ViewPosition constant for the front(main) view controller to move to
     */
    @objc optional func revealController(_ revealController: SlideRevealViewController, didMoveTo position: ViewPosition)
    /*
     Called after the front(main) view controller moved to a new position to expose view controllers beneath, used mostly as a notifcation method
     -Parameters:
     -revealController: The reveal controller object typically passed as self
     -position: The ViewPosition constant for the front(main) view controller to move to
    */
    
    // This will be called inside the reveal animation, thus you can use it to place your own code that will be animated in sync.
    @objc optional func revealController(_ revealController: SlideRevealViewController, animateTo position: ViewPosition)
    
    // Implement the following methods to return false when you want the gesture recognizers to be ignored.
    @objc optional func panGestureRecognizerShouldBegin(_ revealController: SlideRevealViewController) -> Bool
    @objc optional func tapGestureRecognizerShouldBegin(_ revealController: SlideRevealViewController) -> Bool
    
    // Implement the following methods to return true if you want other gesture recognizer to share events with tap and pan gesture.
    @objc optional func panGestureRecognizesSimutaneouslyWith(_ otherGesture: UIGestureRecognizer, revealController: SlideRevealViewController) -> Bool
    @objc optional func tapGestureRecognizesSimutaneouslyWith(_ otherGesture: UIGestureRecognizer, revealController: SlideRevealViewController) -> Bool
    
    // Notification methods called when the pan gesture begins and ends.
    @objc optional func panGestureBegan(_ revealController: SlideRevealViewController?)
    @objc optional func panGestureEnded(_ revealController: SlideRevealViewController?)
    
    // The following methods provide a means to track the evolution of the gesture recognizer.
    // The 'location' parameter is the X origin coordinate of the front view as the user drags it
    // The 'progress' parameter is a number ranging from 0 to 1 indicating the front view location relative to the
    //   leftRevealWidth or rightRevealWidth. 1 is fully revealed, dragging ocurring in the overDraw region will result in values above 1.
    // The 'overProgress' parameter is a number ranging from 0 to 1 indicating the front view location relative to the
    //   overdraw region. 0 is fully revealed, 1 is fully overdrawn. Negative values occur inside the normal reveal region
    @objc optional func revealController(_ revealController: SlideRevealViewController, panGestureBeganFromLocation location: CGFloat, progress: CGFloat, overProgress: CGFloat)
    @objc optional func revealController(_ revealController: SlideRevealViewController, panGestureMovedToLocation location: CGFloat, progress: CGFloat, overProgress: CGFloat)
    @objc optional func revealController(_ revealController: SlideRevealViewController, panGestureEndedToLocation location: CGFloat, progress: CGFloat, overProgress: CGFloat)
    
    // Notification methods called for child view controller replacement.
    @objc optional func revealController(_ revealController: SlideRevealViewController, willAdd viewController: UIViewController?, forOperation: SlideRevealViewOperation, animated: Bool)
    @objc optional func revealController(_ revealController: SlideRevealViewController, didAdd viewController: UIViewController?, forOperation: SlideRevealViewOperation, animated: Bool)
    
    // Support for custom transition animations while replacing child view controllers. If Implemented, it will be called in response to calls to "setXXXXViewController" methods.
    @objc optional func revealController(_ revealController: SlideRevealViewController, animationControllerFor operation: SlideRevealViewOperation, from fromVC: UIViewController?, to toVC: UIViewController?) -> UIViewControllerAnimatedTransitioning?
    
}

//MARK: StatusBar helper function
// computes the required offset adjustment due to the status bar for the passed in view,
// it will return the statusBar height if view fully overlaps the statusBar, otherwise returns 0.0
public func statusBarAdjustment(_ view: UIView) -> CGFloat {
    var adjustment: CGFloat = 0.0
    let app = UIApplication.shared
    let viewFrame = view.convert(view.bounds, to: app.keyWindow)
    let statusBarFrame = app.statusBarFrame
    if viewFrame.intersects(statusBarFrame) {
        adjustment = CGFloat(fminf(Float(statusBarFrame.size.width), Float(statusBarFrame.size.height)))
    }
    return adjustment
}

// MARK: - SlideRevealView class
class SlideRevealView: UIView {
    weak var revealViewController: SlideRevealViewController!
    private(set) var leftView: UIView?
    private(set) var rightView: UIView?
    private(set) var frontView: UIView?
    var disableLayout = false
    
    static func scaledValue(v1: CGFloat, min2: CGFloat, max2: CGFloat, min1: CGFloat, max1: CGFloat) -> CGFloat {
        let result: CGFloat = min2 + (v1 - min1) * ((max2 - min2) / (max1 - min1))
        if result != result {
            return min2
        }
        if result < min2 {
            return min2
        }
        if result > max2 {
            return max2
        }
        return result
    }
    
    init(frame: CGRect, controller: SlideRevealViewController) {
        super.init(frame: frame)
        revealViewController = controller
        let bounds: CGRect = self.bounds
        frontView = UIView(frame: bounds)
        frontView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        reloadShadow()
        self.addSubview(self.frontView!)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
    }
    
    func reloadShadow() {
        let frontViewLayer: CALayer? = frontView?.layer
        frontViewLayer?.shadowColor = revealViewController.frontViewShadowColor.cgColor
        frontViewLayer?.shadowOpacity = Float(revealViewController.frontViewShadowOpacity)
        frontViewLayer?.shadowOffset = revealViewController.frontViewShadowOffset
        frontViewLayer?.shadowRadius = revealViewController.frontViewShadowRadius
    }
    
    func hierarchycalFrameAdjustment(_ frame: CGRect) -> CGRect {
        var frame = frame
        if revealViewController.isPresentFrontViewHierarchically {
            let dummyBar = UINavigationBar()
            let barHeight = dummyBar.sizeThatFits(CGSize(width: CGFloat(100), height: CGFloat(100))).height
            let offset: CGFloat = barHeight + statusBarAdjustment(self)
            frame.origin.y += offset
            frame.size.height -= offset
        }
        return frame
    }
    
    func prepareLeftView(for newPosition: ViewPosition) {
        if leftView == nil {
            leftView = UIView(frame: bounds)
            leftView?.autoresizingMask = [.flexibleHeight, .flexibleWidth]
            insertSubview(leftView!, belowSubview: frontView!)
        }
        let xLocation = frontLocation(for: revealViewController.frontViewPosition!)
        layoutRearViews(for: xLocation)
        prepareFor(newPosition: newPosition)
    }
    
    func prepareRightView(for newPosition: ViewPosition) {
        //TODO: work on the presenting above front view
        if rightView == nil {
            rightView = UIView(frame: bounds)
            rightView?.autoresizingMask = [.flexibleHeight, .flexibleWidth]
            insertSubview(rightView!, belowSubview: frontView!)
        }
        let xLocation = frontLocation(for: revealViewController.frontViewPosition!)
        layoutRearViews(for: xLocation)
        prepareFor(newPosition: newPosition)
    }
    
    func unloadLeftView() {
        leftView?.removeFromSuperview()
        leftView = nil
    }
    
    func unloadRightView() {
        rightView?.removeFromSuperview()
        rightView = nil
    }
    
    func frontLocation(for viewPosition: ViewPosition) -> CGFloat {
        var revealWidth: CGFloat = 0.0
        var revealOverdraw: CGFloat = 0.0
        var location: CGFloat = 0.0
        var frontViewPosition = viewPosition
        let symetry: Int = frontViewPosition.rawValue < ViewPosition.left.rawValue ? -1 : 1
        revealViewController.getRevealWidth(revealWidth: &revealWidth, revealOverdraw: &revealOverdraw, symetry: symetry)
        revealViewController.getAdjusted(frontViewPosition: &frontViewPosition, symetry: symetry)
        if frontViewPosition == .right {
            location = revealWidth
        } else if  frontViewPosition.rawValue > ViewPosition.right.rawValue {
            location = revealWidth + revealOverdraw
        }
        return location * CGFloat(symetry)
    }
    
    func dragFrontViewTo(xLocation: CGFloat) {
        let bounds = self.bounds
        var xLocation = xLocation
        xLocation = adjustedDragLocation(location: xLocation)
        layoutRearViews(for: xLocation)
        let frame = CGRect(x: xLocation, y: CGFloat(0.0), width: bounds.size.width, height: bounds.size.height)
        frontView?.frame = hierarchycalFrameAdjustment(frame)
    }
    
    func dragLeftViewTo(xLocation: CGFloat) {
        let bounds = self.bounds
        var xLocation = xLocation
        xLocation = adjustedLeftDragLocation(location: -xLocation)
        layoutRearViews(for: xLocation)
        let frame = CGRect(x: xLocation, y: 0.0, width: bounds.size.width, height: bounds.size.height)
        print(xLocation)
        leftView?.frame = hierarchycalFrameAdjustment(frame)
    }
    
    //MARK: - Overrides
    override func layoutSubviews() {
        if disableLayout {
            return
        }
        let bounds = self.bounds
        let position = revealViewController.frontViewPosition
        let location = frontLocation(for: position!)
        layoutRearViews(for: location)
        let frame = CGRect(x: location, y: 0.0, width: bounds.size.width, height: bounds.size.height)
        frontView?.frame = hierarchycalFrameAdjustment(frame)
        let frontViewController = revealViewController.frontViewController
        let viewLoaded = frontViewController != nil && (frontViewController?.isViewLoaded)!
        let viewNotRemoved = (position?.rawValue)! > ViewPosition.leftSideMostRemoved.rawValue && (position?.rawValue)! < ViewPosition.rightSideMostRemoved.rawValue
        let shadowBounds = viewLoaded && viewNotRemoved ? frontView?.bounds : CGRect.zero
        let shadowPath = UIBezierPath(rect: shadowBounds!)
        frontView?.layer.shadowPath = shadowPath.cgPath
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        var isInside = super.point(inside: point, with: event)
        if !isInside && revealViewController.isExtendsPointInsideHit {
            let testViews = [leftView, rightView, frontView]
            let testControllers = [revealViewController.leftViewController!, revealViewController.frontViewController!, revealViewController.rightViewController!]
            for i in 0..<3 {
                if testViews[i] != nil && testControllers[i].isViewLoaded {
                    let pt = convert(point, to: testViews[i])
                    isInside = (testViews[i]?.point(inside: pt, with: event))!
                }
            }
        }
        return isInside
    }
    
    func pointInside(point: CGPoint, with event: UIEvent?) -> Bool {
        var isInside = super.point(inside: point, with: event)
        if revealViewController.isExtendsPointInsideHit {
            if !isInside && leftView != nil && (revealViewController.leftViewController?.isViewLoaded)! {
                let pt = convert(point, to: leftView)
                isInside = (leftView?.point(inside: pt, with: event))!
            }
            if !isInside && frontView != nil && (revealViewController.frontViewController?.isViewLoaded)! {
                let pt = convert(point, to: frontView)
                isInside = (frontView?.point(inside: pt, with: event))!
            }
            if !isInside && rightView != nil && (revealViewController.rightViewController?.isViewLoaded)! {
                let pt = convert(point, to: rightView)
                isInside = (rightView?.point(inside: pt, with: event))!
            }
        }
        return isInside
    }
    
    
    //MARK: - Private Methods
    private func layoutRearViews(for location: CGFloat) {
        let bounds = self.bounds
        var leftRevealWidth = revealViewController.leftViewRevealWidth
        if leftRevealWidth < 0 {
            leftRevealWidth = bounds.size.width + revealViewController.leftViewRevealWidth
        }
        let leftXLocation: CGFloat = SlideRevealView.scaledValue(v1: location, min2: -revealViewController.leftViewRevealDisplacement, max2: 0, min1: 0, max1: leftRevealWidth)
        let leftWidth = leftRevealWidth + revealViewController.leftViewRevealOverdraw
        leftView?.frame = CGRect(x: leftXLocation, y: 0.0, width: leftWidth, height: bounds.size.height)
        var rightRevealWidth = revealViewController.rightViewRevealWidth
        if rightRevealWidth < 0 {
            rightRevealWidth = bounds.size.width + revealViewController.rightViewRevealWidth
        }
        let rightXLocation = SlideRevealView.scaledValue(v1: location, min2: 0, max2: revealViewController.rightViewRevealDisplacement, min1: -rightRevealWidth, max1: 0)
        let rightWidth = (rightRevealWidth + revealViewController.rightViewRevealOverdraw)
        rightView?.frame = CGRect(x: (bounds.size.width - rightWidth + rightXLocation), y: 0.0, width: rightWidth, height: bounds.size.height)
    }
    
    private func prepareFor(newPosition: ViewPosition) {
        if leftView == nil || rightView == nil {
            return
        }
        let symetry: Int = newPosition.rawValue < ViewPosition.left.rawValue ? -1 : 1
        let subViews: [UIView] = self.subviews
        let leftIndex: Int = subViews.firstIndex(of: leftView!)!
        let rightIndex: Int = subViews.firstIndex(of: rightView!)!
        if ((symetry < 0 && rightIndex < leftIndex) || (symetry > 0 && leftIndex < rightIndex)) {
            exchangeSubview(at: rightIndex, withSubviewAt: leftIndex)
        }
    }
    
    private func adjustedDragLocation(location: CGFloat) -> CGFloat {
        var result: CGFloat = 0.0
        var revealWidth: CGFloat = 0.0
        var revealOverdraw: CGFloat = 0.0
        var bouncesBack = false
        var stableDrag = false
        let position = revealViewController.frontViewPosition
        let symetry: Int = location < 0 ? -1 : 1
        revealViewController.getRevealWidth(revealWidth: &revealWidth, revealOverdraw: &revealOverdraw, symetry: symetry)
        revealViewController.getBounceBack(bounceBack: &bouncesBack, stableDrag: &stableDrag, symetry: symetry)
        if !bouncesBack || stableDrag || position == ViewPosition.rightSideMostRemoved || position == ViewPosition.leftSideMost {
            revealWidth += revealOverdraw
            revealOverdraw = 0.0
            
        }
        let x = (location * CGFloat(symetry))
        if x <= revealWidth {
            result = x
        }
        else if (x <= revealWidth + 2 * revealOverdraw) {
            result = (revealWidth + (x - revealWidth) / 2)
        }
        else {
            result = revealWidth + revealOverdraw
        }
        return result * CGFloat(symetry)
    }
    
    private func adjustedLeftDragLocation(location: CGFloat) -> CGFloat {
        var result: CGFloat = 0.0
        var revealWidth: CGFloat = 0.0
        var revealOverdraw: CGFloat = 0.0
        var bouncesBack = false
        var stableDrag = false
        let position = revealViewController.frontViewPosition
        let symetry: Int = location < 0 ? -1 : 1
        revealViewController.getRevealWidth(revealWidth: &revealWidth, revealOverdraw: &revealOverdraw, symetry: symetry)
        revealViewController.getBounceBack(bounceBack: &bouncesBack, stableDrag: &stableDrag, symetry: symetry)
        if !bouncesBack || stableDrag || position == ViewPosition.rightSideMostRemoved || position == ViewPosition.leftSideMost {
            revealWidth += revealOverdraw
            revealOverdraw = 0.0
        }
        let x = (location * CGFloat(symetry))
        if x <= revealWidth {
            result = x
        }
        else if (x <= revealWidth + 2 * revealOverdraw) {
            result = (revealWidth + (x - revealWidth) / -2)
        }
        else {
            result = revealWidth + revealOverdraw
        }
        return result * CGFloat(symetry)
    }
}

// MARK: - SlideRevealContextTransitioningObject class
private class SlideRevealContextTransitioningObject: NSObject, UIViewControllerContextTransitioning {
    
    weak internal var revealVC : SlideRevealViewController?
    internal var view: UIView?
    internal var toVC: UIViewController?
    internal var fromVC: UIViewController?
    internal var completion: (() -> Void)?
    
    
    init(revealController revealVC: SlideRevealViewController, containerView view: UIView?, fromVC: UIViewController?, toVC: UIViewController?, completion: @escaping () -> Void) {
        
        self.revealVC = revealVC
        self.view = view
        self.toVC = toVC
        self.fromVC = fromVC
        self.completion = completion
        super.init()
    }
    
    var containerView: UIView {
        return view!
    }
    
    var isAnimated: Bool {
        return true
    }
    
    var isInteractive: Bool {
        return false
    }
    
    var transitionWasCancelled: Bool{
        return false
    }
    
    var presentationStyle: UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
    
    func updateInteractiveTransition(_ percentComplete: CGFloat) {
        //Not supported
    }
    
    func finishInteractiveTransition() {
        //Not supported
    }
    
    func cancelInteractiveTransition() {
        //Not supported
    }
    
    func pauseInteractiveTransition() {
        //Not supported
    }
    
    func completeTransition(_ didComplete: Bool) {
        completion!()
    }
    
    func viewController(forKey key: UITransitionContextViewControllerKey) -> UIViewController? {
        switch key {
        case .from:
            return fromVC
        case .to:
            return toVC
        default:
            return nil
        }
    }
    
    func view(forKey key: UITransitionContextViewKey) -> UIView? {
        return nil
    }
    
    var targetTransform: CGAffineTransform {
        return CGAffineTransform.identity
    }
    
    func initialFrame(for vc: UIViewController) -> CGRect {
        return view!.bounds
    }
    
    func finalFrame(for vc: UIViewController) -> CGRect {
        return view!.bounds
    }
}

// MARK: - SlideRevealAnimationController class
class SlideRevealAnimationController: NSObject, UIViewControllerAnimatedTransitioning {
    
    var duration: TimeInterval
    
    init(with duration: TimeInterval) {
        self.duration = duration
        super.init()
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let fromViewController = transitionContext.viewController(forKey: .from)
        let toViewController = transitionContext.viewController(forKey: .to)
        if fromViewController != nil {
            UIView.transition(from: (fromViewController?.view)!, to: (toViewController?.view)!, duration: duration, options: [.transitionCrossDissolve, .overrideInheritedOptions], completion: {(_ finished: Bool) -> Void in
                transitionContext.completeTransition(finished)
            })
        } else {
            let toView = toViewController?.view
            let alpha = toView?.alpha
            toView?.alpha = 0
            UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseOut], animations: {() -> Void in
                toView?.alpha = alpha!
            }, completion: {(_ finshed: Bool) -> Void in
                transitionContext.completeTransition(finshed)
            })
        }
    }
}

// MARK: - SlideRevealPanGestureRecognizer class

class SlideRevealPanGestureRecognizer: UIPanGestureRecognizer {
    var dragging = false
    var beginPoint = CGPoint.zero
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        let touch = touches.first
        beginPoint = (touch?.location(in: view))!
        dragging = false
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        if dragging || state == .failed {
            return
        }
        let kDirectionPanThreshold: CGFloat = 5.0
        let touch = touches.first
        let nowPoint = touch?.location(in: view)
        if (abs((nowPoint?.x)! - (beginPoint.x)) > kDirectionPanThreshold) {
            dragging = true
        } else if abs((nowPoint?.y)! - beginPoint.y) > kDirectionPanThreshold {
            state = .failed
        }
    }
    
}

// MARK: - SlideRevealViewController class
open class SlideRevealViewController: UIViewController, UIGestureRecognizerDelegate, UIViewControllerRestoration
{
    
    
    //MARK: Properties
    //UIViewController instance variables for holding values of each view controller
    var leftViewController: UIViewController?
    var rightViewController: UIViewController?
    var frontViewController: UIViewController?
    //Defines the width of the left  when shown default is 260.0
    var leftViewRevealWidth: CGFloat = 260.0
    //defines the width of the right view when shown default is 260.0
    var rightViewRevealWidth: CGFloat = 260.0
    //Defines how much overdraw can occur when sliding further than leftViewRevealWidth default is 60.0
    var leftViewRevealOverdraw: CGFloat = 60.0
    //Defines how much overdraw can occur when sliding further than leftViewRevealWidth default is 60.0
    var rightViewRevealOverdraw: CGFloat = 60.0
    //Defines how much displacement is applied to the left view when animating or dragging the front view
    //default is 40.0
    var leftViewRevealDisplacement: CGFloat = 40.0
    //Defines how much displacement is applied to the right view when animating or dragging the front view
    //default is 40.0
    var rightViewRevealDisplacement: CGFloat = 40.0
    //Boolean value to determine if the front view should close if pulled open passed the
    //leftViewRevealOverdraw default is true
    var bounceBackOnOverdraw: Bool = true
    //Boolean value to determine if the front view should close if pulled open passed the
    //rightViewRevealOverdraw default is true
    var bounceBackOnLeftOverdraw: Bool = true
    //Boolean value to determine if the front view should be able to be stable if dragged passed the
    //leftViewRevealOverdraw default is false
    var stableDragOnOverdraw: Bool = false
    //Boolean value to determine if the front view should be able to be stable if dragged passed the
    //rightViewRevealOverdraw default is false
    var stableDragOnLeftOverdraw: Bool = false
    //Defines the draggable border width default is 0.0
    var draggableBorderWidth: CGFloat = 0.0
    //Default is false if true the view controller will be offset vertically by the height of the navigation
    //bar
    var isPresentFrontViewHierarchically: Bool = false
    //Velocity required in a pan direction to toggle a view controller default is 250.0
    var quickFlickVelocity: CGFloat = 250.0
    //Duration for animated view controller replacement using the toggle methods default is 0.3
    var toggleAnimationDuration: TimeInterval = 0.3
    //Type of animation for view controller replacement default is spring
    var toggleAnimationType = SlideRevealAnimationType.spring
    //Defines the damping ratio of the spring animation default is 1.0
    var springDampingRatio: CGFloat = 1.0
    //Duration for animated view controller replacement default is 0.25
    var replaceViewAnimationDuration: TimeInterval = 0.25
    //Defines the radius of the front view controller's shadow, default is 2.5.
    var frontViewShadowRadius: CGFloat = 2.5
    //Defines the front view controller's shadow offset, default is {0.0, 2.5}.
    var frontViewShadowOffset =  CGSize(width: CGFloat(0.0), height: CGFloat(2.5))
    //Defines the front view controller's shadow opacity, default is 1.0.
    var frontViewShadowOpacity: CGFloat = 1.0
    //Defines the front view controller's shadow color, default is black.
    var frontViewShadowColor: UIColor = .black
    //Boolean value to determine if subviews are clipped to the bounds of the screen default is false
    var isClipsViewsToBounds: Bool = false
    //Boolean value to determine if extends point inside the view is hit default is true
    var isExtendsPointInsideHit: Bool = false
    //Instance of UIPanGestureRecognizer used to reveal views
    var panGestureRecognizer: UIPanGestureRecognizer?
    //Instance of UITapGestureRecognizer used to hide views
    var tapGestureRecognizer: UITapGestureRecognizer?
    //Insatnce of the SlideRevealViewControllerDelegate
    weak var delegate: SlideRevealViewControllerDelegate?
    //Instance of view position used to hold the front view position
    var frontViewPosition: ViewPosition? = .left
    //Instance of view position used to hold the right view position
    var rightViewPosition: ViewPosition? = .left
    //Instance of view position used to hold the left view position
    var leftViewPosition: ViewPosition? = .left
    //The initial front position used in pan gesture based reveals
    var panInitialFrontPosition: ViewPosition?
    //Instance of the SlideRevealView class
    private var contentView: SlideRevealView?
    //Boolean value used to hold the state of user interaction enabled vs disabled default is true during
    //initilization and changes during pan gestures
    private var userInteractionStore: Bool = true
    //Animation queue array used to hold any animations in queue
    var animationQueue = [Any]()
    
    //MARK: - Initialization
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initDefaultProperties()
    }
    
    convenience init() {
        self.init(with: nil, frontViewController: nil)
    }
    
    init(with rearViewController: UIViewController?, frontViewController: UIViewController?) {
        super.init(nibName: nil, bundle: nil)
        initDefaultProperties()
        performTransitionOperation(SlideRevealViewOperation.replaceLeftController, with: rearViewController, animated: false)
        performTransitionOperation(SlideRevealViewOperation.replaceFrontController, with: frontViewController, animated: false)
    }
    
    func initDefaultProperties() {
        frontViewPosition = .left
        leftViewPosition = .left
        rightViewPosition = .left
        leftViewRevealWidth = 260.0
        leftViewRevealOverdraw = 60.0
        leftViewRevealDisplacement = 40.0
        rightViewRevealWidth = 260.0
        rightViewRevealOverdraw = 60.0
        rightViewRevealDisplacement = 40.0
        bounceBackOnOverdraw = true
        bounceBackOnLeftOverdraw = true
        stableDragOnOverdraw = false
        stableDragOnLeftOverdraw = false
        isPresentFrontViewHierarchically = false
        quickFlickVelocity = 250.0
        toggleAnimationDuration = 0.3
        toggleAnimationType = .spring
        springDampingRatio = 1
        replaceViewAnimationDuration = 0.25
        frontViewShadowRadius = 2.5
        frontViewShadowOffset = CGSize(width: CGFloat(0.0), height: CGFloat(2.5))
        frontViewShadowOpacity = 1.0
        frontViewShadowColor = UIColor.black
        userInteractionStore = true
        animationQueue = [Any]()
        draggableBorderWidth = 0.0
        isClipsViewsToBounds = false
        isExtendsPointInsideHit = false
    }
    
    //MARK: - StatusBar
    func childViewControllerForStatusBarStyles() -> UIViewController {
        let positionDif = (frontViewPosition?.rawValue)! - ViewPosition.left.rawValue
        var controller: UIViewController = frontViewController!
        if positionDif > 0 {
            controller = leftViewController!
            return controller
        } else if positionDif < 0 {
            controller = rightViewController!
            return controller
        }
        return controller
    }
    
    func childViewControllerForStatusBarHidden() -> UIViewController {
        let controller = childViewControllerForStatusBarStyles()
        return controller
    }
    
    //MARK: - View life cycle
    override open func loadView() {
        loadStoryboardControllers()
        let frame = UIScreen.main.bounds
        contentView = SlideRevealView(frame: frame, controller: self)
        contentView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        contentView?.clipsToBounds = isClipsViewsToBounds
        self.view = contentView
        contentView?.addGestureRecognizer(_panGestureRecognizer)
        contentView?.frontView?.addGestureRecognizer(_tapGestureRecognizer)
        contentView?.backgroundColor = UIColor.black
        let initialPosition: ViewPosition = frontViewPosition!
        frontViewPosition = ViewPosition.none
        leftViewPosition = ViewPosition.none
        rightViewPosition = ViewPosition.none
        setFrontViewPosition(newPosition: initialPosition, with: 0.0)
        
    }
    
    override open func viewDidLoad() {
        print("called viewDidLoad")
        panGestureRecognizer = _panGestureRecognizer
        tapGestureRecognizer = _tapGestureRecognizer
        
        super.viewDidLoad()
        
    }
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        userInteractionStore = (contentView?.isUserInteractionEnabled)!
        
    }
    
    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return super.supportedInterfaceOrientations
    }
    
    func setUpGestureRecognizers() {
        var tapGestureRecognizer: UITapGestureRecognizer? {
            let tapGestureRecognizer: UITapGestureRecognizer? = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(recognizer:)))
            tapGestureRecognizer?.delegate = self
            contentView?.frontView?.addGestureRecognizer(tapGestureRecognizer!)
            return tapGestureRecognizer
        }
        self.tapGestureRecognizer = tapGestureRecognizer
        panGestureRecognizer = SlideRevealPanGestureRecognizer(target: self, action: #selector(handleRevealGesture(recognizer:)))
        panGestureRecognizer!.delegate = self
        contentView?.frontView?.addGestureRecognizer(panGestureRecognizer!)
    }
    
    //MARK: - Public methods and property accessors
    public func setFront(viewController: UIViewController?) {
        setFront(viewController: viewController, animated: false)
    }
    
    public func setFront(viewController: UIViewController?, animated: Bool) {
        if !self.isViewLoaded {
            print("isViewLoaded = false")
            performTransitionOperation(.replaceFrontController, with: viewController, animated: false)
            return
        }
        print("isViewLoaded = true")
        dispatchTransition(operation: .replaceFrontController, withNew: viewController, animated: animated)
    }
    
    public func pushFront(viewController: UIViewController, animated: Bool) {
        if !self.isViewLoaded {
            performTransitionOperation(.replaceFrontController, with: viewController, animated: false)
            return
        }
        dispatchPush(frontViewController: viewController, animated: animated)
    }
    
    public func setLeft(viewController: UIViewController?) {
        setLeft(viewController: viewController, animated: false)
    }
    
    public func setLeft(viewController: UIViewController?, animated: Bool) {
        if !self.isViewLoaded {
            performTransitionOperation(.replaceLeftController, with: viewController, animated: false)
            return
        }
        dispatchTransition(operation: .replaceLeftController, withNew: viewController, animated: animated)
    }
    
    public func setRight(viewController: UIViewController?) {
        setRight(viewController: viewController, animated: false)
    }
    
    public func setRight(viewController: UIViewController?, animated: Bool) {
        if !self.isViewLoaded {
            performTransitionOperation(.replaceRightController, with: viewController, animated: false)
            return
        }
        dispatchTransition(operation: .replaceRightController, withNew: viewController, animated: animated)
    }
    
    public func leftRevealToggle(animated: Bool) {
        var toggleViewPosition = ViewPosition.left
        if (frontViewPosition?.rawValue)! <= ViewPosition.left.rawValue {
            toggleViewPosition = ViewPosition.right
        }
        setFront(viewPosition: toggleViewPosition, animated: animated)
    }
    
    public func rightRevealToggle(animated: Bool) {
        var toggleViewPosition = ViewPosition.left
        if (frontViewPosition?.rawValue)! >= ViewPosition.left.rawValue {
            toggleViewPosition = ViewPosition.leftSide
        }
        setFront(viewPosition: toggleViewPosition, animated: animated)
    }
    
    public func setFront(viewPosition: ViewPosition?) {
        setFront(viewPosition: viewPosition, animated: false)
    }
    
    public func setFront(viewPosition: ViewPosition?, animated: Bool) {
        if !self.isViewLoaded {
            frontViewPosition = viewPosition
            leftViewPosition = viewPosition
            rightViewPosition = viewPosition
            return
        }
        dispatchSet(frontViewPosition: viewPosition, animated: animated)
    }
    
    public func setFrontView(shadowOffset: CGSize) {
        frontViewShadowOffset = shadowOffset
        contentView?.reloadShadow()
    }
    
    public func setFrontView(shadowOpacity: CGFloat) {
        frontViewShadowOpacity = shadowOpacity
        contentView?.reloadShadow()
    }
    
    public func setFrontView(shadowColor: UIColor) {
        frontViewShadowColor = shadowColor
        contentView?.reloadShadow()
    }
    
    public var _panGestureRecognizer: UIPanGestureRecognizer {
        if panGestureRecognizer == nil {
            panGestureRecognizer = SlideRevealPanGestureRecognizer(target: self, action: #selector(handleRevealGesture(recognizer:)))
            panGestureRecognizer?.delegate = self
            contentView?.frontView?.addGestureRecognizer(panGestureRecognizer!)
        }
        return panGestureRecognizer!
    }
    
    public var _tapGestureRecognizer: UITapGestureRecognizer {
        if tapGestureRecognizer == nil {
            tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(recognizer:)))
            tapGestureRecognizer?.delegate = self
            contentView?.frontView?.addGestureRecognizer(tapGestureRecognizer!)
        }
        return tapGestureRecognizer!
    }
    
    public func setClipsToBounds(clipsToBounds: Bool) {
        isClipsViewsToBounds = clipsToBounds
        contentView?.clipsToBounds = isClipsViewsToBounds
    }
    
    //MARK: - Provided action methods
    @IBAction public func leftRevealToggle(sender: Any) {
        leftRevealToggle(animated: true)
    }
    
    @IBAction public func rightRevealToggle(sender: Any) {
        rightRevealToggle(animated: true)
    }
    
    //MARK: - User interaction enabling
    func disableUserInteraction() {
        contentView?.isUserInteractionEnabled = false
        contentView?.disableLayout = true
    }
    
    func restoreUserInteraction() {
        contentView?.isUserInteractionEnabled = userInteractionStore
        contentView?.disableLayout = false
    }
    
    //MARK: - Pan gesture progress notification
    func notifyPanGestureBegin() {
        //if delegate != nil {
            var xLocation , dragProgress , overProgress: CGFloat
            xLocation = 0.0
            dragProgress = 0.0
            overProgress = 0.0
            if let delegateMethod = delegate?.panGestureBegan?(self) {
                delegateMethod
            }
            getDragLocation(xLocation: &xLocation, progress: &dragProgress, overdrawProgress: &overProgress)
            if let delegateMethod = delegate?.revealController?(self, panGestureBeganFromLocation: xLocation, progress: dragProgress, overProgress: overProgress) {
                delegateMethod
            }
        //}
    }
    
    func notifyPanGestureMoved() {
        if delegate != nil {
            var xLocation , dragProgress , overProgress: CGFloat
            xLocation = 0.0
            dragProgress = 0.0
            overProgress = 0.0
            getDragLocation(xLocation: &xLocation, progress: &dragProgress, overdrawProgress: &overProgress)
            if (delegate?.responds(to: #selector(delegate?.revealController(_:panGestureMovedToLocation:progress:overProgress:))))! {
                delegate?.revealController!(self, panGestureMovedToLocation: xLocation, progress: dragProgress, overProgress: overProgress)
            }
        }
    }
    
    func notifyPanGestureEnded() {
        if delegate != nil {
            var xLocation , dragProgress , overProgress: CGFloat
            xLocation = 0.0
            dragProgress = 0.0
            overProgress = 0.0
            getDragLocation(xLocation: &xLocation, progress: &dragProgress, overdrawProgress: &overProgress)
            if (delegate?.responds(to: #selector(delegate?.revealController(_:panGestureEndedToLocation:progress:overProgress:))))! {
                delegate?.revealController!(self, panGestureEndedToLocation: xLocation, progress: dragProgress, overProgress: overProgress)
            }
            if (delegate?.responds(to: #selector(delegate?.panGestureEnded(_:))))! {
                delegate?.panGestureEnded!(self)
            }
        }
    }
    
    //MARK: - Symetry
    func getRevealWidth(revealWidth: UnsafeMutablePointer<CGFloat>, revealOverdraw: UnsafeMutablePointer<CGFloat>, symetry: Int) {
        if symetry < 0 {
            revealWidth.pointee = rightViewRevealWidth
            revealOverdraw.pointee = rightViewRevealOverdraw
        } else {
            revealWidth.pointee = leftViewRevealWidth
            revealOverdraw.pointee = leftViewRevealOverdraw
        }
        if revealWidth.pointee < 0 {
            revealWidth.pointee = (contentView?.bounds.size.width)! + revealWidth.pointee
        }
    }
    
    func getBounceBack(bounceBack: UnsafeMutablePointer<Bool>, stableDrag: UnsafeMutablePointer<Bool>, symetry: Int) {
        if symetry < 0 {
            bounceBack.pointee = bounceBackOnLeftOverdraw
            stableDrag.pointee = stableDragOnLeftOverdraw
        } else {
            bounceBack.pointee = bounceBackOnOverdraw
            stableDrag.pointee = stableDragOnOverdraw
        }
    }
    
    func getAdjusted(frontViewPosition: UnsafeMutablePointer<ViewPosition>, symetry: Int) {
        if symetry < 0 {
            frontViewPosition.pointee = ViewPosition(rawValue: ViewPosition.left.rawValue + symetry * (frontViewPosition.pointee.rawValue - ViewPosition.left.rawValue))!
        }
    }
    
    func getDragLocation(xLocation: UnsafeMutablePointer<CGFloat>, progress: UnsafeMutablePointer<CGFloat>) {
        let frontView = contentView?.frontView
        xLocation.pointee = (frontView?.frame.origin.x)!
        let symetry = xLocation.pointee < 0 ? -1 : 1
        var xWidth: CGFloat = CGFloat(symetry) < 0 ? rightViewRevealWidth : leftViewRevealWidth
        if xWidth < 0 {
            xWidth = (contentView?.bounds.size.width)! + xWidth
        }
        progress.pointee = xLocation.pointee / xWidth * CGFloat(symetry)
    }
    
    func getDragLocation(xLocation: UnsafeMutablePointer<CGFloat>, progress: UnsafeMutablePointer<CGFloat>, overdrawProgress: UnsafeMutablePointer<CGFloat>) {
        let frontView = contentView?.frontView
        xLocation.pointee = (frontView?.frame.origin.x)!
        let symetry = xLocation.pointee < 0 ? -1 : 1
        var xWidth: CGFloat = CGFloat(symetry) < 0 ? rightViewRevealWidth : leftViewRevealWidth
        let xOverWidth: CGFloat = CGFloat(symetry) < 0 ? rightViewRevealOverdraw : leftViewRevealOverdraw
        if xWidth < 0 {
            xWidth = (contentView?.bounds.size.width)! + xWidth
        }
        progress.pointee = (xLocation.pointee * CGFloat(symetry) / xWidth)
        overdrawProgress.pointee = ((xLocation.pointee * CGFloat(symetry) - xWidth) / xOverWidth)
    }
    
    //MARK: - Deferred block execution queue
    // Defines a convienience macro to enqueue single statements
    func enqueue(code: Any) {
        return enqueueBlock({() -> Void in
        })
    }
    
    //Enqueue Block
    func enqueueBlock(_ block: @escaping () -> Void) {
        animationQueue.insert(block, at: 0)
        if animationQueue.count == 1 {
            block()
        }
    }
    
    //Dequeue
    func dequeue() {
        if animationQueue.count > 0 {
            animationQueue.removeLast()
            if animationQueue.count > 0 {
                let block: (() -> Void)?? = animationQueue.last as? (() -> Void)
                block!!()
            }
        }
    }
    
    //MARK: - UIGestureRecognizer Delegate
    private func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if animationQueue.count == 0 {
            print(animationQueue)
            if gestureRecognizer == panGestureRecognizer {
                return panGestureShouldBegin()
            }
            if gestureRecognizer == tapGestureRecognizer {
                return tapGestureShouldBegin()
            }
        }
        return false
    }
    
    private func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == panGestureRecognizer {
            //if delegate != nil {
                if delegate?.panGestureRecognizesSimutaneouslyWith?(otherGestureRecognizer, revealController: self) == true {
                    return true
                }
            //}
        }
        if gestureRecognizer == tapGestureRecognizer {
            //if delegate != nil {
                if delegate?.tapGestureRecognizesSimutaneouslyWith?(otherGestureRecognizer, revealController: self) == true {
                    return true
                }
            //}
        }
        return false
    }
    
    func tapGestureShouldBegin() -> Bool {
        if frontViewPosition == .left || frontViewPosition == .rightSideMostRemoved || frontViewPosition == .leftSideMostRemoved {
            return false
        }
        //if delegate != nil {
        if delegate?.tapGestureRecognizerShouldBegin?(self) == false{
                return false
            }
        //}
        return true
    }
    
    func panGestureShouldBegin() -> Bool {
        let recognizerView = panGestureRecognizer?.view
        let translation: CGPoint = (panGestureRecognizer?.translation(in: recognizerView))!
        //if delegate != nil {
            if delegate?.panGestureRecognizerShouldBegin?(self) == false {
                return false
            }
        //}
        let xLocation: CGFloat = (panGestureRecognizer?.location(in: recognizerView).x)!
        let width = recognizerView?.bounds.size.width
        let draggableBorderAllowing = (
            draggableBorderWidth == 0.0 || (leftViewController != nil && xLocation <= draggableBorderWidth) || (rightViewController != nil &&  xLocation >= (width! - draggableBorderWidth))
        )
        let translationForbidding = (
            frontViewPosition == .left && ((leftViewController == nil && translation.x > 0) || (rightViewController == nil && translation.x < 0))
        )
        return  draggableBorderAllowing && !translationForbidding
    }
    
    //MARK: - Gesture based reveal
    @objc func handleTapGesture(recognizer: UITapGestureRecognizer) {
        let duration = toggleAnimationDuration
        setFrontViewPosition(newPosition: .left, with: duration)
    }
    
    @objc func handleRevealGesture(recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .began:
            handleRevealGestureStateBegin(recognizer: recognizer)
        case .changed:
            handleRevealGestureStateChanged(recognizer: recognizer)
        case .ended:
            handleRevealGestureStateEnded(recognizer: recognizer)
        case .cancelled:
            handleRevealGestureStateCancelled(recognizer: recognizer)
        default:
            break
        }
    }
    
    func handleRevealGestureStateBegin(recognizer: UIPanGestureRecognizer) {
        enqueueBlock {
        }
        panInitialFrontPosition = frontViewPosition
        disableUserInteraction()
        notifyPanGestureBegin()
    }
    
    func handleRevealGestureStateChanged(recognizer: UIPanGestureRecognizer) {
        let xTranslation = recognizer.translation(in: contentView).x
        let baseXLocation = contentView?.frontLocation(for: panInitialFrontPosition!)
        var xLocation = baseXLocation! + xTranslation
        if xLocation < 0 {
            if rightViewController == nil {
                xLocation = 0
            }
            rightViewDeploymentFor(newPosition: .leftSide)()
            leftViewDeploymentFor(newPosition: .leftSide)()
        }
        if xLocation > 0 {
            if leftViewController == nil {
                xLocation = 0
            }
            rightViewDeploymentFor(newPosition: .right)()
            leftViewDeploymentFor(newPosition: .right)()
        }
        contentView?.dragFrontViewTo(xLocation: xLocation)
        notifyPanGestureMoved()
    }
    
    func handleRevealGestureStateEnded(recognizer: UIPanGestureRecognizer) {
        let frontView = contentView?.frontView
        var xLocation: CGFloat = (frontView?.frame.origin.x)!
        let velocity = recognizer.velocity(in: contentView).x
        let symetry: Int = Int(xLocation) < 0 ? -1 : 1
        var revealWidth: CGFloat = 0.0
        var revealOverdraw: CGFloat = 0.0
        var bounceBack = false
        var stableDrag = false
        getRevealWidth(revealWidth: &revealWidth, revealOverdraw: &revealOverdraw, symetry: symetry)
        getBounceBack(bounceBack: &bounceBack, stableDrag: &stableDrag, symetry: symetry)
        xLocation = xLocation * CGFloat(symetry)
        var frontViewPosition: ViewPosition
        frontViewPosition = ViewPosition.left
        var duration = toggleAnimationDuration
        if abs(velocity) > quickFlickVelocity {
            var journey = xLocation
            if (velocity * CGFloat(symetry)) > 0.0 {
                frontViewPosition = ViewPosition.right
                journey = revealWidth - xLocation
                if xLocation > revealWidth {
                    if !bounceBack && stableDrag {
                        frontViewPosition = ViewPosition.rightSideMostRemoved
                        journey = revealWidth + revealOverdraw - xLocation
                    }
                }
            }
            duration = abs(Double(journey / velocity))
        }
        else {
            if xLocation > revealWidth * 0.5 {
                frontViewPosition = ViewPosition.right
                if xLocation > revealWidth {
                    if bounceBack {
                        frontViewPosition = ViewPosition.left
                    }
                    else if stableDrag && xLocation > revealWidth + revealOverdraw * 0.5 {
                        frontViewPosition = ViewPosition.rightMost
                    }
                }
            }
        }
        getAdjusted(frontViewPosition: &frontViewPosition, symetry: symetry)
        restoreUserInteraction()
        notifyPanGestureEnded()
        setFrontViewPosition(newPosition: frontViewPosition, with: duration)
    }
    
    func handleRevealGestureStateCancelled(recognizer: UIPanGestureRecognizer) {
        restoreUserInteraction()
        notifyPanGestureEnded()
        dequeue()
    }
    
    //MARK: - Enqueue position and controller setup
    func dispatchSet(frontViewPosition: ViewPosition?, animated: Bool) {
        let duration = animated ? toggleAnimationDuration : 0.0
        weak var theSelf: SlideRevealViewController? = self
        enqueue(code: theSelf!.setFrontViewPosition(newPosition: frontViewPosition, with: duration))
    }
    
    func dispatchPush(frontViewController: UIViewController, animated: Bool) {
        var preReplacementPosition = ViewPosition.left
        if (frontViewPosition?.rawValue)! > ViewPosition.left.rawValue {
            preReplacementPosition = .rightMost
        }
        if (frontViewPosition?.rawValue)! < ViewPosition.left.rawValue {
            preReplacementPosition = .leftSideMost
        }
        let duration = animated ? toggleAnimationDuration : 0.0
        var firstDuration = duration
        let initialPosDif = abs((frontViewPosition?.rawValue)! - preReplacementPosition.rawValue)
        if initialPosDif == 1 {
            firstDuration *= 0.8
        }
        else if initialPosDif == 0 {
            firstDuration = 0
        }
        weak var theSelf: SlideRevealViewController? = self
        if animated {
            enqueue(code: theSelf!.setFrontViewPosition(newPosition: preReplacementPosition, with: firstDuration))
            enqueue(code: theSelf!.performTransitionOperation(.replaceFrontController, with: frontViewController, animated: false))
            enqueue(code: theSelf!.setFrontViewPosition(newPosition: .left, with: duration))
        }
        else {
            enqueue(code: theSelf!.performTransitionOperation(.replaceFrontController, with: frontViewController, animated: false))
        }
    }
    
    func dispatchTransition(operation: SlideRevealViewOperation, withNew viewController: UIViewController?, animated: Bool) {
        weak var theSelf: SlideRevealViewController? = self
        enqueue(code: theSelf!.performTransitionOperation(operation, with: viewController, animated: animated))
    }
    
    //MARK: - Animated view controller deployment and layout
    func setFrontViewPosition(newPosition: ViewPosition?, with duration: TimeInterval) {
        let leftDeploymentCompletion = leftViewDeploymentFor(newPosition: newPosition)
        let rightDeploymentCompletion = rightViewDeploymentFor(newPosition: newPosition)
        let frontDeploymentCompletion = frontViewDeploymentFor(newPosition: newPosition)
        let animations = {() -> Void in
            self.setNeedsStatusBarAppearanceUpdate()
            self.contentView?.layoutSubviews()
            if self.delegate != nil {
                if (self.delegate?.responds(to: #selector(self.delegate?.revealController(_:animateTo:))))! {
                    self.delegate?.revealController!(self, animateTo: self.frontViewPosition!)
                }
            }
        }
        let completion: ((_: Bool) -> Void) = {(_ finished: Bool) -> Void in
            leftDeploymentCompletion()
            rightDeploymentCompletion()
            frontDeploymentCompletion()
            self.dequeue()
        }
        if duration > 0.0 {
            if toggleAnimationType == SlideRevealAnimationType.easeout {
                UIView.animate(withDuration: duration, delay: 0.0, options: [.curveEaseOut], animations: animations, completion: completion)
            }
            else {
                UIView.animate(withDuration: toggleAnimationDuration, delay: 0.0, usingSpringWithDamping: springDampingRatio, initialSpringVelocity: CGFloat(1.0 / duration), options: [], animations: animations, completion: completion)
            }
        }
        else {
            animations()
            completion(true)
        }
    }
    
    func performTransitionOperation(_ operation: SlideRevealViewOperation, with viewController: UIViewController?, animated: Bool) {
        if delegate != nil {
            if (delegate?.responds(to: #selector(delegate?.revealController(_:willAdd:forOperation:animated:))))! {
                delegate?.revealController!(self, willAdd: viewController, forOperation: operation, animated: animated)
            }
        }
        var old: UIViewController?
        var view: UIView?
        if operation == SlideRevealViewOperation.replaceLeftController {
            old = leftViewController
            leftViewController = viewController
            view = contentView?.leftView
        }
        else if operation == SlideRevealViewOperation.replaceFrontController {
            old = frontViewController
            frontViewController = viewController
            view = (contentView?.frontView)
        }
        else if operation == SlideRevealViewOperation.replaceRightController {
            old = rightViewController
            rightViewController = viewController
            view = (contentView?.rightView)
        }
        let completion = transition(fromViewController: old, toViewController: viewController, in: view)
        let animationCompletion = {() -> Void in
            completion()
            if self.delegate != nil {
                if (self.delegate?.responds(to: #selector(self.delegate?.revealController(_:didAdd:forOperation:animated:))))! {
                    self.delegate?.revealController!(self, didAdd: viewController, forOperation: operation, animated: animated)
                    self.dequeue()
                }
            }
        }
        if animated {
            var animationController = SlideRevealAnimationController(with: replaceViewAnimationDuration)
            if delegate != nil {
                print("delegate is not nil")
                if (delegate?.responds(to: #selector(delegate?.revealController(_:animationControllerFor:from:to:))))! {
                    print("resonded to delegate")
                    animationController = (delegate?.revealController!(self, animationControllerFor: operation, from: old, to: viewController))! as! SlideRevealAnimationController
                }
            }
            let transitionObject = SlideRevealContextTransitioningObject(revealController: self, containerView: view, fromVC: old!, toVC: viewController, completion: animationCompletion)
            if (animationController.transitionDuration(using: transitionObject)) > TimeInterval(0) {
                    animationController.animateTransition(using: transitionObject)
            }
            else {
                animationCompletion()
            }
            
        }
        else {
            animationCompletion()
        }
    }
    
    //MARK: - position based view controller deployment
    // Deploy/Undeploy of the front view controller following the containment principles. Returns a block
    // that must be invoked on animation completion in order to finish deployment
    func frontViewDeploymentFor(newPosition: ViewPosition?) -> () -> Void {
        var newPosition = newPosition
        if rightViewController == nil && (newPosition?.rawValue)! < ViewPosition.left.rawValue || leftViewController == nil && (newPosition?.rawValue)! > ViewPosition.left.rawValue {
            newPosition = ViewPosition(rawValue: ViewPosition.left.rawValue)!
        }
        let positionIsChanging = frontViewPosition?.rawValue != newPosition?.rawValue
        let appear = ((frontViewPosition?.rawValue)! >= ViewPosition.rightSideMostRemoved.rawValue || (frontViewPosition?.rawValue)! <= ViewPosition.leftSideMostRemoved.rawValue || frontViewPosition?.rawValue == ViewPosition.none.rawValue) && ((newPosition!.rawValue) < ViewPosition.rightSideMostRemoved.rawValue && (newPosition!.rawValue) > ViewPosition.leftSideMostRemoved.rawValue)
        let disappear = ((newPosition?.rawValue)! >= ViewPosition.rightSideMostRemoved.rawValue || newPosition!.rawValue <= ViewPosition.leftSideMostRemoved.rawValue) && ((frontViewPosition?.rawValue)! < ViewPosition.rightSideMostRemoved.rawValue && (frontViewPosition?.rawValue)! > ViewPosition.leftSideMostRemoved.rawValue && frontViewPosition?.rawValue != ViewPosition.none.rawValue)
        if positionIsChanging {
            if delegate != nil {
                if (delegate?.responds(to: #selector(delegate?.revealController(_:willMoveTo:))))! {
                    delegate?.revealController!(self, willMoveTo: newPosition!)
                }
            }
        }
        frontViewPosition = newPosition
        let deploymentCompletion: (() -> Void) = deploymentFor(viewController: frontViewController, in: contentView?.frontView, appear: appear, disappear: disappear)
        let completion: (() -> Void) = {() -> Void in
            deploymentCompletion()
            if positionIsChanging {
                if self.delegate != nil {
                    if (self.delegate?.responds(to: #selector(self.delegate?.revealController(_:didMoveTo:))))! {
                        self.delegate?.revealController!(self, didMoveTo: newPosition!)
                    }
                }
            }
        }
        return completion
    }
    
    // Deploy/Undeploy of the left view controller following the containment principles. Returns a block
    // that must be invoked on animation completion in order to finish deployment
    func leftViewDeploymentFor(newPosition: ViewPosition?) -> () -> Void {
        var newPosition = newPosition
        if isPresentFrontViewHierarchically {
            newPosition = ViewPosition.right
        }
        if leftViewController == nil && newPosition!.rawValue > ViewPosition.left.rawValue {
            newPosition = ViewPosition.left
        }
        let appear = ((leftViewPosition?.rawValue)! <= ViewPosition.left.rawValue || leftViewPosition?.rawValue == ViewPosition.none.rawValue) && (newPosition?.rawValue)! > ViewPosition.left.rawValue
        let disappear = (newPosition?.rawValue)! <= ViewPosition.left.rawValue && ((leftViewPosition?.rawValue)! > ViewPosition.left.rawValue && leftViewPosition?.rawValue != ViewPosition.none.rawValue)
        if appear {
            contentView?.prepareLeftView(for: newPosition!)
        }
        leftViewPosition = newPosition
        let deploymentCompletion: (() -> Void) = deploymentFor(viewController: leftViewController, in: contentView?.leftView, appear: appear, disappear: disappear)
        let completion: (() -> Void) = {() -> Void in
            deploymentCompletion()
            if disappear {
                self.contentView?.unloadLeftView()
            }
        }
        return completion
    }
    // Deploy/Undeploy of the right view controller following the containment principles. Returns a block
    // that must be invoked on animation completion in order to finish deployment
    func rightViewDeploymentFor(newPosition: ViewPosition?) -> () -> Void {
        var newPosition = newPosition
        if rightViewController == nil && (newPosition?.rawValue)! < ViewPosition.left.rawValue {
            newPosition = ViewPosition.left
        }
        let appear = ((rightViewPosition?.rawValue)! >= ViewPosition.left.rawValue || rightViewPosition?.rawValue == ViewPosition.none.rawValue) && (newPosition?.rawValue)! < ViewPosition.left.rawValue
        let disappear = (newPosition?.rawValue)! >= ViewPosition.left.rawValue && ((rightViewPosition?.rawValue)! < ViewPosition.left.rawValue && rightViewPosition?.rawValue != ViewPosition.none.rawValue)
        if appear {
            contentView?.prepareRightView(for: newPosition!)
        }
        rightViewPosition = newPosition
        let deploymentCompletion: (() -> Void) = deploymentFor(viewController: rightViewController, in: (contentView?.rightView), appear: appear, disappear: disappear)
        let completion: (() -> Void) = {() -> Void in
            deploymentCompletion()
            if disappear {
                self.contentView?.unloadRightView()
            }
        }
        return completion
        
    }
    
    func deploymentFor(viewController: UIViewController?, in view: UIView?, appear: Bool, disappear: Bool) -> () -> Void {
        if appear {
            return deployFor(viewController: viewController, in: view)
        }
        if disappear {
            return undeployFor(viewController: viewController)
        }
        return {
            () -> Void in
        }
    }
    
    //MARK: - Containment view controller deployment and transistion
    
    // Containment Deploy method. Returns a block to be invoked at the
    // animation completion, or right after return in case of non-animated deployment.
    func deployFor(viewController: UIViewController?, in view: UIView?) -> () -> Void {
        if viewController == nil || view == nil {
            return {
                () -> Void in
            }
        }
        let frame = view?.bounds
        let controllerView = viewController?.view
        controllerView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        controllerView?.frame = frame!
        //if controllerView != nil {
            if (controllerView?.isKind(of: UIScrollView.self))! {
                let adjust = viewController?.automaticallyAdjustsScrollViewInsets
                if adjust! {
                    ((viewController as Any) as! UIScrollView).contentInset = UIEdgeInsets(top: statusBarAdjustment(contentView!), left: 0, bottom: 0, right: 0)
                }
            }
        //}
        view?.addSubview(controllerView!)
        let completion = {() -> Void in
            //nothing to do at this point
        }
        return completion
    }
    
    // Containment Undeploy method. Returns a block to be invoked at the
    // animation completion, or right after return in case of non-animated deployment.
    func undeployFor(viewController: UIViewController?) -> () -> Void {
        if viewController?.isViewLoaded == false {
            return {() -> Void in
            }
        }
        let completion = {() -> Void in
            viewController?.view.removeFromSuperview()
        }
        return completion
    }
    
    // Containment Transition method. Returns a block to be invoked at the
    // animation completion, or right after return in case of non-animated transition.
    func transition(fromViewController: UIViewController?, toViewController: UIViewController?, in view: UIView?) -> () -> Void {
        if fromViewController == toViewController {
            return {() -> Void in
            }
        }
        if toViewController != nil {
            addChild(toViewController!)
        }
        let deployCompletion = deployFor(viewController: toViewController, in: view)
        fromViewController?.willMove(toParent: nil)
        let undeployCompletion = undeployFor(viewController: fromViewController)
        let completionBlock: (() -> Void) = {() -> Void in
            undeployCompletion()
            fromViewController?.removeFromParent()
            deployCompletion()
            toViewController?.didMove(toParent: self)
        }
        return completionBlock
    }
    
    // Load any defined front/rear controllers from the storyboard
    // This method is intended to be overrided in case the default behavior will not meet your needs
    func loadStoryboardControllers() {
        if self.storyboard != nil && leftViewController == nil {
            defer{
                if doesSegueExist(identifier: slideLeftIdentifier) {
                    performSegue(withIdentifier: slideLeftIdentifier, sender: nil)
                }
            }
            defer {
                if doesSegueExist(identifier: slideFrontIdentifier) {
                    performSegue(withIdentifier: slideFrontIdentifier, sender: nil)
                }
                
            }
            defer {
                if doesSegueExist(identifier: slideRightIdentifier) {
                    performSegue(withIdentifier: slideRightIdentifier, sender: nil)
                }
            }
        }
    }
    
    func doesSegueExist(identifier: String) -> Bool {
        let segues = value(forKey: "storyboardSegueTemplates") as? [NSObject]
        guard let filteredSegues = segues?.filter({ $0.value(forKey: "identifier") as? String == identifier})
            else {
                return false
        }
        return filteredSegues.count > 0
    }
    
    //MARK: state preservation and restoration
    
    //MARK: UIViewControllerRestoration delegate method
    public static func viewController(withRestorationIdentifierPath identifierComponents: [String], coder: NSCoder) -> UIViewController? {
        var viewController: SlideRevealViewController? = nil
        let storyboard = coder.decodeObject(forKey: UIApplication.stateRestorationViewControllerStoryboardKey) as? UIStoryboard
        if storyboard != nil {
            viewController = storyboard?.instantiateViewController(withIdentifier: "SlideRevealViewController") as? SlideRevealViewController
            viewController?.restorationIdentifier = identifierComponents.last
            viewController?.restorationClass = SlideRevealViewController.self
        }
        return viewController
    }
 

    override open func encodeRestorableState(with coder: NSCoder) {
        coder.encode(Double(leftViewRevealWidth), forKey: "leftViewRevealWidth")
        coder.encode(Double(leftViewRevealOverdraw), forKey: "leftViewRevealOverdraw")
        coder.encode(Double(leftViewRevealDisplacement), forKey: "leftViewRevealDisplacement")
        coder.encode(Double(rightViewRevealWidth), forKey: "rightViewRevealWidth")
        coder.encode(Double(rightViewRevealOverdraw), forKey: "rightViewRevealOverdraw")
        coder.encode(Double(rightViewRevealDisplacement), forKey: "rightViewRevealDisplacement")
        coder.encode(bounceBackOnOverdraw, forKey: "bounceBackOnOverdraw")
        coder.encode(bounceBackOnLeftOverdraw, forKey: "bounceBackOnLeftOverdraw")
        coder.encode(stableDragOnOverdraw, forKey: "stableDragOnOverdraw")
        coder.encode(stableDragOnLeftOverdraw, forKey: "stableDragOnLeftOverdraw")
        coder.encode(isPresentFrontViewHierarchically, forKey: "presentFrontViewHierarchically")
        coder.encode(Double(quickFlickVelocity), forKey: "quickFlickVelocity")
        coder.encode(Double(toggleAnimationDuration), forKey: "toggleAnimationDuration")
        coder.encode(toggleAnimationType.rawValue, forKey: "toggleAnimationType")
        coder.encode(Double(springDampingRatio), forKey: "springDampingRatio")
        coder.encode(Double(replaceViewAnimationDuration), forKey: "replaceViewAnimationDuration")
        coder.encode(Double(frontViewShadowRadius), forKey: "frontViewShadowRadius")
        coder.encode(frontViewShadowOffset, forKey: "frontViewShadowOffset")
        coder.encode(Double(frontViewShadowOpacity), forKey: "frontViewShadowOpacity")
        coder.encode(frontViewShadowColor, forKey: "frontViewShadowColor")
        coder.encode(userInteractionStore, forKey: "userInteractionStore")
        coder.encode(Double(draggableBorderWidth), forKey: "draggableBorderWidth")
        coder.encode(isClipsViewsToBounds, forKey: "clipsViewsToBounds")
        coder.encode(isExtendsPointInsideHit, forKey: "extendsPointInsideHit")
        coder.encode(leftViewController, forKey: "leftViewController")
        coder.encode(frontViewController, forKey: "frontViewController")
        coder.encode(rightViewController, forKey: "rightViewController")
        coder.encode(Int(frontViewPosition!.rawValue), forKey: "frontViewPosition")
        super.encodeRestorableState(with: coder)
    }
    
    override open func decodeRestorableState(with coder: NSCoder) {
        print("called decodeRestorableState")
        leftViewRevealWidth = CGFloat(coder.decodeDouble(forKey: "leftViewRevealWidth"))
        leftViewRevealOverdraw = CGFloat(coder.decodeDouble(forKey: "leftViewRevealOverdraw"))
        leftViewRevealDisplacement = CGFloat(coder.decodeDouble(forKey: "leftViewRevealDisplacement"))
        rightViewRevealWidth = CGFloat(coder.decodeDouble(forKey: "rightViewRevealWidth"))
        rightViewRevealOverdraw = CGFloat(coder.decodeDouble(forKey: "rightViewRevealOverdraw"))
        rightViewRevealDisplacement = CGFloat(coder.decodeDouble(forKey: "rightViewRevealDisplacement"))
        bounceBackOnOverdraw = coder.decodeBool(forKey: "bounceBackOnOverdraw")
        bounceBackOnLeftOverdraw = coder.decodeBool(forKey: "bounceBackOnLeftOverdraw")
        stableDragOnOverdraw = coder.decodeBool(forKey: "stableDragOnOverdraw")
        stableDragOnLeftOverdraw = coder.decodeBool(forKey: "stableDragOnLeftOverdraw")
        isPresentFrontViewHierarchically = coder.decodeBool(forKey: "presentFrontViewHierarchically")
        quickFlickVelocity = CGFloat(coder.decodeDouble(forKey: "quickFlickVelocity"))
        toggleAnimationDuration = coder.decodeDouble(forKey: "toggleAnimationDuration")
        toggleAnimationType = SlideRevealAnimationType(rawValue: coder.decodeInteger(forKey: "toggleAnimationType"))!
        springDampingRatio = CGFloat(coder.decodeDouble(forKey: "springDampingRatio"))
        replaceViewAnimationDuration = coder.decodeDouble(forKey: "replaceViewAnimationDuration")
        frontViewShadowRadius = CGFloat(coder.decodeDouble(forKey: "frontViewShadowRadius"))
        frontViewShadowOffset = coder.decodeCGSize(forKey: "frontViewShadowOffset")
        frontViewShadowOpacity = CGFloat(coder.decodeDouble(forKey: "frontViewShadowOpacity"))
        frontViewShadowColor = coder.decodeObject(forKey: "frontViewShadowColor") as? UIColor ?? UIColor.black
        userInteractionStore = coder.decodeBool(forKey: "userInteractionStore")
        animationQueue = [Any]()
        draggableBorderWidth = CGFloat(coder.decodeDouble(forKey: "draggableBorderWidth"))
        isClipsViewsToBounds = coder.decodeBool(forKey: "clipsViewsToBounds")
        isExtendsPointInsideHit = coder.decodeBool(forKey: "extendsPointInsideHit")
        //leftViewController = coder.decodeObject(forKey: "leftViewController") as? UIViewController
        //frontViewController = coder.decodeObject(forKey: "frontViewController") as? UIViewController
        //rightViewController = coder.decodeObject(forKey: "rightViewController") as? UIViewController
        setLeft(viewController: leftViewController)
        setFront(viewController: frontViewController)
        setRight(viewController: rightViewController)
        //frontViewPosition = ViewPosition(rawValue: coder.decodeInteger(forKey: "frontViewPosition"))
        setFront(viewPosition: frontViewPosition!)
        //panGestureRecognizer = _panGestureRecognizer
        //tapGestureRecognizer = _tapGestureRecognizer
        super.decodeRestorableState(with: coder)
        
    }
    
    override open func applicationFinishedRestoringState() {
        
        
    }
    
}

// MARK: - Global constants
let slideLeftIdentifier = "slide_left" //Segue identifier for view controller appearing on the left
let slideFrontIdentifier = "slide_front" //Segue identifier for the front (main) view controller
let slideRightIdentifier = "slide_right" //Segue identifier for the view controller appearing on the right

// MARK: - Extension of UIViewController to help with parent controller presentation
public extension UIViewController {
    public func revealViewController() -> SlideRevealViewController? {
        var parent: UIViewController? = self
        if parent != nil && parent is SlideRevealViewController {
            return parent as? SlideRevealViewController
        }
        while (!(parent is SlideRevealViewController) && parent?.parent != nil) {
            parent = parent?.parent
        }
        if parent is SlideRevealViewController {
            return parent as? SlideRevealViewController
        }
        return nil
    }
}

// MARK: - SlideRevealViewControllerSegueSetController class
class SlideRevealViewControllerSegueSetController: UIStoryboardSegue {
    
    override func perform() {
        var operation: SlideRevealViewOperation = .none
        let identifier: String = self.identifier!
        let rvc: SlideRevealViewController? = self.source as? SlideRevealViewController
        let dvc: UIViewController? = self.destination
        if (identifier == slideFrontIdentifier) {
            operation = SlideRevealViewOperation.replaceFrontController
        }
        else if (identifier == slideLeftIdentifier) {
            operation = SlideRevealViewOperation.replaceLeftController
        }
        else if (identifier == slideRightIdentifier) {
            operation = SlideRevealViewOperation.replaceRightController
        }
        
        if operation != SlideRevealViewOperation.none {
            rvc?.performTransitionOperation(operation, with: dvc!, animated: false)
        }
    }
}

// MARK: - SlideRevealViewControllerSeguePushController class
class SlideRevealViewControllerSeguePushController: UIStoryboardSegue {
    
    override func perform() {
        let rvc: SlideRevealViewController? = self.source.revealViewController()
        let dvc: UIViewController? = self.destination
        rvc?.pushFront(viewController: dvc!, animated: true)
    }
}

