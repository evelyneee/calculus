import Foundation

typealias X = Variable

extension ArithmeticBlock {
    func doIntegrationTest() {
        do {
            Swift.print("ƒ "+self.prettyPrint()+" dx = " + (try self.integrate().simplify().prettyPrint()))
        } catch { Swift.print(self.prettyPrint(), error)}
    }
}

func sqrt<T>(_ expr: T) -> Exponent<T> {
    expr.pow(0.5)
}

// Symbolic integrals

(exp(1)^X()).doIntegrationTest()

(4*(X()^2)).doIntegrationTest()

(2/(X()^3)).doIntegrationTest()

((X()^2) * (exp(1)^X())).doIntegrationTest()

(3 * X() + 5).doIntegrationTest()

LN(X()).doIntegrationTest()

((X() - 1)^2).doIntegrationTest()

LN(X()).doIntegrationTest()

((1/X())).doIntegrationTest()
((X()^3) - (2*X()) + 4).doIntegrationTest()
(exp(1)^(X())).doIntegrationTest()
((X() - 1)^4).doIntegrationTest()
((X()^(-1/2))).doIntegrationTest()
((2*X() + 3)^2).doIntegrationTest()
((X()^4) * (2*X() + 3)).doIntegrationTest()
((X()^10) / (2*X() + 3)).doIntegrationTest()
(1*(sin(X()^2))).doIntegrationTest()

// Definite integrals

print(try! (exp(1)^(3*X())).integrate(a: -5, b: Double.infinity * -1))

// Variable change in integrals

let e1 = (((X()^2 + 1)^2))
print("ƒ"+e1.prettyPrint()+" dx = "+(replaceVariableAndSolve(e1)?.prettyPrint() ?? (try! e1.integrate().prettyPrint())))

let e2: any ArithmeticBlock = ((2*X())/((X()^2 + 1)^2))
print("ƒ"+e2.prettyPrint()+" dx = "+(replaceVariableAndSolve(e2)?.prettyPrint() ?? Unreal().prettyPrint()))

let e3: any ArithmeticBlock = ((2*X())/((X()^2 + 1)))
print("ƒ"+e3.prettyPrint()+" dx = "+(replaceVariableAndSolve(e3)?.prettyPrint() ?? Unreal().prettyPrint()))

// Limits

let int = try! (exp(1)^(3*X())).integrate()
let pt1: Double = int.resolve(-5)
print(try! lim(towards: .negativeInfinity, of: pt1-int))
