import UIKit

protocol ImageScaleTransitionSourceProviding {
    var imageScaleTransitionView: UIImageView? { get }
}

@objc(WMFImageScaleTransitionDestinationProviding)
protocol ImageScaleTransitionDestinationProviding {
    var imageScaleTransitionView: UIImageView? { get }
}

class ImageScaleTransitionController: NSObject, UIViewControllerAnimatedTransitioning {
    let source: ImageScaleTransitionSourceProviding
    let destination: ImageScaleTransitionDestinationProviding
    
    init(source: ImageScaleTransitionSourceProviding, destination: ImageScaleTransitionDestinationProviding) {
        self.source = source
        self.destination = destination
        super.init()
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard
            let toViewController = transitionContext.viewController(forKey: .to),
            let fromViewController = transitionContext.viewController(forKey: .from)
        else {
                return
        }
        let containerView = transitionContext.containerView
        let toFinalFrame = transitionContext.finalFrame(for: toViewController)
        toViewController.view.frame = toFinalFrame
        
        let isTransitioningToDestination = toViewController === destination
        
        if isTransitioningToDestination {
            containerView.insertSubview(toViewController.view, aboveSubview: fromViewController.view)
        } else {
            containerView.insertSubview(toViewController.view, belowSubview: fromViewController.view)
        }

        guard
            let fromImageView = self.source.imageScaleTransitionView,
            let toImageView = self.destination.imageScaleTransitionView
        else {
            transitionContext.completeTransition(true)
            return
        }
        
        if toImageView.image == nil {
            toImageView.image = fromImageView.image
        }
        toViewController.view.layoutIfNeeded()
        
        guard let fromSnapshot = fromViewController.view.snapshotView(afterScreenUpdates: true),
            let toSnapshot = toViewController.view.snapshotView(afterScreenUpdates: true) else {
            transitionContext.completeTransition(true)
            return
        }
        toSnapshot.frame = toViewController.view.frame
        fromSnapshot.frame = fromViewController.view.frame

        containerView.addSubview(toSnapshot)
        containerView.addSubview(fromSnapshot)
        
        let fromFrame = containerView.convert(fromImageView.frame, from: fromImageView.superview)
        let toFrame = containerView.convert(toImageView.frame, from: toImageView.superview)
        let deltaX = toFrame.midX - fromFrame.midX
        let deltaY = toFrame.midY - fromFrame.midY
        let scaleX = toFrame.size.width / fromFrame.size.width
        let scaleY = toFrame.size.height / fromFrame.size.height
        let scale = CGAffineTransform(scaleX: scaleX, y: scaleY)
        let delta = CGAffineTransform(translationX: deltaX, y: deltaY)
        let transform = scale.concatenating(delta)
        
        toSnapshot.transform = transform.inverted()
        let duration = self.transitionDuration(using: transitionContext)
        UIView.animateKeyframes(withDuration: duration, delay: 0, options: .allowUserInteraction, animations: {
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 1, animations: {
                fromSnapshot.transform = transform
                toSnapshot.transform = CGAffineTransform.identity
            })
            UIView.addKeyframe(withRelativeStartTime: 0.33, relativeDuration: 0.67, animations: {
                toSnapshot.alpha = isTransitioningToDestination ? 1 : 0
            })
        }) { (finished) in
            toSnapshot.removeFromSuperview()
            fromSnapshot.removeFromSuperview()
            
            transitionContext.completeTransition(true)
        }
    }
}