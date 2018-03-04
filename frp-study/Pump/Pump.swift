import Foundation
import RxSwift

protocol Pump {
    func create(inputs: Inputs, disposeBag: DisposeBag) -> Outputs
}

protocol Pump2 {
    func create(inputs: Inputs, disposeBag: DisposeBag) -> Outputs2
}
