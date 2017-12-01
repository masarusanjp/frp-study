import UIKit
import RxSwift
import RxCocoa
import FrpStudyHelper

class AccumulatePulsesPump: Pump {
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

    static func accumulate(sClearAccumulator: Signal<Void>,
                           sPulses: Signal<Double>,
                           calibration: BehaviorRelay<Double>,
                           disposeBag: DisposeBag) -> BehaviorRelay<Double> {
        let total = BehaviorRelay<Double>(value: 0)
        Signal<Double>.combineLatest(
            Signal<Double>.merge(
                sClearAccumulator.map { _ in 0 },
                sPulses.withLatestFrom(total.asSignal(onErrorJustReturn: 0)) { $0 + $1 }
            ),
            calibration.asSignal(onErrorJustReturn: 0)) { $0 * $1 }
            .emit(onNext: total.accept)
            .disposed(by: disposeBag)
        return total
    }
}

class AccumulatePulsesPumpViewController: UIViewController {
    let disposeBag = DisposeBag()
    override func loadView() {
        super.loadView()
        let frame = self.view.frame
        let pompView = PompView.make()
        pompView.frame = frame
        view = pompView
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        let v = view as! PompView
        
        func converToUpDownSignal(_ button: UIButton) -> Signal<UpDown> {
            return button.rx
                .observe(Bool.self, "isSelected")
                .map { ($0 ?? false) ? UpDown.up : UpDown.down }
                .asSignal(onErrorSignalWith: .empty())
        }
        let nozzle1: Signal<UpDown> = converToUpDownSignal(v.nozzleButtons[0])
        let nozzle2: Signal<UpDown> = converToUpDownSignal(v.nozzleButtons[1])
        let nozzle3: Signal<UpDown> = converToUpDownSignal(v.nozzleButtons[2])
        let keyPad: Signal<Key> = Signal<Key>.merge(v.numberButtons.map { btn in btn.rx.tap.map { Key(rawValue: btn.tag)! }.asSignal(onErrorSignalWith: .empty()) })
        let fuelPulses: Signal<Int> = .empty()
        let calibration = BehaviorRelay<Double>(value: 1.0)
        let price1 = BehaviorRelay<Double>(value: 1.0)
        let price2 = BehaviorRelay<Double>(value: 2.0)
        let price3 = BehaviorRelay<Double>(value: 3.0)
        let clearSale: Signal<Int> = .empty()
        
        let inputs = Inputs(nozzle1: nozzle1, nozzle2: nozzle2, nozzle3: nozzle3, keyPad: keyPad, fuelPulses: fuelPulses, calibration: calibration, price1: price1, price2: price2, price3: price3, clearSale: clearSale)
        
        let lifeCyclePumpOutputs = LifeCyclePump().create(inputs: inputs, disposeBag: disposeBag)
        lifeCyclePumpOutputs.presetLCD
            .bind(to: v.litersLabel.rx.text)
            .disposed(by: disposeBag)
        lifeCyclePumpOutputs.delivery
            .map { $0.rawValue }
            .bind(to: v.dollarsLabel.rx.text)
            .disposed(by: disposeBag)
    }
}
