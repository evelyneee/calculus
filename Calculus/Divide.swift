
import Foundation

struct Divide: ArithmeticBlock {
    
    func prettyPrint() -> String {
        return "(" + self.values.0.simplify().prettyPrint() + " / " + self.values.1.simplify().prettyPrint() + ")"
    }
    
    func resolve(_ value: Double? = nil) -> Double {
        return self.values.0.resolve(value) / self.values.1.resolve(value)
    }
    
    var values: (any ArithmeticBlock, any ArithmeticBlock)
    
    init(_ lhs: any ArithmeticBlock, _ rhs: any ArithmeticBlock) {
        self.values = (lhs, rhs)
    }
    
    func polynomialDivision() -> (any ArithmeticBlock)? {
        // Only supports ax^b/(...) as of now
        if let add = self.values.1 as? Add, let mul = (self.values.0 as? Multiply)?._pullConstant() ?? (self.values.0 as? Exponent<Variable>)?.multiply(1)._pullConstant() {
            if let addsmul = (add.values.0 as? Multiply)?._pullConstant(), let konstant = add.values.1 as? Double {
                // x^4 / (2x + 3) -> (x^3/2) - 3/2 * x^3 / (2x+3)
                let solved = mul.values.1.divide(addsmul.values.1).simplify()
                let div1 = Divide(solved, addsmul.values.0).simplify()
                let div = solved.divide(self.values.1).polynomialDivision()!
                return Sub(div1, Multiply(konstant.divide(addsmul.values.0), div))
            }
        }
        return self
    }
    
    func __integrate(_ ptr: inout Int)-> (any ArithmeticBlock)? {
        if let mul = self.values.1 as? Multiply {
            return Multiply(Divide(self.values.0, mul.values.0), Divide(1, mul.values.1)).integrateByParts(&ptr)
        }
        
        if self.values.0 is Multiply || self.values.0 is Exponent<Variable>, self.values.1 is Add {
            return self.polynomialDivision()?._integrate(&ptr)?.simplify()
        }
        
        if type(of: values.0) == Variable.self && type(of: values.1) != Variable.self,
           let int1 = self.values.0._integrate(&ptr) { // ƒ x/K dx
            return Divide(int1 , self.values.1.resolve(0))
        } else if let dx = values.1.simplify().derive()?.simplify() as? Double, values.0.simplify() is Double { // ƒ K/x dx
            return Multiply(self.values.0.resolve(0), LN(self.values.1)).divide(dx)
        } else if let val = self.values.1.solve(), val.finite {
            return self.values.0._integrate(&ptr)?.divide(val)
        } else if self.unreal(self) { // Unreal
            return Multiply(self.values.0, 1.divide(self.values.1)).integrateByParts(&ptr)
        }
        
        if let solved = self.solve() {
            return Multiply(solved, Variable()) // ƒ K dx
        }
        return nil
    }
    
    func derive() -> (any ArithmeticBlock)? {
        if let d = values.1 as? Double, let dx = values.0.derive() {
            return Divide(dx, d)
        } else if let d = values.0 as? Double, let dx = values.1.derive() {
            return d * -1 * (dx/Multiply(values.1, values.1))
        }
        if let du = self.values.0.derive(), let dv = self.values.1.derive() {
            return Sub(Multiply(du, self.values.1), Multiply(self.values.0, dv)).divide(self.values.1*self.values.1)
        }
        return nil
    }
    
    func simplify() -> any ArithmeticBlock {
        
        if let one = self.values.0 as? Exponent<Variable> ?? (self.values.0 as? Variable)?.pow(1),
            let two = self.values.1 as? Exponent<Variable> ?? (self.values.1 as? Variable)?.pow(1),
            let exp1 = one.values.1.solve(),
            let exp2 = two.values.1.solve() {
            if exp1 > exp2 {
                return Exponent<Variable>(Variable(), exp1-exp2)
            } else if exp2 > exp1 {
                return Divide(1, Exponent<Variable>(Variable(), exp2-exp1))
            }
            return 1
        }
        
        if self.values.0.hash == self.values.1.hash {
            return 1
        }
        
        if self.values.1.solve() == 1 {
            return self.values.0
        }
        if let v = self.solve(), v.finite {
            return v
        }
        
        if let mul = self.values.0 as? Multiply, mul.values.0.hash == self.values.1.hash {
            return mul.values.1
        } else if let mul = self.values.0 as? Multiply, mul.values.1.hash == self.values.1.hash {
            return mul.values.0
        } else if let mul = self.values.1 as? Multiply, mul.values.0.hash == self.values.0.hash {
            return 1.divide(mul.values.1)
        } else if let mul = self.values.1 as? Multiply, mul.values.1.hash == self.values.0.hash {
            return 1.divide(mul.values.0)
        }
        
        if let div = self.values.0.simplify() as? Divide {
            return Divide(div.values.0, Multiply(div.values.1, self.values.1))
        }
        return self
    }
}
