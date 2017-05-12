//
//  CalculatorBrain.swift
//  GraphingCalculator
//
//  Created by tue41582 on 3/29/17.
//  Copyright © 2017 tue41582. All rights reserved.
//

import Foundation

class CalculatorBrain {
    
    // a data type that contains the operation constants done by the brain
    private enum Operation {
        case Constant(Double)
        case UnaryOperation((Double) -> Double, (String) -> String)
        case BinaryOperation((Double, Double) -> Double, (String, String) -> String, Int)
        case Equals
    }
    
    // store the binary function, the first value, the description of the function, and the discription of the value
    private struct PendingBinaryOperationInfo {
        var binaryFunction: (Double, Double) -> Double
        var firstValue: Double
        var descriptionFunction: (String, String) -> String
        var descriptionValue: String
    }
    
    private var accumulator = 0.0 // the stored value for inputs and is used for calculations
    private var pending: PendingBinaryOperationInfo? // initialize the enum PendingBinaryOperationInfo
    private var currentPriority = Int.max // initialize the current priority of the brain
    private var internalProgram = [AnyObject]() // the history of previous calculations
    private var operations: [String:Operation] = [ // database for all key inputs for operations
        "π" : Operation.Constant(Double.pi),
        "e" : Operation.Constant(M_E),
        "±" : Operation.UnaryOperation({-$0}, {"±(" + $0 + ")"}),
        "√" : Operation.UnaryOperation(sqrt, {"√(" + $0 + ")"}),
        "ln" : Operation.UnaryOperation(log, {"ln(" + $0 + ")"}),
        "log" : Operation.UnaryOperation(log10, {"log(" + $0 + ")"}),
        "sin" : Operation.UnaryOperation(sin, {"sin(" + $0 + ")"}),
        "cos" : Operation.UnaryOperation(cos, {"cos(" + $0 + ")"}),
        "tan" : Operation.UnaryOperation(tan, {"tan(" + $0 + ")"}),
        "sin⁻¹" : Operation.UnaryOperation(asin, {"sin⁻¹(" + $0 + ")"}),
        "cos⁻¹" : Operation.UnaryOperation(acos, {"cos⁻¹(" + $0 + ")"}),
        "tan⁻¹" : Operation.UnaryOperation(atan, {"tan⁻¹(" + $0 + ")"}),
        "x⁻¹" : Operation.UnaryOperation({pow($0, -1)}, {"(" + $0 + ")⁻¹"}),
        "x²" : Operation.UnaryOperation({pow($0, 2)}, {"(" + $0 + ")²"}),
        "÷" : Operation.BinaryOperation({$0 / $1}, {$0 + "÷" + $1}, 1),
        "×" : Operation.BinaryOperation({$0 * $1}, {$0 + "×" + $1}, 1),
        "−" : Operation.BinaryOperation({$0 - $1}, {$0 + "-" + $1}, 0),
        "+" : Operation.BinaryOperation({$0 + $1}, {$0 + "+" + $1}, 0),
        "∧" : Operation.BinaryOperation({pow($0, $1)}, {$0 + "^" + $1}, 2),
        "=" : Operation.Equals
    ]
    
    // returns the accumulator to the ViewController for display
    var result: Double {
        get {
            return accumulator
        }
    }
    
    // the lastValue performed
    var lastValue = "0" {
        didSet {
            if pending == nil {
                currentPriority = Int.max
            }
        }
    }
    
    // returns the accumulator history to the ViewController for the sequence
    var description: String {
        get {
            if pending != nil { // checks if the brain is still pending for a second value
                return pending!.descriptionFunction(pending!.descriptionValue, pending!.descriptionValue != lastValue ? lastValue : "") // add "..." to end of description
                // To understand the second argument, if pending!descriptionValue is not equal to accumulatorHistory, check if lastValue is not empty to set pending!descriptionValue as lastValue, else set pending!descriptionValue as "".
            }
            return lastValue // or add "=" to end of description
        }
    }
    
    // returns whether the brain is still pending for a second value
    var isPartialResult: Bool {
        get {
            return pending != nil
        }
    }
    
    // used to store the value in the accumulator to M
    var variableValues = [String:Double]() {
        didSet {
            program = internalProgram as CalculatorBrain.PropertyList
        }
    }
    
    typealias PropertyList = AnyObject
    
    // used to perform the expression in the history
    var program: PropertyList {
        get {
            return internalProgram as CalculatorBrain.PropertyList // get the history array
        } set {
            clear()
            if let arrayOfOps = newValue as? [AnyObject] { // check if newValue is a valid optional array of AnyObject, else null
                for op in arrayOfOps { // check each AnyObject in the array of AnyObject
                    if let operand = op as? Double { // check if op is a valid optional Double, else null
                        setOperand(operand)
                    } else if let symbol = op as? String { // check if op is a valid optional String, else null
                        if operations[symbol] != nil { // checks if the symbol exists in operations
                            performOperation(symbol)
                        } else {
                            setOperand(symbol)
                        }
                    }
                }
            }
        }
    }
    
    // get the operand from the ViewController and put it into the accumulator
    func setOperand(_ operand: Double) {
        accumulator = operand // accumulator value is now the operand value
        lastValue = formatter.string(from: NSNumber(value: accumulator)) ?? "" // set the accumulator as the lastValue
        internalProgram.append(operand as AnyObject) // add operand to history
    }
    func setOperand(_ variable: String) {
        accumulator = variableValues[variable] ?? 0 // unwraps variableValues[variable] and if there is a value, put it to the accumulator, else put a 0 to the accumulator
        lastValue = variable // set the variable as the lastValue
        internalProgram.append(variable as AnyObject) // add the variable to the history
    }
    
    // checks and perform the operation which should be done based on the input sent by the ViewController and the string from operations
    func performOperation(_ symbol: String) {
        internalProgram.append(symbol as AnyObject) // add the symbol to the history
        if let operation = operations[symbol] { // checks if the symbol exists in operations
            switch operation {
            case .Constant(let value): // get the constant value
                accumulator = value // set the constant value to the accumulator
                lastValue = symbol // set the symbol as the lastValue
            case .UnaryOperation(let function, let historyFunction): // perform a unary operation
                accumulator = function(accumulator) // perform the unary operation and set the resulting value to the accumulator
                lastValue = historyFunction(lastValue) // set the process of the function to the lastValue
            case .BinaryOperation(let function, let historyFunction, let priority): // perform a binary operation
                executePendingBinaryOperation() // execute the binary operation if there is a pending binary operation info
                if currentPriority < priority { // check if the current priority is less than the new priority
                    lastValue = "(" + lastValue + ")" // bracket the lastValue
                }
                currentPriority = priority // set the current priority to the new priority
                pending = PendingBinaryOperationInfo(binaryFunction: function, firstValue: accumulator, descriptionFunction: historyFunction, descriptionValue: lastValue) // create a new pending binary operation info
            case .Equals: // checks if the input is "="
                executePendingBinaryOperation() // execute the binary operation if there is a pending binary operation info
            }
        }
    }
    
    // checks if there is a pending binary operation to execute and if so, execute an operation using that info with a second value
    private func executePendingBinaryOperation() {
        if pending != nil { // checks if it is still an operation pending for a second value
            accumulator = pending!.binaryFunction(pending!.firstValue, accumulator) // perform the binary function using the firstValue and the function from pending binary operation info with the accumulator (secondValue) and insert the resulting value to the accumulator
            lastValue = pending!.descriptionFunction(pending!.descriptionValue, lastValue) // set the process of the function to the lastValue
            pending = nil // set pending to be null
        }
    }
    
    // reset the brain to its initial startup
    func clear() {
        accumulator = 0.0
        pending = nil
        lastValue = " "
        currentPriority = Int.max
        internalProgram.removeAll(keepingCapacity: false)
    }
    
    // reset the variableValues
    func clearVariables() {
        variableValues = [:]
    }
    
    // undo the last object inserted to the history
    func undo() {
        guard !internalProgram.isEmpty else { // if history is not empty, go to line 187
            clear()
            return
        }
        internalProgram.removeLast() // remove the last object in the history array
        program = internalProgram as CalculatorBrain.PropertyList // sync the program with the history
    }
}

let formatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = 6
    formatter.groupingSeparator = ","
    formatter.locale = Locale.current
    return formatter
}()
