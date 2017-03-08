//
//  OnboardingContainerViewController.swift
//  8Yet
//
//  Created by Quan Ding on 3/30/15.
//  Copyright (c) 2015 EightYet. All rights reserved.
//

import UIKit

class OnboardingContainerViewController: BaseViewController, UIViewControllerTransitioningDelegate {
    fileprivate var onboardingStep1VC: OnboardingStep1ViewController!
    fileprivate var onboardingStep2VC: OnboardingStep2ViewController!
    fileprivate var onboardingVCs: [UIViewController]!
    fileprivate var currentVC:UIViewController!
    
    lazy var animator:PageControllAnimator = PageControllAnimator()
    
    @IBOutlet weak var btnNext: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let storyBoard = UIStoryboard(name: "Onboarding", bundle: nil)
        onboardingStep1VC = storyBoard.instantiateViewController(withIdentifier: "onboardingStep1") as! OnboardingStep1ViewController
        onboardingStep2VC = storyBoard.instantiateViewController(withIdentifier: "onboardingStep2") as! OnboardingStep2ViewController
        onboardingVCs = [onboardingStep1VC, onboardingStep2VC]
        
        ViewHelpers.roundedCorner(btnNext, radius: 5)
        btnNext.titleLabel?.font = UIFont(name: serifMediumFontName, size: 30 * screenSizeMultiplier)
    }

    override func viewDidAppear(_ animated: Bool) {
        transitionViewControllers(nil, toVC: onboardingStep1VC)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - IBActions
    
    @IBAction func onBtnNext(_ sender: UIButton) {
        Analytics.sharedInstance.event(Analytics.Event.OnboardingNextBtnClicked.rawValue, properties: ["currentStep": String(type(of: self.currentVC))])
        switch currentVC {
        case onboardingStep1VC:
            transitionViewControllers(onboardingStep1VC, toVC: onboardingStep2VC)
        case onboardingStep2VC:
            NotificationCenter.default.post(name: Notification.Name(rawValue: onboardingFinishedNotification), object: nil)
            transitionViewControllers(onboardingStep2VC, toVC: nil)
        default:
            (); //nothing to do
        }
    }
    
    // MARK: - UIViewControllerTransitioningDelegate
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return animator;
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return animator;
    }

    // MARK: - Private functions
    
    fileprivate func transitionViewControllers(_ fromVC: UIViewController?, toVC: UIViewController?){
        
        // if fromVC is not given, toVC is the step1 VC, not need for animation
        // just present it
        if fromVC == nil {
            if let toVC = toVC {
                self.addChildViewController(toVC)
                self.view.insertSubview(toVC.view, at: 0)
                toVC.didMove(toParentViewController: self)
                toVC.view.frame = self.view.bounds
                self.currentVC = toVC
            }
            return
        }
        if toVC == nil {
            if let fromVC = fromVC {
                fromVC.willMove(toParentViewController: nil)
                fromVC.view.removeFromSuperview()
                fromVC.didMove(toParentViewController: nil)
                fromVC.removeFromParentViewController()
            }
            return
        }
        let fromVC = fromVC!
        let toVC = toVC!
        
        fromVC.willMove(toParentViewController: nil)
        self.addChildViewController(toVC)
        self.view.insertSubview(toVC.view, at: 0)
        toVC.view.frame = self.view.bounds
        self.currentVC = toVC

        let fromVCIndex = self.onboardingVCs.index(of: fromVC)
        let toVCIndex = self.onboardingVCs.index(of: toVC)
        let transitionCxt = PrivateTransitionContext(fromViewController: fromVC, toViewcontroller: toVC, goingRight: fromVCIndex! < toVCIndex!)
        transitionCxt.completion = {(didComplete: Bool) -> Void in
            fromVC.view.removeFromSuperview()
            fromVC.didMove(toParentViewController: nil)
            fromVC.removeFromParentViewController()
            toVC.didMove(toParentViewController: self)
        }
        animator.animateTransition(using: transitionCxt)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

class PageControllAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.4
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let fromVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)!
        let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)!

        fromVC.view.frame = transitionContext.initialFrame(for: fromVC)
        toVC.view.frame = transitionContext.initialFrame(for: toVC)
        
        // apply the animation
        UIView.animate(withDuration: 0.4, animations: { () -> Void in
            fromVC.view.frame = transitionContext.finalFrame(for: fromVC)
            toVC.view.frame = transitionContext.finalFrame(for: toVC)
            }, completion: { (finished) in
                // call completion handler
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
}

class PrivateTransitionContext: NSObject, UIViewControllerContextTransitioning {
    var completion: ((Bool) -> Void)?
    fileprivate var _containerView:UIView!
    fileprivate var appearingToRect:CGRect!
    fileprivate var disappearingToRect: CGRect!
    fileprivate var appearingFromRect: CGRect!
    fileprivate var disappearingFromRect: CGRect!
    fileprivate var viewControllers: Dictionary<String, UIViewController> = Dictionary<String, UIViewController>()
    
    init(fromViewController: UIViewController, toViewcontroller: UIViewController, goingRight: Bool) {
        assert(fromViewController.isViewLoaded && fromViewController.view.superview != nil, "The fromViewController view must reside in the container view upon initializing the transition context.")
        super.init()
        self._containerView = fromViewController.view.superview
        viewControllers[UITransitionContextViewControllerKey.from] = fromViewController
        viewControllers[UITransitionContextViewControllerKey.to] = toViewcontroller
        
        let travelDistance = (goingRight ? -_containerView.bounds.size.width : _containerView.bounds.size.width)
        disappearingFromRect = _containerView.bounds
        appearingToRect = _containerView.bounds
        disappearingToRect = _containerView.bounds.offsetBy(dx: travelDistance, dy: 0)
        appearingFromRect = _containerView.bounds.offsetBy(dx: -travelDistance, dy: 0)
    }
    
    var containerView : UIView? {
        return _containerView
    }
   
    // Most of the time this is YES. For custom transitions that use the new UIModalPresentationCustom
    // presentation type we will invoke the animateTransition: even though the transition should not be
    // animated. This allows the custom transition to add or remove subviews to the container view.
    var isAnimated : Bool {
        return true
    }
    
    var isInteractive : Bool {// This indicates whether the transition is currently interactive.
        return false
    }
    
    var transitionWasCancelled : Bool {
        return false
    }
    
    var presentationStyle : UIModalPresentationStyle {
        return UIModalPresentationStyle.custom
    }
    
    // It only makes sense to call these from an interaction controller that
    // conforms to the UIViewControllerInteractiveTransitioning protocol and was
    // vended to the system by a container view controller's delegate or, in the case
    // of a present or dismiss, the transitioningDelegate.
    func updateInteractiveTransition(_ percentComplete: CGFloat) {}
    func finishInteractiveTransition() {}
    func cancelInteractiveTransition() {}
    
    // This must be called whenever a transition completes (or is cancelled.)
    // Typically this is called by the object conforming to the
    // UIViewControllerAnimatedTransitioning protocol that was vended by the transitioning
    // delegate.  For purely interactive transitions it should be called by the
    // interaction controller. This method effectively updates internal view
    // controller state at the end of the transition.
    func completeTransition(_ didComplete: Bool) {
        if let completion = self.completion {
            completion(didComplete)
        }
    }
    
    // Currently only two keys are defined by the
    // system - UITransitionContextToViewControllerKey, and
    // UITransitionContextFromViewControllerKey.
    // Animators should not directly manipulate a view controller's views and should
    // use viewForKey: to get views instead.
    func viewController(forKey key: UITransitionContextViewControllerKey) -> UIViewController? {
        return viewControllers[key]
    }
    
    // Currently only two keys are defined by the system -
    // UITransitionContextFromViewKey, and UITransitionContextToViewKey
    // viewForKey: may return nil which would indicate that the animator should not
    // manipulate the associated view controller's view.
    @available(iOS, introduced: 8.0)
    func view(forKey key: UITransitionContextViewKey) -> UIView? {
        return viewControllers[key]!.view
    }
    
    @available(iOS, introduced: 8.0)
    var targetTransform : CGAffineTransform {
        return CGAffineTransform.identity
    }
    
    // The frame's are set to CGRectZero when they are not known or
    // otherwise undefined.  For example the finalFrame of the
    // fromViewController will be CGRectZero if and only if the fromView will be
    // removed from the window at the end of the transition. On the other
    // hand, if the finalFrame is not CGRectZero then it must be respected
    // at the end of the transition.
    func initialFrame(for vc: UIViewController) -> CGRect {
        if vc == viewController(forKey: UITransitionContextViewControllerKey.from) {
            return disappearingFromRect
        } else {
            return appearingFromRect
        }
    }
    
    func finalFrame(for vc: UIViewController) -> CGRect {
        if vc == viewController(forKey: UITransitionContextViewControllerKey.from) {
            return disappearingToRect
        } else {
            return appearingToRect
        }
    }
}
