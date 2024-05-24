
import Foundation

struct sin: ArithmeticBlock {
    
    var values: (any ArithmeticBlock, any ArithmeticBlock) = (Unreal(), Unreal())
        
    init(_ value: any ArithmeticBlock) {
        self.values.0 = value
    }
    
    func resolve(_ value: Double?) -> Double {
        return Foundation.sin(self.values.0.resolve(value))
    }
    
    func __integrate(_ ptr: inout Int)-> (any ArithmeticBlock)? {
        if let constant = self.values.0.derive() as? Double {
            return Divide(cos.init(self.values.0), -1*constant)
        }
        return Multiply(1, self).integrateByParts(&ptr)
    }
    
    func prettyPrint() -> String {
        return "sin"+self.values.0.prettyPrint()
    }
    
    func derive() -> (any ArithmeticBlock)? {
        guard let derivative = self.values.0.derive() else {
            return nil
        }
        return Multiply(derivative, cos.init(self.values.0))
    }
}

struct cos: ArithmeticBlock {
    
    var values: (any ArithmeticBlock, any ArithmeticBlock) = (Unreal(), Unreal())
        
    init(_ value: any ArithmeticBlock) {
        self.values.0 = value
    }
    
    func resolve(_ value: Double?) -> Double {
        return Foundation.cos(self.values.0.resolve(value))
    }
    
    func __integrate(_ ptr: inout Int)-> (any ArithmeticBlock)? {
        if let constant = self.values.0.derive() as? Double {
            return Divide(sin.init(self.values.0), constant)
        }
        return Multiply(1, self).integrateByParts(&ptr)
    }
    
    func prettyPrint() -> String {
        return "cos"+self.values.0.prettyPrint()
    }
    
    func derive() -> (any ArithmeticBlock)? {
        guard let derivative = self.values.0.derive() else {
            return nil
        }
        return Multiply(Multiply(-1, derivative), sin.init(self.values.0))
    }
}

struct csc: ArithmeticBlock {
    
    var values: (any ArithmeticBlock, any ArithmeticBlock) = (Unreal(), Unreal())
        
    init(_ value: any ArithmeticBlock) {
        self.values.0 = value
    }
    
    func resolve(_ value: Double?) -> Double {
        return 1/Foundation.sin(self.values.0.resolve(value))
    }
    
    func __integrate(_ ptr: inout Int)-> (any ArithmeticBlock)? {
        if let constant = self.values.0.derive() as? Double {
            return Divide(LN(csc(self.values.0) - cot(self.values.0)), -1*constant)
        }
        return Multiply(1, self).integrateByParts(&ptr)
    }
    
    func prettyPrint() -> String {
        return "csc"+self.values.0.prettyPrint()
    }
    
    func derive() -> (any ArithmeticBlock)? {
        guard let derivative = self.values.0.derive() else {
            return nil
        }
        return Multiply(-1*derivative, Multiply(csc(self.values.0), cot(self.values.0)))
    }
}

struct sec: ArithmeticBlock {
    
    var values: (any ArithmeticBlock, any ArithmeticBlock) = (Unreal(), Unreal())
        
    init(_ value: any ArithmeticBlock) {
        self.values.0 = value
    }
    
    func resolve(_ value: Double?) -> Double {
        return 1/Foundation.cos(self.values.0.resolve(value))
    }
    
    func __integrate(_ ptr: inout Int)-> (any ArithmeticBlock)? {
        if let constant = self.values.0.derive() as? Double {
            return Divide(LN(sec(self.values.0) + tan(self.values.0)), constant)
        }
        return Multiply(1, self).integrateByParts(&ptr)
    }
    
    func prettyPrint() -> String {
        return "sec"+self.values.0.prettyPrint()
    }
    
    func derive() -> (any ArithmeticBlock)? {
        guard let derivative = self.values.0.derive() else {
            return nil
        }
        return Multiply(derivative, Multiply(sec(self.values.0), tan(self.values.0)))
    }
}

struct tan: ArithmeticBlock {
    
    var values: (any ArithmeticBlock, any ArithmeticBlock) = (Unreal(), Unreal())
        
    init(_ value: any ArithmeticBlock) {
        self.values.0 = value
    }
    
    func resolve(_ value: Double?) -> Double {
        return Foundation.tan(self.values.0.resolve(value))
    }
    
    func __integrate(_ ptr: inout Int)-> (any ArithmeticBlock)? {
        if let constant = self.values.0.derive() as? Double {
            return Divide(LN(sec(self.values.0)), constant)
        }
        return Multiply(1, self).integrateByParts(&ptr)
    }
    
    func prettyPrint() -> String {
        return "tan"+self.values.0.prettyPrint()
    }
    
    func derive() -> (any ArithmeticBlock)? {
        guard let derivative = self.values.0.derive() else {
            return nil
        }
        return Multiply(derivative, sec.init(self.values.0).pow(2))
    }
}

struct cot: ArithmeticBlock {
    
    var values: (any ArithmeticBlock, any ArithmeticBlock) = (Unreal(), Unreal())
        
    init(_ value: any ArithmeticBlock) {
        self.values.0 = value
    }
    
    func resolve(_ value: Double?) -> Double {
        return 1/Foundation.tan(self.values.0.resolve(value))
    }
    
    func __integrate(_ ptr: inout Int)-> (any ArithmeticBlock)? {
        if let constant = self.values.0.derive() as? Double {
            return Divide(LN(sin(self.values.0)), constant)
        }
        return Multiply(1, self).integrateByParts(&ptr)
    }
    
    func prettyPrint() -> String {
        return "cot"+self.values.0.prettyPrint()
    }
    
    func derive() -> (any ArithmeticBlock)? {
        
        guard let derivative = self.values.0.derive() else {
            return nil
        }
        return Multiply(Multiply(-1, derivative), csc.init(self.values.0).pow(2))
    }
}

