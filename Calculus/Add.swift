
import Foundation

struct Add: ArithmeticBlock {
    
    func prettyPrint() -> String {
        return "(" + self.values.0.simplify().prettyPrint() + " + " + self.values.1.simplify().prettyPrint() + ")"
    }
    
        
    func resolve(_ value: Double? = nil) -> Double {
        return self.values.0.resolve(value) + self.values.1.resolve(value)
    }
    
    var values: (any ArithmeticBlock, any ArithmeticBlock)
    
    init(_ lhs: any ArithmeticBlock, _ rhs: any ArithmeticBlock) {
        self.values = (lhs, rhs)
    }
    
    func __integrate(_ ptr: inout Int)-> (any ArithmeticBlock)? {
        if let int1 = self.values.0._integrate(&ptr), let int2 = self.values.1._integrate(&ptr) {
            return Add(int1, int2)
        }
        print("Failed to integrate both sides of Add")
        return nil
    }
    
    func derive() -> (any ArithmeticBlock)? {
        if self.values.0.simplify() is Double {
            return self.values.1.derive()
        } else if self.values.1.simplify() is Double {
            return self.values.0.derive()
        }
        if let a = self.values.0.derive(), let b = self.values.1.derive() {
            return a + b
        }
        return nil
    }
    
    func simplify() -> any ArithmeticBlock {
        Add(self.values.0.simplify(), self.values.1.simplify())
    }
}

struct Sub: ArithmeticBlock {
        
    func prettyPrint() -> String {
        return "(" + self.values.0.simplify().prettyPrint() + " - " + self.values.1.simplify().prettyPrint() + ")"
    }
    
    func resolve(_ value: Double? = nil) -> Double {
        return self.values.0.resolve(value) - self.values.1.resolve(value)
    }
    
    var values: (any ArithmeticBlock, any ArithmeticBlock)

    init(_ lhs: any ArithmeticBlock, _ rhs: any ArithmeticBlock) {
        self.values = (lhs, rhs)
    }
    
    typealias Integrand = Multiply
    
    func __integrate(_ ptr: inout Int)-> (any ArithmeticBlock)? {
        if let int1 = self.values.0._integrate(&ptr), let int2 = self.values.1._integrate(&ptr) {
            return Sub(int1, int2)
        }
        print("Failed to integrate both sides of Add")
        return nil
    }
    
    func derive() -> (any ArithmeticBlock)? {
        if let val = self.values.0.simplify() as? Double {
            return self.values.1.derive()
        } else if let val = self.values.1.simplify() as? Double {
            return self.values.0.derive()
        }
        if let a = self.values.0.derive(), let b = self.values.1.derive() {
            return a - b
        }
        return nil
    }
    
    func simplify() -> any ArithmeticBlock {
        return Sub(self.values.0.simplify(), self.values.1.simplify())
    }
}
