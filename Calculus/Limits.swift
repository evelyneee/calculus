
import Foundation

enum LimitDirection {
    case upper(Double)
    case center(Double)
    case lower(Double)
    case infinity
    case negativeInfinity
}

enum LimitErrors: Error {
    case asymptotic
}

func lim(towards direction: LimitDirection, of expr: any ArithmeticBlock) throws -> Double {
    switch direction {
    case .upper(let double):
        let val = double+Double.leastNonzeroMagnitude
        return expr.resolve(val)
    case .center(let double):
        let down = try lim(towards: .lower(double), of: expr)
        let up = try lim(towards: .upper(double), of: expr)
        if down == up {
            return down
        }
        throw LimitErrors.asymptotic
    case .lower(let double):
        let val = double + -1 * Double.leastNonzeroMagnitude
        return expr.resolve(val)
    case .infinity:
        return expr.resolve(Double.infinity)
    case .negativeInfinity:
        return expr.resolve(-1 * Double.infinity)
    }
}
