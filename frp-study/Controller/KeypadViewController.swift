import UIKit
import RxSwift
import RxCocoa
import FrpStudyHelper

class KeypadNamespace {

class Keypad {
    let value: BehaviorRelay<Int>
    let beep: Signal<Void>

    convenience init(keypad: Signal<Key>, clear: Signal<Int>, active: BehaviorRelay<Bool>) {
        let filteredKeypad = keypad
            .withLatestFrom(active.asSignal(onErrorSignalWith: .empty())) { ($0, $1) }
            .filter { return $1 == true }
            .map { $0.0 }
        self.init(keypad: filteredKeypad, clear: clear)
    }

    init(keypad: Signal<Key>, clear: Signal<Int>) {
        let value = BehaviorRelay<Int>(value: 0)
        self.value = value
        let keyUpdated: Signal<Int> = keypad
            .withLatestFrom(value.asSignal(onErrorSignalWith: .empty())) { ($0, $1) }
            .flatMap { (key, value) -> Signal<Int> in
                if key == .clear {
                    return .just(0)
                } else {
                    let x10: Int = value * 10
                    if x10 >= 1000 {
                        return .empty()
                    } else {
                        return .just(x10 + key.rawValue)
                    }
                }
            }
        beep = keyUpdated.map { _ in }
    }
}

class KeypadPump: Pump {
    func create(inputs: Inputs, disposeBag: DisposeBag) -> Outputs {
        let keypad = Keypad(keypad: inputs.keyPad, clear: .never())
        let value = BehaviorRelay<String>(value: "")
        keypad.value
            .map { String($0) }
            .bind(to: value)
            .disposed(by: disposeBag)
        return Outputs(presetLCD: value)
    }
}

class KeypadPumpViewController: UIViewController {
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
        
        func convertToUpDownSignal(_ button: UIButton) -> Signal<UpDown> {
            return button.rx
                .tap
                .map { button.isSelected }
                .map { ($0 ?? false) ? UpDown.up : UpDown.down }
                .asSignal(onErrorSignalWith: .empty())
        }
        let nozzle1: Signal<UpDown> = convertToUpDownSignal(v.nozzleButtons[0])
        let nozzle2: Signal<UpDown> = convertToUpDownSignal(v.nozzleButtons[1])
        let nozzle3: Signal<UpDown> = convertToUpDownSignal(v.nozzleButtons[2])
        var buttons = v.numberButtons.map { btn in btn.rx.tap.map { Key(rawValue: btn.tag)! }.asSignal(onErrorSignalWith: .empty()) }
        buttons.append(v.clearButton.rx.tap.map { Key.clear }.asSignal(onErrorSignalWith: .empty()))
        let keyPad: Signal<Key> = Signal<Key>.merge(buttons)
        let fuelPulsesRelay = PublishRelay<Int>()
        let fuelPulses: Signal<Int> = fuelPulsesRelay.asSignal()
        let calibration = BehaviorRelay<Double>(value: 1.0)
        let price1 = BehaviorRelay<Double>(value: 1.0)
        let price2 = BehaviorRelay<Double>(value: 2.0)
        let price3 = BehaviorRelay<Double>(value: 3.0)
        let clearSale: Signal<Int> = v.saleOKButton.rx.tap.map { 0 }.asSignal(onErrorSignalWith: .empty())
        
        let inputs = Inputs(nozzle1: nozzle1, nozzle2: nozzle2, nozzle3: nozzle3, keyPad: keyPad, fuelPulses: fuelPulses, calibration: calibration, price1: price1, price2: price2, price3: price3, clearSale: clearSale)
        
        let outputs = KeypadPump().create(inputs: inputs, disposeBag: disposeBag)
        outputs.presetLCD
            .bind(to: v.presetLabel.rx.text)
            .disposed(by: disposeBag)
    }
}


}
