import Foundation
import RxSwift

protocol Pump {
    func create(inputs: Inputs, disposeBag: DisposeBag) -> Outputs
}
