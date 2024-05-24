
import Foundation

func checkIfDXPresentAndSwap(_ expression: any ArithmeticBlock, oldVariable: any ArithmeticBlock) -> (any ArithmeticBlock)? {
    guard let dx = oldVariable.derive() else {
        return nil
    }
    
    if let mul = expression as? Multiply {
        if mul.values.0.hash == dx.hash {
            return mul.values.1
        } else if mul.values.1.hash == dx.hash {
            return mul.values.0
        }
    }
    
    if let mul = expression as? Divide {
        if mul.values.0.hash == dx.hash {
            return 1.divide(mul.values.1)
        }
    }
    return Unreal()
}

func integrateWithVariableSwap(_ expression: any ArithmeticBlock, variable: any ArithmeticBlock, newVariable: any ArithmeticBlock) -> (any ArithmeticBlock)? {
    
    // Step 1: Replace the variable in the expression with the new variable
    let swappedExpression = replaceVariable(expression, oldVariable: variable, newVariable: newVariable)
    
    // Step 2: Perform the integration with respect to the new variable
    guard let integratedExpression = try? swappedExpression.integrate() else {
        return nil
    }
    
    // Step 3: Substitute back the original variable
    let finalExpression = replaceVariable(integratedExpression, oldVariable: newVariable, newVariable: variable)
    
    return finalExpression
}

import Foundation

func replaceVariable(_ expression: any ArithmeticBlock, oldVariable: any ArithmeticBlock, newVariable: any ArithmeticBlock) -> any ArithmeticBlock {
    // Base case: if the expression is the old variable, return the new variable
    if expression.hash == oldVariable.hash {
        return newVariable
    }
    
    // Recursive case: replace the variable in the sub-expressions
    switch expression {
    case let add as Add:
        return Add(replaceVariable(add.values.0, oldVariable: oldVariable, newVariable: newVariable),
                   replaceVariable(add.values.1, oldVariable: oldVariable, newVariable: newVariable))
    case let sub as Sub:
        return Sub(replaceVariable(sub.values.0, oldVariable: oldVariable, newVariable: newVariable),
                   replaceVariable(sub.values.1, oldVariable: oldVariable, newVariable: newVariable))
    case let multiply as Multiply:
        return Multiply(replaceVariable(multiply.values.0, oldVariable: oldVariable, newVariable: newVariable),
                        replaceVariable(multiply.values.1, oldVariable: oldVariable, newVariable: newVariable))
    case let divide as Divide:
        return Divide(replaceVariable(divide.values.0, oldVariable: oldVariable, newVariable: newVariable),
                      replaceVariable(divide.values.1, oldVariable: oldVariable, newVariable: newVariable))
    case let exponent as Exponent<Double>:
        return Exponent(exponent.values.0,
                        replaceVariable(exponent.values.1, oldVariable: oldVariable, newVariable: newVariable))
    case let exponent as Exponent<Variable>:
        return Exponent(AnyArithmetic(newVariable),
                        replaceVariable(exponent.values.1, oldVariable: oldVariable, newVariable: newVariable))
    case let ln as LN:
        return LN(replaceVariable(ln.values.0, oldVariable: oldVariable, newVariable: newVariable))
    default:
        return expression
    }
}

func replaceVariableAndSolve(_ expression: any ArithmeticBlock) -> (any ArithmeticBlock)? {
            
    // Recursive case: replace the variable in the sub-expressions
    switch expression {
    case let divide as Divide:
        if divide.values.1 is Add || divide.values.1 is Sub,
           let dx = divide.values.1.derive()?.simplify(),
           divide.values.0.hash == dx.hash,
           let newExpr = try? (1.divide(Variable())).integrate() {
            return replaceVariable(newExpr, oldVariable: Variable(), newVariable: divide.values.1).simplify()
        }
    case var mul as Multiply:
        let block: any ArithmeticBlock
        let core: any ArithmeticBlock
        var power: Double = -256
        if mul.values.1 is Exponent<Add> || mul.values.1 is Exponent<Sub> {
            mul = Multiply(mul.values.1, mul.values.0)
        }
        if let expAdd = mul.values.0 as? Exponent<Add>, let solved = expAdd.values.1.solve() {
            block = expAdd
            core = expAdd.values.0
            power = solved
        } else if let expAdd = mul.values.0 as? Exponent<Sub>, let solved = expAdd.values.1.solve() {
            block = expAdd
            core = expAdd.values.1
            power = solved
        } else {
            break
        }
        if (core is Add) || (core is Sub) {
            if let dx = core.derive()?.simplify() {
                print(mul.values.1.prettyPrint(), dx.prettyPrint(), block.prettyPrint())
                if mul.values.1.simplify().hash == dx.simplify().hash {
                    if let newExpr = try? Variable().pow(power).integrate().simplify() {
                        return replaceVariable(newExpr, oldVariable: Variable(), newVariable: core).simplify()
                    }
                }
            }
        }
    default:
        return nil
    }
    return nil
}
