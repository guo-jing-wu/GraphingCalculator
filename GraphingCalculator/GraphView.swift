//
//  GraphView.swift
//  GraphingCalculator
//
//  Created by tue41582 on 4/13/17.
//  Copyright © 2017 tue41582. All rights reserved.
//

import UIKit

@IBDesignable
class GraphView: UIView {
    private struct OldPoint { // keep track of the old points of a line for the path
        var yGraph: CGFloat
        var normal: Bool
    }
    private let axesDrawer = AxesDrawer(color: UIColor.black) // draw the y and x axes
    private var snapshot: UIView? // initialize the snapshot
    private var lightCurve: Bool = false // track when the UIPanGestureRecognizer began and ended
    private var graphCenter: CGPoint { // initialize the initial center of the graph view
        return convert(center, from: superview)
    }
    private var origin: CGPoint { // set the initial center as the origin and change the center when there is a new origin value while keeping track of origin relative to the center
        get {
            var origin = originRelativeToCenter
            origin.x += graphCenter.x
            origin.y += graphCenter.y
            return origin
        }
        set {
            var origin = newValue
            origin.x -= graphCenter.x
            origin.y -= graphCenter.y
            originRelativeToCenter = origin
        }
    }
    
    var yForX: ((_ x: Double) -> Double?)? { // use the x coordinate to get the y coordinate
        didSet {
            setNeedsDisplay()
        }
    }
    var originRelativeToCenter = CGPoint.zero { // initialize the initial origin of the graph view and keep track of its position
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable
    var scale: CGFloat = 50.0 { // initialize the initial scale of the graph view
        didSet {
            setNeedsDisplay()
        }
    }
    @IBInspectable
    var lineWidth: CGFloat = 2.0 { // initialize the line width of the graph view
        didSet {
            setNeedsDisplay()
        }
    }
    @IBInspectable
    var color: UIColor = UIColor.blue { // initialize the line color of the graph view
        didSet {
            setNeedsDisplay()
        }
    }
    
    // draw the axes and curve in the graph view
    override func draw(_ rect: CGRect) {
        axesDrawer.contentScaleFactor = contentScaleFactor
        axesDrawer.drawAxesInRect(bounds, origin: origin, pointsPerUnit: scale)
        if !lightCurve {
            drawCurveInRect(bounds, origin, scale)
        }
    }
    
    // draw the points for the curve
    func drawCurveInRect(_ bounds: CGRect, _ origin: CGPoint, _ scale: CGFloat) {
        color.set()
        var xGraph, yGraph: CGFloat
        var x: Double {
            return Double((xGraph - origin.x) / scale)
        }
        var oldPoint = OldPoint (yGraph: 0.0, normal: false)
        var disContinuity:Bool {
            return abs(yGraph - oldPoint.yGraph) > max(bounds.width, bounds.height) * 1.5
        }
        let path = UIBezierPath()
        path.lineWidth = lineWidth
        for i in 0...Int(bounds.size.width * contentScaleFactor) {
            xGraph = CGFloat(i) / contentScaleFactor
            guard let y = (yForX)?(x), y.isFinite else {
                oldPoint.normal = false
                continue
            }
            yGraph = origin.y - CGFloat(y) * scale
            if !oldPoint.normal {
                path.move(to: CGPoint(x: xGraph, y: yGraph))
            } else {
                guard !disContinuity else {
                    oldPoint = OldPoint (yGraph: yGraph, normal: false)
                    continue
                }
                path.addLine(to: CGPoint(x: xGraph, y: yGraph))
            }
            oldPoint = OldPoint (yGraph: yGraph, normal: true)
        }
        path.stroke()
    }
    
    // change the origin of the graph view based on the UITapGestureRecognizer location
    func origin(_ gesture: UITapGestureRecognizer) {
        if gesture.state == .ended {
            origin = gesture.location(in: self)
        }
    }
    
    // move the origin of the graph view based on the UIPanGestureRecognizer
    func originMove(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            lightCurve = true
            snapshot = self.snapshotView(afterScreenUpdates: false)
            snapshot!.alpha = 0.4
            self.addSubview(snapshot!)
        case .changed:
            let translation = gesture.translation(in: self)
            if translation != CGPoint.zero {
                snapshot!.center.x += translation.x
                snapshot!.center.y += translation.y
                gesture.setTranslation(CGPoint.zero, in: self)
            }
        case .ended:
            origin.x += snapshot!.frame.origin.x
            origin.y += snapshot!.frame.origin.y
            snapshot!.removeFromSuperview()
            snapshot = nil
            lightCurve = false
            setNeedsDisplay()
        default: break
        }
    }
    
    // expand or shrink the graph view based on the UIPinchGestureRecognizer
    func scale(_ gesture: UIPinchGestureRecognizer) {
        switch gesture.state {
        case .began:
            snapshot = self.snapshotView(afterScreenUpdates: false)
            snapshot!.alpha = 0.8
            self.addSubview(snapshot!)
        case .changed:
            let touch = gesture.location(in: self)
            snapshot!.frame.size.height *= gesture.scale
            snapshot!.frame.size.width *= gesture.scale
            snapshot!.frame.origin.x = snapshot!.frame.origin.x * gesture.scale + (1 - gesture.scale) * touch.x
            snapshot!.frame.origin.y = snapshot!.frame.origin.y * gesture.scale + (1 - gesture.scale) * touch.y
            gesture.scale = 1.0
        case .ended:
            let changedScale = snapshot!.frame.height / self.frame.height
            scale *= changedScale
            origin.x = origin.x * changedScale + snapshot!.frame.origin.x
            origin.y = origin.y * changedScale + snapshot!.frame.origin.y
            snapshot!.removeFromSuperview()
            snapshot = nil
            setNeedsDisplay()
        default: break
        }
    }
}
