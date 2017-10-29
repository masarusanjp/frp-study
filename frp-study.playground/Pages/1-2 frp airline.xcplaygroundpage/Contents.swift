//: [Previous](@previous)

import Foundation
import SodiumSwift

let depDate = Cell<String>(value: "2017-09-16")
let retDate = Cell<String>(value: "2017-09-23")
let valid = depDate.lift(retDate) { $0 < $1 }

valid.listen { print($0) }

//: [Next](@next)
