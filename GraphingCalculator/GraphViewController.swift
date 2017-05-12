//
//  GraphViewController.swift
//  GraphingCalculator
//
//  Created by tue41582 on 4/13/17.
//  Copyright © 2017 tue41582. All rights reserved.
//

import UIKit

class GraphViewController: UIViewController {
    
    private struct Keys { // initialize the scale and origin
        static let Scale = "GraphViewController.Scale"
        static let Origin = "GraphViewController.Origin"
    }
    let defaults = UserDefaults.standard // use the user's default settings
    var widthOld = CGFloat(0.0) // initialize the current width of the screen
    var yForX: ((_ x: Double) -> Double?)? { //
        didSet {
            updateUI()
        }
    }
    var scale: CGFloat { // expand or shrink the graph view screen
        get {
            return defaults.object(forKey: Keys.Scale) as? CGFloat ?? 50.0
        }
        set {
            defaults.set(newValue, forKey: Keys.Scale)
        }
    }
    var originRelativeToCenter: CGPoint { // move the center of the graph view screen based on the origin 
        get {
            let originArray = defaults.object(forKey: Keys.Origin) as? [CGFloat]
            let factor = CGPoint(x: originArray?.first ?? CGFloat (0.0), y: originArray?.last ?? CGFloat (0.0))
            return CGPoint (x: factor.x * graphView.bounds.size.width, y: factor.y * graphView.bounds.size.height)
        }
        set {
            let factor = CGPoint(x: newValue.x / graphView.bounds.size.width, y: newValue.y / graphView.bounds.size.height)
            defaults.set([factor.x, factor.y], forKey: Keys.Origin)
        }
    }
    
    // display and update the graph view with gesture recognizers
    @IBOutlet weak var graphView: GraphView! {
        didSet {
            graphView.addGestureRecognizer(UIPinchGestureRecognizer(target: graphView, action: #selector(GraphView.scale(_:))))
            graphView.addGestureRecognizer(UIPanGestureRecognizer(target: graphView, action: #selector(GraphView.originMove(_:))))
            let doubleTapRecognizer = UITapGestureRecognizer(target: graphView, action: #selector(GraphView.origin(_:)))
            doubleTapRecognizer.numberOfTapsRequired = 2
            graphView.addGestureRecognizer(doubleTapRecognizer)
            graphView.scale = scale
            graphView.originRelativeToCenter = originRelativeToCenter
            updateUI()
        }
    }
    
    // update the graph view screen
    func updateUI() {
        graphView?.yForX = yForX
    }
    
    //MARK: - Life Cycle
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        widthOld = graphView.bounds.size.width
        originRelativeToCenter = graphView.originRelativeToCenter
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !(graphView.bounds.size.width == widthOld) {
            graphView.originRelativeToCenter =  originRelativeToCenter
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        scale = graphView.scale
        originRelativeToCenter = graphView.originRelativeToCenter
    }
}
