import UIKit
import RxSwift
import RxCocoa
import FrpStudyHelper

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
