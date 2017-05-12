//
//  CalculatorViewController.swift
//  GraphingCalculator
//
//  Created by tue41582 on 3/26/17.
//  Copyright © 2017 tue41582. All rights reserved.
//

import UIKit

class CalculatorViewController: UIViewController, UISplitViewControllerDelegate {
    private struct Storyboard { // initialize the Storyboard identifier
        static let ShowGraph = "Show Graph"
    }
    private struct Keys { // initialize the program
        static let Program = "CalculatorViewController.Program"
    }
    private let defaults = UserDefaults.standard //
    private var brain = CalculatorBrain() // initialize the CalculatorBrain
    @IBOutlet private weak var display: UILabel! // display the result
    @IBOutlet private weak var sequence: UILabel! // display the history
    @IBOutlet weak var graph: UIButton! { // display the graph if enabled
        didSet {
            graph.isEnabled = false
        }
    }
    private var userIsInMiddleOfTyping = false // checks if the user is in middle of typing
    private var decimalUsed = false // checks if there is already a decimal
    private var displayValue: Double? { // allow to get value as a double and set it as a string
        get { // return as a double
            if let text = display.text, let value = formatter.number(from: text)?.doubleValue {
                return value // convert the display text from a string to a double
            }
            return nil
        } set { // change double into a string, format it, and put it into the display
            if let value = newValue {
                display.text = formatter.string(from: NSNumber(value: value)) // display as a string
                sequence.text = brain.description + (brain.isPartialResult ? "..." : "=") // display the process and check if it is pending to add a "..." or a "="
            } else {
                display.text = "0" // reset display
                sequence.text = " " // reset sequence
                userIsInMiddleOfTyping = false // reset if the user is in the middle of typing
            }
        }
    }
    
    // the digit and . buttons
    @IBAction private func touchDigit(_ sender: UIButton) {
        let digit = sender.currentTitle! // get the string from the button pressed
        if digit == "." && decimalUsed == false { // checks if "." is pressed and decimalUsed is false
            decimalUsed = true // set decimalUsed to true
        } else if digit == "." && decimalUsed == true { // checks if "." is pressed and decimalUsed is true
            return // do not allow "." to be added to the display
        }
        if userIsInMiddleOfTyping { // checks if the user is in the middle of typing
            let currentDisplay = display.text! // store the current display
            display.text = currentDisplay + digit // add the digit to the display
        } else {
            display.text = digit // insert the first digit
        }
        userIsInMiddleOfTyping = true
    }
    
    // all the mathematical symbol buttons
    @IBAction private func performOperation(_ sender: UIButton) {
        if userIsInMiddleOfTyping { // checks if the user is in the middle of typing
            if let value = displayValue {
                brain.setOperand(value) // store operand to the brain
            }
            userIsInMiddleOfTyping = false // reset if the user is in the middle of typing
            decimalUsed = false // reset decimal used
        }
        if let mathematicalSymbol = sender.currentTitle { // checks if sender.currentTitle has an actual value to perform an operation
            brain.performOperation(mathematicalSymbol) //perform an operation using the string from the button pressed
        }
        graph.isEnabled = !brain.isPartialResult
        displayValue = brain.result
    }
    
    // the C button
    @IBAction private func clear(_ sender: UIButton) {
        brain.clear() // reset the brain to its initial startup
        brain.clearVariables() // clear variable values stored
        displayValue = nil
        userIsInMiddleOfTyping = false // reset if the user is in the middle of typing
        decimalUsed = false // reset decimal used
    }
    
    
    // display the "-" instead of "±" when the ± button is pressed
    @IBAction func plusMinus(_ sender: UIButton) {
        if userIsInMiddleOfTyping { // checks if the user is in the middle of typing
            if (display.text!.range(of: "-") != nil) { // checks if display text contains a "-"
                display.text = String((display.text!).characters.dropFirst()) // remove the "-"
            } else {
                display.text = "-" + display.text! // add the "-"
            }
        } else {
            performOperation(sender)
        }
    }
    
    // the undo button
    @IBAction private func backspace(_ sender: UIButton) {
        if userIsInMiddleOfTyping { // checks if user is in middle of typing
            display.text!.remove(at: display.text!.characters.index(before: display.text!.endIndex)) // undo the last digit that was typed
            if display.text!.isEmpty { // checks if the display is empty
                userIsInMiddleOfTyping = false // reset if the user is in the middle of typing
                graph.isEnabled = !brain.isPartialResult
                displayValue = brain.result
            }
        } else {
            brain.undo() // undo the last input in the history
            graph.isEnabled = !brain.isPartialResult
            displayValue = brain.result
        }
    }
    
    // the →M button
    @IBAction func setMemory(_ sender: UIButton) {
        userIsInMiddleOfTyping = false // reset if the user is in the middle of typing
        let symbol = String((sender.currentTitle!).characters.dropFirst()) // remove the → from →M
        if let value = displayValue {
            brain.variableValues[symbol] = value // the value on the display is saved to M
            graph.isEnabled = !brain.isPartialResult
            displayValue = brain.result
        }
    }
    
    // the M button
    @IBAction func pushMemory(_ sender: UIButton) {
        brain.setOperand(sender.currentTitle!)
        graph.isEnabled = !brain.isPartialResult
        displayValue = brain.result
    }
    
    typealias PropertyList = AnyObject
    
    // used to set and get the default values for the program
    private var program: PropertyList? {
        get {
            return defaults.object(forKey: Keys.Program) as CalculatorViewController.PropertyList?
        } set {
            defaults.set(newValue, forKey: Keys.Program)
        }
    }
    
    //MARK: - Navigation
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return !brain.isPartialResult
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let graphVC = segue.destination.contentViewController as? GraphViewController, segue.identifier == Storyboard.ShowGraph {
            prepareGraphVC(graphVC)
        }
    }
    
    @IBAction func showGraph(_ sender: UIButton) {
        program = brain.program
        if let graphVC = splitViewController?.viewControllers.last?.contentViewController as? GraphViewController {
            prepareGraphVC(graphVC)
        } else {
            performSegue(withIdentifier: Storyboard.ShowGraph, sender: nil)
        }
    }
    
    private func prepareGraphVC(_ graphVC : GraphViewController) {
        graphVC.navigationItem.title = brain.description
        graphVC.yForX = {
            [weak weakSelf = self] x in weakSelf?.brain.variableValues["M"] = x
            return weakSelf?.brain.result
        }
    }
    
    //MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        splitViewController?.delegate = self
        if let savedProgram = program as? [AnyObject] {
            brain.program = savedProgram as CalculatorBrain.PropertyList
            graph.isEnabled = !brain.isPartialResult
            displayValue = brain.result
            if let graphVC = splitViewController?.viewControllers.last?.contentViewController as? GraphViewController {
                prepareGraphVC(graphVC)
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if !brain.isPartialResult {
            program = brain.program
        }
    }
    
    //MARK: - UISplitViewControllerDelegate
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        if primaryViewController.contentViewController == self {
            if let graphVC = secondaryViewController.contentViewController as? GraphViewController, graphVC.yForX == nil {
                if program != nil {
                    return false
                }
                return true
            }
        }
        return false
    }
}
extension UIViewController {
    var contentViewController: UIViewController {
        if let navcon = self as? UINavigationController {
            return navcon.visibleViewController ?? self
        } else {
            return self
        }
    }
}

