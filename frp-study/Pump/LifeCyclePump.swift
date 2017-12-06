import Foundation
import RxSwift
import RxCocoa

class LifeCyclePump: Pump {
    func create(inputs: Inputs, disposeBag: DisposeBag) -> Outputs {
        let lc = LifeCycle(nozzle1: inputs.nozzle1,
                           nozzle2: inputs.nozzle2,
                           nozzle3: inputs.nozzle3)
        let d = lc.fillActive.map { fuel -> Delivery in
            switch fuel {
            case .some(.one):
                return .fast1
            case .some(.two):
                return .fast2
            case .some(.three):
                return .fast3
            case .none:
                return .off
            }
            }
            .asDriver(onErrorDriveWith: .empty())
        let lcd = lc.fillActive.map { fuel -> String in
            return fuel?.description ?? ""
            }
            .asDriver(onErrorDriveWith: .empty())

        let dCell = BehaviorRelay<Delivery>(value: .off)
        d.drive(dCell).disposed(by: disposeBag)

        let lcdCell = BehaviorRelay<String>(value: "")
        lcd.drive(lcdCell).disposed(by: disposeBag)
        return Outputs(delivery: dCell, saleQuantityLCD: lcdCell)
    }
}
