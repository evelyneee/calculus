
import Foundation

func factorial(factorialNumber: Int) -> Int {
    if factorialNumber == 0 {
        return 1
    } else {
        return factorialNumber * factorial(factorialNumber: factorialNumber - 1)
    }
}

enum MacLaurinError: Error {
    case failedToIntegrate
    case failedToDerive(remainder: Double)
    case unreal
}

// Approximates an expression's value using MacLaurin series
func solveMacLaurin(_ expr: any ArithmeticBlock, point: Double = 0, value: Double, lowerValue: Double? = nil, depth: Int = 7, integrated: Bool = false) throws -> Double {
    var sum: Double = expr.resolve(point)
    var newExpr = expr
    for i in 1..<depth {
        guard let dx = newExpr.derive() else {
            print("Couldn't derive the expression any further : "+newExpr.prettyPrint())
            throw MacLaurinError.failedToDerive(remainder: sum)
        }
        newExpr = dx
        print(dx.prettyPrint())
        var xExpr: any ArithmeticBlock = (X().pow(Double(i)))
        if integrated {
            guard let int = try? xExpr.integrate() else {
                print("Couldn't integrate the MacLaurin series power"+xExpr.prettyPrint())
                throw MacLaurinError.failedToIntegrate
            }
            xExpr = int
        }
        sum += newExpr.resolve(0)*xExpr
            .divide(Double(factorial(factorialNumber: i)))
            .resolve(value)
        if let lowerValue {
            sum -= newExpr.resolve(0)*((X().pow(Double(i)))
                .divide(Double(factorial(factorialNumber: i))))
                .resolve(lowerValue)
        }
    }
    if sum.isNaN || !sum.isFinite {
        throw MacLaurinError.unreal
    }
    return sum
}

struct DefiniteIntegralError: Error {
    var localizedDescription: String {
        return self.integral.localizedDescription + " & " + self.macLaurin.localizedDescription
    }
    var integral: Error
    var macLaurin: Error
}

extension ArithmeticBlock {
    func integrate(a: Double, b: Double, _depth: Int = 7) throws -> Double {
        do {
            let int = try self.integrate()
            return int.resolve(a)-int.resolve(b)
        } catch {
            let err1 = error
            do {
                let val = try solveMacLaurin(self, point: 0, value: a, lowerValue: b, depth: _depth, integrated: true)
                return val
            } catch {
                throw DefiniteIntegralError(integral: err1, macLaurin: error)
            }
        }
    }
}
