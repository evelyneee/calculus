
import Foundation

#if DEBUG
var layer: Int = 0
#endif

struct Multiply: ArithmeticBlock {
    
    func expType(_ i: any ArithmeticBlock) -> Bool {
        if let mul = i as? Multiply {
            return expType(mul.values.0) || expType(mul.values.1)
        }
        return i is Exponent<Double> || i is Exponent<Variable> || i is Variable
    }
    
    func prettyPrint() -> String {
        if self.values.0.solve() == -1 {
            return "-"+self.values.1.simplify().prettyPrint()
        } else if self.values.1.solve() == -1 {
            return "-"+self.values.0.simplify().prettyPrint()
        } else if expType(self.values.0) && expType(self.values.1) {
            return self.values.0.simplify().prettyPrint()+self.values.1.simplify().prettyPrint()
        } else if expType(self.values.0) && self.values.1 is Double {
            return self.values.1.prettyPrint()+self.values.0.prettyPrint()
        } else if expType(self.values.1) && self.values.0 is Double {
            return self.values.0.prettyPrint()+self.values.1.prettyPrint()
        }
        return "(" + self.values.0.simplify().prettyPrint() + " * " + self.values.1.simplify().prettyPrint() + ")"
    }
    
    func resolve(_ value: Double? = nil) -> Double {
        return self.values.0.resolve(value) * self.values.1.resolve(value)
    }
    
    var values: (any ArithmeticBlock, any ArithmeticBlock)
    
    init(_ lhs: any ArithmeticBlock, _ rhs: any ArithmeticBlock) {
        self.values = (lhs, rhs)
    }
    
    typealias Integrand = Multiply
    
    func __integrate(_ ptr: inout Int)-> (any ArithmeticBlock)? {
        
        let simplified = self.simplify()
        
        if simplified.hash == self.hash {
            return self.___integrate(&ptr)
        }
        
        return simplified._integrate(&ptr)
    }
    func ___integrate(_ ptr: inout Int) -> (any ArithmeticBlock)? {
        
        let int0 = self.values.0._integrate(&ptr)
        let int1 = self.values.1._integrate(&ptr)
                
        if let int1, nil != self.values.0.solve(), self.values.1.solve() == nil {
            return Multiply(self.values.0, int1)
        } else if let int0, nil != self.values.1.solve(), self.values.0.solve() == nil {
            return Multiply(self.values.1, int0)
        } else if let solution = self.solve() {
            return Multiply(solution, Variable())
        }
        
        if let div = self.values.1 as? Divide {
            return Divide(Multiply(self.values.0, div.values.0), div.values.1)._integrate(&ptr)
        }
        
        return self.integrateByParts(&ptr)
    }
    
    func integrateByParts(_ ptr: inout Int) -> (any ArithmeticBlock)? {
        var values = values
        
        layer += 1
        let id = layer
        print("STATUS \(id): Integrating by parts", self.prettyPrint())
        // missing #1, #3, #6, #7
        if values.1 is Variable {
            values.1 = Exponent(Variable(), 1)
        } else if values.0 is Variable {
            values.0 = Exponent(Variable(), 1)
        }
        
        if !(values.0 is Exponent<Variable>), let v = values.0._integrate(&ptr)?.simplify().simplify().simplify(),
           let du = values.1.derive()?.simplify().simplify().simplify() { // ƒ u * dv dx
            let vdu = Multiply(
                v,
                du
            ).simplify().simplify().simplify()._pullConstant()
            print("STARTING \(id): ƒ", self.prettyPrint()+"dx =", Multiply(v, values.0).prettyPrint(), "-", vdu.values.0.prettyPrint()+"* ƒ"+vdu.values.1.prettyPrint()+"dx")
                        
            if vdu.values.1.hash == self._pullConstant().values.1.hash {
                print("AAAA")
                return Divide(
                    Multiply(v, values.1), // v*u
                    (self._pullConstant().values.0+vdu.values.0).solveExpression()
                )
            }
            
            if let int = vdu.values.1.simplify()._integrate(&ptr) {
                #if DEBUG
                if enableLogging {
                    print("SUCCESS \(id): ƒ", self.prettyPrint()+"dx =", Sub(
                        Multiply(v, values.0), // v*u - K * ƒ (v * du) dx
                        Multiply(vdu.values.0, int)
                    ).prettyPrint())
                }
                #endif
                return Sub(
                    Multiply(v, values.1), // v*u
                    Multiply(vdu.values.0, int) // ƒ v * du
                )
            }
        } else if !(values.1 is Exponent<Variable>), let v = values.1._integrate(&ptr)?.simplify(),
                  let du = values.0.derive()?.simplify() { // ƒ u * dv dx
            print("v, du", v.prettyPrint(), du.prettyPrint())
                   let vdu = Multiply(
                       v,
                       du
                   ).simplify()._pullConstant()
            
            if vdu.values.1.hash == self._pullConstant().values.1.hash {
                print("AAAA")
                return Divide(
                    Multiply(v, values.1), // v*u
                    (self._pullConstant().values.0+vdu.values.0).solveExpression()
                )
            }
            
            print("STARTING \(id): ƒ", self.prettyPrint()+"dx =", Multiply(v, values.0).prettyPrint(), "-", vdu.values.0.prettyPrint()+"* ƒ"+vdu.values.1.prettyPrint()+"dx")
                if let int = vdu.values.1.simplify()._integrate(&ptr) {
                    #if DEBUG
                    if enableLogging {
                        print("SUCCESS \(id): ƒ", self.prettyPrint()+"dx =", Sub(
                         Multiply(v, values.0), // v*u
                         Multiply(vdu.values.0, int) // ƒ v * du
                        ).prettyPrint())
                    }
                    #endif

                       return Sub(
                           Multiply(v, values.0), // v*u
                           Multiply(vdu.values.0, int) // ƒ v * du
                       )
                   }
               }
        #if DEBUG
        if enableLogging {
            print("Failed to find suitable parts", values.0.prettyPrint(), values.1.prettyPrint())
        }
        #endif
        return nil
    }
    
    @_optimize(speed)
    func _pullConstant() -> Multiply {
        if let mul = self.values.0 as? Multiply, mul.values.0 is Double {
            return Multiply(mul.values.0, Multiply(self.values.1, mul.values.1))
        } else if let mul = self.values.0 as? Multiply, mul.values.1 is Double {
            return Multiply(mul.values.1, Multiply(self.values.1, mul.values.0))
        } else if let mul = self.values.1 as? Multiply, mul.values.0 is Double {
            return Multiply(mul.values.0, Multiply(self.values.0, mul.values.1))
        } else if let mul = self.values.1 as? Multiply, mul.values.1 is Double {
            return Multiply(mul.values.1, Multiply(self.values.1, mul.values.0))
        } else if self.values.0 is Double {
            return self
        } else if self.values.1 is Double && !(self.values.0 is Double) {
            return Multiply(self.values.1, self.values.0)
        }
                
        return Multiply(1, self)
    }
    
    func derive() -> (any ArithmeticBlock)? {
        if let d = values.1 as? Double, let dx = values.0.derive() {
            return Multiply(d, dx)
        } else if let d = values.0 as? Double, let dx = values.1.derive() {
            return Multiply(d, dx)
        }
        if let du = self.values.0.derive(), let dv = self.values.1.derive() {
            return Add(Multiply(du.simplify(), self.values.1), Multiply(self.values.0, dv.simplify()))
        }
        return nil
    }
    
    @_optimize(speed)
    func simplify() -> any ArithmeticBlock {
                
        if self.values.0.solve() == 0 || self.values.1.solve() == 0 {
            return 0
        }
        
        let values = (self.values.0.simplify(), self.values.1.simplify())
        
        if let solved = self.solve(), solved.truncatingRemainder(dividingBy: 1) == 0 {
            return solved.simplify()
        }
        
        if let add = values.0 as? Add {
            return Add(add.values.0.simplify().multiply(values.1), add.values.1.simplify().multiply(values.1))
        } else if let add = values.1 as? Add {
            return Add(add.values.0.simplify().multiply(values.0), add.values.1.simplify().multiply(values.0))
        } else if let sub = values.0 as? Sub, let d = values.1 as? Double {
            return Sub(sub.values.0.simplify().multiply(d), sub.values.1.simplify().multiply(d))
        } else if let sub = values.1 as? Sub, let d = values.0 as? Double {
            return Sub(sub.values.0.simplify().multiply(d), sub.values.1.simplify().multiply(d))
        }
        
        if let exple = values.0 as? Exponent<Variable> ?? (values.0 as? Variable)?.pow(1),
            let expri = values.1 as? Exponent<Variable> ?? (values.1 as? Variable)?.pow(1) {
            return Exponent<Variable>(Variable(), exple.values.1.add(expri.values.1).solveExpression())
        }
        
        if let bottom = values.1 as? Divide, values.0.hash == bottom.values.1.hash {
            return bottom.values.0.simplify()
        }
        
        if self.values.0 as? Double == 1 {
            return self.values.1
        } else if self.values.1 as? Double == 1 {
            return self.values.0
        } else if let div = values.0 as? Divide {
            return Multiply(div.values.0, values.1).simplify().divide(div.values.1)
        } else if let div = values.1 as? Divide {
            let ret = Multiply(div.values.0, values.0).simplify().divide(div.values.1)
            return ret.simplify()
        } else if let div = values.0.solve(), div.finite, let mul = values.1 as? Multiply {
            if let solved = mul.values.0.solve(), solved.finite {
                return Multiply(div, solved).simplify().multiply(mul.values.1).simplify()
            } else if let solved = mul.values.1.solve(), solved.finite {
                return Multiply(div, solved).simplify().multiply(mul.values.0).simplify()
            }
        } /*else if let ln1 = values.0 as? LN, values.1.solve() != nil {
            return LN(Exponent(ln1.value.eraseToAny(), values.1))
        } else if let ln1 = values.1 as? LN, let solved = values.0.solve() {
            return LN(Exponent(ln1.value.eraseToAny(), solved))
        } */ else if let result = self.values.0.solve(), result.finite {
            return Multiply(result, self.values.1.simplify())
        } else if let result = self.values.1.solve(), result.finite && self.values.0.solve() == nil {
            return Multiply(result, self.values.0.simplify())
        }
                
        if let v = self.solve() {
            return v
        }
        
        return Multiply(values.0.simplify(), values.1.simplify())
    }
}
