import Foundation
import RxSwift
import RxCocoa

class AccumulatePulsesPump: Pump {
    func create(inputs: Inputs, disposeBag: DisposeBag) -> Outputs {
        let lc = LifeCycle(nozzle1: inputs.nozzle1,
                           nozzle2: inputs.nozzle2,
                           nozzle3: inputs.nozzle3,
                           disposeBag: disposeBag)
        let littersDelivered = AccumulatePulsesPump.accumulate(sClearAccumulator: lc.start.map { _ in },
                                                               sPulses: inputs.fuelPulses,
                                                               calibration: inputs.calibration,
                                                               disposeBag: disposeBag)
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
        let dCell = BehaviorRelay<Delivery>(value: .off)
        d.drive(dCell).disposed(by: disposeBag)

        let lcd = littersDelivered.map { q -> String in
            return Formatters.formatSaleQuantity(quantity: q)
            }
            .asDriver(onErrorDriveWith: .empty())
        let lcdCell = BehaviorRelay<String>(value: "")
        lcd.drive(lcdCell).disposed(by: disposeBag)

        return Outputs(delivery: dCell, saleQuantityLCD: lcdCell)
    }

    static func accumulate(sClearAccumulator: Signal<Void>,
                           sPulses: Signal<Int>,
                           calibration: BehaviorRelay<Double>,
                           disposeBag: DisposeBag) -> BehaviorRelay<Double> {
        let total = BehaviorRelay<Double>(value: 0)
        Signal<Double>.combineLatest(
            Signal<Double>.merge(
                sClearAccumulator.map { _ in 0 },
                sPulses.map { Double($0) }.withLatestFrom(total.asSignal(onErrorJustReturn: 0)) { $0 + $1 }
            ),
            calibration.asSignal(onErrorJustReturn: 0)) { $0 * $1 }
            .emit(onNext: total.accept)
            .disposed(by: disposeBag)
        return total
    }
}
