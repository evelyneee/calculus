
import Foundation

func +<A: ArithmeticBlock, B: ArithmeticBlock>(lhs: A, rhs: B) -> Add {
    return lhs.add(rhs)
}
func -<A: ArithmeticBlock, B: ArithmeticBlock>(lhs: A, rhs: B) -> Sub {
    return lhs.sub(rhs)
}

func *<A: ArithmeticBlock, B: ArithmeticBlock>(lhs: A, rhs: B) -> Multiply {
    return lhs.multiply(rhs)
}
func /<A: ArithmeticBlock, B: ArithmeticBlock>(lhs: A, rhs: B) -> Divide {
    return lhs.divide(rhs)
}
func /<A: ArithmeticBlock, B: ArithmeticBlock>(lhs: A, rhs: Exponent<B>) -> Multiply {
    var exp = rhs
    exp.invert()
    return lhs.multiply(exp)
}

func ^<A: ArithmeticBlock, B: ArithmeticBlock>(lhs: A, rhs: B) -> Exponent<A> {
    return lhs.pow(rhs)
}

protocol ArithmeticBlock {
    func add<C: ArithmeticBlock>(_ additive: C) -> Add
    func sub<C: ArithmeticBlock>(_ substract: C) -> Sub
    func multiply<C: ArithmeticBlock>(_ multi: C) -> Multiply
    func divide<C: ArithmeticBlock>(_ quoti: C) -> Divide
    func pow<C: ArithmeticBlock>(_ power: C) -> Exponent<Self>
    
    func resolve(_ value: Double?) -> Double
    func integrate() throws -> (any ArithmeticBlock)
    func integrate(a: Double, b: Double, _depth: Int) throws -> Double
    func _integrate(_ ptr: inout Int) -> (any ArithmeticBlock)?
    func __integrate(_ ptr: inout Int)-> (any ArithmeticBlock)?
    func derive() -> (any ArithmeticBlock)?
    var isExponent: Bool { get }
    func simplify() -> any ArithmeticBlock
    func _underlyingType() -> any ArithmeticBlock.Type
    func _pullConstant() -> Multiply
    
    func prettyPrint() -> String
    
    var hash: Int64 { get }
    
    associatedtype A
    var values: (A, any ArithmeticBlock) { get set }
}

enum IntegrationErrors: Error {
    case recursionLimitReached
    case failure
}

extension ArithmeticBlock {
    
    typealias Integrand = Unreal.Type
    
    func add<C: ArithmeticBlock>(_ additive: C) -> Add {
        return Add(self, additive)
    }
    
    func sub<C: ArithmeticBlock>(_ substract: C) -> Sub {
        return Sub(self, substract)
    }
    
    func multiply<C: ArithmeticBlock>(_ multi: C) -> Multiply {
        return Multiply(self, multi)
    }
    
    func divide<C: ArithmeticBlock>(_ quoti: C) -> Divide {
        return Divide(self, quoti)
    }
    
    func pow<C: ArithmeticBlock>(_ power: C) -> Exponent<Self> {
        return Exponent<Self>(self, power)
    }
    
    func unreal(_ typ: Any) -> Bool {
        // Check if the type matches the struct we're looking for
        if type(of: typ) == Unreal.self || type(of: typ) == Variable.self {
            return true
        }
        
        let mirror = Mirror(reflecting: typ)

        for child in mirror.children {
            // Recursively check each property
            if unreal(child.value) {
                return true
            }
        }
        
        // If the struct was not found in the type's properties, return false
        return false
    }
    
    func solve() -> Double? {
        if !unreal(self) {
            return self.resolve(nil)
        }
        return nil
    }
    
    func solveExpression() -> any ArithmeticBlock {
        if !unreal(self) {
            return self.resolve(nil)
        }
        return self
    }
    
    var isExponent: Bool { false }
    
    func simplify() -> any ArithmeticBlock {
        return self
    }
    
    func _underlyingType() -> any ArithmeticBlock.Type {
        return type(of: self)
    }
    
    func _pullConstant() -> Multiply {
        return Multiply(1, self)
    }
    
    func derive() -> (any ArithmeticBlock)? {
        //print("Derivative of", self.prettyPrint(), "not implemented")
        return nil
    }
    
    func integrate() throws -> (any ArithmeticBlock) {
        var ptr = 0
        let value = self._integrate(&ptr)
        
        if ptr > 4000 {
            throw IntegrationErrors.recursionLimitReached
        }
        guard let value else {
            throw IntegrationErrors.failure
        }
        return value
    }
    
    func _integrate(_ ptr: inout Int) -> (any ArithmeticBlock)? {
        ptr += 1
        if ptr > 1000 {
            return nil
        }
        return self.__integrate(&ptr)
    }
    
    var hash: Int64 {
        Int64(self.prettyPrint().sorted { $0 > $1}.hashValue)
    }
}

struct AnyArithmetic: ArithmeticBlock {
    var values: (any ArithmeticBlock, any ArithmeticBlock) = (Unreal(), Unreal())
    
    var hash: Int64 {
        self.i.hash
    }
    
    func prettyPrint() -> String {
        return self.i.prettyPrint()
    }
    
    var i: any ArithmeticBlock
    
    init(_ i: any ArithmeticBlock) {
        self.i = i
    }
    
    func resolve(_ value: Double?) -> Double {
        return i.resolve(value)
    }
    
    func __integrate(_ ptr: inout Int)-> (any ArithmeticBlock)? {
        return self.i.__integrate(&ptr)
    }
    
    func derive() -> (any ArithmeticBlock)? {
        self.i.derive()
    }
    
    func _underlyingType() -> any ArithmeticBlock.Type {
        return type(of: self.i)
    }
}

extension ArithmeticBlock {
    func eraseToAny() -> AnyArithmetic {
        AnyArithmetic(self)
    }
}

struct Exponent<A: ArithmeticBlock>: ArithmeticBlock {
        
    func prettyPrint() -> String {
//        if self.values.0 is Multiply {
//            return self.simplify().prettyPrint()
//        }
        if self.values.0.solve() == exp(1) {
            return "e" +
            self.values.1.prettyPrint()
                .replacingOccurrences(of: "(", with: "⁽")
                .replacingOccurrences(of: ")", with: "⁾")
                .replacingOccurrences(of: " ", with: "")
                .replacingOccurrences(of: "+", with: "⁺")
                .replacingOccurrences(of: "-", with: "⁻")
                .replacingOccurrences(of: "0", with: "⁰")
                .replacingOccurrences(of: "1", with: "¹")
                .replacingOccurrences(of: "2", with: "²")
                .replacingOccurrences(of: "3", with: "³")
                .replacingOccurrences(of: "4", with: "⁴")
                .replacingOccurrences(of: "5", with: "⁵")
                .replacingOccurrences(of: "6", with: "⁶")
                .replacingOccurrences(of: "7", with: "⁷")
                .replacingOccurrences(of: "8", with: "⁸")
                .replacingOccurrences(of: "9", with: "⁹")
                .replacingOccurrences(of: "x", with: "ˣ")
        }
        if self.values.1.solve()?.truncatingRemainder(dividingBy: 1) == 0 {
            return self.values.0.simplify().prettyPrint() +
            self.values.1.prettyPrint()
                .replacingOccurrences(of: "(", with: "⁽")
                .replacingOccurrences(of: ")", with: "⁾")
                .replacingOccurrences(of: " ", with: "")
                .replacingOccurrences(of: "+", with: "⁺")
                .replacingOccurrences(of: "-", with: "⁻")
                .replacingOccurrences(of: "0", with: "⁰")
                .replacingOccurrences(of: "1", with: "¹")
                .replacingOccurrences(of: "2", with: "²")
                .replacingOccurrences(of: "3", with: "³")
                .replacingOccurrences(of: "4", with: "⁴")
                .replacingOccurrences(of: "5", with: "⁵")
                .replacingOccurrences(of: "6", with: "⁶")
                .replacingOccurrences(of: "7", with: "⁷")
                .replacingOccurrences(of: "8", with: "⁸")
                .replacingOccurrences(of: "9", with: "⁹")
                .replacingOccurrences(of: "x", with: "ˣ")
        }
        return "(" + self.values.0.simplify().prettyPrint() + "^" + self.values.1.simplify().prettyPrint() + ")"
    }
    
    func resolve(_ value: Double? = nil) -> Double {
        return Foundation.pow(self.values.0.resolve(value), self.values.1.resolve(value))
    }
    
    var values: (A, any ArithmeticBlock)
    
    init(_ lhs: A, _ rhs: any ArithmeticBlock) {
        self.values = (lhs, rhs)
    }
    
    typealias Integrand = Multiply
    
    func __integrate(_ ptr: inout Int)-> (any ArithmeticBlock)? {
        let values = (self.values.0.simplify(), self.values.1.simplify())
        
        if values.1.solve() != nil && values.1.solve() == -1, let value = values.0.derive() as? Double {
            return LN(values.0).divide(value).simplify()
        } else if values.1.solve() != nil && values.1.solve() != -1, let value = values.0.derive() as? Double {
            var new = self
            if let val = new.values.1 as? Double {
                new.values.1 = val + 1
            } else {
                new.values.1 = Add(new.values.1, 1)
            }
            return Multiply(Divide(1, 1+values.1.resolve(nil)), new).divide(value).simplify()
        } else if let solved = values.1.solve(),
                    values.1.solve() != -1,
                    let multiply = values.0 as? Multiply,
                    let mulValue = multiply.values.0 as? Double ?? multiply.values.1 as? Double,
                    let variable = multiply.values.1 as? Variable ?? multiply.values.0 as? Variable {
            return Divide(1, 1+solved).multiply(Exponent<Variable>(variable, solved + 1) * (mulValue.pow(solved)))
        } else if values.0.solve() == exp(1), let dx = values.1.derive()?.solve() {
            return self.divide(dx).simplify()
        }
        
        // TRIGONOMETRY RULES
        
        // (sinx)^2
        if self.values.0.hash == sin(Variable()).hash && self.values.1.solve() == 2 {
            return Variable().divide(2)-sin(2*Variable())/4
        }
        
        // (cosx)^2
        if self.values.0.hash == cos(Variable()).hash && self.values.1.solve() == 2 {
            return Variable().divide(2)+sin(2*Variable())/4
        }
        
        // (tanx)^2
        if self.values.0.hash == tan(Variable()).hash && self.values.1.solve() == 2 {
            return tan(Variable()) - Variable()
        }
        
        // (cotx)^2
        if self.values.0.hash == cot(Variable()).hash && self.values.1.solve() == 2 {
            return -1*cot(Variable()) - Variable()
        }
        
        // (secx)^2
        if self.values.0.hash == sec(Variable()).hash && self.values.1.solve() == 2 {
            return tan(Variable())
        }
        
        // (cscx)^2
        if self.values.0.hash == csc(Variable()).hash && self.values.1.solve() == 2 {
            return -1*cot(Variable())
        }
        
        // LAST RESORT
        
        if let solved = self.values.1.solve() {
            return Multiply(self.values.0, self.values.0.pow(solved - 1).simplify()).integrateByParts(&ptr)
        }
        
        return Multiply(1, self).integrateByParts(&ptr)
    }
    
    func expandPolynomial() -> any ArithmeticBlock {
        if (self.values.1 as? Double ?? 0) > 1, let add = self.values.0 as? Add {
            if self.values.1 as? Double == 2 {
                return Add(add.values.0 * add.values.0, Add(Multiply(2, Multiply(add.values.0, add.values.1).simplify()), add.values.1*add.values.1))
            }
            return Multiply(Add(add.values.0 * add.values.0, Add(Multiply(2, Multiply(add.values.0, add.values.1)), add.values.1*add.values.1)), Exponent(self.values.0, self.values.1.resolve(0) - 2).expandPolynomial())
        } else if (self.values.1 as? Double ?? 0) > 1, let add = self.values.0 as? Sub {
            if self.values.1 as? Double == 2 {
                return Sub(add.values.0 * add.values.0, Sub(Multiply(2, Multiply(add.values.0, add.values.1).simplify()), add.values.1*add.values.1))
            }
            return Multiply(Sub(add.values.0 * add.values.0, Sub(Multiply(2, Multiply(add.values.0, add.values.1)), add.values.1*add.values.1)), Exponent(self.values.0, self.values.1.resolve(0) - 2).expandPolynomial())
        }
        return self
    }
    
    func derive() -> (any ArithmeticBlock)? {
        
        if let dx = self.values.1.derive(), self.values.0.solve() == exp(1) {
            return dx*self
        }
        
        if self.values.1 as? Double == 1 {
            return self.values.0.derive()
        }
        if self.values.0 is Variable, self.values.1 as? Double == 1 {
            return self.values.1
        } else if self.values.0 is Variable, self.values.1 is Double {
            return Multiply(self.values.1, Exponent(self.values.0, self.values.1 as! Double - 1))
        }
        if let dx = self.values.0.derive(), let solved = self.values.1.solve() {
            return Multiply(Multiply(self.values.1, dx), Exponent(self.values.0, solved - 1))
        }
        return nil
    }
    
    func simplify() -> any ArithmeticBlock {
        if let val = self.values.1 as? Double, val == 1 {
            return self.values.0
        } else if let val = self.values.1 as? Double, val == 0 {
            return 1
        }
        if let solved = values.1.solve(),
                    values.1.solve() != -1,
                    let multiply = values.0 as? Multiply,
                    let mulValue = multiply.values.0 as? Double ?? multiply.values.1 as? Double,
                    let variable = multiply.values.1 as? Variable ?? multiply.values.0 as? Variable {
            return Multiply(mulValue.pow(solved).resolve(), Exponent<Variable>(variable, solved))
        }
        return self
    }
    
    mutating func invert() {
        
        if var solved = self.values.1.solve() {
            solved.negate()
            self.values.1 = solved
            return
        }
        
        if let mul = self.values.1 as? Multiply, mul.values.1.solve() == -1 {
            self.values.1 = mul.values.0
        }
        self.values.1 = Multiply(self.values.1, -1)
    }
    
    var isExponent: Bool { true }
}

struct LN: ArithmeticBlock {
    
    var values: (any ArithmeticBlock, any ArithmeticBlock) = (Unreal(), Unreal())
    
    func prettyPrint() -> String {
        return "LN("+self.values.0.prettyPrint()+")"
    }
    
    func resolve(_ value: Double? = nil) -> Double {
        return log(abs(self.values.0.resolve(value)))
    }
        
    init(_ lhs: any ArithmeticBlock) {
        self.values.0 = lhs
    }
    
    typealias Integrand = Multiply
    
    func __integrate(_ ptr: inout Int)-> (any ArithmeticBlock)? {
        return Multiply(1, self).integrateByParts(&ptr)
    }
    
    func derive() -> (any ArithmeticBlock)? {
        guard let dx = self.values.0.derive() else { return nil }
        return dx.divide(self.values.0)
    }
}

struct Unreal: ArithmeticBlock {
    
    var values: (any ArithmeticBlock, any ArithmeticBlock) = (0, 0)
    
    init() {
    }
    
    func prettyPrint() -> String {
        "∄"
    }
    
    func add<C: ArithmeticBlock>(_ additive: C) -> Self {
        return self
    }
    
    func sub<C: ArithmeticBlock>(_ substract: C) -> Self {
        return self
    }
    
    func resolve(_ value: Double? = nil) -> Double {
        0
    }
    
    typealias Integrand = Unreal
    
    func __integrate(_ ptr: inout Int)-> (any ArithmeticBlock)? {
        return Unreal()
    }
}

extension String: Error {
    var localizedDescription: String { self }
}

struct Variable: ArithmeticBlock {
    func prettyPrint() -> String {
        return "x"
    }
    
    typealias Integrand = Multiply
    
    func resolve(_ valu: Double? = nil) -> Double {
        if let value, !unreal {
            return value
        } else if let valu {
            return valu
        }
        return -1
    }
    
    func solve() -> Double? {
        if let value, !unreal {
            return value
        } else {
            return nil
        }
    }
    
    var values: (any ArithmeticBlock, any ArithmeticBlock) = (Unreal(), Unreal())
    var unreal: Bool
    var value: Double?
    
    init(_ value: Double? = nil, unreal: Bool = false) {
        self.value = value
        self.unreal = unreal
    }
    
    func __integrate(_ ptr: inout Int) -> (any ArithmeticBlock)? {
        return Multiply(Divide(1, 2).resolve(), Exponent(self, 2))
    }
    
    func derive() -> (any ArithmeticBlock)? {
        return 1
    }
}

extension Double: ArithmeticBlock {
    
    typealias A = any ArithmeticBlock
    var values: (any ArithmeticBlock, any ArithmeticBlock) {
        get {
            (Unreal(), Unreal())
        }
        set {
        }
    }
            
    func prettyPrint() -> String {
        
        if self.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(self))"
        }
        
        return "\(self)"
    }
    
    func add<C: ArithmeticBlock>(_ additive: C) -> Add {
        return Add(self, additive)
    }
    
    func sub<C: ArithmeticBlock>(_ substract: C) -> Sub {
        return Sub(self, substract)
    }
    
    func resolve(_ value: Double? = nil) -> Double {
        self
    }
    
    typealias Integrand = Multiply
    
    func __integrate(_ ptr: inout Int)-> (any ArithmeticBlock)? {
        return Multiply(self, Variable())
    }
    func derive() -> (any ArithmeticBlock)? {
        return 0
    }
    
    var finite: Bool { truncatingRemainder(dividingBy: 0.5) == 0 }
}
