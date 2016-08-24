//
//  JKNotificationPanel.swift
//  Pods
//
//  Created by Ter on 12/20/2558 BE.
//  http://www.macfeteria.com
//

import UIKit


public protocol JKNotificationPanelDelegate {
    func notificationPanelDidDismiss ()
    func notificationPanelDidTap()
}

public class JKNotificationPanel: NSObject {
    
    let defaultViewHeight:CGFloat = 42.0

    public var enableTapDismiss = true
    public var timeUntilDismiss:NSTimeInterval = 2
    public var delegate:JKNotificationPanelDelegate!
    
    var tapAction:(()->Void)? = nil
    var dismissAction:(()->Void)? = nil
    
    var completionHandler:()->Void = { }    
    var view:UIView?
    var tapGesture:UITapGestureRecognizer!
    var verticalSpace:CGFloat = 0
    
    public var withView:UIView?
    var navigationBar:UINavigationBar?
    var timer: NSTimer?
    
    public override init() {
        super.init()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    public func transitionToSize(size:CGSize) {
        
        if let jkview = self.withView as? JKDefaultView {
            jkview.transitionTosize(size)
        }
        
        if let navBar  = self.navigationBar , let view = self.view {
            let navHeight = navBar.frame.height + UIApplication.sharedApplication().statusBarFrame.size.height
            verticalSpace = navHeight
            view.frame = CGRectMake(0, self.verticalSpace, view.frame.width, view.frame.height)
        }
    }
    
    
    public func defaultView(status:JKType, message:String?, size:CGSize? = nil) -> JKDefaultView {
        
        var height:CGFloat = defaultViewHeight
        var width:CGFloat = UIScreen.mainScreen().bounds.size.width
        
        if let size = size {
            height = size.height
            width = size.width
        }
        
        let view = JKDefaultView(frame: CGRectMake(0, 0, width,  height))
        view.setPanelStatus(status)
        view.setMessage(message)
        
        return view
    }

    
    public func addPanelDidTapAction(action:()->Void ) {
        tapAction = action
    }
    
    public func addPanelDidDissmissAction(action:()->Void ) {
        dismissAction  = action
    }
    
    
    public func showNotify(withStatus status: JKType, belowNavigation navigation: UINavigationController, message text:String? = nil) {
        navigationBar = navigation.navigationBar
        verticalSpace = navigation.navigationBar.frame.size.height + UIApplication.sharedApplication().statusBarFrame.size.height
        let panelSize = CGSize(width: navigation.navigationBar.frame.size.width, height: defaultViewHeight)
        let defaultView = self.defaultView(status,message: text,size: panelSize)
        self.showNotify(withView: defaultView, inView: navigation.view)
    }
    
    public func showNotify(withStatus status: JKType, inView view: UIView, message text:String? = nil) {
        
        verticalSpace = 0
        let panelSize = CGSize(width: view.frame.size.width, height: defaultViewHeight)
        let defaultView = self.defaultView(status,message: text,size: panelSize)
        self.showNotify(withView: defaultView, inView: view)
    }
    
    
    
    public func showNotify(withView view: UIView,  belowNavigation navigation: UINavigationController , completion handler:(()->Void)? = nil) {
        navigationBar = navigation.navigationBar
        verticalSpace = navigation.navigationBar.frame.size.height + UIApplication.sharedApplication().statusBarFrame.size.height
        self.showNotify(withView: view, inView: navigation.view )
    }
    
    public func showNotify(withView view: UIView,inView: UIView, belowView: UIView? = nil) {
        
 
        reset()
        if let belowView = belowView{
            verticalSpace = belowView.frame.size.height
        }

        
        self.withView = view
        
        let width = inView.frame.width
        let height = view.frame.height
        let top = (-height/2.0) + verticalSpace
        
        self.view = UIView()
        
        self.tapGesture = UITapGestureRecognizer(target: self, action: #selector(JKNotificationPanel.tapHandler))
        self.view!.addGestureRecognizer(tapGesture)
        
        self.view!.alpha = 1
        self.view!.frame = CGRectMake(0, top , width, height)
        self.view!.backgroundColor = UIColor.clearColor()
        self.view!.addSubview(view)
        self.view!.bringSubviewToFront(view)
        view.autoresizingMask = [.FlexibleWidth]
        self.view!.autoresizingMask = [.FlexibleWidth]
        
        if let belowView = belowView {
            inView.insertSubview(self.view!, belowSubview: belowView)
        }else{
            if inView.subviews.count > 1 {
                inView.insertSubview(self.view!, atIndex: 1)
            }else{
                inView.addSubview(self.view!)
            }
        }
    
        // Start Animate
        
        
        UIView.animateWithDuration(0.2, animations: { [weak self] in
                self?.view?.alpha = 1
                self?.view?.frame = CGRectMake(0, self?.verticalSpace ?? 0, width, height + 5)
            }) { (success) in
                if let view = self.view {
                    
                    UIView.animateWithDuration(0.2, animations: { 
                        self.view?.frame = CGRectMake(0, self.verticalSpace , width, height)
                        }, completion: { (success) in
                            if self.timeUntilDismiss > 0 {
                                UIView.animateWithDuration(0.1, delay: self.timeUntilDismiss, options: .AllowUserInteraction, animations: { 
                                    self.view?.alpha = 0.8
                                    }, completion: { (success) in
                                        if success {
                                            self.animateFade(0.2)
                                        }
                                })
                                
                            }
                    })
                }
        }
    }
    
    
    func tapHandler () {
        if  enableTapDismiss ==   true {
            self.dismissNotify()
        }
        
        if let delegate = self.delegate {
            delegate.notificationPanelDidTap()
        } else if let userTapAction = tapAction {
            userTapAction()
        }
        
    }
    
    func reset() {
        if let view = self.view {
            view.removeGestureRecognizer(self.tapGesture )
            view.removeFromSuperview()
            self.view = nil
            self.withView = nil
        }
    }
    
    public func dismissAfterDuration(duration: NSTimeInterval) {
        
        timer?.invalidate()
        
        timer = NSTimer.scheduledTimerWithTimeInterval(duration, target: self, selector: #selector(JKNotificationPanel.dismissViewNow), userInfo: nil, repeats: false)
    }
    
    func dismissViewNow() {
        animateFade(0.3)
    }
    
    func animateFade(duration:NSTimeInterval) {
        if let view = self.view{
            var frame = view.frame
            frame.origin.y = frame.origin.y - frame.size.height
//            frame.size.height = -10
        
            let fade = {
//                view.alpha = 0
                view.frame = frame
            }
        
            let fadeComplete = { (success:Bool) -> Void in
                self.removePanelFromSuperView()
            }
        
            UIView.animateWithDuration(duration, animations: fade, completion: fadeComplete)
        }
    }
    
    func removePanelFromSuperView() {
        if let view = self.view {
            view.removeGestureRecognizer(self.tapGesture )
            view.removeFromSuperview()
            self.view = nil
            self.withView = nil
            
            if let delegate = self.delegate {
                delegate.notificationPanelDidDismiss()
            } else if let userDismissAction = dismissAction {
                userDismissAction()
            }
        }
    }
    
    public func dismissNotify(fadeDuration:NSTimeInterval = 0.2) {
        if fadeDuration == 0 {
            removePanelFromSuperView()
        }
        else {
            animateFade(fadeDuration)
        }
    }
    
}
